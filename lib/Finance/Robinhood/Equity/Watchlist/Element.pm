package Finance::Robinhood::Equity::Watchlist::Element;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Equity::Watchlist - Represents a Single Robinhood Watchlist
Element

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new->login('user', 'pass');
    my $watchlist = $rh->watchlists->current();
    warn $watchlist->current->instrument->symbol;

    # TODO

=cut

our $VERSION = '0.92_002';

sub _test__init {
    my $rh      = t::Utility::rh_instance(1);
    my $element = $rh->equity_watchlist_by_name('Default')->current;
    isa_ok( $element, __PACKAGE__ );
    t::Utility::stash( 'ELEMENT', $element );    #  Store it for later
}
use Mojo::Base-base, -signatures;
use Mojo::URL;
use Time::Moment;
use overload '""' => sub ( $s, @ ) { $s->{url} }, fallback => 1;
use Finance::Robinhood::Equity::Instrument;

sub _test_stringify {
    t::Utility::stash('ELEMENT') // skip_all();
    like( +t::Utility::stash('ELEMENT'), qr'^https://api.robinhood.com/watchlists/Default/.+$' );
}
#
has _rh => undef => weak => 1;

=head1 METHODS

=head2 C<created_at( )>

    $element->created_at();

Returns a Time::Moment object representing the time this element was added to
the watchlist.

=cut

sub created_at ($s) {
    Time::Moment->from_string( $s->{created_at} );
}

sub _test_created_at {
    t::Utility::stash('ELEMENT') // skip_all();
    isa_ok( t::Utility::stash('ELEMENT')->created_at(), 'Time::Moment' );
}

=head2 C<delete( )>

    $element->delete();

Removes a instrument from the parent watchlist.

=cut

sub delete ($s) {
    my $res = $s->_rh->_delete( $s->{url} );
    return $res->is_success || Finance::Robinhood::Error->new( %{ $res->json } );
}

sub _test_delete {
    t::Utility::stash('ELEMENT') // skip_all();
    todo( "Add something and remove it and check watchlist" => sub { pass('ugh') } );

    # isa_ok( t::Utility::stash('ELEMENT')->instrument, 'Finance::Robinhood::Equity::Instrument' );
}

=head2 C<instrument( )>

    $element->instrument();

Returns a Finance::Robinhood::Equity::Instrument object.

=cut

sub instrument ($s) {
    my $res = $s->_rh->_get( $s->{instrument} );
    return $res->is_success
        ? Finance::Robinhood::Equity::Instrument->new( _rh => $s->_rh, %{ $res->json } )
        : Finance::Robinhood::Error->new( %{ $res->json } );
}

sub _test_instrument {
    t::Utility::stash('ELEMENT') // skip_all();
    isa_ok( t::Utility::stash('ELEMENT')->instrument, 'Finance::Robinhood::Equity::Instrument' );
}

=head2 C<id( )>

    $element->id();

Returns the UUID of the equity instrument.

=cut

sub id ($s) {
    $s->{instrument} =~ qr[/([0-9a-f]{8}(?:\-[0-9a-f]{4}){3}\-[0-9a-f]{12})/$]i;
    $1;
}

sub _test_id {
    t::Utility::stash('ELEMENT') // skip_all();
    like( t::Utility::stash('ELEMENT')->id, qr[^[0-9a-f]{8}(?:\-[0-9a-f]{4}){3}\-[0-9a-f]{12}$]i );
}

=head2 C<watchlist( )>

    $element->watchlist();

Returns a Finance::Robinhood::Equity::Instrument object.

=cut

sub watchlist ($s) {
    my $res = $s->_rh->_get( $s->{watchlist} );
    return $res->is_success
        ? Finance::Robinhood::Equity::Watchlist->new( _rh => $s->_rh, %{ $res->json } )
        : Finance::Robinhood::Error->new(
        $res->is_server_error ? ( details => $res->message ) : $res->json );
}

sub _test_watchlist {
    t::Utility::stash('ELEMENT') // skip_all();
    my $watchlist = t::Utility::stash('ELEMENT')->watchlist;
    isa_ok( $watchlist, 'Finance::Robinhood::Equity::Watchlist' );
    is( $watchlist->name, 'Default' );
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
