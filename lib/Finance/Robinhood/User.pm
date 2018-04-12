package Finance::Robinhood::User;
use Moo;
with 'MooX::Singleton';
use DateTime::Tiny;
#
has [
    qw[email email_verified id first_name last_name username url
        ]
] => ( is => 'ro' );
has '_' . $_ => ( is => 'ro', init_arg => $_ )
    for qw[id_info basic_info additional_info employment international_info
    investment_profile
];
has ['created_at'] => (
    is     => 'ro',
    coerce => sub {
        $_[0] =~ s'Z$'';

        # BUG: DateTime::Tiny cannot handle sub-second values.
        $_[0] =~ s'\..+$'';
        DateTime::Tiny->from_string( $_[0] );
    }
);

=head2 C<basic_info( )>

    my $user_info = $rh->user->basic_info( );

Grab user personal information. This is returned as a C<Finance::Robinhood::User::BasicInfo> object.

=cut

sub basic_info {
    my ($s) = @_;
    my ( $status, $data ) = Finance::Robinhood::Utils::Client->instance->get( $s->_basic_info );
    $status == 200 ? Finance::Robinhood::User::BasicInfo->new($data) : $data;
}

=head2 C<id_info( )>

    my $id_info = $rh->user->id_info( );

Grab user ID information. This is returned as a C<Finance::Robinhood::User::Id> object.

=cut

sub id_info {
    my ($s) = @_;
    my ( $status, $data ) = Finance::Robinhood::Utils::Client->instance->get( $s->_id_info );
    $status == 200 ? Finance::Robinhood::User::Id->new($data) : $data;
}

=head2 C<investment_profile( )>

    my $profile = $rh->user->investment_profile( );

Grab user's investment experience information. This is returned as a C<Finance::Robinhood::User::InvestmentProfile> object.

=cut

sub investment_profile {
    my ($s) = @_;
    my ( $status, $data )
        = Finance::Robinhood::Utils::Client->instance->get( $s->_investment_profile );
    $status == 200 ? Finance::Robinhood::User::InvestmentProfile->new($data) : $data;
}

=head2 C<additional_info( )>

    my $add_info = $rh->user->additional_info( );

Grab additional user information. This is returned as a C<Finance::Robinhood::User::AdditionalInfo> object.

=cut

sub additional_info {
    my ($s) = @_;
    my ( $status, $data )
        = Finance::Robinhood::Utils::Client->instance->get( $s->_additional_info );
    $status == 200 ? Finance::Robinhood::User::AdditionalInfo->new($data) : $data;
}
1;
