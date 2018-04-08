package Finance::Robinhood::Account;
use Moo;
with 'MooX::Singleton';
use DateTime::Tiny;
use Date::Tiny;
#
use Finance::Robinhood::Account::InstantEligibility;
use Finance::Robinhood::Account::MarginBalances has [
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
        $_[0] =~ s'Z$'';

        # BUG: DateTime::Tiny cannot handle sub-second values.
        $_[0] =~ s'\..+$'';
        DateTime::Tiny->from_string( $_[0] );
    }
);
has [
    qw[can_downgrade_to_cash portfolio positions
        ]
] => ( is => 'ro' );
1;
