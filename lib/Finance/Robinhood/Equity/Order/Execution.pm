package Finance::Robinhood::Equity::Order::Execution;
use Moo;
use Time::Moment;
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
        Time::Moment->from_string( $_[0] );
    }
);
has ['settlement_date'] => (
    is     => 'ro',
    coerce => sub {
        Time::Moment->from_string( $_[0] );
    }
);
1;
