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
        debug       => 0,
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
ok !$person->can('save'), '... but other dbic attributes should not be inherited';
ok $person->result_source->isa('Sample::Schema::Result::Person'),
    '... but we can get at them via our result_source()';

$fixtures->load('basic_customer');
my $customer = $fixtures->get_result('basic_customer');
$person_result = $fixtures->get_result('person_with_customer');
$person = My::Object::Person->new( { result_source => $person_result } );

isa_ok $person->customer, 'My::Object::Customer';

done_testing;
