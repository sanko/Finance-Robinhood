package Finance::Robinhood::Tag;
use Moo;
has [
    qw[
        description name slug
        ]
] => ( is => 'ro' );
has '_instruments' => ( is => 'ro', init_arg => 'instruments' );
has 'instruments' => (
    is       => 'ro',
    init_arg => undef,
    lazy     => 1,
    builder  => sub {
        my $s = shift;
        [   map {
                my ( $status, $data ) = Finance::Robinhood::Utils::Client->instance->get($_);
                $status == 200 ? Finance::Robinhood::Equity::Instrument->new($data) : $data;
            } @{ $s->_instruments }
        ];
    }
);
1;
