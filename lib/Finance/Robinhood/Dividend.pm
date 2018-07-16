package Finance::Robinhood::Dividend;
use Moo;
use Time::Moment;
#
has [qw[amount id instrument position rate withholding url]] => ( is => 'ro' );
has ['paid_at'] => (
    is     => 'ro',
    coerce => sub {
        Time::Moment->from_string( $_[0] );
    }
);
#
has [ 'payable_date', 'record_date' ] => (
    is     => 'ro',
    coerce => sub {
        Time::Moment->from_string( $_[0] );
    }
);

# TODO: coerce account to object
1;
