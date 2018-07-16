package Finance::Robinhood::Options::Position;
use Moo;
use Time::Moment;
has [
    qw[account average_price chain_id chain_symbol id
        intraday_average_open_price intraday_quantity
        quantity pending_buy_quantity pending_expired_quantity pending_sell_quantity
        type url
        ]
] => ( is => 'ro' );
has [ 'created_at', 'updated_at' ] => (
    is     => 'ro',
    coerce => sub {
        Time::Moment->from_string( $_[0] );
    }
);
has '_option_url' => ( is => 'ro', init_arg => 'option' );
has 'option' => (
    is       => 'ro',
    lazy     => 1,
    init_arg => undef,
    builder  => sub {
        my ( $status, $data )
            = Finance::Robinhood::Utils::Client->instance->get( $_[0]->_option_url );
        $status == 200 ? Finance::Robinhood::Options::Instrument->new($data) : $data;
    }
);
1;
