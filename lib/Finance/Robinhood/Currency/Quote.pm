package Finance::Robinhood::Currency::Quote;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Currency::Quote - Represents Quote Data for a Single Forex
Currency Pair

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;

    # TODO

=cut

our $VERSION = '0.92_003';
use Moo;
use Data::Dump;
use HTTP::Tiny;
use JSON::Tiny;
use Types::Standard qw[InstanceOf Num StrMatch Str];
use URI;
use experimental 'signatures';
#
use Finance::Robinhood::Currency::Pair;

sub _test__init {
    my $rh    = t::Utility::rh_instance(1);
    my $quote = $rh->currency_pairs->current->quote();
    isa_ok($quote, __PACKAGE__);
    t::Utility::stash('QUOTE', $quote);    #  Store it for later
}
#
has robinhood =>
    (is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood']);

=head1 METHODS


=head2 C<ask_price( )>

Live ask price.

=head2 C<bid_price( )>

Delayed bid price.

=head2 C<high_price( )>

Period high price.

=head2 C<low_price( )>

Period low price.

=head2 C<mark_price( )>

Spread midpoint.

=head2 C<open_price( )>

Period open price.

=head2 C<symbol( )>

The ticker symbol of the currency pair related to this quote data. See C<pair(
)> to be given the object itself.

=head2 C<volume( )>

Volume traded during period.

=cut

has [qw[ask_price bid_price high_price low_price mark_price open_price volume]
] => (is => 'ro', isa => Num, required => 1);
has id => (
    is  => 'ro',
    isa => StrMatch [
        qr'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'i
    ],
    required => 1
);
has symbol => (is => 'ro', isa => Str, required => 1);

=head2 C<pair( )>

    my $instrument = $quote->pair();

Loops back to a Finance::Robinhood::Currency::Pair object.

=cut

sub pair ($s) {
    return $s->robinhood->currency_pair_by_id($s->id);
}

sub _test_pair {
    t::Utility::stash('QUOTE') // skip_all();
    isa_ok(t::Utility::stash('QUOTE')->pair(),
           'Finance::Robinhood::Currency::Pair');
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
