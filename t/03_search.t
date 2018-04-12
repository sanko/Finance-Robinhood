use strict;
use Test::More 0.98;
use lib '../lib/';
$|++;
use_ok $_ for qw(
    Finance::Robinhood
);
my $rh = Finance::Robinhood->new();
#
my $msft = $rh->search('MSFT');
isa_ok $msft->{instruments}[0], 'Finance::Robinhood::Equity::Instrument',
    'Searched for Microsoft...';
is $msft->{instruments}[0]->symbol, 'MSFT', '...and the first instrument result is Microsoft';
#
my $coin = $rh->search('coin');
isa_ok $coin->{currency_pairs}[0], 'Finance::Robinhood::Forex::CurrencyPair',
    'Searched for "coin"...';
#
my $finance = $rh->search('finance');
isa_ok $finance->{tags}[0], 'Finance::Robinhood::Tag', 'Searched for "finance"...';
#
done_testing;
