package Finance::Robinhood::Options::Position;
use Moo;
use DateTime::Tiny;
use Date::Tiny;
has [
    qw[account average_price chain_id chain_symbol id
        intraday_average_open_price intraday_quantity
        option
        quantity pending_buy_quantity pending_expired_quantity pending_sell_quantity
        type url
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
1;
