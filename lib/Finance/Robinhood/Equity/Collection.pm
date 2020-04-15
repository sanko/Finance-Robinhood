package Finance::Robinhood::Equity::Collection;
our $VERSION = '0.92_003';

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Equity::Collection - Represents a Single Categorized List
of Equity Instruments

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $oil  = Finance::Robinhood->new->tags('oil');
    CORE::say sprintf '%d members of the tag named %s', $oil->membership_count, $oil->name;
    CORE::say join ', ', map { $_->symbol } $oil->instruments;

=head1 METHODS

=cut

use Moo;
use MooX::Enumeration;
use Types::Standard qw[ArrayRef Bool Dict Enum InstanceOf Maybe Num Str StrMatch];
use URI;
use Time::Moment;
use Data::Dump;
use experimental 'signatures';
#
use Finance::Robinhood::Equity::PriceMovement;

sub _test__init {
    my $rh  = t::Utility::rh_instance(1);
    my $tag = $rh->tags('food')->current;
    isa_ok( $tag, __PACKAGE__ );
    t::Utility::stash( 'TAG', $tag );    #  Store it for later
}
use overload '""' => sub ( $s, @ ) { $s->{slug} }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('TAG') // skip_all();
    like( +t::Utility::stash('TAG'), 'food', );
}
#
has robinhood => ( is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood'] );

=head2 C<canonical_examples( )>

If available, this returns a short blurb about what sort of instruments are
contained in this tag.

=head2 C<description( )>

If available, this returns a full text description suited for display.

=head2 C<membership_count( )>

Returns the number of instruments are contained in this tag.

=head2 C<name( )>

Returns the name of this tag in a format suited for display

=head2 C<slug( )>

Returns the internal string used to locate this tag.

=cut

has [qw[canonical_examples description name slug]] => ( is => 'ro', isa => Str, required => 1 );
has membership_count                               => ( is => 'ro', isa => Num, required => 1 );

=head2 C<instruments( )>

    my $instruments = $mover->instruments();

Returns a list of Finance::Robinhood::Equity objects.

=cut

has _instruments => (
    is     => 'ro',
    isa    => ArrayRef [ InstanceOf ['URI'] ],
    coerce => sub ($urls) {
        [ map { URI->new($_) } @{$urls} ]
    },
    required => 1,
    init_arg => 'instruments'
);
has instruments => (
    is       => 'ro',
    isa      => ArrayRef [ InstanceOf ['Finance::Robinhood::Equity'] ],
    builder  => 1,
    lazy     => 1,
    init_arg => undef
);

sub _build_instruments ($s) {
    [
        $s->robinhood->equities_by_id(
            map {m/([0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12})\/$/i}
                @{ $s->_instruments }
        )
    ];
}

sub _test_instruments {
    t::Utility::stash('TAG') // skip_all();
    my @instruments = t::Utility::stash('TAG')->instruments();
    isa_ok( $instruments[0], 'Finance::Robinhood::Equity' );
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
