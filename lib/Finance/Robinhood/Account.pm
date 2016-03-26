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
has $_ => (is => 'bare', required => 1, accessor => "_get_$_", weak_ref => 1)
    for (qw[rh]);

sub positions {
    my ($self) = @_;

    # TODO: Cursors!
    my ($result)
        = $self->_get_rh()->_send_request('GET',
                            Finance::Robinhood::endpoint('accounts/positions')
                                . '?account='
                                . $self->account_number()
                                . '&nonzero=true');
    return $self->_get_rh()
        ->_paginate($result, 'Finance::Robinhood::Position');
}

sub portfolio {
    my ($self) = @_;
    my ($result)
        = $self->_get_rh()->_send_request('GET',
                           Finance::Robinhood::endpoint('accounts/portfolios')
                               . $self->account_number()
                               . '/');
}
1;

=encoding utf-8

=head1 NAME

Finance::Robinhood::Account - Single securities trade account

=head1 SYNOPSIS

    use Finance::Robinhood;

    my $rh = Finance::Robinhood->new( token => ... );
    my @accounts = $rh->accounts()->{results};
    my $account = $accounts[0];

=head1 DESCRIPTION

This class represents a single account. Objects are usually created by
Finance::Robinhood's C<accounts( ... )> method rather than directly.

=head1 METHODS

This class has several getters and a few methods as follows...

=head2 C<portfolio( )>

Gets a quick rundown of the account's financial standing. Results are returned
as a hash with the following keys:

    adjusted_equity_previous_close      Total balance as of previous close +/- after hours trading
    equity                              Total balance
    equity_previous_close               Total balance as of previous close
    excess_margin
    extended_hours_equity               Total valance including after hours trading
    extended_hours_market_value         Market value of securities including after hours trading
    last_core_equity                    Total balance
    last_core_market_value              Market value of securities
    market_value                        Marekt value of securities

=head2 C<positions( ... )>

    my @positions = $account->positions( );

Returns a paginated list of all securities this account has ever owned. The
results are blessed Finance::Robinhood::Position objects.

=head2 C<account_number( )>

    my $acct = $account->account_number();

Returns the alphanumeric string Robinhood uses to identify this particular
account. Keep this secret!

=head2 C<buying_power( )>

Total amount of money you currently have for buying shares of securities.

This is not a total amount of cash as it does not include unsettled funds.

=head2 C<cash( )>

Total amount of money on hand. This includes unsettled funds and cash on hand.

=head2 C<cash_available_for_withdrawal( )>

Amount of money on hand you may withdrawl to an associated bank account.

=head2 C<cash_held_for_orders( )>

Amount of money currently marked for unexecuted buy orders.

=head2 C<deactivated( )>

If the account is deactivated for any reason, this will be a true value.

=head2 C<deposit_halted( )>

If an attempt to deposit funds to Robinhood fails, I imagine this boolean
value would be true.

=head2 C<margin_balances( )>

For margin accounts (Robinhood Instant), this is the amount of funds you have
access to.

=head2 C<max_ach_early_access_amount( )>

Robinhood Instant accounts have early access to a defined amount of money
before the actual transfer has cleared.

=head2 C<only_position_closing_trades( )>

Boolean value.

=head2 C<sma( )>

Simple moving average of funds.

=head2 C<sms_held_for_orders( )>

Simple moving average for cash held for outstanding orders.

=head2 C<sweep_enabled( )>

Alternative markets?

=head2 C<type( )>

Basic Robinhood accounts are C<cash> accounts while Robinhood Instant accounts
would be C<margin>.

I<Note>: ...I would imagine, not having Instant yet.

=head2 C<uncleared_deposits( )>

When a deposit is initited but has not be completed, the amount is added here.

=head2 C<unsettled_funds( )>

The amount of money from sell orders which has not settled (see T+3 rule).

=head2 C<updated_at( )>

DateTime object marking the last time the account was changed.

=head2 C<withdrawal_halted( )>

Boolean value.

=head1 LEGAL

This is a simple wrapper around the API used in the official apps. The author
provides no investment, legal, or tax advice and is not responsible for any
damages incured while using this software. Neither this software nor its
author are affiliated with Robinhood Financial LLC in any way.

For Robinhood's terms and disclosures, please see their website at http://robinhood.com/

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Other copyrights, terms, and conditions may apply to data transmitted through
this module. Please refer to the L<LEGAL> section.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut
