package Finance::Robinhood::Equity::Account;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Equity::Account - Represents a Single Robinhood Account

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new->login('user', 'pass');
    my $account = $rh->equity_accounts->current();

    CORE::say sprintf '$%0.2f of $%0.2f can be withdrawn', 
        $account->cash_available_for_withdrawal,
        $account->cash;

=cut

our $VERSION = '0.92_002';

sub _test__init {
    my $rh   = t::Utility::rh_instance(1);
    my $acct = $rh->equity_accounts->current;
    isa_ok( $acct, __PACKAGE__ );
    t::Utility::stash( 'ACCT', $acct );    #  Store it for later
}
use Mojo::Base-base, -signatures;
use Mojo::URL;
use overload '""' => sub ( $s, @ ) { $s->{url} }, fallback => 1;
use Finance::Robinhood::Equity::Account::Portfolio;
use Finance::Robinhood::Equity::Account::InstantEligibility;
use Finance::Robinhood::Equity::Account::MarginBalances;

sub _test_stringify {
    t::Utility::stash('ACCT') // skip_all();
    like( +t::Utility::stash('ACCT'), qr'https://api.robinhood.com/accounts/.+/' );
}
##

=head1 METHODS

=cut

has _rh => undef => weak => 1;

=head2 C<account_number( )>

The string used to identify this account. Used in the URL for many endpoints.

=head2 C<buying_power( )>

The maximum amount of cash on hand and available margin you may use to buy
stuff.

=head2 C<cash( )>

The amount of settled cash on hand.

=head2 C<cash_available_for_withdrawal( )>

The amount of settled cash on hand that has been in the account long enough to
be withdrawn back to the original bank account.

=head2 C<cash_held_for_orders( )>

Money set aside for buy orders that have not yet executed.

=head2 C<deactivated( )>

Returns true if the account has been closed.

=head2 C<deposit_halted( )>

Returns true if ACH deposits are disabled.

=head2 C<is_pinnacle_account( )>

True if account is backed by Robinhood Clearing rather than Apex Clearing.

=head2 C<max_ach_early_access_amount( )>

Maximum amount instantly available after an ACH deposit. Unless you have a Gold
subscription, this will likely be Instant's standard $1000.

=head2 C<only_position_closing_trades( )>

If your account is restricted from opening new positions, this will be true.

=head2 C<option_level( )>

One of several options:

=over

=item * C<option_level_1>

=item * C<option_level_2>

=item * C<option_level_3>

=back
     
=head2 C<rhs_account_number( )>          

Internal account number used for official documents (tax forms, etc.)

=head2 C<sma( )>

TODO

=head2 C<sma_held_for_orders( )>          

TODO

=head2 C<sweep_enabled( )>          

Returns true if sweep is enabled to move cash between your brokerage account to
RH's crypto service.

=head2 C<type( )>

Simple C<cash> or C<margin> account flag.

=head2 C<uncleared_deposits( )>          

Incoming ACH deposits that have not cleared yet.

=head2 C<unsettled_debit( )>          

Outgoing funds that are not yet settled.

=head2 C<unsettled_funds( )>          

Funds that are not yet settled but may be used thanks to Gold or Instant margin
accounts.

=head2 C<withdrawal_halted( )>

True if the account has been flagged and ACH withdrawal has been disabled.

=cut

has [
    'account_number',              'cash',
    'buying_power',                'cash_available_for_withdrawal',
    'cash_held_for_orders',        'deactivated',
    'deposit_halted',              'is_pinnacle_account',
    'max_ach_early_access_amount', 'only_position_closing_trades',
    'option_level',                'rhs_account_number',
    'sma',                         'sma_held_for_orders',
    'sweep_enabled',               'type',
    'uncleared_deposits',          'unsettled_debit',
    'unsettled_funds',             'url',
    'withdrawal_halted'
];

=head2 C<created_at( )>

Returns a Time::Moment object.

=cut

sub created_at ($s) {
    Time::Moment->from_string( $s->{created_at} );
}

sub _test_created_at {
    t::Utility::stash('ACCT') // skip_all('No account object in stash');
    isa_ok( t::Utility::stash('ACCT')->created_at, 'Time::Moment' );
}

=head2 C<updated_at( )>

Returns a Time::Moment object.

=cut

sub updated_at ($s) {
    Time::Moment->from_string( $s->{updated_at} );
}

sub _test_updated_at {
    t::Utility::stash('ACCT') // skip_all('No account object in stash');
    isa_ok( t::Utility::stash('ACCT')->updated_at, 'Time::Moment' );
}

=head2 C<user( )>

Returns the related Finance::Robinhood::Equity::Account object.

=cut

sub user ($s) {
    my $res = $s->_rh->_get( $s->{user} );
    require Finance::Robinhood::User;
    $res->is_success
        ? Finance::Robinhood::User->new( _rh => $s->_rh, %{ $res->json } )
        : Finance::Robinhood::Error->new(
        $res->is_server_error ? ( details => $res->message ) : $res->json );
}

sub _test_user {
    t::Utility::stash('ACCT') // skip_all('No account object in stash');
    isa_ok( t::Utility::stash('ACCT')->user, 'Finance::Robinhood::User' );
}

=head2 C<can_downgrade_to_cash( )>

This method returns a true value if your account is currently eligible for
downgrading from a margin account (Instant or Gold) to a cash account.

=cut

sub can_downgrade_to_cash ($s) {
    my $res = $s->_rh->_get( $s->{can_downgrade_to_cash} );
    $res->is_success
        ? $res->json->{can_downgrade_to_cash}
        : Finance::Robinhood::Error->new(
        $res->is_server_error ? ( details => $res->message ) : $res->json );
}

sub _test_can_downgrade_to_cash {
    t::Utility::stash('ACCT') // skip_all('No account object in stash');
    my $can_downgrade_to_cash = t::Utility::stash('ACCT')->can_downgrade_to_cash;
    isa_ok( $can_downgrade_to_cash, 'JSON::PP::Boolean' );
}

=head2 C<instant_eligibility( )>

Returns the related Finance::Robinhood::Equity::Account::InstantEligibility
object.

=cut

sub instant_eligibility ($s) {
    Finance::Robinhood::Equity::Account::InstantEligibility->new(
        _rh => $s->_rh,
        %{ $s->{instant_eligibility} }
    );
}

sub _test_instant_eligibility {
    t::Utility::stash('ACCT') // skip_all('No account object in stash');
    my $instant_eligibility = t::Utility::stash('ACCT')->instant_eligibility;
    isa_ok( $instant_eligibility, 'Finance::Robinhood::Equity::Account::InstantEligibility' );
}

=head2 C<margin_balances( )>

Returns the related Finance::Robinhood::Equity::Account::MarginBalances object.

=cut

sub margin_balances ($s) {
    Finance::Robinhood::Equity::Account::MarginBalances->new(
        _rh => $s->_rh,
        %{ $s->{margin_balances} }
    );
}

sub _test_margin_balances {
    t::Utility::stash('ACCT') // skip_all('No account object in stash');
    my $margin_balances = t::Utility::stash('ACCT')->margin_balances;
    isa_ok( $margin_balances, 'Finance::Robinhood::Equity::Account::MarginBalances' );
}

=head2 C<portfolio( )>

Returns the related Finance::Robinhood::Equity::Account::Portfolio object.

=cut

sub portfolio ($s) {
    my $res = $s->_rh->_get( $s->{portfolio} );
    $res->is_success
        ? Finance::Robinhood::Equity::Account::Portfolio->new( _rh => $s->_rh, %{ $res->json } )
        : Finance::Robinhood::Error->new(
        $res->is_server_error ? ( details => $res->message ) : $res->json );
}

sub _test_portfolio {
    t::Utility::stash('ACCT') // skip_all('No account object in stash');
    my $portfolio = t::Utility::stash('ACCT')->portfolio;
    isa_ok( $portfolio, 'Finance::Robinhood::Equity::Account::Portfolio' );
}

=head2 C<positions( )>

    my $positions = $account->equity_positions( );

Returns the related paginated list object filled with
Finance::Robinhood::Equity::Position objects.

    my $positions = $account->equity_positions( nonzero => \1 );

You can filter and modify the results. All options are optional.

=over

=item C<nonzero> - true or false. Default is false.

=item C<ordering> - List of equity instruments

=back

=cut

sub positions ( $s, %filters ) {
    $filters{nonzero} = !!$filters{nonzero} ? 'true' : 'false' if defined $filters{nonzero};
    Finance::Robinhood::Utility::Iterator->new(
        _rh        => $s->_rh,
        _next_page => Mojo::URL->new( $s->{positions} )->query( \%filters ),
        _class     => 'Finance::Robinhood::Equity::Position'
    );
}

sub _test_positions {
    t::Utility::stash('ACCT') // skip_all('No account object in stash');
    my $positions = t::Utility::stash('ACCT')->positions;
    isa_ok( $positions,          'Finance::Robinhood::Utility::Iterator' );
    isa_ok( $positions->current, 'Finance::Robinhood::Equity::Position' );
}

=head1 LEGAL

This is a simple wrapper around the API used in the official apps. The author
provides no investment, legal, or tax advice and is not responsible for any
damages incurred while using this software. This software is not affiliated
with Robinhood Financial LLC in any way.

For Robinhood's terms and disclosures, please see their website at
https://robinhood.com/legal/

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module. Please refer to
the L<LEGAL> section.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut

1;
