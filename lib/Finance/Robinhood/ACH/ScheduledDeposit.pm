package Finance::Robinhood::ACH::ScheduledDeposit;
use Moo;
use DateTime::Tiny;
use Date::Tiny;
has 'client' => (
    is      => 'rw',
    default => sub { Finance::Robinhood::Client->instance },
    handles => [qw[post delete]]
);
has [qw[id amount frequency url ach_relationship]] => ( is => 'ro' );
has [ 'next_deposit_date', 'last_attempt_date' ] => (
    is     => 'ro',
    coerce => sub {
        $_[0] // return;
        Date::Tiny->from_string( $_[0] );
    }
);
has [ 'created_at', 'updated_at' ] => (
    is     => 'ro',
    coerce => sub {
        $_[0] // return;
        $_[0] =~ s'Z$'';

        # BUG: DateTime::Tiny cannot handle sub-second values.
        $_[0] =~ s'\..+$'';
        DateTime::Tiny->from_string( $_[0] );
    }
);

sub cancel {
    my ( $status, $data ) = $_[0]->delete( $_[0]->url );
    $_[0] = () if $status == 204;
    $_[0];
}
1;