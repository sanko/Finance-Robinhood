package Finance::Robinhood::Options::Instrument::Historicals;
use Moo;
use Finance::Robinhood::Options::Instrument::Historicals::DataPoint;
#
has [qw[open_price previous_close_price interval span bounds]] => ( is => 'ro' );
has [ 'open_time', 'previous_close_time' ] => (
    is     => 'ro',
    coerce => sub {
        $_[0] =~ s'Z$'';

        # BUG: DateTime::Tiny cannot handle sub-second values.
        $_[0] =~ s'\..+$'';
        DateTime::Tiny->from_string( $_[0] );
    }
);
has 'data_points' => (
    is     => 'ro',
    coerce => sub {
        [ map { Finance::Robinhood::Options::Instrument::Historicals::DataPoint->new($_) }
                @{ $_[0] } ];
    }
);
1;
