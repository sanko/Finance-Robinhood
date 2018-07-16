package Finance::Robinhood::Equity::Quote;
use Moo;
use Time::Moment;
has [
    qw[adjusted_previous_close  previous_close
        ask_price ask_size bid_price bid_size
        has_traded
        last_extended_hours_trade_price last_trade_price last_trade_price_source
        symbol
        trading_halted
        ]
] => ( is => 'ro' );
has '_instrument_url' => (
    is       => 'ro',
    init_arg => 'instrument',
    coerce   => sub {
        ref $_[0] ? $_[0]->url : $_[0];
    }
);
has 'instrument' => (
    is       => 'ro',
    lazy     => 1,
    init_arg => undef,
    builder  => sub {
        my ( $status, $data )
            = Finance::Robinhood::Utils::Client->instance->get( shift->_instrument_url );
        $status == 200 ? Finance::Robinhood::Equity::Instrument->new($data) : ();
    }
);
has 'previous_close_date' => (
    is     => 'ro',
    coerce => sub {
        Time::Moment->from_string( $_[0] . 'T00:00:00Z' );
    }
);
has 'updated_at' => (
    is     => 'ro',
    coerce => sub {
        Time::Moment->from_string( $_[0] );
    }
);
1;
