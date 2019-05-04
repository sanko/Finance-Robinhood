package Finance::Robinhood::Equity::Account::MarginBalances;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Equity::Account - Robinhood Account's Instant or Gold
Margin Account Balances

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new->login('user', 'pass');
    my $account = $rh->equity_accounts->current();

    CORE::say 'How much can I borrow? ' . $account->margin_balances->margin_limit;

=cut

our $VERSION = '0.92_003';
use Mojo::Base-base, -signatures;
use Mojo::URL;

sub _test__init {
    my $rh              = t::Utility::rh_instance(1);
    my $acct            = $rh->equity_accounts->current;
    my $margin_balances = $acct->margin_balances;
    isa_ok($margin_balances, __PACKAGE__);
    t::Utility::stash('MARGIN', $margin_balances);    #  Store it for later
}
use overload '""' => sub ($s, @) { +$s->{created_at} }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('MARGIN') // skip_all();
    like(+t::Utility::stash('MARGIN'),
         qr'^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d\.\d+Z$');
}

=head1 METHODS

=cut

has _rh => undef => weak => 1;

=head2 C<cash( )>

=head2 C<cash_available_for_withdrawal( )>

=head2 C<cash_held_for_dividends( )>

=head2 C<cash_held_for_nummus_restrictions( )>

=head2 C<cash_held_for_options_collateral( )>

=head2 C<cash_held_for_orders( )>

=head2 C<cash_pending_from_options_events( )>

 
=head2 C<day_trade_buying_power( )>

=head2 C<day_trade_buying_power_held_for_orders( )>

=head2 C<day_trade_ratio( )>

=head2 C<gold_equity_requirement( )>

=head2 C<margin_limit( )>

 
=head2 C<outstanding_interest( )>

=head2 C<overnight_buying_power( )>

=head2 C<overnight_buying_power_held_for_orders( )>

=head2 C<overnight_ratio( )>

=head2 C<sma( )>

=head2 C<start_of_day_dtbp( )>

=head2 C<start_of_day_overnight_buying_power( )>

=head2 C<unallocated_margin_cash( )>

=head2 C<uncleared_deposits( )>

=head2 C<uncleared_nummus_deposits( )>

=head2 C<unsettled_debit( )>

=head2 C<unsettled_funds( )>



=cut

has ['cash',
     'cash_available_for_withdrawal',
     'cash_held_for_dividends',
     'cash_held_for_nummus_restrictions',
     'cash_held_for_options_collateral',
     'cash_held_for_orders',
     'cash_pending_from_options_events',
     'day_trade_buying_power',
     'day_trade_buying_power_held_for_orders',
     'day_trade_ratio',
     'gold_equity_requirement',
     'margin_limit',
     'outstanding_interest',
     'overnight_buying_power',
     'overnight_buying_power_held_for_orders',
     'overnight_ratio',
     'sma',
     'start_of_day_dtbp',
     'start_of_day_overnight_buying_power',
     'unallocated_margin_cash',
     'uncleared_deposits',
     'uncleared_nummus_deposits',
     'unsettled_debit',
     'unsettled_funds',
];

=head2 C<marked_pattern_day_trader_date( )>

Returns a Time::Moment object if applicable.

=cut

sub marked_pattern_day_trader_date ($s) {
    defined $s->{marked_pattern_day_trader_date}
        ? Time::Moment->from_string($s->{marked_pattern_day_trader_date})
        : ();
}

sub _test_marked_pattern_day_trader_date {
    t::Utility::stash('MARGIN')
        // skip_all('No margin balances object in stash');
    skip_all('Not marked as a PDT')
        if !
        defined t::Utility::stash('MARGIN')->marked_pattern_day_trader_date;
    isa_ok(t::Utility::stash('MARGIN')->marked_pattern_day_trader_date,
           'Time::Moment');
}

=head2 C<created_at( )>

Returns a Time::Moment object.

=cut

sub created_at ($s) {
    Time::Moment->from_string($s->{created_at});
}

sub _test_created_at {
    t::Utility::stash('MARGIN')
        // skip_all('No margin balances object in stash');
    isa_ok(t::Utility::stash('MARGIN')->created_at, 'Time::Moment');
}

=head2 C<updated_at( )>

Returns a Time::Moment object if applicable.

=cut

sub updated_at ($s) {
    Time::Moment->from_string($s->{updated_at});
}

sub _test_updated_at {
    t::Utility::stash('MARGIN')
        // skip_all('No margin balances object in stash');
    isa_ok(t::Utility::stash('MARGIN')->updated_at, 'Time::Moment');
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
