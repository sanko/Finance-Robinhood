package Finance::Robinhood::Options::Chain;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Options::Chain - Represents a Single Options Chain

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new->login('user', 'pass');
 
    # TODO

=head1 METHODS

=cut

our $VERSION = '0.92_002';
use Mojo::Base-base, -signatures;
use Mojo::URL;
use Time::Moment;
use Finance::Robinhood::Options::Chain::Ticks;
use Finance::Robinhood::Options::Chain::Underlying;

sub _test__init {
    my $rh = t::Utility::rh_instance(0);

    my $chains = $rh->options_chains;
    my $chain;
    while ( $chains->has_next ) {
        my @dates = $chains->next->expiration_dates;
        if (@dates) {
            $chain = $chains->current;
            last;
        }
    }

    isa_ok( $chain, __PACKAGE__ );
    t::Utility::stash( 'CHAIN', $chain );    #  Store it for later
}
use overload '""' => sub ( $s, @ ) { 'https://api.robinhood.com/options/chains/' . $s->{id} . '/' },
    fallback      => 1;

sub _test_stringify {
    t::Utility::stash('CHAIN') // skip_all();
    like(
        +t::Utility::stash('CHAIN'),
        qr'^https://api.robinhood.com/options/chains/[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}/$'i
    );
}

has _rh => undef => weak => 1;

=head2 C<can_open_position( )>

Returns a boolean value. True if you may open a new position.

=head2 C<cash_compenent( )>

If defined, a dollar amount.

=head2 C<id( )>

Returns a UUID.

=head2 C<symbol( )>

Chain's ticker symbol.

=head2 C<trade_value_multiplier( )>



=cut

has [ 'can_open_position', 'cash_component', 'id', 'symbol', 'trade_value_multiplier' ];

=head2 C<expiration_dates( )>

Returns a list of Time::Moment objects.

=cut

sub expiration_dates($s) {
    map { Time::Moment->from_string( $_ . 'T00:00:00Z' ) } @{ $s->{expiration_dates} };
}

sub _test_expiration_dates {
    t::Utility::stash('CHAIN') // skip_all();
    my ($date) = t::Utility::stash('CHAIN')->expiration_dates;
    isa_ok( $date, 'Time::Moment' );
}

=head2 C<underlying_instruments( )>

Returns a list of Finance::Robinhood::Options::Chain::Underlying objects.

=cut

sub underlying_instruments($s) {
    map { Finance::Robinhood::Options::Chain::Underlying->new( _rh => $s->_rh, %$_ ) }
        @{ $s->{underlying_instruments} };
}

sub _test_underlying_instruments {
    t::Utility::stash('CHAIN') // skip_all();
    my ($underlying) = t::Utility::stash('CHAIN')->underlying_instruments;
    isa_ok(
        $underlying,
        'Finance::Robinhood::Options::Chain::Underlying'
    );
}

=head2 C<min_ticks( )>

Returns a Finance::Robinhood::Options::Chain::Ticks object.

=cut

sub min_ticks ($s) {
    Finance::Robinhood::Options::Chain::Ticks->new( _rh => $s->_rh, %{ $s->{min_ticks} } );
}

sub _test_min_ticks {
    t::Utility::stash('CHAIN') // skip_all();
    isa_ok( t::Utility::stash('CHAIN')->min_ticks, 'Finance::Robinhood::Options::Chain::Ticks' );
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
