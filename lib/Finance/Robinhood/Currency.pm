package Finance::Robinhood::Currency;
our $VERSION = '0.92_003';

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Currency - Represents a Single Forex Currency Pair

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;

    # TODO

=cut

use Moo;
use Data::Dump;
use HTTP::Tiny;
use JSON::Tiny;
use Types::Standard qw[Enum InstanceOf Num StrMatch Str];
use URI;
use experimental 'signatures';
#
use Finance::Robinhood::Currency::Quote;
use Finance::Robinhood::Types qw[:all];

sub _test__init {
    my $rh  = t::Utility::rh_instance(1);
    my $btc = $rh->currency_by_id('d674efea-e623-4396-9026-39574b92b093');    # BTC
    isa_ok( $btc, __PACKAGE__ );
    t::Utility::stash( 'CURRENCY', $btc );                                    #  Store it for later
}
use overload '""' => sub ( $s, @ ) { $s->id }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('CURRENCY') // skip_all();
    like(
        +t::Utility::stash('CURRENCY'),
        qr'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'i
    );
}
#
has robinhood => ( is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood'] );

=head1 METHODS

=head2 C<brand_color( )>

If defined, this returns a hex color code used for display.

=head2 C<code( )>

Short code used to represent this currency for display. 'USD' or 'ETH', for
example.

=head2 C<id( )>

Returns a UUID.

=head2 C<increment( )>

The increment used as a minimum for display, etc. For example, USD would return
C<0.01> to prevent sub-penny price display.

=head2 C<name( )>

Returns a string suited for display. And example would be 'US Dollar'.

=head2 C<type( )>

This is the asset type. Currently, C<fiat> or C<cryptocurrency>.

=cut

has [qw[brand_color code name]] => ( is => 'ro', isa => Str,  required => 1 );
has increment                   => ( is => 'ro', isa => Num,  required => 1 );
has id                          => ( is => 'ro', isa => UUID, required => 1 );
has type                        => (
    is       => 'ro',
    isa      => Enum [qw[fiat cryptocurrency]],
    handles  => [qw[is_fiat is_cryptocurrency]],
    required => 1
);

=head2 C<news( )>

    my $news = $currency->news;

Returns an iterator containing Finance::Robinhood::News elements.

=cut

sub news ($s) { $s->robinhood->news( $s->id ) }

sub _test_news {
    t::Utility::stash('CURRENCY') // skip_all();
    my $news = t::Utility::stash('CURRENCY')->news;
    isa_ok( $news,          'Finance::Robinhood::Utilities::Iterator' );
    isa_ok( $news->current, 'Finance::Robinhood::News' );
}

=head2 C<pair( )>

    my $pair = $currency->pair;

Returns a Finance::Robinhood::Currency::Pair object.

=cut

has pair => (
    is       => 'ro',
    isa      => InstanceOf ['Finance::Robinhood::Currency::Pair'],
    lazy     => 1,
    builder  => 1,
    init_arg => undef
);

sub _build_pair ($s) {
    my ($retval) = grep { $_->asset_currency->id eq $s->id } $s->robinhood->currency_pairs->all;
    $retval;
}

sub _test_pair {
    t::Utility::stash('CURRENCY') // skip_all();
    my $pair = t::Utility::stash('CURRENCY')->pair;
    isa_ok( $pair, 'Finance::Robinhood::Currency::Pair' );
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
