package Finance::Robinhood::Options::Event;
use Moo;
use Finance::Robinhood::Utils::Client;
use Finance::Robinhood::Options::Event::EquityComponent;
use Finance::Robinhood::Options::Event::CashComponent;
use Time::Moment;
has 'client' => (
    is      => 'rw',
    default => sub { Finance::Robinhood::Utils::Client->instance },
    handles => [qw[post]]
);
has [
    qw[direction id option position quantity state total_cash_amount type
        ]
] => ( is => 'ro' );
has [ 'created_at', 'updated_at' ] => (
    is     => 'ro',
    coerce => sub {
        Time::Moment->from_string( $_[0] );
    }
);
has 'equity_components' => (
    is     => 'ro',
    coerce => sub {
        [ map { Finance::Robinhood::Options::Event::EquityComponent->new($_) } @{ $_[0] } ];
    }
);
has 'cash_components' => (
    is     => 'ro',
    coerce => sub {
        [ map { Finance::Robinhood::Options::Event::CashComponent->new($_) } @{ $_[0] } ];
    }
);
has 'event_date' => (
    is     => 'ro',
    coerce => sub {
        Time::Moment->from_string( $_[0] );
    }
);
1;
