use strict;
use Test::More 0.98;
use lib '../lib/';
use_ok $_ for qw(
    Finance::Robinhood
);
subtest 'skippy' => sub {
    plan skip_all => 'Missing token!' if !defined $ENV{RHTOKEN};
    my $rh = Finance::Robinhood->new(token => $ENV{RHTOKEN});
    my $msft = $rh->quote('MSFT');
    isa_ok $msft, 'Finance::Robinhood::Quote', 'Gathered quote data for MSFT';
    isa_ok $msft->refresh(), 'Finance::Robinhood::Quote', 'Refreshed data';
    my ($southwest, $jetblue, $delta) = $rh->quote('LUV', 'JBLU', 'DAL');
    is $southwest->symbol(), 'LUV',  'Southwest Airlines';
    is $jetblue->symbol(),   'JBLU', 'JetBlue Airways';
    is $delta->symbol(),     'DAL',  'Delta Air Lines';
};
done_testing;
