package Finance::Robinhood::Options::Event::CashComponent;
use Moo;
use Finance::Robinhood::Utils::Client;
has 'client' => (
    is      => 'rw',
    default => sub { Finance::Robinhood::Utils::Client->instance },
    handles => [qw[get]]
);
has [
    qw[id cash_amount direction
        ]
] => ( is => 'ro' );
1;
