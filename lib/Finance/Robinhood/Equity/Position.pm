package Finance::Robinhood::Equity::Position;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Equity::Position - Represents a Single Equity Position on a
Robinhood Account

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new->login('user', 'pass');
    my $account = $rh->equity_accounts->current();

	for my $position ($account->equity_positions) {
		CORE::say $position->instrument->symbol;
	}

=cut

our $VERSION = '0.92_001';
use Mojo::Base-base, -signatures;
use Mojo::URL;
use Finance::Robinhood::Equity::Instrument;

sub _test__init {
    my $rh       = t::Utility::rh_instance(1);
    my $acct     = $rh->equity_accounts->current;
    my $position = $acct->positions->current;
    isa_ok( $position, __PACKAGE__ );
    t::Utility::stash( 'POSITION', $position );    #  Store it for later
}
use overload '""' => sub ( $s, @ ) { $s->{url} }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('POSITION') // skip_all();
    like(
        +t::Utility::stash('POSITION'), qr'https://api.robinhood.com/accounts/.+/positions/.+/',
    );
}
##

=head1 METHODS

=cut

has _rh => undef => weak => 1;

=head2 C<average_buy_price( )>


=head2 C<intraday_average_buy_price( )>


=head2 C<intraday_quantity( )>


=head2 C<pending_average_buy_price( )>


=head2 C<quantity( )>


=head2 C<shares_held_for_buys( )>


=head2 C<shares_held_for_options_collateral( )>

Shares held for collateral for a sold call, etc.

=head2 C<shares_held_for_options_events( )>


=head2 C<shares_held_for_sells( )>

Shares that are marked to be sold in outstanding orders.

=head2 C<shares_held_for_stock_grants( )>

Shares that were a reward (referral, etc.) and must be held for a period before
they can be sold.

=head2 C<shares_pending_from_options_events( )>


=cut

has [
    'average_buy_price',                  'intraday_average_buy_price',
    'intraday_quantity',                  'pending_average_buy_price',
    'quantity',                           'shares_held_for_buys',
    'shares_held_for_options_collateral', 'shares_held_for_options_events',
    'shares_held_for_sells',              'shares_held_for_stock_grants',
    'shares_pending_from_options_events',
];

=head2 C<created_at( )>

Returns a Time::Moment object.

=cut

sub created_at ($s) {
    Time::Moment->from_string( $s->{created_at} );
}

sub _test_created_at {
    t::Utility::stash('POSITION') // skip_all('No position object in stash');
    isa_ok( t::Utility::stash('POSITION')->created_at, 'Time::Moment' );
}

=head2 C<updated_at( )>

Returns a Time::Moment object.

=cut

sub updated_at ($s) {
    Time::Moment->from_string( $s->{updated_at} );
}

sub _test_updated_at {
    t::Utility::stash('POSITION') // skip_all('No position object in stash');
    isa_ok( t::Utility::stash('POSITION')->updated_at, 'Time::Moment' );
}

=head2 C<instrument( )>

Returns the related Finance::Robinhood::Equity::Instrument object.

=cut

sub instrument ($s) {
    my $res = $s->_rh->_get( $s->{instrument} );
    return $res->is_success
        ? Finance::Robinhood::Equity::Instrument->new( _rh => $s->_rh, %{ $res->json } )
        : Finance::Robinhood::Error->new(
        $res->is_server_error ? ( details => $res->message ) : $res->json );
}

sub _test_instrument {
    t::Utility::stash('POSITION') // skip_all('No position object in stash');
    isa_ok( t::Utility::stash('POSITION')->instrument, 'Finance::Robinhood::Equity::Instrument' );
}

=head2 C<account( )>

Returns the related Finance::Robinhood::Equity::Account object.

=cut

sub account ($s) {
    my $res = $s->_rh->_get( $s->{account} );
    return $res->is_success
        ? Finance::Robinhood::Equity::Account->new( _rh => $s->_rh, %{ $res->json } )
        : Finance::Robinhood::Error->new(
        $res->is_server_error ? ( details => $res->message ) : $res->json );
}

sub _test_account {
    t::Utility::stash('POSITION') // skip_all('No position object in stash');
    isa_ok( t::Utility::stash('POSITION')->account, 'Finance::Robinhood::Equity::Account' );
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
