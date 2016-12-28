use strict;
use Test::More 0.98;
use lib '../lib/';
use_ok $_ for qw(
    Finance::Robinhood
);
#
can_ok 'Finance::Robinhood::Instrument',
    qw[bloomberg_unique day_trade_ratio min_tick_size margin_initial_ratio
    id maintenance_ratio name state symbol tradeable country
    list_date
    market splits fundamentals
    quote
];
my $msft = new_ok 'Finance::Robinhood::Instrument',
    [id => '50810c35-d215-4866-9758-0ada4ac79ffa'];
is $msft->symbol, 'MSFT', 'Instrument symbol == MSFT';
my $aapl = Finance::Robinhood::instrument('AAPL');
isa_ok $aapl, 'Finance::Robinhood::Instrument',
    'Searched with F::R::instrument(...)';
is $aapl->symbol, 'AAPL', 'Instrument symbol == AAPL';
#
isa_ok $aapl->market, 'Finance::Robinhood::Market', '->market( )';
isa_ok $aapl->splits->[0], 'Finance::Robinhood::Instrument::Split',
    '->splits( )';
isa_ok $aapl->quote, 'Finance::Robinhood::Quote', '->quote( )';
#
done_testing;
