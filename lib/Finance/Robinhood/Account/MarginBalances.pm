package Finance::Robinhood::Account::MarginBalances;
use Moo;
use Time::Moment;
has [
    qw[cash
        cash_available_for_withdrawal cash_held_for_options_collateral cash_held_for_orders
        day_trade_buying_power day_trade_buying_power_held_for_orders day_trade_ratio
        gold_equity_requirement margin_limit marked_pattern_day_trader_date outstanding_interest
        overnight_buying_power overnight_buying_power_held_for_orders overnight_ratio
        start_of_day_dtbp start_of_day_overnight_buying_power
        unallocated_margin_cash uncleared_deposits
        unsettled_debit unsettled_funds
        ]
] => ( is => 'ro' );
has [qw[created_at updated_at]] => (
    is     => 'ro',
    coerce => sub {
        $_[0] // return;
        Time::Moment->from_string( $_[0] );
    }
);
1;
