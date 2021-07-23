use strict;
use warnings;
use Test::More;
use lib './t';
use Data::Dumper;
{
    no warnings 'redefine';
    *Data::Dumper::qquote = sub { qq["${\(shift)}"] };
    $Data::Dumper::Useperl = 1;
    $Data::Dumper::Sortkeys = 1;
}

my @argv = qw(--string Alice
	   Life
	   --number 42
	   --list mostly --list harmless
	   Universe and
	   --hash animal=dolphin --hash fish=babel
	   --implicit
	   --both 99
	   Everything
    );

use App::Foo;
(my $app = App::Foo->new)->run(@argv);

is_deeply($app->{string}, "Alice", "String");
is_deeply($app->{say}, "Hello", "String (default)");
is_deeply($app->{number}, 42, "Number");
is_deeply($app->{implicit}, 42, "Default parameter");
is_deeply($app->{list}, [ qw(mostly harmless) ], "List");
is_deeply($app->{hash}, { animal => 'dolphin', fish => 'babel' }, "Hash");
is_deeply($app->{left}, 99, "action");
is_deeply($app->{ARGV}, [ qw(Life Universe and Everything) ], '<>');

done_testing;
