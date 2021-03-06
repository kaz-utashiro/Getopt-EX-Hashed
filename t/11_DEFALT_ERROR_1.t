use strict;
use warnings;
use Test::More;
use lib './t';

my @argv = qw(
    --string Alice
    Life
    --number 42
    --list mostly --list harmless
    Universe and
    --hash animal=dolphin --hash fish=babel
    --implicit
    -s -42
    --end 999
    --beeblebrox
    --so-long
    --both 99
    Everything
    );

BEGIN {
    no warnings 'once';
    $App::Foo::ACCESSOR_DEFAULT_ERROR1 = 1;
}

eval q{ use App::Foo };
like($@, qr/must be arrayref/, "DEFAULT ERROR 1");

done_testing;
