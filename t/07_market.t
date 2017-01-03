use strict;
use Test::More 0.98;
use lib '../lib/';
use_ok $_ for qw(
    Finance::Robinhood
);
#
my $markets = Finance::Robinhood::markets();
isa_ok $markets->{results}[0], 'Finance::Robinhood::Market',
    'gathered lists of markets';
#
my $nasdaq = Finance::Robinhood::Market->new('XNAS');
isa_ok $nasdaq, 'Finance::Robinhood::Market',
    'scraped info to create NASDAQ market object';
is $nasdaq->acronym, 'NASDAQ',                   '->acronym() eq "NASDAQ"';
is $nasdaq->city,    'New York',                 '->city()';
is $nasdaq->country, 'United States of America', '->country()';
is $nasdaq->mic,     'XNAS',                     '->mic()';
is $nasdaq->name,    'NASDAQ - All Markets',     '->name()';
is $nasdaq->operating_mic, 'XNAS',           '->operating_mic()';
is $nasdaq->timezone,      'US/Eastern',     '->timezone()';
is $nasdaq->website,       'www.nasdaq.com', '->website()';
isa_ok $nasdaq->todays_hours, 'Finance::Robinhood::Market::Hours',
    '->todays_hours()';
#
can_ok $nasdaq->todays_hours, $_
    for
    qw[is_open date opens_at closes_at next_open_hours previous_open_hours];
isa_ok $nasdaq->todays_hours->next_open_hours,
    'Finance::Robinhood::Market::Hours', '->todays_hours->next_open_hours()';
isa_ok $nasdaq->todays_hours->previous_open_hours,
    'Finance::Robinhood::Market::Hours',
    '->todays_hours->previous_open_hours()';
#
my $nyse = Finance::Robinhood::Market->new(
                            url => 'https://api.robinhood.com/markets/XNYS/');
isa_ok $nyse, 'Finance::Robinhood::Market',
    'scraped info to create NYSE market object';
is $nyse->acronym, 'NYSE', '->acroym() eq "NYSE"';
#
done_testing;
