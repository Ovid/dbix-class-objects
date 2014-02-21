# NAME

DBIx::Class::Objects - Rewrite your DBIC objects via inheritance

# VERSION

0.01

# SYNOPSIS

    my $schema = My::DBIx::Class::Schema->connect(@args);

    my $objects = DBIx::Class::Objects->new({
        schema      => $schema,
        object_base => 'My::Object',
    });
    $objects->load_objects;

    my $person = $objects->objectset('Person')
                         ->find( { email => 'not@home.com' } );

    # If found, $person is a My::Object::Person object, not a
    # My::DBIx::Class::Schema::Result::Person

# WARNING

The `DBIx::Class::Objects` module is an experiment to "fix" (for some values
of "fix") some issues we traditionally have with ORMs by allowing the
programmer to use easily use objects as they wish to rather than the hierarchy
forced on them by `DBIx::Class`.

This is __ALPHA__ code and may be a very bad idea. Use at your own risk.

# DESCRIPTION

Consider a database where you have people and each person might be a customer.
The following two tables might demonstrate that relationship.

    CREATE TABLE people (
        person_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name      VARCHAR(255) NOT NULL,
        email     VARCHAR(255)     NULL UNIQUE,
        birthday  DATETIME     NOT NULL
    );

    CREATE TABLE customers (
        customer_id    INTEGER PRIMARY KEY AUTOINCREMENT,
        person_id      INTEGER  NOT NULL UNIQUE,
        first_purchase DATETIME NOT NULL,
        FOREIGN KEY(person_id) REFERENCES people(person_id)
    );

If your schema starts with `Sample::Schema::`, in `DBIx::Class` terms you'll
find that `Sample::Schema::Result::Person` _might\_have_ a
`Sample::Schema::Result::Customer`:

    __PACKAGE__->might_have(
        "customer",
        "Sample::Schema::Result::Customer",
        { "foreign.person_id" => "self.person_id" },
    );

As a programmer, you might find that frustrating. From your viewpoint, you
might think that `Customer` _isa_ `Person`. Or perhaps you also have
`Employee`s in your database and a person can be both a customer and an
employee, how do you model that? For `DBIx::Class`, you have delegation:

    my $customer = $person->customer;
    my $employee = $person->employee;

Whereas for OO code, you might want to have a `Person` class and `Employee`
and `Customer` roles. Or maybe you're a fan of multiple inheritance (I hope
not) and you create a `CustomerEmployee` class which tries to inherit from
both `Customer` and `Employee`.

Not having full control over your object hierarchy is merely one of the
problems with the [Object-Relational Impedence Mismatch](http://en.wikipedia.org/wiki/Object-relational_impedance_mismatch).

Or maybe you're dismayed to instantiate a `Sample::Schema::Result::Person`
object and discover that you have 157 methods because you were forced to
inherit from `DBIx::Class::Core`, when all you wanted was the name, email and
birthday. This experiment tries to minimize that.

# METHODS

## `new`

    my $objects = DBIx::Class::Objects->new({
        schema      => $schema,
        object_base => 'My::Object',
    });

The `new` constructor takes two required arguments and one optional argument:

- `schema` (required)

    A `DBIx::Class::Schema` object.

- `object_base` (required)

    The package prefix of your name objects. If your schema classes resemble
    something like `Sample::Schema::Result::Person`, your returned objects will
    have names like `My::Object::Person` (assuming you used `My::Object` for the
    `object_base` parameter).

- `debug` (optional)

    At the present time, this will print to STDERR a list of objects you're trying
    to build and whether or not a concrete implementation was found or it's being
    built on the fly.

        Trying to load My::Object::Person
            My::Object::Person found.
        Trying to load My::Object::Order
            My::Object::Order not found. Building.
        Trying to load My::Object::Customer
            My::Object::Customer found.
        Trying to load My::Object::Item
            My::Object::Item not found. Building.
        Trying to load My::Object::OrderItem
            My::Object::OrderItem not found. Building.

## `load_objects`

    $objects->load_objects;

Similar to [DBIx::Class::Schema](https://metacpan.org/pod/DBIx::Class::Schema)'s `load_namespaces`, but it's an instane
method instead of a class method. It will load all of your objects for you. It
will ensure that your objects inherit from [DBIx::Class::Objects::Base](https://metacpan.org/pod/DBIx::Class::Objects::Base) and
will apply the parameterized role [DBIx::Class::Objects::Role::Result](https://metacpan.org/pod/DBIx::Class::Objects::Role::Result).

The base class is what allows things like `update` to be called directly on
the object. Is is the parameterized role which sets up the delegation to the
`DBIx::Class` objects.

## `objectset`

    my $person = $objects->objectset('Person')
                         ->find( { email => 'not@home.com' } );

This method is similar to `$schema->resultset`, but it returns sets of
`DBIx::Class::Objects` objects instead of results. The interface is the same
as `DBIx::Class::ResultSet`, but calling methods like `find`, `next`,
`first`, `all` and so on should _do the right thing_ (famous last words).

# LET'S DELEGATE TO DBIx::Class RESULTS

`DBIx::Class::Objects` is an attempt to allow you to recompose your
`DBIx::Class` objects as you would like. Instead of `DBIx::Class` returning
resultsets and results, `DBIx::Class::Objects` returns objectsets and
objects. You can do anything you want with the latter.

## Basic Usage

Using this module is as simple as this:

    my $schema = Sample::Schema->connect(@args);

    my $objects = DBIx::Class::Objects->new({
        schema      => $schema,
        object_base => 'My::Object',
    });
    $objects->load_objects;

    my $person = $objects->objectset('Person')
                         ->find( { email => 'not@home.com' } );

And you'll discover that you get back a `My::Object::Person` object instead
of a `Sample::Schema::Result::Person` object. In `DBIx::Class`, if you don't
explicitly create resultset classes, a default resultset class will be created
for you. In `DBIx::Class::Objects`, if you don't explicitly create object
classes, a default one is created for you. For example, if you don't have a
`My::Object::Person` class written (or if `DBIx::Class::Objects` can't find
it), you will have a basic `My::Object::Person` instance with the following
methods (according to the debugger):

    DB<2> m $person
    BUILD
    _my_object_person
    birthday
    customer
    email
    meta
    name
    person_id
    result_source
    update
    via DBIx::Class::Objects::Base: DESTROY
    via DBIx::Class::Objects::Base: new
    via DBIx::Class::Objects::Base -> Moose::Object: BUILDALL
    via DBIx::Class::Objects::Base -> Moose::Object: BUILDARGS
    via DBIx::Class::Objects::Base -> Moose::Object: DEMOLISHALL
    via DBIx::Class::Objects::Base -> Moose::Object: DOES
    via DBIx::Class::Objects::Base -> Moose::Object: does
    via DBIx::Class::Objects::Base -> Moose::Object: dump
    via UNIVERSAL: VERSION
    via UNIVERSAL: can
    via UNIVERSAL: isa

That's actually not too bad, compared to `DBIx::Class`. If you remove
`UNIVERSAL` methods and methods in ALL CAPS, you get this:

    _my_object_person
    birthday
    customer
    email
    meta
    name
    person_id
    result_source
    update
    via DBIx::Class::Objects::Base: new
    via DBIx::Class::Objects::Base -> Moose::Object: does
    via DBIx::Class::Objects::Base -> Moose::Object: dump

That's actually a fairly clean object. The `person_id`, `email`, `name` and
`birthday` objects are handled by the `result_source`. If you want to update
the object, you do this:

    $person->name($new_name);
    $person->update;

## Creating your own objects

Having these objects spring up automatically is great and if you have 100
result sources, it's nice that you don't have to write 100 object classes.
However, though you have far fewer methods, what's the point?

Well, you can write your own classes:

    package My::Object::Person;

    use Moose;
    use namespace::autoclean;

    # this is optional. If you forget to include it, DBIx::Class::Objects will
    # inject this for you. However, it's good to have it here for
    # documentation purposes.
    extends 'DBIx::Class::Objects::Base';

    sub is_customer {
        my $self = shift;
        return defined $self->customer;
    }

    __PACKAGE__->meta->make_immutable;

    1;

Again, that's not much of a win, but what if you want inheritance?

    package My::Object::Customer;

    use Moose;
    extends 'My::Object::Person';

    __PACKAGE__->meta->make_immutable;

    1;

You've now inherited the delegated methods from `My::Object::Person`.

    my $customer_os = $objects->objectset('Customer')->search(
        \%dbix_class_search_args
    );
    foreach my $customer ($customer_os->next) {
        if ( $some_condition ) {
            $customer->name('new name');
            $customer->update; # updates $customer->person, too
        }
    }

For every object, calling `result_source` gets you the original
`DBIx::Class::Result`.

    say $customer->result_source; # Sample::Schema::Result::Customer
    say $customer->person->result_source; # Sample::Schema::Result::Person

# AUTHOR

Curtis "Ovid" Poe, `<ovid at cpan.org>`

# BUGS

Please report any bugs or feature requests to `bug-object-bridge at
rt.cpan.org`, or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Class-Objects](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=DBIx-Class-Objects).  I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc DBIx::Class::Objects

You can also look for information at:

- RT: CPAN's request tracker (report bugs here)

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Class-Objects](http://rt.cpan.org/NoAuth/Bugs.html?Dist=DBIx-Class-Objects)

- AnnoCPAN: Annotated CPAN documentation

    [http://annocpan.org/dist/DBIx-Class-Objects](http://annocpan.org/dist/DBIx-Class-Objects)

- CPAN Ratings

    [http://cpanratings.perl.org/d/DBIx-Class-Objects](http://cpanratings.perl.org/d/DBIx-Class-Objects)

- Search CPAN

    [http://search.cpan.org/dist/DBIx-Class-Objects/](http://search.cpan.org/dist/DBIx-Class-Objects/)

# ACKNOWLEDGEMENTS

# LICENSE AND COPYRIGHT

Copyright 2014 Curtis "Ovid" Poe.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

[http://www.perlfoundation.org/artistic\_license\_2\_0](http://www.perlfoundation.org/artistic_license_2_0)

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
