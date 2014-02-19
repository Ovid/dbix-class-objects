package DBIx::Class::Objects;

use Moose;

# using this because it will be applied to result classes, not because we want
# to import this behavior
use DBIx::Class::Objects::Role::Result;
use DBIx::Class::Objects::ResultSet;

use Class::Load 'try_load_class';
use namespace::autoclean;
with 'DBIx::Class::Objects::Role::ClassName';

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

sub BUILD {
    my $self = shift;

    # XXX bless me father, for I have sinned
    $self->schema->{__object_base__} = $self->object_base;
}

sub resultset {
    my ( $self, $source_name ) = @_;

    my $resultset = $self->schema->resultset($source_name);
    return DBIx::Class::Objects::ResultSet->meta->rebless_instance($resultset);
}

sub load_objects {
    my $self   = shift;
    my $schema = $self->schema;

    foreach my $source_name ( $schema->sources ) {
        my $class = $self->get_object_class_name($source_name);

        $self->_debug("Trying to load $class");

        if ( try_load_class($class) ) {
            $self->_debug("\t$class found.");
        }
        else {
            $self->_debug("\t$class not found. Building.");
            Moose::Meta::Class->create(
                $class,
                superclasses => ['Moose::Object'],
            );
            unless ( Class::Load::is_class_loaded($class) ) {
                die "$class didn't load";
            }
        }
        $self->_add_methods( $class, $source_name );
    }
}

sub _add_methods {
    my ( $self, $class, $source_name ) = @_;
    my $schema = $self->schema;
    my $meta   = $class->meta;

    my $source = $schema->resultset($source_name)->result_source;
    DBIx::Class::Objects::Role::Result->meta->apply(
        $meta,
        handles => [ $source->columns ],
    );

    my @relationships = $source->relationships;
    foreach my $relationship (@relationships) {
        my $info     = $source->relationship_info($relationship);
        my $is_multi = 'multi' eq $info->{attrs}{accessor};
        my $source
          = $schema->resultset( $info->{source} )->result_source->source_name;
        my $other_class = $self->get_object_class_name($source);

        if ($is_multi) {

            # TODO
        }
        else {
            $meta->add_method(
                $relationship => sub {
                    my $self = shift;
                    return $other_class->new(
                        {   result_source =>
                              $self->result_source->$relationship
                        }
                    );
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
