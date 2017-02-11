use strict;
use Test::More 0.98;
use lib '../lib/';
use_ok $_ for qw(
    Finance::Robinhood::Instrument::Fundamentals
);
#
can_ok 'Finance::Robinhood::Instrument::Fundamentals',
    qw[average_volume description dividend_yield high high_52_weeks
    low low_52_weeks market_cap open pe_ratio volume
];
my $msft_url = new_ok 'Finance::Robinhood::Instrument::Fundamentals',
    [url => 'https://api.robinhood.com/fundamentals/MSFT/'], 'url => ...';
is substr($msft_url->description, 0, 23), 'Microsoft Corp. engages',
    'description == Microsoft Corp. engages...';
ok $msft_url->high >= $msft_url->low, 'high >= low';
ok $msft_url->high_52_weeks >= $msft_url->low_52_weeks,
    'high_52_weeks >= low_52_weeks';
#
done_testing;
