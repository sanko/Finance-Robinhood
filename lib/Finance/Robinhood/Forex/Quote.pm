package Finance::Robinhood::Forex::Quote;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Forex::Quote - Represents Quote Data for a Single Forex
Currency Pair

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;
    
    # TODO

=cut

our $VERSION = '0.92_002';
use Mojo::Base-base, -signatures;
use Mojo::URL;
use Time::Moment;
use Finance::Robinhood::Forex::Pair;

sub _test__init {
    my $rh    = t::Utility::rh_instance(1);
    my $quote = $rh->forex_pairs->current->quote();
    isa_ok($quote, __PACKAGE__);
    t::Utility::stash('QUOTE', $quote);    #  Store it for later
}
#
has _rh => undef => weak => 1;

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

has ['ask_price', 'bid_price',  'high_price', 'id',
     'low_price', 'mark_price', 'open_price', 'symbol',
     'volume'
];

=head2 C<instrument( )>

    my $instrument = $quote->instrument();

Loops back to a Finance::Robinhood::Forex::Instrument object.

=cut

sub pair ($s) {
    return $s->_rh->forex_pair_by_id($s->{id});
}

sub _test_pair {
    t::Utility::stash('QUOTE') // skip_all();
    isa_ok(t::Utility::stash('QUOTE')->pair(),
           'Finance::Robinhood::Forex::Pair');
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
