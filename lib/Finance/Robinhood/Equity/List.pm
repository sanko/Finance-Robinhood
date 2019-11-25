package Finance::Robinhood::Equity::List;
our $VERSION = '0.92_003';

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Equity::List - Represents a User-curated List of Equity
Instruments

=head1 SYNOPSIS

    use Finance::Robinhood;

	# TODO

=head1 METHODS

The curated list feature is under development.

=cut

use Moo;
use MooX::Enumeration;
use Types::Standard qw[ArrayRef Bool HashRef Dict Enum InstanceOf Maybe Num Str StrMatch];
use URI;
use Time::Moment;
use Data::Dump;
use experimental 'signatures';
#
use Finance::Robinhood::Types qw[URL UUID];
#
sub _test__init {
    my $rh  = t::Utility::rh_instance(1);
    my $tag = $rh->search('software')->{lists}->[0];
    isa_ok( $tag, __PACKAGE__ );
    t::Utility::stash( 'LIST', $tag );    #  Store it for later
}
use overload '""' => sub ( $s, @ ) { $s->display_name }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('LIST') // skip_all();
    like( +t::Utility::stash('LIST'), 'Software' );
}
#
has robinhood => ( is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood'] );

=head2 C<display_description( )>

If available, this returns a full text description suited for display.

=head2 C<item_count( )>

Returns the number of instruments contained in this list.

=head2 C<display_name( )>

Returns the name of this list in a format suited for display.

=head2 C<id( )>

Internal UUID of the list.

=head2 C<image_urls( )>

If available, this returns a hash reference full of URLs. These are icons
suited for display. The keys sare 'shape' and rough dimentions. For example
C<circle_64:3> and C<header_mob:1>

=head2 C<owner_type( )>

Returns the owner of the list.

=head2 C<read_permission( )>

Returns one of the following: C<in_app>

=cut

has [qw[display_description display_name]] => ( is => 'ro', isa => Str, required => 1 );
has item_count                             => ( is => 'ro', isa => Num, required => 1 );
has image_urls => ( is => 'ro', isa => HashRef [URL], required => 1, coerce => 1 );
has id         => ( is => 'ro', isa => UUID,          required => 1 );
has owner_type      => ( is => 'ro', isa => Enum [qw[robinhood]], required => 1 );
has read_permission => ( is => 'ro', isa => Enum [qw[in_app]],    required => 1 );

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
