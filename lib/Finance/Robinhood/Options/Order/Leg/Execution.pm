package Finance::Robinhood::Options::Order::Leg::Execution;
use Moo;
use DateTime::Tiny;
use Date::Tiny;
#
has [qw[id price quantity]] => ( is => 'ro' );
has 'settlement_date' => (
    is     => 'ro',
    coerce => sub {
        Date::Tiny->from_string( $_[0] );
    }
);
has 'timestamp' => (
    is     => 'ro',
    coerce => sub {
        $_[0] =~ s'Z$'';

        # BUG: DateTime::Tiny cannot handle sub-second values.
        $_[0] =~ s'\..+$'';
        DateTime::Tiny->from_string( $_[0] );
    }
);
1;
