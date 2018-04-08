package Finance::Robinhood::Options::Instrument::Historicals::DataPoint;
use Moo;
#
has [qw[close_price interpolated open_price session volume]] => ( is => 'ro' );
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
