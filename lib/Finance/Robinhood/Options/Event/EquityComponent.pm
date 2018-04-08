package Finance::Robinhood::Options::Event::EquityComponent;
use Moo;
use DateTime::Tiny;
use Date::Tiny;
use Finance::Robinhood::Utils::Client;
has 'client' => (
    is      => 'rw',
    default => sub { Finance::Robinhood::Utils::Client->instance },
    handles => [qw[get]]
);
has [
    qw[id instrument price quantity side symbol
        ]
] => ( is => 'ro' );
1;
