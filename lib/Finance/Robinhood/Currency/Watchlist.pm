package Finance::Robinhood::Currency::Watchlist;
our $VERSION = '0.92_003';

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Currency::Watchlist - Represents a Single Robinhood
Watchlist

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new(...);

    # TODO

=cut

sub _test__init {
    my $rh        = t::Utility::rh_instance(1);
    my $watchlist = $rh->currency_watchlists->current;
    isa_ok( $watchlist, __PACKAGE__ );
    t::Utility::stash( 'WATCHLIST', $watchlist );    #  Store it for later
}
use Moo;
use Types::Standard qw[ArrayRef Bool Dict Enum InstanceOf Maybe Num Str StrMatch];
use URI;
use Time::Moment;
use Data::Dump;
use experimental 'signatures';
use Time::Moment;
#
use Finance::Robinhood::Types qw[Timestamp UUID];
#
has robinhood => (
    is       => 'ro',
    required => 1,
    isa      => InstanceOf ['Finance::Robinhood'],
    required => 1
);

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

has name => ( is => 'ro', isa => Str, required => 1 );

=head2 C<currency_pair_ids( )>

Returns a list of UUIDs.

=cut

has currency_pair_ids => ( is => 'ro', isa => ArrayRef [UUID], required => 1 );

=head2 C<currency_pairs( )>

Returns a list of Finance::Robinhood::Currency::Pair objects.

=cut

has currency_pairs => (
    is       => 'ro',
    isa      => ArrayRef [ InstanceOf ['Finance::Robinhood::Currency::Pair'] ],
    lazy     => 1,
    builder  => 1,
    init_arg => undef
);

sub _build_currency_pairs($s) {
    my %pairs = map { $_->id => $_ } $s->robinhood->currency_pairs->all;
    [ map { $pairs{$_} } @{ $s->currency_pair_ids } ];
}

sub _test_currency_pairs {
    t::Utility::stash('WATCHLIST') // skip_all();
    isa_ok( $_, 'Finance::Robinhood::Currency::Pair' )
        for @{ t::Utility::stash('WATCHLIST')->currency_pairs };
    is( t::Utility::stash('WATCHLIST')->name, 'Default' );
}

=head2 C<id( )>

Returns a UUID.

=cut

has id => ( is => 'ro', isa => UUID, required => 1 );

=head2 C<created_at( )>

Returns a Time::Moment object.

=head2 C<updated_at( )>

Returns a Time::Moment object.

=cut

has [qw[created_at updated_at]] => ( is => 'ro', isa => Timestamp, coerce => 1, required => 1 );

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
