package Finance::Robinhood::Account::Portfolio;
use Moo;
with 'MooX::Singleton';
use Time::Moment;
#
has [
    qw[account adjusted_equity_previous_close equity equity_previous_close
        excess_maintenance excess_maintenance_with_uncleared_deposits
        excess_margin excess_margin_with_uncleared_deposits
        extended_hours_equity extended_hours_market_value
        last_core_equity last_core_market_value
        unwithdrawable_deposits unwithdrawable_grants
        url
        withdrawable_amount ]
] => ( is => 'ro' );
has ['start_date'] => (
    is     => 'ro',
    coerce => sub {
        Time::Moment->from_string( $_[0] . 'T00:00:00Z' );
    }
);
1;
