package Finance::Robinhood::Options::Chain::UnderlyingInstrument;
use Moo;
has [qw[id quantity]] => ( is => 'ro' );
has '_instrument_url' => ( is => 'ro', init_arg => 'instrument' );
has 'instrument' => (
    is       => 'ro',
    lazy     => 1,
    init_arg => undef,
    builder  => sub {
        my ( $status, $data )
            = Finance::Robinhood::Utils::Client->instance->get( $_[0]->_instrument_url );
        $status == 200 ? Finance::Robinhood::Equity::Instrument->new($data) : $data;
    }
);
1;
