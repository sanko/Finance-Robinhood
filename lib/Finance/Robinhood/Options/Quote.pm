package Finance::Robinhood::Options::Quote;
use Moo;
use Date::Tiny;
has [
    qw[adjusted_mark_price ask_price ask_size bid_price bid_size break_even_price high_price
        last_trade_price last_trade_size low_price mark_price open_interest
        previous_close_price volume chance_of_profit_long chance_of_profit_short delta gamma
        implied_volatility rho theta vega]
] => ( is => 'ro' );
has 'previous_close_date' => (
    is     => 'ro',
    coerce => sub {
        Date::Tiny->from_string( $_[0] );
    }
);
has '_instrument' => ( is => 'ro', init_arg => 'instrument' );
has 'instrument' => (
    is       => 'ro',
    init_arg => undef,
    lazy     => 1,
    builder  => sub {
        my $s = shift;
        my ( $status, $data ) = Finance::Robinhood::Utils::Client->instance->get( $_->_instrument );
        $status == 200 ? Finance::Robinhood::Equity::Instrument->new($data) : $data;
    }
);
1;
