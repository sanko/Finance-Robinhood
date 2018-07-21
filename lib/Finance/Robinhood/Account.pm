package Finance::Robinhood::Account;
use Moo;
with 'MooX::Singleton';
use Time::Moment;
#
use Finance::Robinhood::Equity::Position;
use Finance::Robinhood::Account::InstantEligibility;
use Finance::Robinhood::Account::MarginBalances;
use Finance::Robinhood::Account::Portfolio;
use Finance::Robinhood::Account::Portfolio::Historicals;
has [
    qw[account_number buying_power
        cash cash_available_for_withdrawl cash_balances cash_held_for_orders
        deactivated deposit_halted
        max_ach_early_access_amount
        only_position_closing_trades
        option_level sma sma_held_for_orders sweep_enabled type uncleared_deposits
        unsettled_debt unsettled_funds url withdrawal_halted
        ]
] => ( is => 'ro' );
has 'instant_eligibility' =>
    ( is => 'ro', coerce => sub { Finance::Robinhood::Account::InstantEligibility->new( $_[0] ) } );
has 'margin_balances' =>
    ( is => 'ro', coerce => sub { Finance::Robinhood::Account::MarginBalances->new( $_[0] ) } );
has [ 'created_at', 'updated_at' ] => (
    is     => 'ro',
    coerce => sub {
        Time::Moment->from_string( $_[0] );
    }
);
has '_' . $_ . '_url' => (
    is       => 'ro',
    init_arg => $_,
    coerce   => sub {
        ref $_[0] ? $_[0]->url : $_[0];
    }
) for qw[portfolio positions can_downgrade_to_cash];
has 'portfolio' => (
    is       => 'ro',
    lazy     => 1,
    init_arg => undef,
    builder  => sub {
        my ( $status, $data )
            = Finance::Robinhood::Utils::Client->instance->get( shift->_portfolio_url );
        $status == 200 ? Finance::Robinhood::Account::Portfolio->new($data) : ();
    }
);
has 'positions' => (
    is       => 'ro',
    lazy     => 1,
    init_arg => undef,
    builder  => sub {
        Finance::Robinhood::Utils::Paginated->new(
            class => 'Finance::Robinhood::Equity::Position',
            next  => shift->_positions_url
        );
    }
);

=head2 C<portfolio_historicals( ... )>

    my $ok = $account->portfolio_historicals( interval => 'week' );

Gather historical quote data for all supported options instrument. This is
returned as a C<Finance::Robinhood::Account::Portfolio::Historicals> object.

The following arguments are accepted:

=over

=item C<interval> - C<5minute>, C<10minute>, C<hour>, C<day>, C<week>, or C<month>

=item C<span> - C<week>, C<year>, C<5year>, or C<10year>

=item C<bounds> - C<extended>, C<regular>, C<trading>

=back

C<interval> is required.

=cut

sub portfolio_historicals {
    my ( $s,      %args ) = @_;
    my ( $status, $data ) = Finance::Robinhood::Utils::Client->instance->get(
        Finance::Robinhood::Utils::Client::__url_and_args(
            sprintf( $Finance::Robinhood::Endpoints{'portfolios/historicals/{accountNumber}'}, $s->account_number ),
            \%args
        )
    );
    $status == 200 ? Finance::Robinhood::Account::Portfolio::Historicals->new($data) : $data;
}

has 'can_downgrade_to_cash' => (
    is       => 'ro',
    lazy     => 1,
    init_arg => undef,
    builder  => sub {
        my ( $status, $data )
            = Finance::Robinhood::Utils::Client->instance->get( shift->_can_downgrade_to_cash_url );
        $status == 200 ? $data->{can_downgrade_to_cash} : ()    # simple boolean
    }
);
1;
