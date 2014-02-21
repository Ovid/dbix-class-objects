use 5.006;
use strict;
use warnings FATAL => 'all';
use inc::Module::Install;

name 'DBIx-Class-Objects';
all_from 'lib/DBIx/Class/Objects.pm';
author q{Curtis "Ovid" Poe <ovid@cpan.org>};
license 'artistic2';

perl_version 5.006;

tests_recursive('t');

resources(
    #homepage   => 'http://yourwebsitehere.com',
    #IRC        => 'irc://irc.perl.org/#DBIx-Class-Objects',
    license    => 'http://www.perlfoundation.org/artistic_license_2_0',
    repository => 'git://github.com/Curtis "Ovid" Poe/dbix-class-objects.git',
    bugtracker => 'https://github.com/Ovid/dbix-class-objects/issues',
);

configure_requires(
    'Module::Install' => 0,
);

build_requires(
    'Test::Most'               => 0,
    'DBIx::Class::EasyFixture' => '0.02',
);

requires(
    'Class::Load'                 => 0,
    'DBIx::Class'                 => 0,
    'Moose'                       => 0,
    'MooseX::NonMoose'            => 0,
    'MooseX::Role::Parameterized' => 0,
);

install_as_cpan;
auto_install;
WriteAll;
