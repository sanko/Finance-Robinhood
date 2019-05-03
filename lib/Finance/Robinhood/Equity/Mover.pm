package Finance::Robinhood::Equity::Mover;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Equity::Mover - Represents a Top Moving Equity Instrument

=head1 SYNOPSIS

    use Text::Wrap qw[wrap];
    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;
    my $movers = $rh->top_movers(direction => 'up');

    for my $mover ($movers->all) {
        CORE::say $mover->instrument->name;
    }

=head1 METHODS

=cut

our $VERSION = '0.92_002';
use Mojo::Base-base, -signatures;
use Mojo::URL;
use Time::Moment;
use Finance::Robinhood::Equity::PriceMovement;

sub _test__init {
    my $rh  = t::Utility::rh_instance(1);
    my $top = $rh->top_movers(direction => 'up')->current;
    isa_ok($top, __PACKAGE__);
    t::Utility::stash('MOVER', $top);    #  Store it for later
}
use overload '""' => sub ($s, @) { $s->{instrument_url} }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('MOVER') // skip_all();
    like(+t::Utility::stash('MOVER'),
         qr'https://api.robinhood.com/instruments/.+/',);
}
#
has _rh => undef => weak => 1;

=head2 C<description( )>

Returns a full text description suited for display.

=head2 C<symbol( )>

Returns the ticker symbol of the instrument.

=cut

has ['description', 'symbol'];

=head2 C<updated_at( )>

    $article->updated_at->to_string;

Returns the time the article was published or last updated as a Time::Moment
object.

=cut

sub updated_at($s) {
    Time::Moment->from_string($s->{updated_at});
}

sub _test_updated_at {
    t::Utility::stash('MOVER') // skip_all();
    isa_ok(t::Utility::stash('MOVER')->updated_at, 'Time::Moment');
}

=head2 C<instrument( )>

    my $instrument = $mover->instrument();

Builds a Finance::Robinhood::Equity::Instrument object.

=cut

sub instrument ($s) {
    my $res = $s->_rh->_get($s->{instrument_url});
    $res->is_success
        ? Finance::Robinhood::Equity::Instrument->new(_rh => $s->_rh,
                                                      %{$res->json})
        : Finance::Robinhood::Error->new(
             $res->is_server_error ? (details => $res->message) : $res->json);
}

sub _test_instrument {
    t::Utility::stash('MOVER') // skip_all();
    isa_ok(t::Utility::stash('MOVER')->instrument(),
           'Finance::Robinhood::Equity::Instrument');
}

=head2 C<price_movement( )>

    my $price_movement = $mover->price_movement();

Builds a Finance::Robinhood::Equity::PriceMovement object.

=cut

sub price_movement ($s) {
    Finance::Robinhood::Equity::PriceMovement->new(_rh => $s->_rh,
                                                   %{$s->{price_movement}});
}

sub _test_price_movement {
    t::Utility::stash('MOVER') // skip_all();
    isa_ok(t::Utility::stash('MOVER')->price_movement(),
           'Finance::Robinhood::Equity::PriceMovement');
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
