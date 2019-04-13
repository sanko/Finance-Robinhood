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

our $VERSION = '0.92_002';

sub _test__init {
    my $rh   = t::Utility::rh_instance(1);
    my $msft = $rh->search('microsoft');
    my $btc  = $rh->search('bitcoin');
    my $tag  = $rh->search('New on Robinhood');

    isa_ok( $msft, __PACKAGE__ );
    t::Utility::stash( 'MSFT', $msft );    #  Store it for later

    isa_ok( $btc, __PACKAGE__ );
    t::Utility::stash( 'BTC', $btc );      #  Store it for later

    isa_ok( $tag, __PACKAGE__ );
    t::Utility::stash( 'TAG', $tag );      #  Store it for later
}
use Mojo::Base-base, -signatures;
use Mojo::URL;

use Finance::Robinhood::Equity::Tag;
use Finance::Robinhood::Forex::Pair;
use Finance::Robinhood::Equity::Instrument;
#
has _rh => undef => weak => 1;

=head2 C<forex_pairs( )>

If available, this will return a list of Finance::Robinhood::Forex::Pair
objects.

=cut

sub forex_pairs ( $s ) {
    map { Finance::Robinhood::Forex::Pair->new( _rh => $s->_rh, %$_ ) } @{ $s->{currency_pairs} };
}

sub _test_forex_pairs {
    t::Utility::stash('BTC') // skip_all();
    my ($btc_usd) = t::Utility::stash('BTC')->forex_pairs;
    isa_ok( $btc_usd, 'Finance::Robinhood::Forex::Pair' );
}

=head2 C<equity_instruments( )>

If available, this will return a list of Finance::Robinhood::Equity::Instrument
objects.

=cut

sub equity_instruments ( $s ) {
    map { Finance::Robinhood::Equity::Instrument->new( _rh => $s->_rh, %$_ ) }
        @{ $s->{instruments} };
}

sub _test_equity_instruments {
    t::Utility::stash('MSFT') // skip_all();
    my ($instrument) = t::Utility::stash('MSFT')->equity_instruments;
    isa_ok(
        $instrument,
        'Finance::Robinhood::Equity::Instrument'
    );
}

=head2 C<tags( )>

If available, this will return a list of Finance::Robinhood::Equity::Tag
objects.


=cut

sub tags ( $s ) {
    map { Finance::Robinhood::Equity::Tag->new( _rh => $s->_rh, %$_ ) } @{ $s->{tags} };
}

sub _test_tags {
    t::Utility::stash('TAG') // skip_all();
    my ($tag) = t::Utility::stash('TAG')->tags;
    isa_ok( $tag, 'Finance::Robinhood::Equity::Tag' );
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
