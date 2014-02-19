
use Test::Most;
use lib 't/lib';
use My::Objects;
use My::Fixtures;
use Sample::Schema;

use Carp::Always;
my $schema = Sample::Schema->test_schema;
my $fixtures = My::Fixtures->new( { schema => $schema } );
$fixtures->load('person_without_customer');
my $objects = My::Objects->new(
    {   schema      => $schema,
        object_base => 'My::Object',
        debug       => 0,
    }
);
$objects->load_objects;

my $person
  = $objects->resultset('Person')->find( { email => 'not@home.com' } );
isa_ok $person, 'My::Object::Person';
is $person->name, 'Bob', '... and their name should be correct';
ok !$person->can('save'), '... and they do not directly inherit dbic methods';

done_testing;
