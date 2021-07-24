use strict;
use warnings;
use Test::More;
use lib './t';
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

my @saved = my @argv = qw(
    Life
    Universe and
    Everything
    ) x 1;

BEGIN {
    $App::Foo::TAKE_IT_ALL = 1;
}
use App::Foo;

(my $app = App::Foo->new)->run(@argv);

#TODO: {
#    local $TODO = "This test fails in 5~10% possibility.";
    is_deeply($app->{ARGV}, \@argv, '<>');
#}

done_testing;
