package Getopt::EX::Hashed;

our $VERSION = '1.03';

=head1 NAME

Getopt::EX::Hashed - Hash store object automation for Getopt::Long

=head1 VERSION

Version 1.03

=head1 SYNOPSIS

  use App::foo;
  App::foo->new->run();

  package App::foo;

  use Getopt::EX::Hashed; {
      has start    => ' =i  s begin ' , default => 1;
      has end      => ' =i  e       ' ;
      has file     => ' =s@ f       ' , is => 'rw', any => qr/^(?!\.)/;
      has score    => ' =i          ' , min => 0, max => 100;
      has answer   => ' =i          ' , must => sub { $_[1] == 42 };
      has mouse    => ' =s          ' , any => [ 'Frankie', 'Benjy' ];
      has question => ' =s          ' , any => qr/^(life|universe|everything)$/i;
  } no Getopt::EX::Hashed;

  sub run {
      my $app = shift;
      use Getopt::Long;
      $app->getopt or pod2usage();
      if ($app->{start}) {
          ...

=cut

use v5.14;
use warnings;
use Hash::Util qw(lock_keys lock_keys_plus unlock_keys);
use Carp;
use Data::Dumper;
use List::Util qw(first);

# store metadata in caller context
my  %__DB__;
sub  __DB__ {
    $__DB__{$_[0]} //= do {
	no strict 'refs';
	state $sub = __PACKAGE__ =~ s/::/_/gr;
	\%{"$_[0]\::$sub\::__DB__"};
    };
}
sub __Member__ { __DB__(@_)->{Member} //= [] }
sub __Config__ { __DB__(@_)->{Config} //= {} }

my %DefaultConfig = (
    DEBUG_PRINT        => 0,
    LOCK_KEYS          => 1,
    REPLACE_UNDERSCORE => 1,
    REMOVE_UNDERSCORE  => 0,
    GETOPT             => 'GetOptions',
    GETOPT_FROM_ARRAY  => 'GetOptionsFromArray',
    ACCESSOR_PREFIX    => '',
    DEFAULT            => [],
    INVALID_MSG        => \&_invalid_msg,
    );
lock_keys %DefaultConfig;

our @EXPORT = qw(has);

sub import {
    my $caller = caller;
    no strict 'refs';
    push @{"$caller\::ISA"}, __PACKAGE__;
    *{"$caller\::$_"} = \&$_ for @EXPORT;
    my $config = __Config__($caller);
    unless (%$config) {
	unlock_keys %$config;
	%$config = %DefaultConfig or die "something wrong!";
	lock_keys %$config;
    }
}

sub unimport {
    my $caller = caller;
    no strict 'refs';
    delete ${"$caller\::"}{$_} for @EXPORT;
}

sub configure {
    my $class = shift;
    my $config = do {
	if (ref $class) {
	    $class->_conf;
	} else {
	    my $ctx = $class ne __PACKAGE__ ? $class : caller;
	    __Config__($ctx);
	}
    };
    while (my($key, $value) = splice @_, 0, 2) {
	if ($key eq 'DEFAULT') {
	    ref($value) eq 'ARRAY' or die "DEFAULT must be arrayref";
	    @$value % 2 == 0       or die "DEFAULT have wrong member";
	}
	$config->{$key} = $value;
    }
    return $class;
}

sub reset {
    my $caller = caller;
    my $member = __Member__($caller);
    my $config = __Config__($caller);
    @$member = ();
    %$config = %DefaultConfig;
    return $_[0];
}

sub has {
    my($key, @param) = @_;
    if (@param % 2) {
	my $default = ref $param[0] eq 'CODE' ? 'action' : 'spec';
	unshift @param, $default;
    }
    my @name = ref $key eq 'ARRAY' ? @$key : $key;
    my $caller = caller;
    my $member = __Member__($caller);
    for my $name (@name) {
	my $append = $name =~ s/^\+//;
	my $i = first { $member->[$_][0] eq $name } 0 .. $#{$member};
	if ($append) {
	    defined $i or die "$name: Not found\n";
	    push @{$member->[$i]}, @param;
	} else {
	    defined $i and die "$name: Duplicated\n";
	    my $config = __Config__($caller);
	    push @$member, [ $name, @{$config->{DEFAULT}}, @param ];
	}
    }
}

sub new {
    my $class = shift;
    my $obj = bless {}, $class;
    my $ctx = $class ne __PACKAGE__ ? $class : caller;
    my $master = __Member__($ctx);
    my $member = $obj->{__Member__} = [];
    my $config = $obj->{__Config__} = { %{__Config__($ctx)} }; # make copy
    for my $m (@$master) {
	my($name, %param) = @$m;
	push @$member, [ $name => \%param ];
	if (my $is = $param{is}) {
	    no strict 'refs';
	    my $access = $config->{ACCESSOR_PREFIX} . $name;
	    *{"$class\::$access"} = _accessor($is, $name)
		unless ${"$class\::"}{$access};
	}
	$obj->{$name} = do {
	    local $_ = $param{default};
	    if    (ref eq 'ARRAY') {  [ @$_ ]  }
	    elsif (ref eq 'HASH' ) { ({ %$_ }) }
	    elsif (ref eq 'CODE' ) {  $_->()   }
	    else                   {  $_       }
	};
    }
    lock_keys %$obj if $config->{LOCK_KEYS};
    $obj;
}

sub optspec {
    my $obj = shift;
    map $obj->_opt_pair($_), @{$obj->_member};
}

sub getopt {
    my $obj = shift;
    if (@_ == 0) {
	my $getopt = caller . "::" . $obj->_conf->{GETOPT};
	no strict 'refs';
	$getopt->($obj->optspec());
    }
    elsif (@_ == 1 and ref $_[0] eq 'ARRAY') {
	my $getopt = caller . "::" . $obj->_conf->{GETOPT_FROM_ARRAY};
	no strict 'refs';
	$getopt->($_[0], $obj->optspec());
    }
    else {
	die "getopt: wrong parameter.";
    }
}

sub use_keys {
    my $obj = shift;
    unlock_keys %$obj;
    lock_keys_plus %$obj, @_;
}

sub _conf   { $_[0]->{__Config__} }

sub _member { $_[0]->{__Member__} }

sub _accessor {
    my($is, $name) = @_;
    {
	ro => sub {
	    $#_ and die "$name is readonly\n";
	    $_[0]->{$name};
	},
	rw => sub {
	    $#_ and do { $_[0]->{$name} = $_[1]; return $_[0] };
	    $_[0]->{$name};
	}
    }->{$is} or die "$name has invalid 'is' parameter.\n";
}

sub _opt_pair {
    my $obj = shift;
    my $member = shift;
    my $spec_str = $obj->_opt_str($member) // return ();
    ( $spec_str => $obj->_opt_dest($member) );
}

sub _opt_str {
    my $obj = shift;
    my($name, $m) = @{+shift};

    $name eq '<>' and return $name;
    my $spec = $m->{spec} // return undef;
    if (my $alias = $m->{alias}) {
	$spec .= " $alias";
    }
    $obj->_compile($name, $spec);
}

sub _compile {
    my $obj = shift;
    my($name, $args) = @_;
    my @args  = split ' ', $args;
    my $spec_re = qr/[!+=:]/;
    my @spec  = grep  /$spec_re/, @args;
    my @alias = grep !/$spec_re/, @args;
    my $spec = do {
	if    (@spec == 0) { '' }
	elsif (@spec == 1) { $spec[0] }
	else               { die }
    };
    my @names = ($name, @alias);
    for ($name, @alias) {
	push @names, tr[_][-]r if /_/ && $obj->_conf->{REPLACE_UNDERSCORE};
	push @names, tr[_][]dr if /_/ && $obj->_conf->{REMOVE_UNDERSCORE};
    }
    push @names, '' if @names and $spec !~ /^($spec_re|$)/;
    join('|', @names) . $spec;
}

sub _opt_dest {
    my $obj = shift;
    my($name, $m) = @{+shift};

    my $action = $m->{action};
    if (my $is_valid = _validator($m)) {
	$action ||= \&_generic_setter;
	sub {
	    local $_ = $obj;
	    &$is_valid or die &{$obj->_conf->{INVALID_MSG}};
	    &$action;
	};
    }
    elsif ($action) {
	sub { &$action for $obj };
    }
    else {
	if (ref $obj->{$name} eq 'CODE') {
	    sub { &{$obj->{$name}} for $obj };
	} else {
	    \$obj->{$name};
	}
    }
} 

my %tester = (
    min  => sub { $_[-1] >= $_->{min} },
    max  => sub { $_[-1] <= $_->{max} },
    must => sub {
	my $must = $_->{must};
	for $_ (ref($must) eq 'ARRAY' ? @$must : $must) {
	    return 0 if not &$_;
	}
	return 1;
    },
    any => sub {
	my $any = $_->{any};
	for (ref($any) eq 'ARRAY' ? @$any : $any) {
	    if (ref eq 'Regexp') {
		return 1 if $_[-1] =~ $_;
	    } elsif (ref eq 'CODE') {
		return 1 if &$_;
	    } else {
		return 1 if $_[-1] eq $_;
	    }
	}
	return 0;
    },
    );

sub _tester {
    my $m = shift;
    map $tester{$_}, grep { defined $m->{$_} } keys %tester;
}

sub _validator {
    my $m = shift;
    my @test = _tester($m) or return undef;
    sub {
	local $_ = $m;
	for my $test (@test) {
	    return 0 if not &$test;
	}
	return 1;
    }
}

sub _generic_setter {
    my $dest = $_->{$_[0]};
    (ref $dest eq 'ARRAY') ? do { push @$dest, $_[1] } :
    (ref $dest eq 'HASH' ) ? do { $dest->{$_[1]} = $_[2] }
                           : do { $_->{$_[0]} = $_[1] };
}

sub _invalid_msg {
    my $opt = do {
	$_[0] = $_[0] =~ tr[_][-]r;
	if (@_ <= 2) {
	    '--' . join '=', @_;
	} else {
	    sprintf "--%s %s=%s", @_[0..2];
	}
    };
    "$opt: option validation error\n";
}

1;

__END__

=head1 DESCRIPTION

B<Getopt::EX::Hashed> is a module to automate a hash object to store
command line option values for B<Getopt::Long> and compatible modules
including B<Getopt::EX::Long>.

Major objective of this module is integrating initialization and
specification into single place.

Module name shares B<Getopt::EX>, but it works independently from
other modules in B<Getopt::EX>, so far.

Accessor methods are automatically generated when appropriate parameter
is given.

=head1 FUNCTION

=over 7

=item B<has>

Declare option parameters in a form of:

    has option_name => ( param => value, ... );

If array reference is given, multiple names can be declared at once.

    has [ 'left', 'right' ] => ( spec => "=i" );

If the name start with plus (C<+>), given parameter updates values.

    has '+left' => ( default => 1 );

As for C<spec> parameter, label can be omitted if it is the first
parameter.

    has left => "=i", default => 1;

If the number of parameter is not even, default label is assumed to be
exist at the head: C<action> if the first parameter is code reference,
C<spec> otherwise.

Following parameters are available.

=over 7

=item [ B<spec> => ] I<string>

Give option specification.  C<< spec => >> label can be omitted if and
only if it is the first parameter.

In I<string>, option spec and alias names are separated by white
space, and can show up in any order.  Declaration

    has start => "=i s begin";

will be compiled into string:

    start|s|begin=i

which conform to C<Getopt::Long> definition.  Of course, you can write
as this:

    has start => "s|begin=i";

If the name and aliases contain underscore (C<_>), another alias name
is defined with dash (C<->) in place of underscores.  So

    has a_to_z => "=s";

will be compiled into:

    a_to_z|a-to-z:s

If nothing special is necessary, give empty (or white space only)
string as a value.  Otherwise, it is not considered as an option.

=item B<alias> => I<string>

Additional alias names can be specified by B<alias> parameter too.
There is no difference with ones in C<spec> parameter.

    has start => "=i", alias => "s begin";

=item B<is> => C<ro> | C<rw>

To produce accessor method, C<is> parameter is necessary.  Set the
value C<ro> for read-only, C<rw> for read-write.

If you want to make accessor for all following members, use
C<configure> and set C<DEFAULT> parameter.

    Getopt::EX::Hashed->configure( DEFAULT => [ is => 'rw' ] );

=item B<default> => I<value> | I<coderef>

Set default value.  If no default is given, the member is initialized
as C<undef>.

If the value is a reference for ARRAY or HASH, new reference with same
member is assigned.  This means that member data is shared across
multiple C<new> calls.  Please be careful if you call C<new> multiple
times and alter the member data.

If a code reference is given, it is called at the time of B<new> to
get default value.  This is effective when you want to evaluate the
value at the time of execution, rather than declaration.  Use
B<action> parameter to define a default action.

=item [ B<action> => ] I<coderef>

Parameter C<action> takes code reference which is called to process
the option.  C<< action => >> label can be omitted if and only if it
is the first parameter.

When called, hash object is passed as C<$_>.

    has [ qw(left right both) ] => '=i';
    has "+both" => sub {
        $_->{left} = $_->{right} = $_[1];
    };

You can use this for C<< "<>" >> to catch everything.  In that case,
spec parameter does not matter and not required.

    has ARGV => default => [];
    has "<>" => sub {
        push @{$_->{ARGV}}, $_[0];
    };

=back

Following parameters are all for data validation.  First C<must> is a
generic validator and can implement anything.  Others are shortcut
for common rules.

=over 7

=item B<must> => I<coderef> | [ I<coderef> ... ]

Parameter C<must> takes a code reference to validate option values.
It takes same arguments as C<action> and returns boolean.  With next
example, option B<--answer> takes only 42 as a valid value.

    has answer =>
        spec => '=i',
        must => sub { $_[1] == 42 };

If multiple code reference is given, all code have to return true.

    has answer =>
        spec => '=i',
        must =>[ sub { $_[1] >= 42 }, sub { $_[1] <= 42 } ];

=item B<min> => I<number>

=item B<max> => I<number>

Set the minimum and maximum limit for the argument.

=item B<any> => I<arrayref> | qr/I<regex>/

Set the valid string parameter list.  Each item is a string or a regex
reference.  The argument is valid when it is same as, or match to any
item of the given list.  If the value is not an arrayref, it is taken
as a single item list (regexpref usually).

Following declarations are almost equivalent, except second one is
case insensitive.

    has question => '=s',
        any => [ 'life', 'universe', 'everything' ];

    has question => '=s',
        any => qr/^(life|universe|everything)$/i;

If you are using optional argument, don't forget to include default
value in the list.  Otherwise it causes validation error.

    has question => ':s',
        any => [ 'life', 'universe', 'everything', '' ];

=back

=back

=head1 METHOD

=over 7

=item B<new>

Class method to get initialized hash object.

=item B<optspec>

Return option specification list which can be given to C<GetOptions>
function.

    GetOptions($obj->optspec)

C<GetOptions> has a capability of storing values in a hash, by giving
the hash reference as a first argument, but it is not necessary.

=item B<getopt> [ I<arrayref> ]

Call appropiate function defined in caller's context to process
options.

    $obj->getopt

    $obj->getopt(\@argv);

are shortcut for:

    GetOptions($obj->optspec)

    GetOptionsFromArray(\@argv, $obj->optspec)

=item B<use_keys> I<keys>

Because hash keys are protected by C<Hash::Util::lock_keys>, accessing
non-existent member causes an error.  Use this function to declare new
member key before use.

    $obj->use_keys( qw(foo bar) );

If you want to access arbitrary keys, unlock the object.

    use Hash::Util 'unlock_keys';
    unlock_keys %{$obj};

You can change this behavior by C<configure> with C<LOCK_KEYS>
parameter.

=item B<configure> B<label> => I<value>, ...

Use class method C<< Getopt::EX::Hashed->configure() >> before
creating an object; this information is stored in the area unique for
calling package.  After calling C<new()>, package unique configuration
is copied in the object, and it is used for further operation.  Use
C<< $obj->configure() >> to update object unique configuration.

There are following configuration parameters.

=over 7

=item B<LOCK_KEYS> (default: 1)

Lock hash keys.  This avoids accidental access to non-existent hash
entry.

=item B<REPLACE_UNDERSCORE> (default: 1)

Produce alias with underscores replaced by dash.

=item B<REMOVE_UNDERSCORE> (default: 0)

Produce alias with underscores removed.

=item B<GETOPT> (default: 'GetOptions')

=item B<GETOPT_FROM_ARRAY> (default: 'GetOptionsFromArray')

Set function name called from C<getopt> method.

=item B<ACCESSOR_PREFIX>

When specified, it is prepended to the member name to make accessor
method.  If C<ACCESSOR_PREFIX> is defined as C<opt_>, accessor for
member C<file> will be C<opt_file>.

=item B<DEFAULT>

Set default parameters.  At the call for C<has>, DEFAULT parameters
are inserted before argument parameters.  So if both include same
parameter, later one in argument list has precedence.  Incremental
call with C<+> is not affected.

Typical use of DEFAULT is C<is> to prepare accessor method for all
following hash entries.  Declare C<< DEFAULT => [] >> to reset.

    Getopt::EX::Hashed->configure(DEFAULT => [ is => 'ro' ]);

=back

=item B<reset>

Reset the class to the original state.

=back

=head1 SEE ALSO

L<Getopt::Long>

L<Getopt::EX>, L<Getopt::EX::Long>

=head1 AUTHOR

Kazumasa Utashiro

=head1 COPYRIGHT

The following copyright notice applies to all the files provided in
this distribution, including binary files, unless explicitly noted
otherwise.

Copyright 2021-2022 Kazumasa Utashiro

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

#  LocalWords:  Accessor param ro rw accessor undef coderef qw ARGV
#  LocalWords:  validator qr GETOPT GetOptions getopt obj optspec foo
#  LocalWords:  Kazumasa Utashiro min
