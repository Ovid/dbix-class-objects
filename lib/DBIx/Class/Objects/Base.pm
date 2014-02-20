package DBIx::Class::Objects::Base;

use Moose;

sub BUILD {
    my $self = shift;
    my @parents = grep { $_ ne __PACKAGE__ } $self->meta->superclasses;

    my $source        = $self->result_source;
    my @relationships = $source->relationships;

    my $class = ref $self;
    foreach my $relationship (@relationships) {
        my $info = $source->relationship_info($relationship);
        next if 'multi' eq $info->{attrs}{accessor};
        Test::Most::show($class, $relationship);
    }
}

1;
