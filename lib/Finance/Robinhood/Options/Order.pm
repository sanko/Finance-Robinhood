package Finance::Robinhood::Options::Order;
use Moo;
use DateTime::Tiny;
use Finance::Robinhood::Options::Order::Leg;
use Finance::Robinhood::Account;
#
has [
    qw[
        direction premium time_in_force processed_premium
        pending_quantity processed_quantity
        id ref_id state cancel_url
        price
        trigger
        chain_id chain_symbol
        response_category
        type
        quantity cancelled_quantity
        ]
] => ( is => 'ro' );
has [ 'created_at', 'updated_at' ] => (
    is     => 'ro',
    coerce => sub {
        $_[0] =~ s'Z$'';

        # BUG: DateTime::Tiny cannot handle sub-second values.
        $_[0] =~ s'\..+$'';
        DateTime::Tiny->from_string( $_[0] );
    }
);
has 'legs' => (
    is     => 'ro',
    coerce => sub {
        [ map { Finance::Robinhood::Options::Order::Leg->new($_) } @{ $_[0] } ];
    }
);

sub cancel {
    my ($s) = @_;
    return if !$s->cancel_url;
    Finance::Robinhood::Utils::Client->instance->post( $s->cancel_url );
}

sub day_trade_checks {
    my $s = shift;

    #use Data::Dump;
    #ddx( Finance::Robinhood::Utils::Client->instance->account );
    Finance::Robinhood::Utils::Client->instance->get(
        $Finance::Robinhood::Endpoints{'options/orders/day_trade_checks'},
        {   'account' => '/accounts/' .
                Finance::Robinhood::Utils::Client->instance->account->account_number,
        }
    );
}
1;
