package Finance::Robinhood::Equity::Order;
our $VERSION = '0.92_003';

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Equity::Order - Represents a Single Equity Order

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new( ... );
    my $orders = $rh->equity_orders();

    for my $order ($orders->all) {
        $order->cancel if $order->can_cancel;
    }

=head1 METHOD

=cut

use Moo;
use MooX::Enumeration;
use Types::Standard qw[ArrayRef Bool Dict Enum InstanceOf Maybe Num Str StrMatch];
use URI;
use Time::Moment;
use Data::Dump;
use experimental 'signatures';
use Finance::Robinhood::Types qw[:all];
#
sub _test__init {
    my $rh    = t::Utility::rh_instance(1);
    my $order = $rh->equity_orders->current;
    isa_ok( $order, __PACKAGE__ );
    t::Utility::stash( 'ORDER', $order );    #  Store it for later
}
use overload '""' => sub ( $s, @ ) { $s->_url }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('ORDER') // skip_all();
    like( +t::Utility::stash('ORDER'), qr'https://api.robinhood.com/orders/.+/' );
}
#
has robinhood => ( is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood'] );
has '_' . $_ => ( is => 'ro', required => 1, isa => URL, coerce => 1, init_arg => $_ )
    for qw[account instrument position url];

=head2 C<account( )>

Returns the related Finance::Robinhood::Equity::Account object.

=cut

has account => (
    is       => 'ro',
    isa      => InstanceOf ['Finance::Robinhood::Equity::Account'],
    lazy     => 1,
    builder  => 1,
    init_arg => undef
);

sub _build_account ($s) {
    $s->robinhood->_req( GET => $s->_account )->as('Finance::Robinhood::Equity::Account');
}

sub _test_account {
    t::Utility::stash('ORDER') // skip_all('No order object in stash');
    isa_ok( t::Utility::stash('ORDER')->account, 'Finance::Robinhood::Equity::Account' );
}

=head2 C<instrument( )>

Returns the related Finance::Robinhood::Equity object.

=cut

has instrument => (
    is       => 'ro',
    isa      => InstanceOf ['Finance::Robinhood::Equity'],
    lazy     => 1,
    builder  => 1,
    init_arg => undef
);

sub _build_instrument ($s) {
    $s->robinhood->_req( GET => $s->_instrument )->as('Finance::Robinhood::Equity');
}

sub _test_instrument {
    t::Utility::stash('ORDER') // skip_all('No order object in stash');
    isa_ok( t::Utility::stash('ORDER')->instrument, 'Finance::Robinhood::Equity' );
}

=head2 C<position( )>

Returns the related Finance::Robinhood::Equity::Position object.

=cut

has position => (
    is       => 'ro',
    isa      => InstanceOf ['Finance::Robinhood::Equity::Position'],
    lazy     => 1,
    builder  => 1,
    init_arg => undef
);

sub _build_position ($s) {
    $s->robinhood->_req( GET => $s->_position )->as('Finance::Robinhood::Equity::Position');
}

sub _test_position {
    t::Utility::stash('ORDER') // skip_all('No order object in stash');
    isa_ok( t::Utility::stash('ORDER')->position, 'Finance::Robinhood::Equity::Position' );
}

=head2 C<average_price( )>

Average price per share for all executions so far.

=cut

has average_price => ( is => 'ro', isa => Maybe [Num] );

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
    ( is => 'ro', required => 1, isa => Maybe [URL], coerce => 1, init_arg => 'cancel' );
has can_cancel => ( is => 'ro', isa => Bool, builder => 1, lazy => 1, init_arg => undef );
sub _build_can_cancel($s) { defined $s->_cancel ? 1 : 0 }

sub cancel ($s) {
    $s->can_cancel || return ();
    my $res = $s->robinhood->_req( POST => $s->_cancel );
    return $res->success;    # Our order isn't returned... which would be nice!
}

sub _test_can_cancel {
    my $rh     = t::Utility::rh_instance(1);
    my $orders = $rh->equity_orders;
    my ( $filled, $cancelled );
    while ( $orders->has_next ) {
        my $order = $orders->next;

        #$filled   = $order if $order->is_queued;
        $cancelled = $order if $order->is_cancelled;
        last if $filled && $cancelled;
    }
SKIP: {
        skip( 'I need to create a new equity order here', 1 );
        $filled // skip( 'Cannot find a filled equity order', 1 );
        my $execution = $filled->executions->[0];
        ref_ok( $execution, 'HASH' );
    }
SKIP: {
        $cancelled // skip( 'Cannot find a canceled equity order', 1 );
        isnt( $cancelled->can_cancel, 1, 'canceled order cannot be cancelled' );
    }
    todo( "Place an order and test if it can be cancelled then cancel it, reload, and retest it" =>
            sub { pass('ugh') } );
}

=head2 C<id( )>

UUID used to identify this specific order.

=cut

has id => ( is => 'ro', required => 1, isa => UUID );

=head2 C<ref_id( )>

Client generated UUID is returned.

=cut

# Only generated server side since 2018 (I have a single malformed ref_id so this is less... strict)
has ref_id => ( is => 'ro', required => 1, isa => Maybe [ UUID | UUIDBroken ] );

=head2 C<dollar_based_amount( )>

If the order is based on fractional shares, this will be the dollar amount.

=cut

has dollar_based_amount => ( is => 'ro', required => 1, isa => Maybe [Num] );

=head2 C<drip_dividend_id( )>

If DRIP is enabled.

=cut

has drip_dividend_id => ( is => 'ro', required => 1, isa => Maybe [UUID] );

=head2 C<extended_hours( )>

Returns a true value if this order is set to execute during extended hours and
pre-market.


=head2 C<override_day_trade_checks( )>

A boolean value indicating whether this order bypassed PDT checks.

=head2 C<override_dtbp_checks( )>

A boolean value indicating whether this order bypassed day trade buying power
checks.

Risky Regulation T violation warning!

=cut

has $_ => ( is => 'ro', required => 1, isa => Bool, coerce => 1 )
    for qw[extended_hours override_day_trade_checks override_dtbp_checks];

=head2 C<quantity( )>

Returns the total number of shares in this order.

=head2 C<cumulative_quantity( )>

Number of shares that have been bought or sold with this order's execution(s)
so far.

=head2 C<fees( )>

Fees imposed on the execution of this order. Nearly always C<0.00> on buys and
at least C<0.02> on sell orders due to SEC and FINRA fees.

=cut

has $_ => ( is => 'ro', required => 1, isa => Num ) for qw[cumulative_quantity fees quantity];

=head2 C<price( )>

The price used as an exact limit (for limit and stop-limit orders) or as the
price to collar from (for market and stop-loss orders).

=head2 C<stop_price( )>

Returns a float if the trigger type is C<stop>, otherwise, C<undef>.

=cut

has $_ => ( is => 'ro', isa => Maybe [Num], required => 1 ) for qw[price stop_price];

=head2 C<last_trail_price( )>

If the order is a trailing stop, this returns a hash reference with the
following keys:

=over

=item C<amount>

=item C<currency_code>

=item C<currency_id>

=back

=cut

has last_trail_price => (
    is  => 'ro',
    isa => Maybe [
        Dict [
            amount        => Num,
            currency_code => Str,    # USD
            currency_id   => UUID
        ]
    ],
    require => 1
);

=head2 C<side( )>

Indicates if this is an order to C<buy> or C<sell>.

=cut

has side =>
    ( is => 'ro', required => 1, isa => Enum [qw[buy sell]], handles => [qw[is_buy is_sell]] );

=head2 C<response_category( )>

Returns the response category if applicable.

=cut

has response_category => (
    is       => 'ro',
    required => 1,
    isa      => Maybe [ Enum [qw[end_of_day invalid_limit invalid_stop success unknown]] ],
    handles  => [qw[is_end_of_day is_invalid_limit is_invalid_stop is_success is_unknown]]
);

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

=item C<cancelled> - Note that equity orders use C<cancelled> rather than C<canceled> like currency orders

=item C<failed>

=item C<voided>

=back

=cut

has state => (    # Currency uses canceled rather than cancelled
    is       => 'ro',
    required => 1,
    isa      => Enum [
        qw[cancelled confirmed failed filled partially_filled pending placed queued rejected unconfirmed voided]
    ],
    handles => [
        qw[is_cancelled is_confirmed is_failed is_filled is_partially_filled is_pending is_placed is_queued is_rejected is_unconfirmed is_voided]
    ]
);

=head2 C<time_in_force( )>

Returns the Time-in-Force value. C<gfd> (good for day) or C<gtc> (good 'til
cancelled).

=cut

has time_in_force => (
    is       => 'ro',
    required => 1,
    isa      => Enum [qw[fok gfd gtc ioc opg]],
    handles  => [qw[is_fok is_gfd is_gtc is_ioc is_opg]]
);

=head2 C<trigger( )>

Returns the trigger. C<stop> or C<immediate>.

=cut

has trigger => (
    is       => 'ro',
    required => 1,
    isa      => Enum [qw[immediate on_close stop]],
    handles  => [qw[is_immediate is_on_close is_stop]]
);

=head2 C<type( )>

Returns the order type. C<limit> or C<market>.

=cut

has type => (
    is       => 'ro',
    required => 1,
    isa      => Enum [qw[limit market]],
    handles  => [qw[is_limit is_market]]
);
has $_ => ( is => 'ro', required => 1, isa => Maybe [Timestamp], coerce => 1 )
    for qw[last_trail_price_updated_at last_transaction_at stop_triggered_at];

=head2 C<created_at( )>

Returns a Time::Moment object.

=head2 C<last_transaction_at( )>

Returns a Time::Moment object if applicable.

=head2 C<updated_at( )>

Returns a Time::Moment object.

=cut

has $_ => ( is => 'ro', required => 1, isa => Timestamp, coerce => 1, )
    for qw[created_at updated_at];

sub _test_created_at {
    t::Utility::stash('ORDER') // skip_all('No order object in stash');
    isa_ok( t::Utility::stash('ORDER')->created_at, 'Time::Moment' );
}

sub _test_last_transaction_at {
    t::Utility::stash('ORDER') // skip_all('No order in stash');
    my $last_transaction_at = t::Utility::stash('ORDER')->last_transaction_at;
    skip_all('No transactions... goodbye') if !defined $last_transaction_at;
    isa_ok( $last_transaction_at, 'Time::Moment' );
}

sub _test_updated_at {
    t::Utility::stash('ORDER') // skip_all('No order object in stash');
    isa_ok( t::Utility::stash('ORDER')->updated_at, 'Time::Moment' );
}

=head2 C<reject_reason( )>

If the order was rejected, this will be filled with the reason.

=cut

has reject_reason => ( is => 'ro', required => 1, isa => Maybe [Str] );

=head2 C<investment_schedule_id( )>


=cut

has investment_schedule_id => ( is => 'ro', required => 1, isa => Maybe [UUID] );

=head2 C<total_notional( )>

This returns a hash reference with the following keys:

=over

=item C<amount>

=item C<currency_code>

=item C<currency_id>

=back


=cut

=head2 C<executed_notional( )>

If the order executed, this returns a hash reference with the following keys:

=over

=item C<amount>

=item C<currency_code>

=item C<currency_id>

=back


=cut

has [qw[executed_notional total_notional]] => (
    is       => 'ro',
    required => 1,
    isa      => Maybe [ Dict [ amount => Num, currency_code => Str, currency_id => UUID ] ]
);

=head2 C<executions( )>

Returns a list of hash references if applicable. These hashes contain the
following keys:

=over

=item C<id> - UUID

=item C<price> - Dollar amount

=item C<quantity> - Size of the execution

=item C<settlement_date> - The date this particular execution will settle

=item C<timestamp> - Time::Moment object

=back

=cut

has executions => (
    is  => 'ro',
    isa => ArrayRef [
        Dict [
            id              => UUID,
            price           => Num,
            quantity        => Num,
            settlement_date => StrMatch [qr[^\d\d\d\d-\d\d-\d\d$]],
            timestamp       => Timestamp
        ]
    ],
    coerce => 1
);

sub _test_executions {
    my $rh     = t::Utility::rh_instance(1);
    my $orders = $rh->equity_orders;
    my ( $filled, $rejected );
    while ( $orders->has_next ) {
        my $order = $orders->next;
        $filled   = $order if $order->state eq 'filled';
        $rejected = $order if $order->state eq 'rejected';
        last if $filled && $rejected;
    }
SKIP: {
        $filled // skip( 'Cannot find a filled equity order', 1 );
        ref_ok( $filled->executions, 'ARRAY', 'Executions are a list' );
    }
SKIP: {
        $rejected // skip( 'Cannot find a rejected equity order', 1 );
        is( $rejected->executions, [], 'rejected order has no executions' );
    }
}

=head2 C<last_trail_price_source( )>

Returns one of the following:

=over

=item C<venue>

=item C<market>

=item C<market_data>

=back

=cut

has last_trail_price_source => ( is => 'ro', isa => Maybe [ Enum [qw[venue market market_data]] ] );
has trailing_peg            => (
    is        => 'ro',
    predicate => 1,
    isa       => Maybe [
        Dict [ type => StrMatch [qr'percentage'], percentage => Num ] | Dict [
            type  => StrMatch [qr'price'],
            price => Dict [ amount => Num, currency_code => Str, currency_id => UUID ]
        ]
    ]
);

=head2 C<reload( )>

    $order->reload();

Reloads the data for this order from the API server.

Use this if you think the status or some other info might have changed.

=cut

sub reload($s) {
    $_[0] = $s->robinhood->_req( GET => $s->_url )->as('Finance::Robinhood::Equity::Order');
}

sub _test_reload {
    t::Utility::stash('ORDER') // skip_all('No order object in stash');
    t::Utility::stash('ORDER')->reload;
    isa_ok( t::Utility::stash('ORDER'), 'Finance::Robinhood::Equity::Order' );
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
