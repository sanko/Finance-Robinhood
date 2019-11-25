package Finance::Robinhood::Equity::Account::MarginBalances;
our $VERSION = '0.92_003';
#
use Moo;
use MooX::Enumeration;
use Types::Standard qw[ArrayRef Bool Enum InstanceOf Maybe Num Str StrMatch];
use URI;
use Time::Moment;
use Data::Dump;
use experimental 'signatures';
#
has $_ => (is => 'ro', required => 1, isa => Num) for qw[
    cash cash_available_for_withdrawal
    cash_held_for_dividends cash_held_for_nummus_restrictions
    cash_held_for_options_collateral cash_held_for_orders
    cash_held_for_restrictions cash_pending_from_options_events
    crypto_buying_power day_trade_buying_power day_trade_buying_power_held_for_orders
    day_trade_ratio funding_hold_balance gold_equity_requirement
    margin_limit net_moving_cash outstanding_interest
    overnight_buying_power overnight_buying_power_held_for_orders overnight_ratio
    pending_debit_card_debits pending_deposit portfolio_cash settled_amount_borrowed sma
    start_of_day_dtbp start_of_day_overnight_buying_power unallocated_margin_cash uncleared_deposits
    uncleared_nummus_deposits unsettled_debit
    unsettled_funds];
has day_trades_protection => (is       => 'ro',
                              required => 1,
                              isa      => Bool,
                              coerce   => sub ($bool) { !!$bool }
);
has marked_pattern_day_trader_date => (
    is       => 'ro',
    requried => 1,
    isa      => Maybe [InstanceOf ['Time::Moment']],
    coerce   => sub ($date) {
        $date ? Time::Moment->from_string($date . 'T00:00:00.0000Z') : ();
    }
);
has $_ => (is       => 'ro',
           requried => 1,
           isa      => InstanceOf ['Time::Moment'],
           coerce   => sub ($date) { Time::Moment->from_string($date) }
) for qw[created_at updated_at];
1;
