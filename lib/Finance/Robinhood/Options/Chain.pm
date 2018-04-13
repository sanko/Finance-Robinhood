package Finance::Robinhood::Options::Chain;
use Moo;
use Date::Tiny;
has [qw[can_open_position cash_component id symbol trade_value_multiplier]] => ( is => 'ro' );
has 'expiration_dates' => (
    is     => 'ro',
    coerce => sub {
        [ map { Date::Tiny->from_string($_) } @{ $_[0] } ];
    }
);
has 'min_ticks' =>
    ( is => 'ro', coerce => sub { Finance::Robinhood::Options::Chain::Ticks->new( $_[0] ) } );
has 'underlying_instruments' => (
    is     => 'ro',
    coerce => sub {
        [ map { Finance::Robinhood::Options::Chain::UnderlyingInstrument->new($_) } @{ $_[0] } ]
    }
);
1;
