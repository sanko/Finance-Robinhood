package Finance::Robinhood::Forex::Watchlist;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Forex::Watchlist - Represents a Single Forex/Crypto
Watchlist

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;

    # TODO

=cut

our $VERSION = '0.92_002';
use Mojo::Base-base, -signatures;
use Mojo::URL;
use Time::Moment;

sub _test__init {
    my $rh        = t::Utility::rh_instance(1);
    my $watchlist = $rh->forex_watchlists->current;
    isa_ok( $watchlist, __PACKAGE__ );
    t::Utility::stash( 'WATCHLIST', $watchlist );    #  Store it for later
}
use overload '""' => sub ( $s, @ ) { $s->{id} }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('WATCHLIST') // skip_all();
    like(
        +t::Utility::stash('WATCHLIST'),
        qr'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'i
    );
}
#
has _rh => undef => weak => 1;

=head1 METHODS

=head2 C<created_at( )>

Returns a Time::Moment object.

=head2 C<id( )>

Returns a UUID.

=head2 C<name( )>



=head2 C<updated_at( )> 

Returns a Time::Moment object.

=cut

has [ 'id', 'name' ];

sub created_at ($s) {
    Time::Moment->from_string( $s->{created_at} );
}

sub _test_created_at {
    t::Utility::stash('WATCHLIST') // skip_all();
    isa_ok( t::Utility::stash('WATCHLIST')->created_at, 'Time::Moment' );
}

sub updated_at ($s) {
    Time::Moment->from_string( $s->{updated_at} );
}

sub _test_updated_at {
    t::Utility::stash('WATCHLIST') // skip_all();
    isa_ok( t::Utility::stash('WATCHLIST')->updated_at, 'Time::Moment' );
}

=head2 C<pair_ids( [...] )>

    $watchlist->pair_ids( )

Returns a list of UUIDs.

    $watchlist->pair_ids( 
        "76637d50-c702-4ed1-bcb5-5b0732a81f48",
        "3d961844-d360-45fc-989b-f6fca761d511" );

Updates the watchlist with a list of currency pairs.

=cut

sub pair_ids ( $s, @ids ) {
    return $s->{pair_ids} if !@ids;
    my $res = $s->_rh->_patch(
        'https://nummus.robinhood.com/watchlists/' . $s->{id} . '/',
        pair_ids => @ids
    );
    return $_[0] = Finance::Robinhood::Forex::Watchlist->new( _rh => $s->_rh, %{ $res->json } )
        if $res->is_success;
    Finance::Robinhood::Error->new(
        $res->is_server_error ? ( details => $res->message ) : $res->json );
}

sub _test_pair_ids {
    t::Utility::stash('WATCHLIST') // skip_all();
    my @ids = t::Utility::stash('WATCHLIST')->pair_ids;
    ok( t::Utility::stash('WATCHLIST')->pair_ids( reverse @ids ) );
    is( t::Utility::stash('WATCHLIST')->pair_ids(), reverse @ids );
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
