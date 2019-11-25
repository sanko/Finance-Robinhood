package Finance::Robinhood::Currency::OrderBuilder;
our $VERSION = '0.92_003';

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Currency::OrderBuilder - Provides a Sugary Builder-type
Interface for Generating a Forex Order

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;
    my $btc_usd = $rh->currency_pair_by_id('3d961844-d360-45fc-989b-f6fca761d511');

    $btc_usd->buy(1)->submit;

=head1 DESCRIPTION

This is cotton candy for creating valid order structures.

Without any additional method calls, this will create a simple market order
that looks like this:

    {
       account          => 'XXXXXXXXXXXXXXXXXXXXXX',
       currency_pair_id => '3d961844-d360-45fc-989b-f6fca761d511',
       price            => '111.700000', # Automatically grabs ask or bid price quote
       quantity         => 4, # Actually the amount of crypto you requested
       side             => 'buy', # Or sell
       time_in_force    => 'ioc',
       type             => 'market'
     }

You may chain together several methods to generate and submit advanced order
types such as stop limits that are held up to 90 days:

    $order->gtc->limit->submit;

=cut

use Data::Dump;
use strictures 2;
use namespace::clean;
use HTTP::Tiny;
use JSON::Tiny;
use Moo;
use MooX::ChainedAttributes;
use Types::Standard qw[Bool Dict Enum InstanceOf Maybe Num Str StrMatch];
use experimental 'signatures';
#
use Finance::Robinhood::Utilities qw[gen_uuid];
#
sub _test__init {
    my $rh      = t::Utility::rh_instance(1);
    my $btc_usd = $rh->currency_pair_by_id('3d961844-d360-45fc-989b-f6fca761d511');
    t::Utility::stash( 'BTC_USD', $btc_usd );    #  Store it for later
    isa_ok( $btc_usd->buy(3),  __PACKAGE__ );
    isa_ok( $btc_usd->sell(3), __PACKAGE__ );
}

=head1 METHODS


=head2 C<account( ... )>

Expects a Finance::Robinhood::Currency::Account object.

=head2 C<pair( ... )>

Expects a Finance::Robinhood::Currency::Pair object.

=head2 C<quantity( ... )>

Expects a whole number of shares.

=cut

has robinhood => ( is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood'] );
has account =>
    ( is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood::Currency::Account'] );
has pair => ( is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood::Currency::Pair'] );

=begin internal

=head2 C<buy( ... )>

    $order->buy( 3 );

Use this to change the order side.

=head2 C<sell( ... )>

    $order->sell( 4 );

Use this to change the order side.

=end internal

=cut
has side => ( is => 'rw', isa => Enum [qw[buy sell]], required => 1, chained => 1 );

sub _test_buy {
    t::Utility::stash('BTC_USD') // skip_all('No cached currency pair');
    my $order = t::Utility::stash('BTC_USD')->buy(3);
    is(
        { $order->_dump(1) },
        {   account          => '--private--',
            currency_pair_id => '3d961844-d360-45fc-989b-f6fca761d511',
            price            => '5.00',
            quantity         => '3.00000000',
            ref_id           => '00000000-0000-0000-0000-000000000000',
            side             => 'buy',
            time_in_force    => 'gtc',
            type             => 'market',
        },
        'dump is correct'
    );
}

sub _test_sell {
    t::Utility::stash('BTC_USD') // skip_all('No cached currency pair');
    my $order = t::Utility::stash('BTC_USD')->sell(3);
    is(
        { $order->_dump(1) },
        {   account          => '--private--',
            currency_pair_id => '3d961844-d360-45fc-989b-f6fca761d511',
            price            => '5.00',
            quantity         => '3.00000000',
            ref_id           => '00000000-0000-0000-0000-000000000000',
            side             => 'sell',
            time_in_force    => 'gtc',
            type             => 'market',
        },
        'dump is correct'
    );
}
has quantity => ( is => 'rw', isa => Num, required => 1, chained => 1 );

=head2 C<limit( ... )>

    $order->limit( 17.98 );

Expects a price.

Use this to create limit and stop limit orders.

=head2 C<market( )>

    $order->market( );

Use this to create market and stop loss orders.

=cut

has limit => ( is => 'rw', predicate => 1, isa => Num, clearer => 'market', chained => 1 );

sub _test_limit {
    t::Utility::stash('BTC_USD') // skip_all('No cached currency pair');
    my $order = t::Utility::stash('BTC_USD')->buy(3)->limit(3.40);
    is(
        { $order->_dump(1) },
        {   account          => '--private--',
            currency_pair_id => '3d961844-d360-45fc-989b-f6fca761d511',
            price            => '3.40',
            quantity         => '3.00000000',
            ref_id           => '00000000-0000-0000-0000-000000000000',
            side             => 'buy',
            time_in_force    => 'gtc',
            type             => 'limit',
        },
        'dump is correct'
    );
}

sub _test_market {
    t::Utility::stash('BTC_USD') // skip_all('No cached currency pair');
    my $order = t::Utility::stash('BTC_USD')->sell(3);
    is(
        { $order->_dump(1) },
        {   account          => '--private--',
            currency_pair_id => '3d961844-d360-45fc-989b-f6fca761d511',
            price            => '5.00',
            quantity         => '3.00000000',
            ref_id           => '00000000-0000-0000-0000-000000000000',
            side             => 'sell',
            time_in_force    => 'gtc',
            type             => 'market',
        },
        'dump is correct'
    );
}
has stop => (
    is        => 'rw',
    predicate => 1,
    isa       => Num,
    clearer   => '_clear_stop',
    trigger   => sub ( $s, $value ) {
        $s->trigger('stop');
    },
    chained => 1
);

#has trigger => (is      => 'rw',
#                isa     => Enum [qw[immediate on_close stop]],
#                handles => [qw[is_immediate is_on_close is_stop]],
#                default => 'immediate',
#                chained => 1
#);
#sub immediate($s) { $s->trigger('immediate'); $s->_clear_stop; $s; }
#sub on_close ($s) { $s->trigger('on_close');  $s->_clear_stop; $s }

=head2 C<gtc( )>

    $order->gtc( );

Use this to change the order's time in force value to Good-Till-Cancelled
(actually 90 days from submission).


=head2 C<ioc( )>

    $order->ioc( );

Use this to change the order's time in force value to Immediate-Or-Cancel.

This may require special permissions.

=cut

has time_in_force => ( is => 'rw', isa => Enum [qw[gtc ioc]], default => 'gtc', chained => 1 );
sub gtc($s) { $s->time_in_force('gtc') }
sub ioc($s) { $s->time_in_force('ioc') }

sub _test_gtc {
    t::Utility::stash('BTC_USD') // skip_all('No cached currency pair');
    my $order = t::Utility::stash('BTC_USD')->sell(3)->gtc();
    is(
        { $order->_dump(1) },
        {   account          => '--private--',
            currency_pair_id => '3d961844-d360-45fc-989b-f6fca761d511',
            price            => '5.00',
            quantity         => '3.00000000',
            ref_id           => '00000000-0000-0000-0000-000000000000',
            side             => 'sell',
            time_in_force    => 'gtc',
            type             => 'market',
        },
        'dump is correct'
    );
}

sub _test_ioc {
    t::Utility::stash('BTC_USD') // skip_all('No cached currency pair');
    my $order = t::Utility::stash('BTC_USD')->sell(3)->ioc();
    is(
        { $order->_dump(1) },
        {   account          => '--private--',
            currency_pair_id => '3d961844-d360-45fc-989b-f6fca761d511',
            price            => '5.00',
            quantity         => '3.00000000',
            ref_id           => '00000000-0000-0000-0000-000000000000',
            side             => 'sell',
            time_in_force    => 'ioc',
            type             => 'market',
        },
        'dump is correct'
    );
}
#

=head2 C<submit( )>

    $order->submit( );

Use this to finally submit the order. On success, your builder is replaced by a
new Finance::Robinhood::Currency::Order object which is also returned. On
failure, your builder object is replaced by a Finance::Robinhood::Error object.

=cut

sub submit ($s) {
    $_[0] = $s->robinhood->_req(    # Doesn't accept multi-part form post
        POST => 'https://nummus.robinhood.com/orders/',
        json => { $s->_dump }
    )->as('Finance::Robinhood::Currency::Order');
    $_[0];
}

sub _test_submit {
    t::Utility::stash('BTC_USD') // skip_all('No cached currency pair');

    # TODO: Skp these tests if we don't have enough cash on hand.
    my $ask = t::Utility::stash('BTC_USD')->quote->ask_price;

    # Orders must be within 10% of ask/bid
    my $order = t::Utility::stash('BTC_USD')->buy(.001)
        ->gtc->limit( sprintf '%.2f', $ask - ( $ask * .1 ) );
    isa_ok( $order->submit, 'Finance::Robinhood::Currency::Order' );
    isa_ok( $order,         'Finance::Robinhood::Currency::Order' );
    use Data::Dump;
    ddx $order;
    $order->cancel;
}

# Do it! (And debug it...)
sub _dump ( $s, $test = 0 ) {
    (    # Defaults
        currency_pair_id => $s->pair->id,
        account          => $test ? '--private--' : $s->account->id,
        side             => $s->side,
        price            => sprintf(
            '%1.' . ( -1 + index $s->pair->min_order_price_increment, '1' ) . 'f', (
                $s->has_limit ? $s->limit :
                    $test     ? '5.00' :
                    ( $s->limit // $s->pair->quote->last_trade_price )
            )
        ),
        ref_id   => $test ? '00000000-0000-0000-0000-000000000000' : gen_uuid(),
        quantity => sprintf(
            '%1.' . ( -1 + index $s->pair->min_order_quantity_increment, '1' ) . 'f',
            $s->quantity
        ),
        time_in_force => $s->time_in_force,
        $s->has_limit() ? ( type       => 'limit' )  : ( type => 'market' ),
        $s->has_stop()  ? ( stop_price => $s->stop ) : ()
    )
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
