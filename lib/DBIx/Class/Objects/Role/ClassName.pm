package DBIx::Class::Objects::Role::ClassName;
use Moose::Role;
use Carp;

has 'object_base' => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,  # XXX Fix this later
    writer   => '_set_object_base',
);

sub get_object_class_name {
    my ( $self, $source_name ) = @_;
    my $base = $self->object_base;

    # XXX ... and further into the darkness we go
    # basically, it's hard finding a clean way of sharing this data on a "per
    # schema" basis. And then you have to hunt for the damned schema!
    unless (defined $base) {
        if ( $self->can('schema') ) {
            $base = $self->schema->{__object_base__};
        }
        elsif ( $self->can('result_source') ) {
            $base = $self->result_source->schema->{__object_base__};
        }
        else {
            croak("Can't find the schema object to fetch the object base");
        }
    }
    return $base . '::' . $source_name;
}

1;
