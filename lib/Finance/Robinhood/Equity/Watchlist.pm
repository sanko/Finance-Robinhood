package Finance::Robinhood::Equity::Watchlist;
our $VERSION = '0.92_003';

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Equity::Watchlist - Represents a Single Robinhood Watchlist

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new->login('user', 'pass');
    my $watchlist = $rh->watchlist_by_name('Default');

    # TODO

=cut

sub _test__init {
    my $rh        = t::Utility::rh_instance(1);
    my $watchlist = $rh->equity_watchlist_by_name('Default');
    isa_ok( $watchlist, __PACKAGE__ );
    t::Utility::stash( 'WATCHLIST', $watchlist );    #  Store it for later
}
use Moo;
extends 'Finance::Robinhood::Utilities::Iterator';
use MooX::Enumeration;
use Types::Standard qw[Bool Enum InstanceOf Maybe Num Str StrMatch];
use URI;
use Time::Moment;
use Data::Dump;
use experimental 'signatures';
use Time::Moment;
use Finance::Robinhood::Equity::Watchlist::Element;

sub _test_stringify {
    t::Utility::stash('WATCHLIST') // skip_all();
    is( +t::Utility::stash('WATCHLIST'), 'https://api.robinhood.com/watchlists/Default/' );
}
has robinhood => ( is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood'], );

=head1 METHODS

This is a subclass of Finance::Robinhood::Utilities::Iterator. All the sweet,
sugary goodness from there works here. Note that C<next( )>, C<current( )>,
etc. return  Finance::Robinhood::Equity::Watchlist::Element objects.

=cut

# Inherits robinhood from Iterator

=head2 C<name( )>

	warn $watchlist->name;

Returns the name given to this watchlist.

=cut

has name => ( is => 'ro', isa => Str, lazy => 1, builder => 1 );

sub _build_name($s) {
    $s->current->watchlist =~ m[.+\/(\w+)\/$];
    $1;
}

sub _test_name {
    t::Utility::stash('WATCHLIST') // skip_all();
    is( t::Utility::stash('WATCHLIST')->name, 'Default' );
}

# Private
has url => (
    is      => 'ro',
    isa     => InstanceOf ['URI'],
    builder => 1,
    lazy    => 1,
    coerce  => sub ($url) { URI->new($url) }
);

sub _build_url ($s) {
    sprintf 'https://api.robinhood.com/watchlists/%s/', $s->name;
}

sub _test_url {
    t::Utility::stash('WATCHLIST') // skip_all();
    is( t::Utility::stash('WATCHLIST')->url, 'https://api.robinhood.com/watchlists/Default/' );
}

# Override methods from Iterator
#has '+class' => ( default => 'Finance::Robinhood::Equity::Watchlist::Element');
#has '+_next_page' => ()
#has _next_page => sub ($s) { $s->{url} };
sub _test_current {
    t::Utility::stash('WATCHLIST') // skip_all();
    t::Utility::stash('WATCHLIST')->reset;
    isa_ok(
        t::Utility::stash('WATCHLIST')->current,
        'Finance::Robinhood::Equity::Watchlist::Element'
    );
}

sub _test_next {
    t::Utility::stash('WATCHLIST') // skip_all();
    t::Utility::stash('WATCHLIST')->reset;
    isa_ok(
        t::Utility::stash('WATCHLIST')->next,
        'Finance::Robinhood::Equity::Watchlist::Element'
    );
}

=head2 C<populate( ... )>

    $watchlist->populate('MSFT', 'QQQ', 'BA');

Adds a list of equity instruments in bulk by their ticker symbol and returns a
boolean.

=cut

sub populate ( $s, @symbols ) {

    # Split symbols into groups of 32 to keep URL length down
    my $res;
    while (@symbols) {
        $res = $s->robinhood->_req(
            POST => $s->url . 'bulk_add/',
            json => { symbols => [ splice @symbols, 0, 32 ] }
        );
        return Finance::Robinhood::Error->new( $res->json ) if !$res->{success};
    }
    return $res->{success}
        || Finance::Robinhood::Error->new(
        $res->status >= 300 ? ( details => $res->{reason} ) : $res->json );
}

sub _test_populate {
    t::Utility::stash('WATCHLIST') // skip_all();
    t::Utility::stash('WATCHLIST')->reset;
    ok( t::Utility::stash('WATCHLIST')->populate('MSFT'), 'adding MSFT' );
    todo( "Test that the instrument was added by checking watchlist size" => sub { pass('ugh') } );
}

=head2 C<add_instrument( ... )>

    $watchlist->add_instrument($msft);

Adds an equity instrument. If successful, a
Finance::Robinhood::Equity::Watchlist::Element object is returned.

=cut

sub add_instrument ( $s, $instrument ) {
    $s->robinhood->_req(
        POST => $s->url,
        form => { instrument => $instrument },
        as   => 'Finance::Robinhood::Equity::Watchlist::Element'
    );
}

sub _test_add_instrument {
    t::Utility::stash('WATCHLIST') // skip_all();
    t::Utility::stash('WATCHLIST')->reset;
    my $result = t::Utility::stash('WATCHLIST')
        ->add_instrument( t::Utility::stash('WATCHLIST')->_rh->equity('MSFT') );
    isa_ok(
        $result,
        $result ? 'Finance::Robinhood::Equity::Watchlist::Element' : 'Finance::Robinhood::Error'
    );
}

=head2 C<equities( )>

    my @instruments = $watchlist->equities();

This method makes a call to grab data for every equity instrument on the
watchlist and returns them as a list.

=cut

sub equities ($s) {
    $s->robinhood->equities_by_id( map { $_->id } $s->all );
}

sub _test_instruments {
    t::Utility::stash('WATCHLIST') // skip_all();
    t::Utility::stash('WATCHLIST')->reset;
    my @instruments = t::Utility::stash('WATCHLIST')->instruments;
    isa_ok( $_, 'Finance::Robinhood::Equity::Instrument' ) for @instruments;
}

=head2 C<ids( )>

    my @ids = $watchlist->ids();

Returns the instrument id for all equity instruments as a list.

=cut

sub ids ($s) {
    map { $_->id } $s->all;
}

sub _test_ids {
    t::Utility::stash('WATCHLIST') // skip_all();
    t::Utility::stash('WATCHLIST')->reset;
    my @ids = t::Utility::stash('WATCHLIST')->ids;
    like( $_, qr[^[0-9a-f]{8}(?:\-[0-9a-f]{4}){3}\-[0-9a-f]{12}$]i, $_ ) for @ids;
}

=head2 C<reorder( ... )>

    $watchlist->reorder( @ids );

This method moves items of the watchlist around.

=cut

sub reorder ( $s, @ids ) {
    my $res
        = $s->robinhood->_req( POST => $s->url . 'reorder/', form => { uuids => join ',', @ids } );
    return $res->success || Finance::Robinhood::Error->new( %{ $res->json } );
}

sub _test_reorder {
    t::Utility::stash('WATCHLIST') // skip_all();
    t::Utility::stash('WATCHLIST')->reset;
    my @ids = t::Utility::stash('WATCHLIST')->ids;
    ok( t::Utility::stash('WATCHLIST')->reorder( reverse @ids ), 'reorder(...)' );
    t::Utility::stash('WATCHLIST')->reset;
    my @reordered = t::Utility::stash('WATCHLIST')->ids;
    is( [ reverse @ids ], \@reordered );
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
