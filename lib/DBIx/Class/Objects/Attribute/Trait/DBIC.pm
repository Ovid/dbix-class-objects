package DBIx::Class::Objects::Attribute::Trait::DBIC;

use Moose::Role;

package Moose::Meta::Attribute::Custom::Trait::DBIC;
sub register_implementation { 'DBIx::Class::Objects::Attribute::Trait::DBIC' }

1;
