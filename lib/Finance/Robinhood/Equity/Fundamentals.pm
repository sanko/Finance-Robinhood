package Finance::Robinhood::Equity::Fundamentals;
use Moo;
use Time::Moment;
has [
    qw[open high low volume average_volume_2_weeks average_volume
        high_52_weeks low_52_weeks
        dividend_yield market_cap
        pe_ratio
        shares_outstanding
        description
        ceo headquarters_city
        headquarters_state
        num_employees
        year_founded
        ]
] => ( is => 'ro' );
has '_instrument_url' => (
    is       => 'ro',
    init_arg => 'instrument',
    coerce   => sub {
        ref $_[0] ? $_[0]->url : $_[0];
    }
);
has 'instrument' => (
    is       => 'ro',
    lazy     => 1,
    init_arg => undef,
    builder  => sub {
        my ( $status, $data )
            = Finance::Robinhood::Utils::Client->instance->get( shift->_instrument_url );
        $status == 200 ? Finance::Robinhood::Equity::Instrument->new($data) : ();
    }
);
1;
