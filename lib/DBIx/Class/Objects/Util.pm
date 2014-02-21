package DBIx::Class::Objects::Util;

use strict;
use warnings;

use base 'Exporter';
our @EXPORT_OK = qw(
  class_name_to_private_accessor
);

sub class_name_to_private_accessor {
    my $class_name = shift;
    my $accessor   = '_' . lc $class_name;
    $accessor =~ s/\W+/_/g;
    return $accessor;
}

1;
