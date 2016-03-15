package Finance::Robinhood::Watchlist;
use 5.008001;
use strict;
use warnings;
use Carp;
our $VERSION = "0.01";
use Data::Dump qw[ddx];
use Moo;
use JSON::Tiny qw[decode_json];
use strictures 2;
use namespace::clean;
#
has $_ => (is => 'ro', required => 1, writer => "_set_$_")
    for ( qw[name] );
has $_ => (is => 'ro', writer => "_set_$_")
    for ( qw[instruments] );
1;

=encoding utf-8

=head1 NAME

Finance::Robinhood::Watchlist - Persistant List of Financial Instruments

=head1 SYNOPSIS

    use Finance::Robinhood::Instrument;

    #...

    my $watchlist = $rh->create_watchlist( 'Tech' );

    $watchlist->add_instrument( $rh->instrument('APPL') );

=head1 DESCRIPTION

Robinhood allows persistant, categorized lists of financial instruments in
'watchlists'. The 'Default' watchlist is created by the official Robinhood
apps and are preloaded with popular securities.

If you intend to create your own, please use
C<Finance::Robinhood->create_watchlist( ... )>.

=head1 METHODS

Watchlists are rather simple in themselves.

=head2 C<delete( ... )>

This deletes the watchlist from Robinhood.

=head2 C<delete_instrument( ... )>

Removes a financial instrument from the watchlist.

=head2 C<add_instrument( ... )>

Adds a financial instrument to the watchlist. Attempts to add an instrument a
second time will fail.

=head2 C<populate( ... )>

    $watchlist->populate(qw[APPL MSFT FB]);

Add multiple instruments in a single API call and by their symbols with this.

...easier than looping through the symbols yourself, right?

=head2 C<reorder( ... )>

TODO

=head1 LEGAL

This is a simple wrapper around the API used in the official apps. The author
provides no investment, legal, or tax advice and is not responsible for any
damages incured while using this software. Neither this software nor its
author are affiliated with Robinhood Financial LLC in any way.

For Robinhood's terms and disclosures, please see their website at http://robinhood.com/

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Other copyrights, terms, and conditions may apply to data transmitted through
this module. Please refer to the L<LEGAL> section.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut
