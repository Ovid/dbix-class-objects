use Test::Most;
use lib 't/lib';
use My::Objects;
use My::Fixtures;
use Sample::Schema;

my $schema = Sample::Schema->test_schema;

my $people_rs = $schema->resultset('Person');

my $fixtures = My::Fixtures->new( { schema => $schema } );
$fixtures->load('person_without_customer');
my $objects = My::Objects->new(
    {   schema      => $schema,
        object_base => 'My::Object',
        debug       => 1,
    }
);
$objects->load_objects;

my $person_result = $fixtures->get_result('person_without_customer');
my $person = My::Object::Person->new( { result_source => $person_result } );

my @attributes = qw(person_id name birthday email);
foreach my $attribute (@attributes) {
    is $person->$attribute, $person_result->$attribute,
      "The '$attribute' attribute should be delegated correctly";
}
ok !$person->can('save'),
  '... but other dbic attributes should not be inherited';
ok $person->result_source->isa('Sample::Schema::Result::Person'),
  '... but we can get at them via our result_source()';

ok $person->can('is_customer'),
    'Our custom methods in the class should exist';
ok !$person->is_customer,
    '... and should return the correct response';

$fixtures->load('basic_customer');
my $customer_result = $fixtures->get_result('basic_customer');
my $customer
  = My::Object::Customer->new( { result_source => $customer_result } );

$person_result = $fixtures->get_result('person_with_customer');
$person = My::Object::Person->new( { result_source => $person_result } );

isa_ok $person->customer, 'My::Object::Customer';
ok $person->is_customer,
    '... and our custom methods should still work';

done_testing;
exit;


$fixtures->load('order_with_items');
my $order_result = $fixtures->get_result('order_with_items');
my $order        = My::Object::Order->new( { result_source => $order_result } );
my $order_items  = $order->order_items;
is $order_items->count, 2, 'Methods returning resultsets should work';
ok $order_items->isa('DBIx::Class::Objects::ResultSet'),
  '... and should return our custom result set';

while ( my $order_item = $order_items->next ) {
    ok $order_item->isa('My::Object::OrderItem'),
      '... and individual results should have the right class';
}

done_testing;
