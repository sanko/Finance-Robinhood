package Finance::Robinhood::Search;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Search - Represents Search Results

=head1 SYNOPSIS

    use Text::Wrap qw[wrap];
    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;

    my $search = $rh->search('shoes');

=head1 METHODS

=cut

our $VERSION = '0.92_003';

sub _test__init {
    my $rh   = t::Utility::rh_instance(1);
    my $msft = $rh->search('microsoft');
    my $btc  = $rh->search('bitcoin');
    my $tag  = $rh->search('New on Robinhood');
    isa_ok($msft, __PACKAGE__);
    t::Utility::stash('MSFT', $msft);    #  Store it for later
    isa_ok($btc, __PACKAGE__);
    t::Utility::stash('BTC', $btc);      #  Store it for later
    isa_ok($tag, __PACKAGE__);
    t::Utility::stash('TAG', $tag);      #  Store it for later
}
#
use Moo;
use Time::Moment;
use Types::Standard qw[ArrayRef InstanceOf Maybe];
use experimental 'signatures';
#
use Finance::Robinhood::Equity::Collection;
use Finance::Robinhood::Currency::Pair;
use Finance::Robinhood::Equity;
#
has robinhood =>
    (is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood']);
#
around BUILDARGS => sub {
    my ($orig, $class, %args) = @_;
    $_->{robinhood} = $args{robinhood}
        for @{$args{currency_pairs}}, @{$args{instruments}}, @{$args{tags}};
    $class->$orig(%args);
};

=head2 C<currency_pairs( )>

If available, this will return a list of Finance::Robinhood::Forex::Pair
objects.

=cut

has currency_pairs => (
    is => 'rw',
    isa =>
        Maybe [ArrayRef [InstanceOf ['Finance::Robinhood::Currency::Pair']]],
    coerce => sub ( $pairs ) {
        [map { Finance::Robinhood::Currency::Pair->new(%$_) } @$pairs];
    },
    predicate => 'has_currency_pairs'
);

sub _test_currency_pairs {
    t::Utility::stash('BTC') // skip_all();
    my ($btc_usd) = t::Utility::stash('BTC')->currency_pairs;
    isa_ok($btc_usd, 'Finance::Robinhood::Forex::Pair');
}

=head2 C<equity_instruments( )>

If available, this will return a list of Finance::Robinhood::Equity objects.

=cut

has instruments => (
    is     => 'rw',
    isa    => Maybe [ArrayRef [InstanceOf ['Finance::Robinhood::Equity']]],
    coerce => sub ( $pairs ) {
        [map { Finance::Robinhood::Equity->new(%$_) } @$pairs]
    },
    predicate => 'has_instruments'
);

sub _test_equity_instruments {
    t::Utility::stash('MSFT') // skip_all();
    my ($instrument) = t::Utility::stash('MSFT')->equity_instruments;
    isa_ok($instrument, 'Finance::Robinhood::Equity');
}

=head2 C<tags( )>

If available, this will return a list of Finance::Robinhood::Equity::Tag
objects.


=cut

has tags => (
    is  => 'rw',
    isa => Maybe [ArrayRef [InstanceOf ['Finance::Robinhood::Equity::Tag']]],
    coerce => sub ( $pairs ) {
        [map { Finance::Robinhood::Equity::Tag->new(%$_) } @$pairs]
    },
    predicate => 'has_tags'
);

sub _test_tags {
    t::Utility::stash('TAG') // skip_all();
    my ($tag) = t::Utility::stash('TAG')->tags;
    isa_ok($tag, 'Finance::Robinhood::Equity::Tag');
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
