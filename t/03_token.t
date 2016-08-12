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
    isa_ok $msft->{results}[0], 'Finance::Robinhood::Quote',
        'Gathered quote data...';
    is $msft->{results}[0]->symbol(), 'MSFT', '...for Microsoft';
    isa_ok $msft->{results}[0]->refresh(), 'Finance::Robinhood::Quote',
        'Refreshed data';
    my $results = $rh->quote('LUV', 'JBLU', 'DAL');
    is $results->{results}[0]->symbol(), 'LUV',  'Southwest Airlines';
    is $results->{results}[1]->symbol(), 'JBLU', 'JetBlue Airways';
    is $results->{results}[2]->symbol(), 'DAL',  'Delta Air Lines';
};
done_testing;
