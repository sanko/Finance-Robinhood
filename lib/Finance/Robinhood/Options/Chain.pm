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
has 'underlying_instruments' => (    # Equity
    is     => 'ro',
    coerce => sub {
        [ map { Finance::Robinhood::Options::Chain::UnderlyingInstrument->new($_) } @{ $_[0] } ]
    }
);

sub options_instruments {
    my ( $s, %args ) = @_;
    $args{chain_id} = [ $s->id ];
    Finance::Robinhood->options_instruments(%args);
}
1;
