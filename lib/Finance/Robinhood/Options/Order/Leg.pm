package Finance::Robinhood::Options::Order::Leg;
use Moo;
#
use Finance::Robinhood::Options::Order::Leg::Execution;
#
has [qw[side position_effect id ratio_quantity]] => ( is => 'ro' );
has '_option_url' => (
    is       => 'ro',
    init_arg => 'option',
    coerce   => sub {

        # If created by user, accept object
        # If created by /options/order/ API call, accept plain url
        ref $_[0] ? $_[0]->url : $_[0];
    }
);
has 'option' => (
    is       => 'ro',
    lazy     => 1,
    init_arg => undef,
    builder  => sub {
        my ( $status, $data )
            = Finance::Robinhood::Utils::Client->instance->get( shift->_option_url );
        $status == 200 ? Finance::Robinhood::Options::Instrument->new($data) : ();
    }
);
has 'executions' => (
    is     => 'ro',
    coerce => sub {
        [ map { Finance::Robinhood::Options::Order::Leg::Execution->new($_) } @{ $_[0] } ];
    }
);
1;
