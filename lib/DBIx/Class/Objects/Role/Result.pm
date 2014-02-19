package DBIx::Class::Objects::Role::Result;
use MooseX::Role::Parameterized;

parameter 'handles' => (
    isa      => 'ArrayRef[Str]',
    required => 1,
);

role {
    my $param = shift;
    has 'result_source' => (
        is       => 'ro',
        isa      => 'DBIx::Class::Core',
        required => 1,
        handles  => $param->handles,
    );
};

1;
