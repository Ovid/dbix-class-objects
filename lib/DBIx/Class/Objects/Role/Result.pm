package DBIx::Class::Objects::Role::Result;
use MooseX::Role::Parameterized;
use DBIx::Class::Objects::Attribute::Trait::DBIC;
use DBIx::Class::Objects::Util 'class_name_to_private_accessor';

parameter 'handles' => (
    isa      => 'ArrayRef[Str]',
    required => 1,
);

parameter 'source' => (
    isa      => 'Str',
    required => 1,
);

parameter 'result_source_class' => (
    isa      => 'Str',
    required => 1,
);

role {
    my $param = shift;

    my $source = class_name_to_private_accessor( $param->source );

    has $source => (
        traits  => ['DBIC'],
        is      => 'rw',
        isa     => $param->result_source_class,
        handles => $param->handles,
    );
    has 'result_source' => (
        is       => 'rw',
        isa      => $param->result_source_class,
        required => 1,
    );

    # XXX This looks strange, but here's what's going on. Inside of our
    after 'BUILD' => sub {
        my $self          = shift;
        my $result_source = $self->result_source;
        $self->$source($result_source)
          if $result_source->isa( $param->result_source_class );
    };
};

1;
