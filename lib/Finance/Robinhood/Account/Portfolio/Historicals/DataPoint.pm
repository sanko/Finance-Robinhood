package Finance::Robinhood::Account::Portfolio::Historicals::DataPoint;
use Moo;
use Time::Moment;
#
has [qw[adjusted_close_equity adjusted_open_equity close_equity close_market_value net_return open_equity open_market_value session]] => ( is => 'ro' );
has 'begins_at' => (
    is     => 'ro',
    coerce => sub {
        Time::Moment->from_string( $_[0] );
    }
);
1;
