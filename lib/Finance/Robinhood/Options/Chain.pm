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
has 'min_ticks' => (
    is     => 'ro',
    coerce => sub {

        # TODO
        $_[0];    # { above_tick => "0.10", below_tick => 0.05, cutoff_price => "3.00" }
    }
);
has 'underlying_instruments' => (
    is     => 'ro',
    coerce => sub {
        $_[0];    # [

# TODO
#           {
#             id => "600c76b0-87a0-426f-8bd6-6b599cb49781",
#             instrument => "https://api.robinhood.com/instruments/b13ae284-239a-4808-af3a-564848cf6868/",
#             quantity => 100,
#           },
#         ],
    }
);
1;
