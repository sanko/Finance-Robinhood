package Finance::Robinhood::Equity::Instrument::Historicals;
use Moo;
use Finance::Robinhood::Equity::Instrument::Historicals::DataPoint;
#
has [qw[quote symbol interval span bounds]] => ( is => 'ro' );
has 'historicals' => (
    is     => 'ro',
    coerce => sub {
        [ map { Finance::Robinhood::Equity::Instrument::Historicals::DataPoint->new($_) }
                @{ $_[0] } ];
    }
);

# TODO:
#   "quote": "https://api.robinhood.com/quotes/50810c35-d215-4866-9758-0ada4ac79ffa/",
#   "instrument": "https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/",
1;
