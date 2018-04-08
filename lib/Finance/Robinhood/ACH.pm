package Finance::Robinhood::ACH;
use Moo;
use DateTime::Tiny;
use Finance::Robinhood::Utils::Client;
has 'client' => (
    is      => 'rw',
    default => sub { Finance::Robinhood::Utils::Client->instance },
    handles => [qw[post]]
);
has [
    qw[account
        bank_account_holder_name bank_account_nickname bank_account_number bank_account_type bank_routing_number
        id initial_deposit
        verification_method verified verify_micro_deposits
        withdrawl_limit
        url
        ]
] => ( is => 'ro' );
has [ 'created_at', 'updated_at' ] => (
    is     => 'ro',
    coerce => sub {
        $_[0] =~ s'Z$'';

        # BUG: DateTime::Tiny cannot handle sub-second values.
        $_[0] =~ s'\..+$'';
        DateTime::Tiny->from_string( $_[0] );
    }
);
has "_unlink" => ( is => 'ro', init_arg => 'unlink' );

sub unlink {

    # TODO
}

=head2 C<schedule_deposit( ... )>

    my $ok = $ach->schedule_deposit( 500, 'weekly' );

Create a scheduled ACH deposit. This is returned as a C<Finance::Robinhood::ACH::ScheduledDeposit> object.

Expected arguments are:

=over

=item * amount to transfer

=item * frequency

Options for frequency include:

=over

=item * C<once> - The deposit will be initiated immediately.

=item * C<weekly> - The deposit will be initiated every Monday.

=item * C<biweekly> - The deposit will be initiated on the 1st and 15th of every month.

=item * C<monthly> - The deposit will be initiated on the 1st of every month.

=item * C<quarterly> - The deposit will be initiated on the 1st of January, April, July, and October.

=back

=back

To cancel the deposit, use the object's C<cancel()> method.

=cut

sub schedule_deposit {
    my ( $s, $amount, $frequency ) = @_;
    my ( $status, $data ) = $s->post( $Finance::Robinhood::Endpoints{'ach/deposit_schedules'},
        { ach_relationship => $s->url, amount => $amount, frequency => $frequency } );
    $status == 201 ? Finance::Robinhood::ACH::ScheduledDeposit->new($data) : ();
}
1;
