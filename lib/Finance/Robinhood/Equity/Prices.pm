package Finance::Robinhood::Equity::Prices;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Equity::Prices - Represents Basic Price Data for a Single
Equity Instrument

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;
    my $instrument = $rh->equity_instrument_by_symbol('MSFT');

    my $price = $instrument->price();

=cut

our $VERSION = '0.92_002';
use Mojo::Base-base, -signatures;
use Mojo::URL;
use Time::Moment;
use Finance::Robinhood::Equity::Instrument;

sub _test__init {
    my $rh    = t::Utility::rh_instance(1);
    my $price = $rh->equity_instrument_by_symbol('MSFT')->prices();
    isa_ok($price, __PACKAGE__);
    t::Utility::stash('PRICES', $price);    #  Store it for later
}
#
has _rh => undef => weak => 1;

=head1 METHODS

=head2 C<ask_price( )>

The current best ask price.

=head2 C<ask_size( )>

The current best ask price's depth.

=head2 C<bid_price( )>

The current best bid price.

=head2 C<bid_size( )>

The current best bid's depth.

=head2 C<price( )>

The current last trade price.

=head2 C<size( )>

Size of the last trade.

=cut

has ['ask_price', 'ask_size', 'bid_price', 'bid_size', 'price', 'size'];

=head2 C<ask_source( )>

    CORE::say $prices->ask_source->name;

If available, this returns a Finance::Robinhood::Equity::Market object that
represents the source for the C<ask_price( )> and C<ask_size( )>.

=cut

sub ask_source ($s) {
    $s->_rh->equity_market_by_mic($s->{ask_mic}) if defined $s->{ask_mic};
}

sub _test_ask_source {
    t::Utility::stash('PRICES') // skip_all();
    my $source = t::Utility::stash('PRICES')->ask_source();
SKIP: {
        skip('Bad mic', 1) if !$source;
        isa_ok($source, 'Finance::Robinhood::Equity::Market');
    }
}

=head2 C<bid_source( )>

    CORE::say $prices->bid_source->name;

If available, this returns a Finance::Robinhood::Equity::Market object that
represents the source for the C<bid_price( )> and C<bid_size( )>.

=cut

sub bid_source ($s) {
    $s->_rh->equity_market_by_mic($s->{bid_mic}) if defined $s->{bid_mic};
}

sub _test_bid_source {
    t::Utility::stash('PRICES') // skip_all();
    my $source = t::Utility::stash('PRICES')->bid_source();
SKIP: {
        skip('Bad mic', 1) if !$source;
        isa_ok($source, 'Finance::Robinhood::Equity::Market');
    }
}

=head2 C<source( )>

    CORE::say $prices->source->name;

If available, this returns a Finance::Robinhood::Equity::Market object that
represents the source for the C<price( )> and C<size( )>.

=cut

sub source ($s) {
    $s->_rh->equity_market_by_mic($s->{mic}) if defined $s->{mic};
}

sub _test_source {
    t::Utility::stash('PRICES') // skip_all();
    my $source = t::Utility::stash('PRICES')->source();
SKIP: {
        skip('Bad mic', 1) if !$source;
        isa_ok($source, 'Finance::Robinhood::Equity::Market');
    }
}

=head2 C<updated_at( )>

    $prices->updated_at();

Returns a Time::Moment object.

=cut

sub updated_at ($s) {
    Time::Moment->from_string($s->{updated_at});
}

sub _test_updated_at {
    t::Utility::stash('PRICES') // skip_all();
    isa_ok(t::Utility::stash('PRICES')->updated_at(), 'Time::Moment');
}

=head2 C<instrument( )>

    my $instrument = $prices->instrument();

Loops back to a Finance::Robinhood::Equity::Instrument object.

=cut

sub instrument ($s) {
    $s->_rh->equity_instrument_by_id($s->{instrument_id});
}

sub _test_instrument {
    t::Utility::stash('PRICES') // skip_all();
    isa_ok(t::Utility::stash('PRICES')->instrument(),
           'Finance::Robinhood::Equity::Instrument');
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
