use strict;
use warnings;
use Test::More;
use lib './t';
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

use Getopt::Long;
use Getopt::EX::Hashed 'has';

has answer    => '=i', min => 42, max => 42;

has answer_is => '=i', min => 42, max => 42,
    action => sub {
	$_->{$_[0]} = "Answer is $_[1]";
    };

has question => '=s@',
    default => [],
    any => qr/^(life|universe|everything)$/i;

has mouse => '=s',
    any => [ qw(Frankie Benjy) ];

has nature => '=s%',
    default => {},
    any => qr/^paranoid$/i;

VALID: {
    local @ARGV = qw(--answer 42
		     --answer-is 42
		     --question life
		     --mouse Benjy
		     --nature Marvin=Paranoid
		   );

    my $app = Getopt::EX::Hashed->new;
    $app->getopt;

    is($app->{answer}, 42, "Number");
    is($app->{answer_is}, "Answer is 42", "Number with action");
    is($app->{question}->[0], "life", "RE");
    is($app->{mouse}, "Benjy", "List");
    is($app->{nature}->{Marvin}, "Paranoid", "Hash");
}

INVALID: {
    local @ARGV = qw(--answer 41
		     --answer-is 41
		     --question space
		     --mouse Benji
		     --nature Marvin=Sociable
		   );

    my $app = Getopt::EX::Hashed->new;
    $app->getopt;

    is($app->{answer}, undef, "Number");
    is($app->{answer_is}, undef, "Number with action");
    is($app->{question}->[0], undef, "RE");
    is($app->{mouse}, undef, "List");
    is($app->{nature}->{Marvin}, undef, "Hash");
}

done_testing;
