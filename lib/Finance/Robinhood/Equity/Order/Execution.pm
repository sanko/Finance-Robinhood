package Finance::Robinhood::Equity::Order::Execution;
use Moo;
use DateTime::Tiny;
use Date::Tiny;
#
has [
    qw[
        price
        id
        quantity
        ]
] => ( is => 'ro' );
has ['timestamp'] => (
    is     => 'ro',
    coerce => sub {
        $_[0] =~ s'Z$'';

        # BUG: DateTime::Tiny cannot handle sub-second values.
        $_[0] =~ s'\..+$'';
        DateTime::Tiny->from_string( $_[0] );
    }
);
has ['settlement_date'] => (
    is     => 'ro',
    coerce => sub {
        Date::Tiny->from_string( $_[0] );
    }
);
1;
