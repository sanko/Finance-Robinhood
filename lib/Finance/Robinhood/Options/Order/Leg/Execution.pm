package Finance::Robinhood::Options::Order::Leg::Execution;
use Moo;
use Time::Moment;
#
has [qw[id price quantity]] => ( is => 'ro' );
has 'settlement_date' => (
    is     => 'ro',
    coerce => sub {
        Time::Moment->from_string( $_[0] );
    }
);
has 'timestamp' => (
    is     => 'ro',
    coerce => sub {
        Time::Moment->from_string( $_[0] );
    }
);
1;
