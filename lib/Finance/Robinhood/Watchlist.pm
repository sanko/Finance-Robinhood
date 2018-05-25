package Finance::Robinhood::Watchlist;
use Moo;
has [
    qw[name url user]
] => ( is => 'ro' );
1;
