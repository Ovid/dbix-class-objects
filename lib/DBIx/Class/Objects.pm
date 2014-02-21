package DBIx::Class::Objects;

use Moose;
use Carp;

# using this because it will be applied to result classes, not because we want
# to import this behavior
use DBIx::Class::Objects::Role::Result;

use Class::Load 'try_load_class';
use namespace::autoclean;

our $VERSION = '0.01';

has 'schema' => (
    is       => 'ro',
    isa      => 'DBIx::Class::Schema',
    required => 1,
);

has 'debug' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has 'base_class' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    default  => 'DBIx::Class::Objects::Base',
);

has 'result_role' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
    default  => 'DBIx::Class::Objects::Role::Result',
);

has 'object_base' => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,  # XXX Fix this later
    writer   => '_set_object_base',
);

sub get_object_class_name {
    my ( $self, $source_name ) = @_;
    return $self->object_base . '::' . $source_name;
}

sub objectset {
    my ( $self, $source_name ) = @_;

    return $self->_create_object_set(
        $self->schema->resultset($source_name) );
}

sub _create_object_set {

    # this method allows the user to ensure that resultsets contain instances
    # of DBIx::Class::Objects instead of DBIx::Class::Result
    my ( $self, $resultset ) = @_;

    my %methods;
    foreach my $method (qw/find next/) {

        # Haven't debugged this, but simply declaring a single subroutine and
        # assigning it to the keys doesn't work. You get errors like this:
        #
        # DBIx::Class::ResultSet::find(): find() expects either a column/value
        # hashref, or a list of values corresponding to the columns of the
        # specified unique constraint 'primary' at t/resultset.t line 30
        #
        # Doing it this way results in a fresh copy of the subref for every
        # method at a slight performance cost. Caching bug?
        $methods{$method} = sub {
            my $this         = shift;
            my $result       = $this->next::method(@_) or return;
            my $source_name  = $result->result_source->source_name;
            unless ($source_name) {
                my $type = ref $result;
                croak("Panic: Couldn't determine source name in '$method' for '$type'");
            }
            my $object_class = $self->get_object_class_name($source_name)
              or croak(
                "Panic: Couldn't determine object class in '$method' for '$source_name'");
            return $object_class->new( { result_source => $result } );
        };
    }

    # we do it this way because they might have created a custom
    # resultset class and thus, we don't know *which* class we're inheriting
    # from.
    my $meta = Moose::Meta::Class->create_anon_class(
        superclasses => [ ref $resultset ],
        cache        => 1,
        methods      => {
            %methods,
            all => sub {
                my $this = shift;
                my @all  = $this->next::method(@_);
                return unless @all;
                my $object_class = $self->get_object_class_name(
                    $all[0]->result_source->source_name );
                return
                  map { $object_class->new( { result_source => $_ } ) } @all;
            },
        },
    );
    $meta->rebless_instance($resultset);
    return $resultset;
}

sub load_objects {
    my $self   = shift;
    my $schema = $self->schema;

    foreach my $source_name ($schema->sources) {
        my $object_class = $self->get_object_class_name($source_name);

        $self->_debug("Trying to load $object_class");

        if ( try_load_class($object_class) ) {
            $self->_debug("\t$object_class found.");
        }
        else {
            $self->_debug("\t$object_class not found. Building.");
            Moose::Meta::Class->create(
                $object_class,
                superclasses => [ $self->base_class ],
            );
            unless ( Class::Load::is_class_loaded($object_class) ) {
                die "$object_class didn't load";
            }
        }

        # XXX Not sure about this. If they forget to inherit from
        # DBIx::Class::Objects::Base, we do it for them. It works around an
        # issue the programmer might forget, but is this too much magic, given
        # that we're already doing a lot of it?
        my $meta = $object_class->meta;
        my $was_immutable = $meta->is_immutable;
        $meta->make_mutable if $was_immutable;
        unless ( $object_class->isa( $self->base_class ) ) {
            $meta->superclasses( $meta->superclasses, $self->base_class );
        }
        $self->_add_methods( $object_class, $source_name );
        $meta->make_immutable if $was_immutable;
    }
}

sub _add_methods {
    my ( $self, $class, $source_name ) = @_;
    my $schema = $self->schema;
    my $meta   = $class->meta;

    my $source = $schema->resultset($source_name)->result_source;

    $self->result_role->meta->apply(
        $meta,
        handles             => [ $source->columns ],
        result_source_class => $source->result_class,
        source              => $class,
    );

    my @relationships = $source->relationships;
    foreach my $relationship (@relationships) {
        my $info = $source->relationship_info($relationship);

        # if the accessor is a "multi" access, it returns a resultset, not a
        # result.
        my $is_multi = 'multi' eq $info->{attrs}{accessor};
        my $source
          = $schema->resultset( $info->{source} )->result_source->source_name;
        my $other_class = $self->get_object_class_name($source);

        # XXX Bless me father for I have sinned ...
        $info->{_result_class_to_object_class} = $other_class;

        if ($is_multi) {

            # all resultsets get blessed into our resultset class
            $meta->add_method(
                $relationship => sub {
                    my $this      = shift;
                    my $resultset = $this->result_source->$relationship(@_)
                      or return;
                    return $self->_create_object_set($resultset);
                },
            );
        }
        else {
            # all results are our objects, not results
            $meta->add_method(
                $relationship => sub {
                    my $this     = shift;
                    my $response = $this->result_source->$relationship
                      or return;
                    return $other_class->new(
                        { result_source => $response } );
                }
            );
        }
    }
}

sub _debug {
    my ( $self, $message ) = @_;
    return unless $self->debug;
    warn "$message\n";
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

DBIx::Class::Objects - The great new DBIx::Class::Objects!

=head1 VERSION

Version 0.01


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use DBIx::Class::Objects;

    my $foo = DBIx::Class::Objects->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=head1 AUTHOR

Curtis "Ovid" Poe, C<< <ovid at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-object-bridge at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Object-Bridge>.  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::Objects

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Object-Bridge>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Object-Bridge>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Object-Bridge>

=item * Search CPAN

L<http://search.cpan.org/dist/Object-Bridge/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Curtis "Ovid" Poe.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
