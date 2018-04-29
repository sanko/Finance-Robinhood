package Finance::Robinhood::Equity::Order;
use Moo;
use DateTime::Tiny;
#
has [
    qw[
        ref_id
        time_in_force
        fees
        response_category
        id
        cumulative_quantity
        stop_price
        reject_reason
        state
        trigger
        override_dtbp_checks
        type
        price
        extended_hours
        url
        side
        override_day_trade_checks
        average_price
        quantity
        ]
] => ( is => 'ro' );
has [ 'created_at', 'last_transaction_at' ] => (
    is     => 'ro',
    coerce => sub {
        $_[0] =~ s'Z$'';

        # BUG: DateTime::Tiny cannot handle sub-second values.
        $_[0] =~ s'\..+$'';
        DateTime::Tiny->from_string( $_[0] );
    }
);
has 'executions' => (
    is     => 'ro',
    coerce => sub {
        [ map { Finance::Robinhood::Equity::Order::Execution->new($_) } @{ $_[0] } ];
    }
);
has 'cancel_url' => ( is => 'ro', predicate => 1, init_arg => 'cancel' );

sub cancel {
    my ($s) = @_;
    return if !$s->cancel_url;
    my ( $status, $data ) = Finance::Robinhood::Utils::Client->instance->post( $s->cancel_url );
    $status == 200 ?
        $_[0]
        = __PACKAGE__->new( scalar Finance::Robinhood::Utils::Client->instance->get( $s->url ) ) :
        $data;
}
has '_account_url' => (
    is       => 'ro',
    init_arg => 'account',
    coerce   => sub {
        ref $_[0] ? $_[0]->url : $_[0];
    }
);
has 'account' => (
    is       => 'ro',
    lazy     => 1,
    init_arg => undef,
    builder  => sub {
        my ( $status, $data )
            = Finance::Robinhood::Utils::Client->instance->get( shift->_account_url );
        $status == 200 ? Finance::Robinhood::Account->new($data) : ();
    }
);
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
has '_position_url' => (
    is       => 'ro',
    init_arg => 'position',
    coerce   => sub {
        ref $_[0] ? $_[0]->url : $_[0];
    }
);
has 'position' => (
    is       => 'ro',
    lazy     => 1,
    init_arg => undef,
    builder  => sub {
        my ( $status, $data )
            = Finance::Robinhood::Utils::Client->instance->get( shift->_position_url );
        $status == 200 ? Finance::Robinhood::Equity::Position->new($data) : ();
    }
);
1;
