[![Actions Status](https://github.com/kaz-utashiro/Getopt-EX-Hashed/workflows/test/badge.svg)](https://github.com/kaz-utashiro/Getopt-EX-Hashed/actions) [![MetaCPAN Release](https://badge.fury.io/pl/Getopt-EX-Hashed.svg)](https://metacpan.org/release/Getopt-EX-Hashed)
# NAME

Getopt::EX::Hashed - Hash store object automation

# VERSION

Version 0.9915

# SYNOPSIS

    use App::foo;
    App::foo->new->run();

    package App::foo;

    use Getopt::EX::Hashed;
    has start  => ( spec => "=i s begin", default => 1 );
    has end    => ( spec => "=i e" );
    has file   => ( spec => "=s", is => 'rw', re => qr/^(?!\.)/ );
    has score  => ( spec => '=i', min => 0, max => 100 );
    has answer => ( spec => '=i', must => sub { $_[1] == 42 } );
    no  Getopt::EX::Hashed;

    sub run {
        my $app = shift;
        use Getopt::Long;
        $app->getopt or pod2usage();
        if ($app->{start}) {
            ...

# DESCRIPTION

**Getopt::EX::Hashed** is a module to automate a hash object to store
command line option values.  Major objective of this module is
integrating initialization and specification into single place.
Module name shares **Getopt::EX**, but it works independently from
other modules included in **Getopt::EX**, so far.

In the current implementation, using **Getopt::Long**, or compatible
module such as **Getopt::EX::Long** is assumed.  It is configurable,
but no other module is supported now.

Accessor methods are automatically generated when appropriate parameter
is given.

# FUNCTION

## **has**

Declare option parameters in a form of:

    has option_name => ( param => value, ... );

If array reference is given, multiple names can be declared at once.

    has [ 'left', 'right' ] => ( spec => "=i" );

If the name start with plus (`+`), given parameters are added to
current value.

    has '+left' => ( default => 1 );

Following parameters are available.

- **is** => `ro` | `rw`

    To produce accessor method, `is` parameter is necessary.  Set the
    value `ro` for read-only, `rw` for read-write.

    If you want to make accessor for all following members, use
    `configure` and set `DEFAULT` parameter.

        Getopt::EX::Hashed->configure( DEFAULT => is => 'rw' );

- **spec** => _string_

    Give option specification.  Option spec and alias names are separated
    by white space, and can show up in any order.

    Declaration

        has start => ( spec => "=i s begin" );

    will be compiled into string:

        start|s|begin=i

    which conform to `Getopt::Long` definition.  Of course, you can write
    as this:

        has start => ( spec => "s|begin=i" );

    If the name and aliases contain underscore (`_`), another alias name
    is defined with dash (`-`) in place of underscores.  So

        has a_to_z => ( spec => "=s" );

    will be compiled into:

        a_to_z|a-to-z:s

    If nothing special is necessary, give empty (or white space only)
    string as a value.  Otherwise, it is not considered as an option.

- **alias** => _string_

    Additional alias names can be specified by **alias** parameter too.
    There is no difference with ones in `spec` parameter.

- **default** => _value_

    Set default value.  If no default is given, the member is initialized
    as `undef`.

- **action** => _coderef_

    Parameter `action` takes code reference which is called to process
    the option.  When called, hash object is passed as `$_`.

        has [ qw(left right both) ] => spec => '=i';
        has "+both" => action => sub {
            $_->{left} = $_->{right} = $_[1];
        };

    You can use this for `"<>"` to catch everything.  In that case,
    spec parameter does not matter and not required.

        has ARGV => default => [];
        has "<>" => action => sub {
            push @{$_->{ARGV}}, $_[0];
        };

    In fact, `default` parameter takes code reference too.  It is stored
    in the hash object and the code works almost same.  But the hash value
    can not be used for option storage.

Following parameters are all for data validation.  First `must` is a
generic validator and can implement anything.  Others are shorthand
for common rules.

- **must** => _coderef_

    Parameter `must` takes a code reference to validate option values.
    It takes same arguments as `action` and returns boolean.  With next
    example, option **--answer** takes only 42 as a valid value.

        has answer =>
            spec => '=i',
            must => sub { $_[1] == 42 };

- **min** => _number_
- **max** => _number_

    Set the minimum and maximum limit for the argument.

- **re** => qr/_pattern_/

    Set the required regular expression pattern for the argument.

# METHOD

- **new**

    Class method to get initialized hash object.

- **optspec**

    Return option specification list which can be given to `GetOptions`
    function.

        GetOptions($obj->optspec)

    `GetOptions` has a capability of storing values in a hash, by giving
    the hash reference as a first argument, but it is not necessary.

- **getopt**

    Call `GetOptions` function defined in caller's context with
    appropriate parameters.

        $obj->getopt

    is just a shortcut for:

        GetOptions($obj->optspec)

- **use\_keys**

    Because hash keys are protected by `Hash::Util::lock_keys`, accessing
    non-existent member causes an error.  Use this function to declare new
    member key before use.

        $obj->use_keys( qw(foo bar) );

    If you want to access arbitrary keys, unlock the object.

        use Hash::Util 'unlock_keys';
        unlock_keys %{$obj};

    You can change this behavior by `configure` with `LOCK_KEYS`
    parameter.

- **configure** **label** => _value_, ...

    There are following configuration parameters.

    - **LOCK\_KEYS** (default: 1)

        Lock hash keys.  This avoids accidental access to non-existent hash
        entry.

    - **REPLACE\_UNDERSCORE** (default: 1)

        Produce alias with underscores replaced by dash.

    - **REMOVE\_UNDERSCORE** (default: 0)

        Produce alias with underscores removed.

    - **GETOPT** (default: 'GetOptions')

        Set function name called from `getopt` method.

    - **ACCESSOR\_PREFIX**

        When specified, it is prepended to the member name to make accessor
        method.  If `ACCESSOR_PREFIX` is defined as `opt_`, accessor for
        member `file` will be `opt_file`.

    - **DEFAULT**

        Set default parameters.  At the call for `has`, DEFAULT parameters
        are inserted before argument parameters.  So if both include same
        parameter, later one in argument list has precedence.  Incremental
        call with `+` is not affected.

        Typical use of DEFAULT is `is` to prepare accessor method for all
        following hash entries.  Declare `is => ''` to reset.

            Getopt::EX::Hashed->configure(is => 'ro');

- **reset**

    Reset the class to the original state.

# SEE ALSO

[Getopt::Long](https://metacpan.org/pod/Getopt::Long)

[Getopt::EX](https://metacpan.org/pod/Getopt::EX), [Getopt::EX::Long](https://metacpan.org/pod/Getopt::EX::Long)

# AUTHOR

Kazumasa Utashiro

# COPYRIGHT

The following copyright notice applies to all the files provided in
this distribution, including binary files, unless explicitly noted
otherwise.

Copyright 2021 Kazumasa Utashiro

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
