package Finance::Robinhood::Dividend;
use Moo;
use Date::Tiny;
#
has [qw[amount id instrument position rate withholding url]] => ( is => 'ro' );
has ['paid_at'] => (
    is     => 'ro',
    coerce => sub {
        $_[0] =~ s'Z$'';

        # BUG: DateTime::Tiny cannot handle sub-second values.
        $_[0] =~ s'\..+$'';
        DateTime::Tiny->from_string( $_[0] );
    }
);
#
has [ 'payable_date', 'record_date' ] => (
    is     => 'ro',
    coerce => sub {
        Date::Tiny->from_string( $_[0] );
    }
);

# TODO: coerce account to object
1;
