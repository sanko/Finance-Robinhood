package Finance::Robinhood::Equity::Instrument;
use Moo;
use Date::Tiny;

# TODO:
#  "splits": "https://api.robinhood.com/instruments/ad5fc8ab-c9e1-41ba-ab38-37253577bcba/splits/",
#      "url": "https://api.robinhood.com/instruments/ad5fc8ab-c9e1-41ba-ab38-37253577bcba/",
#      "quote": "https://api.robinhood.com/quotes/KNG/",
#      "fundamentals": "https://api.robinhood.com/fundamentals/KNG/",
#      "market": "https://api.robinhood.com/markets/BATS/",
#
has [
    qw[type margin_initial_ratio tradability bloomberg_unique
        name symbol state country day_trade_ratio
        tradeable maintenance_ratio id simple_name min_tick_size]
] => ( is => 'ro' );
has 'list_date' => (
    is     => 'ro',
    coerce => sub {
        $_[0] ? Date::Tiny->from_string( $_[0] ) : ();
    }
);
1;
