package Finance::Robinhood::Currency::Order;
our $VERSION = '0.92_003';

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Currency::Order - Represents a Single Cryptocurrency Order

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new( ... );
    my $orders = $rh->currency_orders();

    for my $order ($orders->all) {
        $order->cancel if $order->can_cancel;
    }

=cut

sub _test__init {
    my $rh    = t::Utility::rh_instance(1);
    my $order = $rh->currency_orders->current;
    isa_ok( $order, __PACKAGE__ );
    t::Utility::stash( 'ORDER', $order );    #  Store it for later
}
#
use Moo;
use MooX::Enumeration;
use Types::Standard qw[Any Overload ArrayRef Bool Dict Enum InstanceOf Maybe Num Str StrMatch];
use URI;
use Time::Moment;
use Data::Dump;
use experimental 'signatures';
use Finance::Robinhood::Types qw[UUID Timestamp URL];
#
#use Finance::Robinhood::User::AdditionalInfo;
#use Finance::Robinhood::User::BasicInfo;
#use Finance::Robinhood::User::Employment;
#use Finance::Robinhood::User::IDInfo;
#use Finance::Robinhood::User::InternationalInfo;
#use Finance::Robinhood::User::Profile;
#
use overload '""' => sub ( $s, @ ) { $s->id }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('ORDER') // skip_all();
    like(
        +t::Utility::stash('ORDER'),
        qr'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'i
    );
}
has robinhood =>
    ( is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood'], handles => ['_req'] );

=head1 METHODS

=head2 C<account_id( )> - UUID

=head2 C<average_price> - If defined, this is a dollar amount



=head2 C<cumulative_quantity( )>

Returns the amount of currency bought or sold.

=head2 C<currency_pair_id( )>

Returns a UUID.

=head2 C<id( )>

Returns a UUID.

=head2 C<last_transaction_at( )>

Returns a Time::Moment object.

=head2 C<price( )>

Returns a dollar amount.

=head2 C<quantity( )>

Returns the amount of currency in the order.

=head2 C<ref_id( )>

Returns a UUID.

=head2 C<rounded_executed_notional( )>

Returns a dollar amount.

=head2 C<side>

Returns C<buy> or C<sell>.

=head2 C<time_in_force( )>

Returns C<gtc> or C<ioc>.

=head2 C<type( )>

Returns C<limit> or C<market>.

=head2 C<updated_at( )>

Returns a Time::Moment object.

=cut

has [qw[account_id currency_pair_id id]] => ( is => 'ro', isa => UUID, required => 1 );
has ref_id                               => (
    is       => 'ro',
    isa      => Str,    # I have some broken ref_ids... oops...
    required => 1
);
has average_price => ( is => 'ro', isa => Maybe [Num], required => 1 );
has [qw[created_at  updated_at]] => ( is => 'ro', isa => Timestamp, coerce => 1, required => 1 );
has last_transaction_at => ( is => 'ro', isa => Maybe [Timestamp], coerce => 1, required => 1 );
has [qw[cumulative_quantity price quantity rounded_executed_notional]] =>
    ( is => 'ro', isa => Num, required => 1 );
has side =>
    ( is => 'ro', isa => Enum [qw[buy sell]], required => 1, handles => [qw[is_buy is_sell]] );

=head2 C<state( )>

One of the following:

=over

=item C<queued>

=item C<new>

=item C<unconformed>

=item C<confirmed>

=item C<partially_filled>

=item C<filled>

=item C<rejected>

=item C<canceled> - Note that currency orders use C<canceled> rather than C<cancelled> like equities

=item C<failed>

=item C<voided>

=back

=cut

has state => (    # Currency uses canceled rather than cancelled
    is       => 'ro',
    required => 1,
    isa      => Enum [
        qw[canceled confirmed failed filled partially_filled pending placed queued rejected unconfirmed voided]
    ],
    handles => [
        qw[is_canceled is_confirmed is_failed is_filled is_partially_filled is_pending is_placed is_queued is_rejected is_unconfirmed is_voided]
    ]
);
has time_in_force =>
    ( is => 'ro', isa => Enum [qw[gtc ioc]], required => 1, handles => [qw[is_gtc is_ioc]] );
has type => (
    is       => 'ro',
    isa      => Enum [qw[limit market]],
    required => 1,
    handles  => [qw[is_limit is_market]]
);

=head2 C<executions( )>

Returns a list of hash references which contain the following keys:

=over

=item C<effective_price>

=item C<id>

=item C<quantity>

=item C<timestamp>

=back

=cut

has executions => (
    is  => 'ro',
    isa => ArrayRef [
        Dict [ effective_price => Num, id => UUID, quantity => Num, timestamp => Timestamp ]
    ],
    coerce => 1
);

sub _test_executions {
    my $rh     = t::Utility::rh_instance(1);
    my $orders = $rh->currency_orders;
    my ( $filled, $rejected );
    while ( $orders->has_next ) {
        my $order = $orders->next;
        $filled   = $order if $order->is_filled;
        $rejected = $order if $order->is_rejected;
        last if $filled && $rejected;
    }
SKIP: {
        $filled // skip( 'Cannot find a filled currency order', 1 );
        ref_ok( $filled->executions, 'ARRAY', 'Executions are a list' );
    }
SKIP: {
        $rejected // skip( 'Cannot find a rejected currency order', 1 );
        is( $rejected->executions, [], 'rejected order has no executions' );
    }
}

=head2 C<can_cancel( )>

Returns true if the order can be cancelled.

=head2 C<cancel( )>

    $order->cancel();

If the order can be cancelled, this method will do it.

Be aware that the order is still active for about a second after this is called
so add a 'smart' delay here and then call C<reload( )> to update the object
correctly.

=cut

has '_cancel' =>
    ( is => 'ro', required => 1, isa => Maybe [URL], coerce => 1, init_arg => 'cancel_url' );
has can_cancel => ( is => 'ro', isa => Bool, builder => 1, lazy => 1, init_arg => undef );
sub _build_can_cancel($s) { defined $s->_cancel ? 1 : 0 }

sub cancel ($s) {
    $s->can_cancel || return ();
    my $res = $s->robinhood->_req( POST => $s->_cancel );
    $res->{success} ? 1 : 0    # Our order isn't returned... which would be nice!
}

sub _test_can_cancel {
    my $rh     = t::Utility::rh_instance(1);
    my $orders = $rh->currency_orders;
    my ( $filled, $cancelled );
    while ( $orders->has_next ) {
        my $order = $orders->next;

        #$filled   = $order if $order->is_queued;
        $cancelled = $order if $order->is_canceled;     # Equity uses cancelled
        last                if $filled && $cancelled;
    }
SKIP: {
        skip( 'I need to create a new currency order here', 1 );
        $filled // skip( 'Cannot find a filled currency order', 1 );
        my $execution = $filled->executions->[0];
        ref_ok( $execution, 'HASH' );
    }
SKIP: {
        $cancelled // skip( 'Cannot find a cancelled currency order', 1 );
        isnt( $cancelled->can_cancel, 1, 'cancelled order cannot be cancelled' );
    }
    todo( "Place an order and test if it can be cancelled then cancel it, reload, and retest it" =>
            sub { pass('ugh') } );
}

=head2 C<reload( )>

    $order->reload();

Reloads the data for this order from the API server.

Use this if you think the status or some other info might have changed.

=cut

sub reload($s) {
    $_[0] = $s->robinhood->_req( GET => 'https://nummus.robinhood.com/orders/' . $s->id . '/' )
        ->as('Finance::Robinhood::Currency::Order');
}

sub _test_reload {
    t::Utility::stash('ORDER') // skip_all('No order object in stash');
    t::Utility::stash('ORDER')->reload;
    isa_ok( t::Utility::stash('ORDER'), 'Finance::Robinhood::Currency::Order' );
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
