package Finance::Robinhood::Equity::PriceMovement;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Equity::PriceMovement - Represents How Much a Top Moving
Equity Instrument has Moved

=head1 SYNOPSIS

    use Text::Wrap qw[wrap];
    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;
    my $movers = $rh->top_movers(direction => 'up');

    for my $mover ($movers->all) {
        CORE::say $mover->instrument->name . ' has increased by ' . $mover->price_movement->market_hours_last_movement_pct . '%' ;
    }

=head1 METHODS

=cut

our $VERSION = '0.92_001';

use Mojo::Base-base, -signatures;
use Mojo::URL;

sub _test__init {
    my $rh  = t::Utility::rh_instance(1);
    my $top = $rh->top_movers( direction => 'up' )->current->price_movement;
    isa_ok( $top, __PACKAGE__ );
    t::Utility::stash( 'MOVEMENT', $top );    #  Store it for later
}

use overload '""' => sub ( $s, @ ) { $s->{market_hours_last_movement_pct} }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('MOVEMENT') // skip_all();
    like(
        +t::Utility::stash('MOVEMENT'),
        qr[^\-?\d+\.\d+$],
    );
}
#
has _rh => undef => weak => 1;

=head2 C<market_hours_last_movement_pct( )>

Returns a number of positive of negative percentage points.

=head2 C<market_hours_last_price( )>

Returns the actual price.

=cut

has [
    'market_hours_last_movement_pct',
    'market_hours_last_price'
];

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
