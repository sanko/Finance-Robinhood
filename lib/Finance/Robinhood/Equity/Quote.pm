package Finance::Robinhood::Equity::Quote;
use Moo;
use DateTime::Tiny;
use Date::Tiny;
has [
    qw[adjusted_previous_close  previous_close
        ask_price ask_size bid_price bid_size
        has_traded
        last_extended_hours_trade_price last_trade_price last_trade_price_source
        symbol
        trading_halted
        ]
] => ( is => 'ro' );

# TODO:
#   - instrument
#
has 'previous_close_date' => (
    is     => 'ro',
    coerce => sub {
        Date::Tiny->from_string( $_[0] );
    }
);
has 'updated_at' => (
    is     => 'ro',
    coerce => sub {
        $_[0] =~ s'Z$'';
        DateTime::Tiny->from_string( $_[0] );
    }
);
1;
