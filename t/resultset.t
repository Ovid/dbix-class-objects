
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

$fixtures->load('all_items');
my $items = $objects->resultset('Item');
is $items->count, 3, 'We should have the correct number of items';

while ( my $item = $items->next ) {
    my $ref = ref $item;
    show $ref;
    ok $item->isa('My::Object::Item'),
      '... and it should have the correct class name';
}

my @items
  = $objects->resultset('Item')->search( { price => { '>' => 1.2 } } )->all;
is @items, 2, 'We should be able to search correctly';
foreach my $item (@items) {
    ok $item->isa('My::Object::Item'),
      '... and it should have the correct class name';
    cmp_ok $item->price, '>', 1.2,
      '... and the search parameters should be respected';
}

done_testing;
