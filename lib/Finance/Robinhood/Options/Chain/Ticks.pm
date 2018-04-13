package Finance::Robinhood::Options::Chain::Ticks;
use Moo;
has [qw[above_tick below_tick cutoff_price]] => ( is => 'ro' );
1;
