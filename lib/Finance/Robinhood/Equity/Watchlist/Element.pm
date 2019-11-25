package Finance::Robinhood::Equity::Watchlist::Element;
our $VERSION = '0.92_003';

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Equity::Watchlist - Represents a Single Robinhood Watchlist
Element

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new( ... );
    my $watchlist = $rh->equity_watchlist;
    warn $watchlist->current->instrument->symbol;

    # TODO

=cut

sub _test__init {
    my $rh      = t::Utility::rh_instance(1);
    my $element = $rh->equity_watchlist_by_name('Default')->current;
    isa_ok($element, __PACKAGE__);
    t::Utility::stash('ELEMENT', $element);    #  Store it for later
}
use Moo;
use MooX::Enumeration;
use Types::Standard qw[Bool Enum InstanceOf Maybe Num Str StrMatch];
use URI;
use Time::Moment;
use Data::Dump;
use experimental 'signatures';
use Time::Moment;
use overload '""' => sub ($s, @) { $s->_url }, fallback => 1;
#
use Finance::Robinhood::Equity;

sub _test_stringify {
    t::Utility::stash('ELEMENT') // skip_all();
    like(+t::Utility::stash('ELEMENT'),
         qr'^https://api.robinhood.com/watchlists/Default/.+$');
}
#

=head1 METHODS


=cut

has robinhood =>
    (is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood']);
has '_'
    .
    $_ => (is       => 'ro',
           isa      => InstanceOf ['URI'],
           coerce   => sub ($url) { URI->new($url) },
           init_arg => $_,
           required => 1
    ) for qw[url instrument watchlist];

=head2 C<created_at( )>

    $element->created_at();

Returns a Time::Moment object representing the time this element was added to
the watchlist.

=cut

has created_at => (is     => 'ro',
                   isa    => InstanceOf ['Time::Moment'],
                   coerce => sub ($date) { Time::Moment->from_string($date) },
                   required => 1
);

sub _test_created_at {
    t::Utility::stash('ELEMENT') // skip_all();
    isa_ok(t::Utility::stash('ELEMENT')->created_at(), 'Time::Moment');
}

=head2 C<delete( )>

    $element->delete();

Removes a instrument from the parent watchlist.

=cut

sub delete ($s) {
    my $res = $s->robinhood->_req(DELETE => $s->url);
    return $res->{success} || Finance::Robinhood::Error->new(%{$res->json});
}

sub _test_delete {
    t::Utility::stash('ELEMENT') // skip_all();
    todo("Add something and remove it and check watchlist" =>
         sub { pass('ugh') });

# isa_ok( t::Utility::stash('ELEMENT')->instrument, 'Finance::Robinhood::Equity::Instrument' );
}

=head2 C<instrument( )>

    $element->instrument();

Returns a Finance::Robinhood::Equity object.

=cut

sub instrument ($s) {
    $s->robinhood->_req(GET => $s->_instrument,
                        as  => 'Finance::Robinhood::Equity');
}

sub _test_instrument {
    t::Utility::stash('ELEMENT') // skip_all();
    isa_ok(t::Utility::stash('ELEMENT')->instrument,
           'Finance::Robinhood::Equity');
}

=head2 C<id( )>

    $element->id();

Returns the UUID of the equity instrument.

=cut

has id => (
    is  => 'ro',
    isa => StrMatch [
        qr[^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$]i
    ],
    lazy    => 1,
    builder => 1
);

sub _build_id ($s) {
    warn $s->_instrument;
    $s->_instrument =~ m[/([0-9a-f]{8}(?:\-[0-9a-f]{4}){3}\-[0-9a-f]{12})/$]i;
    warn $1;
    $1;
}

sub _test_id {
    t::Utility::stash('ELEMENT') // skip_all();
    like(t::Utility::stash('ELEMENT')->id,
         qr[^[0-9a-f]{8}(?:\-[0-9a-f]{4}){3}\-[0-9a-f]{12}$]i);
}

=head2 C<watchlist( )>

    $element->watchlist();

Returns a Finance::Robinhood::Equity::Watchlist object.

=cut

sub watchlist ($s) {
    $s->robinhood->_req(GET => $s->_watchlist,
                        as  => 'Finance::Robinhood::Equity::Watchlist');
}

sub _test_watchlist {
    t::Utility::stash('ELEMENT') // skip_all();
    my $watchlist = t::Utility::stash('ELEMENT')->watchlist;
    isa_ok($watchlist, 'Finance::Robinhood::Equity::Watchlist');
    is($watchlist->name, 'Default');
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
