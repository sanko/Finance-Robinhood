package Finance::Robinhood::Equity::Ratings;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Equity::Ratings - Morningstar ratings for equity
instruments Watchlist

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;

    my $msft = $rh->equity_instrument_by_id('50810c35-d215-4866-9758-0ada4ac79ffa');
    my $ratings = $msft->ratings;

    # TODO

=cut

our $VERSION = '0.92_002';
use Mojo::Base-base, -signatures;
use Mojo::URL;

sub _test__init {
    my $rh = t::Utility::rh_instance(1);
    my $msft = $rh->equity_instrument_by_id(
                               '50810c35-d215-4866-9758-0ada4ac79ffa'); # MSFT
    my $ratings = $msft->ratings;
    isa_ok($ratings, __PACKAGE__);
    t::Utility::stash('RATINGS', $ratings);    #  Store it for later
}
use overload '""' => sub ($s, @) { $s->{instrument_id} }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('RATINGS') // skip_all();
    like(+t::Utility::stash('RATINGS'),
         qr'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'i
    );
}
#
has _rh => undef => weak => 1;

=head1 METHODS

=head2 C<buy( )>

Returns a list of buy ratings.

=cut

sub buy ($s) {
    map { $_->{text} } grep { $_->{type} eq 'buy' } @{$s->{ratings}};
}
sub _test_buy { skip_all() }

=head2 C<sell( )>

Returns a list of sell ratings.

=cut

sub sell ($s) {
    map { $_->{text} } grep { $_->{type} eq 'sell' } @{$s->{ratings}};
}
sub _test_sell { skip_all() }

=head2 C<hold( )>

Returns a list of hold ratings.

=cut

sub hold ($s) {
    map { $_->{text} } grep { $_->{type} eq 'hold' } @{$s->{ratings}};
}
sub _test_hold { skip_all() }

=head2 C<all( )>

Returns a hash reference with the following keys: C<buy>, C<sell>, C<hold>. The
values are ratings.

=cut

sub all ($s) {
    {buy => [$s->buy], hold => [$s->hold], sell => [$s->sell]}
}

sub _test_all {

    #t::Utility::stash('RATINGS') //
    skip_all();
}

=head2 C<totals( )>

Returns a hash reference with the following keys: C<buy>, C<sell>, C<hold>. The
values are numbers.

=cut

sub totals ($s) {
    {buy  => $s->{summary}{num_buy_ratings},
     hold => $s->{summary}{num_hold_ratings},
     sell => $s->{summary}{num_sell_ratings}
    }
}

sub _test_totals {

    #t::Utility::stash('RATINGS') //
    skip_all();

    #my $instrument = t::Utility::stash('RATINGS')->instrument;
    #isa_ok( $instrument, 'Finance::Robinhood::Instrument' );
}

=head2 C<instrument( )>

    my $instrument = $ratings->instrument;

Returns an iterator containing Finance::Robinhood::News elements.

=cut

sub instrument ($s) { $s->_rh->equity_instrument_by_id($s->{instrument_id}) }

sub _test_instrument {
    t::Utility::stash('RATINGS') // skip_all();
    my $instrument = t::Utility::stash('RATINGS')->instrument;
    isa_ok($instrument, 'Finance::Robinhood::Equity::Instrument');
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
