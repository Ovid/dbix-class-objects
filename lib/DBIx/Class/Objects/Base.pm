package DBIx::Class::Objects::Base;

use Moose;
use DBIx::Class::Objects::Util 'class_name_to_private_accessor';

sub BUILD {
    my $self = shift;
    my @parents = grep { $_ ne __PACKAGE__ } $self->meta->superclasses;

    my $source        = $self->result_source;
    my @relationships = $source->relationships;

    foreach my $relationship (@relationships) {
        my $info = $source->relationship_info($relationship);
        next if 'multi' eq $info->{attrs}{accessor};
        my $parent = $info->{_result_class_to_object_class};
        next unless $self->isa($parent);
        my $accessor = class_name_to_private_accessor($parent);
        $self->$accessor( $self->$relationship->result_source );
    }
}

sub update {
    my $self = shift;

    foreach my $attribute ( $self->meta->get_all_attributes ) {
        next
          unless $attribute->does(
            'DBIx::Class::Objects::Attribute::Trait::DBIC');
        my $name = $attribute->name;
        $self->$name->update;
    }
}

1;
