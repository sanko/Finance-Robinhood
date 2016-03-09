package Finance::Robinhood::Account;
use 5.008001;
use strict;
use warnings;
use Carp;
our $VERSION = "0.01";
use Data::Dump qw[ddx];
use Moo;
use JSON::Tiny qw[decode_json];
use strictures 2;
use namespace::clean;
#
has $_ => (is => 'ro', required => 1, writer => "_set_$_")
    for (
     qw[account_number buying_power cash cash_available_for_withdrawal
     cash_held_for_orders deactivated deposit_halted margin_balances
     max_ach_early_access_amount only_position_closing_trades sma
     sma_held_for_orders sweep_enabled type uncleared_deposits unsettled_funds
     updated_at withdrawal_halted]
    );
1;
