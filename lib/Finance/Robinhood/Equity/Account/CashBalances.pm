package Finance::Robinhood::Equity::Account::CashBalances;
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
has $_ => (is => 'ro', required => 1, isa => Num)
    for
    qw[buying_power cash_held_for_dividends cash_held_for_options_collateral cash_held_for_orders
    crypto_buying_power pending_deposit uncleared_deposits uncleared_nummus_deposits unsettled_funds];
has $_ => (is       => 'ro',
           requried => 1,
           isa      => InstanceOf ['Time::Moment'],
           coerce   => sub ($date) { Time::Moment->from_string($date) }
) for qw[created_at updated_at];
1;
