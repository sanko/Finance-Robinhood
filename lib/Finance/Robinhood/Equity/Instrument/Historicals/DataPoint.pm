package Finance::Robinhood::Equity::Instrument::Historicals::DataPoint;
use Moo;
use Time::Moment;
#
has [qw[open_price close_price high_price low_price volume session interpolated]] => ( is => 'ro' );
has 'begins_at' => (
    is     => 'ro',
    coerce => sub {
        Time::Moment->from_string( $_[0] );
    }
);
1;
