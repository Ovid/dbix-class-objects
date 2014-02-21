package My::Object::Person;

use Moose;
use namespace::autoclean;
extends 'DBIx::Class::Objects::Base';

sub is_customer {
    my $self = shift;
    return defined $self->customer;
}

1;
