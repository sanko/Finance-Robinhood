package Finance::Robinhood::Currency::Position;
our $VERSION = '0.92_003';

=encoding utf-8

=for stopwords watchlist watchlists untradable urls btw

=head1 NAME

Finance::Robinhood::Currency::Position - Represents a Single Cryptocurrency
Position

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;
    # TODO

=head1 METHODS

=cut

use Moo;
use Data::Dump;
use HTTP::Tiny;
use JSON::Tiny;
use Time::Moment;
use Types::Standard qw[ArrayRef Bool Dict Enum InstanceOf Maybe Num Str StrMatch];
use URI;
use experimental 'signatures';
#
use Finance::Robinhood::Types qw[URL UUID UUIDBroken Timestamp];
#
sub _test__init {
    my $rh        = t::Utility::rh_instance(1);
    my $positions = $rh->currency_positions;
    isa_ok( $positions->current, __PACKAGE__ );
    t::Utility::stash( 'POSITIONS', $positions->current );    #  Store it for later
}
use overload '""' => sub ( $s, @ ) { $s->id }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('POSITIONS') // skip_all();
    like( +t::Utility::stash('POSITIONS'),
        qr'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[0-9a-f]{4}-[0-9a-f]{12}$'i );
}
#
has robinhood =>
    ( is => 'ro', predicate => 1, isa => InstanceOf ['Finance::Robinhood'], required => 1 );

=head2 C<account_id( )>

Returns a UUID.

=cut

has account_id => ( is => 'ro', isa => UUID, required => 1 );

=head2 C<cost_bases( )>

Returns a list of objects which have the following methods:

=over

=item C<currency_id( )>

Returns a UUID.

=item C<direct_cost_basis( )>

=item C<direct_quantity( )>

=item C<id( )>

=item C<intraday_cost_basis( )>

=item C<intraday_quantity( )>

=item C<marked_cost_basis( )>

=item C<marked_cost_basis( )>

=item C<marked_quantity( )>

=back

=cut

{
    package    # Hide it!
        Finance::Robinhood::Currency::CostBasis;
    use Moo;
    use MooX::Enumeration;
    use Types::Standard qw[ArrayRef Bool Dict Enum InstanceOf Maybe Num Str StrMatch];
    use experimental 'signatures';
    #
    use Finance::Robinhood::Types qw[URL UUID Timestamp];
    has [qw[currency_id id]] => ( is => 'ro', isa => UUID, required => 1 );
    has [
        qw[direct_cost_basis direct_quantity
            intraday_cost_basis intraday_quantity
            marked_cost_basis marked_quantity]
    ] => ( is => 'ro', isa => Num, required => 1 );
}
has _cost_bases => ( is => 'ro', isa => ArrayRef [Dict], required => 1, init_arg => 'cost_bases' );
has cost_bases  => (
    is       => 'ro',
    isa      => ArrayRef [ InstanceOf ['Finance::Robinhood::Currency::CostBasis'] ],
    lazy     => 1,
    init_arg => undef,
    builder  => 1
);

sub _build_cost_bases($s) {
    [ map { Finance::Robinhood::Currency::CostBasis->new( robinhood => $s->robinhood, %$_ ) }
            @{ $s->_cost_bases } ];
}

=head2 C<created_at( )>

Returns a Time::Moment object.

=head2 C<updated_at( )>

Returns a Time::Moment object.

=cut

has [qw[created_at updated_at]] => ( is => 'ro', isa => Timestamp, coerce => 1, required => 1 );

=head2 C<currency( )>

Returns the related Finance::Robinhood::Currency object.

=cut

has _currency => (
    is  => 'ro',
    isa => Dict [
        brand_color => Str,
        code        => Str,
        id          => UUID,
        increment   => Num,
        name        => Str,
        type        => Enum [qw[cryptocurrency fiat]]
    ],
    required => 1,
    init_arg => 'currency'
);
has currency => (
    is       => 'ro',
    isa      => InstanceOf ['Finance::Robinhood::Currency'],
    builder  => 1,
    lazy     => 1,
    init_arg => undef
);

sub _build_currency ($s) {
    $s->robinhood->currency_by_id( $s->_currency->{id} );
}

sub _test_currency {
    t::Utility::stash('POSITIONS') // skip_all();
    isa_ok( t::Utility::stash('POSITIONS')->currency, 'Finance::Robinhood::Currency' );
}

=head2 C<id( )>

Returns a UUID.

=cut

has id => ( is => 'ro', isa => UUIDBroken, required => 1 );

=head2 C<quantity( )>


=head2 C<quantity_available( )>


=head2 C<quantity_held_for_buy( )>


=head2 C<quantity_held_for_sell( )>


=cut

has [qw[quantity quantity_available quantity_held_for_buy quantity_held_for_sell]] =>
    ( is => 'ro', isa => Num, required => 1 );

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
