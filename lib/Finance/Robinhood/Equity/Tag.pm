package Finance::Robinhood::Equity::Tag;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Tag - Represents a Single Categorized List of Equity
Instruments

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh  = Finance::Robinhood->new;
    my $oil = $rh->tags('oil')->next;

    CORE::say sprintf '%d members of the tag named %s', $oil->membership_count, $oil->name;
    CORE::say join ', ', map { $_->symbol } $oil->instruments;

=head1 METHODS

=cut

our $VERSION = '0.92_002';

use Mojo::Base-base, -signatures;
use Mojo::URL;
use Time::Moment;
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
    like(
        +t::Utility::stash('TAG'),
        'food',
    );
}
#
has _rh => undef => weak => 1;

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

has [ 'canonical_examples', 'description', 'membership_count', 'name', 'slug' ];

=head2 C<instruments( )>

    my $instruments = $mover->instruments();

Returns a list of Finance::Robinhood::Equity::Instrument objects.

=cut

sub instruments ($s) {
    $s->_rh->equity_instruments_by_id(
        map {m/([0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12})\/$/i}
            @{ $s->{instruments} } );

}

sub _test_instruments {
    t::Utility::stash('TAG') // skip_all();
    my @instruments = t::Utility::stash('TAG')->instruments();
    isa_ok( $instruments[0], 'Finance::Robinhood::Equity::Instrument' );
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
