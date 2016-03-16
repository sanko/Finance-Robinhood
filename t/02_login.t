use strict;
use Test::More 0.98;
use lib '../lib/';
use_ok $_ for qw(
    Finance::Robinhood
);
subtest 'skippy' => sub {
    plan skip_all => 'Missing token!' if !defined $ENV{RHUSER} || ! defined $ENV{RHPASSWORD};
    my $rh = Finance::Robinhood->new();
    ok $rh->login($ENV{RHUSER}, $ENV{RHPASSWORD}), '->login(...)';
    my $msft = $rh->quote('MSFT');
    isa_ok $msft, 'Finance::Robinhood::Quote', 'Gathered quote data for MSFT';
    isa_ok $msft->refresh(), 'Finance::Robinhood::Quote', 'Refreshed data';
    my ($southwest, $jetblue, $delta) = $rh->quote('LUV', 'JBLU', 'DAL');
    is $southwest->symbol(), 'LUV',  'Southwest Airlines';
    is $jetblue->symbol(),   'JBLU', 'JetBlue Airways';
    is $delta->symbol(),     'DAL',  'Delta Air Lines';
};
done_testing;
