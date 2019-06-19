package Finance::Robinhood::Options::Position;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Options::Position - Represents a Single Options Position on
a Robinhood Account

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new->login('user', 'pass');

	for my $position ($rh->options_positions) {
		CORE::say $position->instrument->symbol;
	}

=cut

our $VERSION = '0.92_003';
use Mojo::Base-base, -signatures;
use Mojo::URL;
use Finance::Robinhood::Equity::Instrument;

sub _test__init {
    my $rh       = t::Utility::rh_instance(1);
    my $position = $rh->options_positions->current;
    isa_ok($position, __PACKAGE__);
    t::Utility::stash('POSITION', $position);    #  Store it for later
}
use overload '""' => sub ($s, @) { $s->{url} }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('POSITION') // skip_all();
    like(+t::Utility::stash('POSITION'),
         qr'https://api.robinhood.com/options/positions/.+/');
}
##

=head1 METHODS

=cut

has _rh => undef => weak => 1;

=head2 C<average_price( )>


=head2 C<chain_id( )>


=head2 C<chain_symbol( )>


=head2 C<intraday_average_open_price( )>

=head2 C<intraday_quantity( )>

=head2 C<pending_buy_quantity>


=head2 C<pending_expired_quantity( )>

=head2 C<pending_sell_quantity( )>

=head2 C<quantity( )>


=head2 C<trade_value_multiplier( )>


=head2 C<type( )>


=cut

has ['average_price',               'chain_id',
     'chain_symbol',                'id',
     'intraday_average_open_price', 'intraday_quantity',
     'pending_buy_quantity',        'pending_expired_quantity',
     'pending_sell_quantity',       'quantity',
     'trade_value_multiplier',      'type',
];

=head2 C<created_at( )>

Returns a Time::Moment object.

=cut

sub created_at ($s) {
    Time::Moment->from_string($s->{created_at});
}

sub _test_created_at {
    t::Utility::stash('POSITION') // skip_all('No position object in stash');
    isa_ok(t::Utility::stash('POSITION')->created_at, 'Time::Moment');
}

=head2 C<updated_at( )>

Returns a Time::Moment object.

=cut

sub updated_at ($s) {
    Time::Moment->from_string($s->{updated_at});
}

sub _test_updated_at {
    t::Utility::stash('POSITION') // skip_all('No position object in stash');
    isa_ok(t::Utility::stash('POSITION')->updated_at, 'Time::Moment');
}

=head2 C<instrument( )>

Returns the related Finance::Robinhood::Options::Instrument object.

=cut

sub instrument ($s) {
    my $res = $s->_rh->_get($s->{option});
    return $res->is_success
        ? Finance::Robinhood::Options::Instrument->new(_rh => $s->_rh,
                                                       %{$res->json})
        : Finance::Robinhood::Error->new(
             $res->is_server_error ? (details => $res->message) : $res->json);
}

sub _test_instrument {
    t::Utility::stash('POSITION') // skip_all('No position object in stash');
    isa_ok(t::Utility::stash('POSITION')->instrument,
           'Finance::Robinhood::Options::Instrument');
}

=head2 C<chain( )>

Returns the related Finance::Robinhood::Options::Chain object.

=cut

sub chain ($s) {
    $s->_rh->options_chain_by_id($s->{chain_id});
}

sub _test_chain {
    t::Utility::stash('POSITION') // skip_all('No position object in stash');
    isa_ok(t::Utility::stash('POSITION')->chain,
           'Finance::Robinhood::Options::Chain');
}

=head2 C<account( )>

Returns the related Finance::Robinhood::Equity::Account object.

=cut

sub account ($s) {
    my $res = $s->_rh->_get($s->{account});
    return $res->is_success
        ? Finance::Robinhood::Equity::Account->new(_rh => $s->_rh,
                                                   %{$res->json})
        : Finance::Robinhood::Error->new(
             $res->is_server_error ? (details => $res->message) : $res->json);
}

sub _test_account {
    t::Utility::stash('POSITION') // skip_all('No position object in stash');
    isa_ok(t::Utility::stash('POSITION')->account,
           'Finance::Robinhood::Equity::Account');
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
