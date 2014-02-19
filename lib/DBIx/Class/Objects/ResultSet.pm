package DBIx::Class::Objects::ResultSet;
use Moose;
use namespace::autoclean;
use MooseX::NonMoose;
extends 'DBIx::Class::ResultSet';
with 'DBIx::Class::Objects::Role::ClassName';

sub BUILDARGS { $_[2] }

has 'object_class_name' => (
    is         => 'ro',
    isa        => 'Str',
    required   => 1,
    lazy_build => 1,
);

sub _build_object_class_name {
    my $self = shift;
    return $self->get_object_class_name( $self->result_source->source_name );
}

sub find {
    my $self = shift;
    return $self->object_class_name->new(
        { result_source => $self->next::method(@_) } );
}

sub next {
    my $self   = shift;
    my $result = $self->next::method or return;
    return $self->object_class_name->new( { result_source => $result } );
}

#around 'all' => sub {
#    my $orig = shift;
#    my $self = shift;
#    my @results = $self->$orig;
#    my @all;
#    foreach my $result (@results) {
#        #my $source
#        #  = $schema->resultset( $info->{source} )->result_source->source_name;
#        my $source
#          = $schema->resultset( $info->{source} )->result_source->source_name;
#        my $other_class = $self->get_bridge_class_name($source);
#        #my $other_class = $self->get_bridge_class_name($source);
#    }
#    return @all;

# next
# first

1;
