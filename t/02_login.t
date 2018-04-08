use strict;
use Test::More 0.98;
use lib '../lib/';
use_ok $_ for qw(
    Finance::Robinhood
);
subtest 'skippy' => sub {
    plan skip_all => 'Missing username/password!'
        if !defined $ENV{RHUSER} || !defined $ENV{RHPASSWORD};
    my $rh = Finance::Robinhood->new();
    ok $rh->login( $ENV{RHUSER}, $ENV{RHPASSWORD} ), '->login(...)';

    # TOOD:
    #   Attempt to migrate token and make a call
    #   Attempt to check old skool token
};
done_testing;
