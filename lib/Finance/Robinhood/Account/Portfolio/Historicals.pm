package Finance::Robinhood::Account::Portfolio::Historicals;
use Moo;
use Finance::Robinhood::Account::Portfolio::Historicals::DataPoint;
#
has [
    qw[adjusted_open_equity open_equity
        adjusted_previous_close_equity previous_close_equity
        bounds interval span
        open_time
        total_return]
] => ( is => 'ro' );
has 'equity_historicals' => (
    is     => 'ro',
    coerce => sub {
        [ map { Finance::Robinhood::Account::Portfolio::Historicals::DataPoint->new($_) }
                @{ $_[0] } ];
    }
);
1;
