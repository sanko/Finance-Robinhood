package Finance::Robinhood::Equity::Instrument::Historicals::DataPoint;
use Moo;
#
has [qw[open_price close_price high_price low_price volume session interpolated]] => ( is => 'ro' );
has 'begins_at' => (
    is     => 'ro',
    coerce => sub {
        $_[0] =~ s'Z$'';

        # BUG: DateTime::Tiny cannot handle sub-second values.
        $_[0] =~ s'\..+$'';
        DateTime::Tiny->from_string( $_[0] );
    }
);
1;
