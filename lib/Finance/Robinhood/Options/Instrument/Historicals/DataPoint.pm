package Finance::Robinhood::Options::Instrument::Historicals::DataPoint;
use Moo;
use Time::Moment;
#
has [qw[close_price interpolated open_price session volume]] => ( is => 'ro' );
has 'begins_at' => (
    is     => 'ro',
    coerce => sub {
        Time::Moment->from_string( $_[0] );
    }
);
1;
