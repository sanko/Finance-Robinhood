package Finance::Robinhood::Account;
use 5.010;
use strict;
use warnings;
use Carp;
our $VERSION = "0.10";
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
     withdrawal_halted]
    );
has $_ =>
    (is => 'bare', required => 1, writer => "_set_$_", reader => "_get_$_")
    for (qw[url]);
has $_ => (is       => 'ro',
           required => 1,
           coerce   => \&Finance::Robinhood::_2_datetime
) for (qw[updated_at]);
has $_ => (is => 'bare', required => 1, accessor => "_get_$_", weak_ref => 1)
    for (qw[rh]);

sub positions {
    my ($self, $type) = @_;
    my ($status, $result, $raw) = $self->_get_rh()->_send_request(
        'GET',
        sprintf(Finance::Robinhood::endpoint('accounts/positions'),
                $self->account_number()
            )
            . sub {
            my $opt = shift;
            return '' if !ref $opt || ref $type ne 'HASH';
            return '?cursor=' . $opt->{cursor} if defined $opt->{cursor};
            return '?nonzero=' . ($opt->{nonzero} ? 'true' : 'false')
                if defined $opt->{nonzero};
            return '';
        }
            ->($type)
    );
    return
        Finance::Robinhood::_paginate($self->_get_rh(), $result,
                                      'Finance::Robinhood::Position');
}

sub portfolio {
    my ($self) = @_;
    my ($status, $result, $raw)
        = $self->_get_rh()->_send_request('GET',
                                    Finance::Robinhood::endpoint('portfolios')
                                        . $self->account_number()
                                        . '/');
    return $result;
}

sub historicals {
    my ($self, $interval, $span) = @_;
    my ($status, $result, $raw)
        = $self->_get_rh()->_send_request('GET',
                        Finance::Robinhood::endpoint('portfolios/historicals')
                            . $self->account_number()
                            . "/?interval=$interval&span=$span");
    return () if $status != 200;
    for (@{$result->{equity_historicals}}) {
        $_->{begins_at} = Finance::Robinhood::_2_datetime($_->{begins_at});
    }
    return $result;
}
1;

=encoding utf-8

=head1 NAME

Finance::Robinhood::Account - Single Robinhood Trade Account

=head1 SYNOPSIS

    use Finance::Robinhood;

    my $rh = Finance::Robinhood->new( token => ... );
    my $account = $rh->accounts()->{results}[0];

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

=head2 C<historicals( ... )>

    $account->historicals( '5minute', 'day' );

Returns historical data about your portfolio. The first argument is an interval
time and must be either C<5minute>, C<10minute>, C<day>, or C<week>.

The second argument is a span of time indicating how far into the past you
would like to retrieve and may be one of the following: C<day>, C<week>,
C<year>, or C<5year>.

Results are returned as a hash with the following keys:

=over

=item C<equity_historicals> - List of hashes which contain the following keys:

=over

=item C<adjusted_close_equity>

=item C<adjusted_open_equity>

=item C<begins_at>

=item C<close_equity>

=item C<close_market_value>

=item C<net_return>

=item C<open_equity>

=item C<open_market_value>

=back

=item C<total_return> - The total ratio of returns for the span

=back

=head2 C<positions( ... )>

    my @positions = $account->positions( );

Returns a paginated list of I<all> securities this account has ever owned. The
C<results> are blessed Finance::Robinhood::Position objects.

    my $positions = $account->positions( {cursor => ...} )

Paginated list of positions is continued.

    my $positions = $account->positions( {nonzero => 1} )

Returns a paginated list of securities currently owned by this account. This
is likely what you want.

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

Amount of money on hand you may withdrawal to an associated bank account.

=head2 C<cash_held_for_orders( )>

Amount of money currently marked for active buy orders.

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

When a deposit is initiated but has not be completed, the amount is added here.

=head2 C<unsettled_funds( )>

The amount of money from sell orders which has not settled (see T+3 rule).

=head2 C<updated_at( )>

DateTime object marking the last time the account was changed.

=head2 C<withdrawal_halted( )>

Boolean value.

=head1 LEGAL

This is a simple wrapper around the API used in the official apps. The author
provides no investment, legal, or tax advice and is not responsible for any
damages incurred while using this software. Neither this software nor its
author are affiliated with Robinhood Financial LLC in any way.

For Robinhood's terms and disclosures, please see their website at http://robinhood.com/

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify
it under the terms found in the Artistic License 2.

Other copyrights, terms, and conditions may apply to data transmitted through
this module. Please refer to the L<LEGAL> section.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut
