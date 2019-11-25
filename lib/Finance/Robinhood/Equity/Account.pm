package Finance::Robinhood::Equity::Account;
our $VERSION = '0.92_003';

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

#
use Moo;
use MooX::Enumeration;
use Types::Standard qw[Bool Enum InstanceOf Maybe Num Str StrMatch];
use URI;
use Time::Moment;
use Data::Dump;
use experimental 'signatures';
#
use Finance::Robinhood::Types qw[Timestamp UUID URL];
use Finance::Robinhood::Equity::Account::CashBalances;
use Finance::Robinhood::Equity::Account::MarginBalances;
use Finance::Robinhood::Equity::Account::MarginEligibility;
use Finance::Robinhood::Equity::Account::Portfolio;
use Finance::Robinhood::Equity::Position;

sub _test__init {
    my $rh   = t::Utility::rh_instance(1);
    my $acct = $rh->equity_accounts->current;
    isa_ok( $acct, __PACKAGE__ );
    t::Utility::stash( 'ACCT', $acct );    #  Store it for later
}

=head1 METHODS

=cut

#
has robinhood => ( is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood'] );

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

=head2 C<user( )>

Returns the related Finance::Robinhood::Equity::User object.

=head2 C<can_downgrade_to_cash( )>

This method returns a true value if your account is currently eligible for
downgrading from a margin account (Instant or Gold) to a cash account.

=head2 C<received_ach_debit_locked( )>

Boolean.

=head2 C<cash_management_enabled( )>

Returns a boolean value.

=cut

has url => ( is => 'ro', required => 1, isa => URL, coerce => 1, );
has '_' . $_ => ( is => 'ro', required => 1, isa => URL, coerce => 1, init_arg => $_ )
    for qw[can_downgrade_to_cash portfolio positions user];
has user => (
    is       => 'ro',
    isa      => InstanceOf ['Finance::Robinhood::User'],
    lazy     => 1,
    builder  => 1,
    init_arg => undef
);

sub _build_user ($s) {    # _url() is malformed by RH. They forget the protocol.
    $s->robinhood->_req( GET => 'https://api.robinhood.com/user/' )->as('Finance::Robinhood::User');
}

sub _test_user {
    t::Utility::stash('ACCT') // skip_all('No account object in stash');
    isa_ok( t::Utility::stash('ACCT')->user, 'Finance::Robinhood::User' );
}
has can_downgrade_to_cash =>
    ( is => 'ro', isa => Bool, lazy => 1, builder => 1, coerce => 1, init_arg => undef );

sub _build_can_downgrade_to_cash ($s) {
    $s->robinhood->_req( GET => $s->_can_downgrade_to_cash )->json->{can_downgrade_to_cash} ? 1 : 0;
}

sub _test_can_downgrade_to_cash {
    t::Utility::stash('ACCT') // skip_all('No account object in stash');
    my $can_downgrade_to_cash = t::Utility::stash('ACCT')->can_downgrade_to_cash;
    pass('TODO: Somehow check that $can_downgrade_to_cash is true or false');
}
has cash_management_enabled => ( is => 'ro', isa => Bool, coerce   => 1, required => 1 );
has account_number          => ( is => 'ro', isa => Str,  required => 1 );
has [
    qw[buying_power cash cash_available_for_withdrawal cash_held_for_orders crypto_buying_power
        max_ach_early_access_amount portfolio_cash
        rhs_account_number
        sma
        sma_held_for_orders
        uncleared_deposits
        unsettled_debit
        unsettled_funds
        ]
] => ( is => 'ro', isa => Num, required => 1 );
has received_ach_debit_locked => ( is => 'ro', isa => Bool, coerce => 1, required => 1 );

=head2 C<created_at( )>

Returns a Time::Moment object.

=head2 C<updated_at( )>

Returns a Time::Moment object.

=cut

has $_ => ( is => 'ro', required => 1, coerce => 1, isa => Timestamp )
    for qw[created_at updated_at];

sub _test_created_at {
    t::Utility::stash('ACCT') // skip_all('No account object in stash');
    isa_ok( t::Utility::stash('ACCT')->created_at, 'Time::Moment' );
}

sub _test_updated_at {
    t::Utility::stash('ACCT') // skip_all('No account object in stash');
    isa_ok( t::Utility::stash('ACCT')->updated_at, 'Time::Moment' );
}
has margin_eligibility => (
    is       => 'ro',
    required => 1,
    init_arg => 'instant_eligibility',
    coerce   => sub ($data) {
        Finance::Robinhood::Equity::Account::MarginEligibility->new(%$data);
    },
    isa => InstanceOf ['Finance::Robinhood::Equity::Account::MarginEligibility'],
);
has active_subscription_id => ( is => 'ro', required => 1, isa => Maybe [UUID] );
has [
    qw[deactivated deposit_halted is_pinnacle_account locked
        permanently_deactivated sweep_enabled withdrawal_halted
        only_position_closing_trades
        ]
] => ( is => 'ro', isa => Bool, required => 1, coerce => sub($bool) { !!$bool } );
has type => (
    is       => 'ro',
    required => 1,
    isa      => Enum [qw[cash margin]],
    handles  => [qw[is_cash is_margin]]
);
has state => ( is => 'ro', required => 1, isa => Enum [qw[active]], handles => [qw[is_active]] );
has option_level => (
    is       => 'ro',
    required => 1,
    isa      => Enum [qw[option_level_1 option_level_2 option_level_3]],
    handles  => [qw[is_option_level_1 is_option_level_2 is_option_level_3]]
);
has cash_balances => (
    is        => 'ro',
    required  => 1,
    predicate => 'has_cash_balances',
    coerce    => sub ($data) {
        $data ? Finance::Robinhood::Equity::Account::CashBalances->new(%$data) : ();
    },
    isa => Maybe [ InstanceOf ['Finance::Robinhood::Equity::Account::CashBalances'] ],
);
has margin_balances => (
    is        => 'ro',
    required  => 1,
    predicate => 'has_margin_balances',
    coerce    => sub ($data) {
        $data ? Finance::Robinhood::Equity::Account::MarginBalances->new(%$data) : ();
    },
    isa => Maybe [ InstanceOf ['Finance::Robinhood::Equity::Account::MarginBalances'] ],
);

=head2 C<portfolio( )>

Returns the related Finance::Robinhood::Equity::Account::Portfolio object.

=cut
has portfolio => (
    is       => 'ro',
    isa      => InstanceOf ['Finance::Robinhood::Equity::Account::Portfolio'],
    lazy     => 1,
    builder  => 1,
    init_arg => undef
);

sub _build_portfolio ($s) {
    $s->robinhood->_req( GET => $s->_portfolio )
        ->as('Finance::Robinhood::Equity::Account::Portfolio');
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
    my $url = URI->new( $s->_positions );
    $url->query_form(%filters);
    Finance::Robinhood::Utilities::Iterator->new(
        robinhood => $s->robinhood,
        url       => $url,
        as        => 'Finance::Robinhood::Equity::Position'
    );
}

sub _test_positions {
    t::Utility::stash('ACCT') // skip_all('No account object in stash');
    my $positions = t::Utility::stash('ACCT')->positions;
    isa_ok( $positions,          'Finance::Robinhood::Utilities::Iterator' );
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
