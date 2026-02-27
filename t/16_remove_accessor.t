use strict;
use warnings;
use Test::More;

{
    package App1;
    use Getopt::EX::Hashed;
    Getopt::EX::Hashed->configure(REMOVE_ACCESSOR => 1);
    has name => ( default => 'Alice', is => 'rw' );
    no Getopt::EX::Hashed;
}

{
    my $app = App1->new;
    is($app->name, 'Alice', "accessor works");
    ok(App1->can('name'), "accessor exists before destroy");
}
# $app is destroyed here
ok(!App1->can('name'), "accessor removed after destroy with REMOVE_ACCESSOR");

{
    package App2;
    use Getopt::EX::Hashed;
    has name => ( default => 'Bob', is => 'rw' );
    no Getopt::EX::Hashed;
}

{
    my $app = App2->new;
    is($app->name, 'Bob', "accessor works");
}
# $app is destroyed here
ok(App2->can('name'), "accessor persists after destroy without REMOVE_ACCESSOR");

done_testing;
