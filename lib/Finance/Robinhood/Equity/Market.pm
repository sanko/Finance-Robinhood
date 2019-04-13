package Finance::Robinhood::Equity::Market;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Equity::Market - Represents a Single Equity Market

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;
    my $msft = $rh->equity_instrument_by_symbol('MSFT');

    CORE::say $msft->symbol . ' is traded on ' . $msft->market->name;

=cut

our $VERSION = '0.92_001';
use Mojo::Base-base, -signatures;
use Mojo::URL;
use Time::Moment;
use Finance::Robinhood::Equity::Market::Hours;

sub _test__init {
    my $rh     = t::Utility::rh_instance(0);
    my $market = $rh->equity_market_by_mic('XNAS');    # NASDAQ
    isa_ok( $market, __PACKAGE__ );
    t::Utility::stash( 'MARKET', $market );            #  Store it for later
}
use overload '""' => sub ( $s, @ ) { $s->{url} }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('MARKET') // skip_all();
    is( +t::Utility::stash('MARKET'), 'https://api.robinhood.com/markets/XNAS/' );
}
#
has _rh => undef => weak => 1;

=head1 METHODS

=head2 C<acronym( )>

Simple acronym typically used to identify the exchange. Note that the same
acronym may be used for more than one venue.

=head2 C<city( )>

Location of the exchange/market.

=head2 C<country( )>

Location of the exchange/market.

=head2 C<mic( )>

Returns the ISO 10383 Market Identifier Code.

=head2 C<name( )>

Name of the exchange/market. Suited for display.

=head2 C<operating_mic( )>

Returns the ISO 20022 Operating Market Identifier Code.

=head2 C<timezone( )>

Timezone of the exchange/market.

=cut

has [ 'acronym', 'city', 'country', 'mic', 'name', 'operating_mic', 'timezone' ];

=head2 C<website()>

Website of the exchange in a Mojo::URL object.

=cut

sub website ($s) {
    Mojo::URL->new( $s->{website} );
}

sub _test_website {
    t::Utility::stash('MARKET') // skip_all();
    isa_ok( t::Utility::stash('MARKET')->website, 'Mojo::URL' );
    is( +t::Utility::stash('MARKET')->website, 'www.nasdaq.com' );
}

=head2 C<todays_hours( )>

    my $hours = $market->todays_hours( );

Return a Finance::Robinhood::Equity::Market::Hours object with today's data.

=cut

sub todays_hours ( $s ) {
    my $res = $s->_rh->_get( $s->{todays_hours} );
    $res->is_success
        ? Finance::Robinhood::Equity::Market::Hours->new( _rh => $s->_rh, %{ $res->json } )
        : Finance::Robinhood::Error->new(
        $res->is_server_error ? ( details => $res->message ) : $res->json );
}

sub _test_todays_hours {
    t::Utility::stash('MARKET') // skip_all();
    my $hours = t::Utility::stash('MARKET')->todays_hours();
    isa_ok( $hours, 'Finance::Robinhood::Equity::Market::Hours' );
    ok( $hours->date <= Time::Moment->now_utc );
}

=head2 C<hours( ... )>

    my $hours = $market->hours( $date );

Returns the Finance::Robinhood::Equity::Market::Hours object for the given
date. This method expects C<$date> to be a Time::Moment object.

=cut

sub hours ( $s, $date ) {
    my $res = $s->_rh->_get( $s->{url} . 'hours/' . $date->strftime('%Y-%m-%d') . '/' );
    $res->is_success
        ? Finance::Robinhood::Equity::Market::Hours->new( _rh => $s->_rh, %{ $res->json } )
        : Finance::Robinhood::Error->new(
        $res->is_server_error ? ( details => $res->message ) : $res->json );
}

sub _test_hours {
    t::Utility::stash('MARKET') // skip_all();
    my $hours = t::Utility::stash('MARKET')->hours( Time::Moment->now );
    isa_ok( $hours, 'Finance::Robinhood::Equity::Market::Hours' );
    is( $hours->date->strftime('%Y-%m-%d'), Time::Moment->now->strftime('%Y-%m-%d') );
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
