package Finance::Robinhood::Equity::Mover;
our $VERSION = '0.92_003';

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Equity::Mover - Represents a Top Moving Equity Instrument

=head1 SYNOPSIS

    use Text::Wrap qw[wrap];
    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;
    my $movers = $rh->top_movers(direction => 'up');

    for my $mover ($movers->all) {
        CORE::say $mover->instrument->name;
    }

=head1 METHODS

=cut

use Moo;
use MooX::Enumeration;
use Types::Standard qw[Bool Dict Enum InstanceOf Maybe Num Str StrMatch];
use URI;
use Time::Moment;
use Data::Dump;
use experimental 'signatures';
#
use Finance::Robinhood::Equity::PriceMovement;

sub _test__init {
    my $rh  = t::Utility::rh_instance(1);
    my $top = $rh->top_movers( direction => 'up' )->current;
    isa_ok( $top, __PACKAGE__ );
    t::Utility::stash( 'MOVER', $top );    #  Store it for later
}
use overload '""' => sub ( $s, @ ) { $s->instrument_url }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('MOVER') // skip_all();
    like(
        +t::Utility::stash('MOVER'),
        qr'https://api.robinhood.com/instruments/.+/',
    );
}
#
has robinhood => ( is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood'], );

=head2 C<description( )>

Returns a full text description suited for display.

=head2 C<symbol( )>

Returns the ticker symbol of the instrument.

=cut

has [qw[description symbol]] => ( is => 'ro', isa => Str, requried => 1 );

=head2 C<updated_at( )>

    $article->updated_at->to_string;

Returns the time the article was published or last updated as a Time::Moment
object.

=cut

has updated_at => (
    is       => 'ro',
    isa      => InstanceOf ['Time::Moment'],
    coerce   => sub ($date) { Time::Moment->from_string($date) },
    required => 1
);

sub _test_updated_at {
    t::Utility::stash('MOVER') // skip_all();
    isa_ok( t::Utility::stash('MOVER')->updated_at, 'Time::Moment' );
}

=head2 C<instrument( )>

    my $instrument = $mover->instrument();

Builds a Finance::Robinhood::Equity::Instrument object.

=cut

has instrument_url => (
    is       => 'ro',
    isa      => InstanceOf ['URI'],
    coerce   => sub ($url) { URI->new($url) },
    required => 1
);
has instrument => (
    is      => 'ro',
    isa     => InstanceOf ['Finance::Robinhood::Equity'],
    builder => 1,
    lazy    => 1
);

sub _build_instrument ($s) {
    ddx $s;
    $s->robinhood->_req(
        GET => $s->instrument_url,
        as  => 'Finance::Robinhood::Equity'
    );
}

sub _test_instrument {
    t::Utility::stash('MOVER') // skip_all();
    isa_ok(
        t::Utility::stash('MOVER')->instrument(),
        'Finance::Robinhood::Equity::Instrument'
    );
}

=head2 C<price_movement( )>

    my $price_movement = $mover->price_movement();

Returns a hash with the following keys:

=over

=item C<market_hours_last_movement_pct>

Returns a number of positive of negative percentage points.

=item C<market_hours_last_price>

Returns the actual price.

=back

=cut

has price_movement => (
    is  => 'ro',
    isa => Dict [
        market_hours_last_movement_pct => Num,
        market_hours_last_price        => Num
    ],
    required => 1
);

sub _test_price_movement {
    t::Utility::stash('MOVER') // skip_all();
    ref_ok(
        t::Utility::stash('MOVER')->price_movement,
        'HASH', 'price_movement is a hash'
    );
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
