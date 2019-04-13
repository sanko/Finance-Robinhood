package Finance::Robinhood::Forex::OrderBuilder;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Forex::OrderBuilder - Provides a Sugary Builder-type
Interface for Generating a Forex Order

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;
    my $btc_usd = $rh->forex_pair_by_id('3d961844-d360-45fc-989b-f6fca761d511');

    $btc_usd->buy(1)->submit;

=head1 DESCRIPTION

This is cotton candy for creating valid order structures.

Without any additional method calls, this will create a simple market order
that looks like this:

    {
       account          => "XXXXXXXXXXXXXXXXXXXXXX",
       currency_pair_id => "3d961844-d360-45fc-989b-f6fca761d511",
       price            => "111.700000", # Automatically grabs ask or bid price quote
       quantity         => 4, # Actually the amount of crypto you requested
       side             => "buy", # Or sell
       time_in_force    => "ioc",
       type             => "market"
     }

You may chain together several methods to generate and submit advanced order
types such as stop limits that are held up to 90 days:

    $order->gtc->limit->submit;

=cut

our $VERSION = '0.92_002';
use Mojo::Base-base, -signatures;
use Finance::Robinhood::Forex::Order;

sub _test__init {
    my $rh      = t::Utility::rh_instance(1);
    my $btc_usd = $rh->forex_pair_by_id('3d961844-d360-45fc-989b-f6fca761d511');
    t::Utility::stash( 'BTC_USD', $btc_usd );    #  Store it for later
    isa_ok( $btc_usd->buy(3),  __PACKAGE__ );
    isa_ok( $btc_usd->sell(3), __PACKAGE__ );
}
#
has _rh => undef => weak => 1;

=head1 METHODS


=head2 C<account( ... )>

Expects a Finance::Robinhood::Forex::Account object.

=head2 C<pair( ... )>

Expects a Finance::Robinhood::Forex::Pair object.

=head2 C<quantity( ... )>

Expects a whole number of shares.

=cut

has _account => undef;    # => weak => 1;
has _pair    => undef;    # => weak => 1;
has [ 'quantity', 'price' ];
#
# Type

=head2 C<limit( ... )>

    $order->limit( 17.98 );

Expects a price.

Use this to create limit and stop limit orders.

=head2 C<market( )>

    $order->market( );

Use this to create market and stop loss orders.

=cut

sub limit ( $s, $price ) {
    $s->with_roles('Finance::Robinhood::Forex::OrderBuilder::Role::Limit')->limit($price);
}
{

    package Finance::Robinhood::Forex::OrderBuilder::Role::Limit;
    use Mojo::Base-role, -signatures;
    has limit    => 0;
    around _dump => sub ( $orig, $s, $test = 0 ) {
        my %data = $orig->( $s, $test );
        ( %data, price => $s->limit, type => 'limit' );
    };
}

sub _test_limit {
    t::Utility::stash('BTC_USD') // skip_all('No cached currency pair');
    my $order = t::Utility::stash('BTC_USD')->buy(3)->limit(3.40);
    is(
        { $order->_dump(1) },
        {
            account          => "--private--",
            currency_pair_id => "3d961844-d360-45fc-989b-f6fca761d511",
            price            => 3.40,
            quantity         => 3,
            ref_id           => "00000000-0000-0000-0000-000000000000",
            side             => "buy",
            time_in_force    => "gtc",
            type             => "limit",
        },
        'dump is correct'
    );
}

sub market($s) {
    $s->with_roles('Finance::Robinhood::Forex::OrderBuilder::Role::Market');
}
{

    package Finance::Robinhood::Forex::OrderBuilder::Role::Market;
    use Mojo::Base-role, -signatures;
    around _dump => sub ( $orig, $s, $test = 0 ) {
        my %data = $orig->( $s, $test );
        ( %data, type => 'market' );
    };
}

sub _test_market {
    t::Utility::stash('BTC_USD') // skip_all('No cached currency pair');
    my $order = t::Utility::stash('BTC_USD')->sell(3)->market();
    is(
        { $order->_dump(1) },
        {
            account          => "--private--",
            currency_pair_id => "3d961844-d360-45fc-989b-f6fca761d511",
            price            => '5.00',
            quantity         => 3,
            ref_id           => "00000000-0000-0000-0000-000000000000",
            side             => "sell",
            time_in_force    => "gtc",
            type             => "market",
        },
        'dump is correct'
    );
}

=begin internal

=head2 C<buy( ... )>

    $order->buy( 3 );

Use this to change the order side.

=head2 C<sell( ... )>

    $order->sell( 4 );

Use this to change the order side.

=end internal

=cut

# Side
sub buy ( $s, $quantity = $s->quantity ) {
    $s->with_roles('Finance::Robinhood::Forex::OrderBuilder::Role::Buy');
    $s->quantity($quantity);
}
{

    package Finance::Robinhood::Forex::OrderBuilder::Role::Buy;
    use Mojo::Base-role, -signatures;
    around _dump => sub ( $orig, $s, $test = 0 ) {
        my %data = $orig->( $s, $test );
        (
            %data,
            side  => 'buy',
            price => $test ? '5.00' : $s->price // $s->_pair->quote->bid_price
        );
    };
}

sub _test_buy {
    t::Utility::stash('BTC_USD') // skip_all('No cached currency pair');
    my $order = t::Utility::stash('BTC_USD')->sell(32)->buy(3);
    is(
        { $order->_dump(1) },
        {
            account          => "--private--",
            currency_pair_id => "3d961844-d360-45fc-989b-f6fca761d511",
            price            => '5.00',
            quantity         => 3,
            ref_id           => "00000000-0000-0000-0000-000000000000",
            side             => "buy",
            time_in_force    => "gtc",
            type             => "market",
        },
        'dump is correct'
    );
}

sub sell ( $s, $quantity = $s->quantity ) {
    $s->with_roles('Finance::Robinhood::Forex::OrderBuilder::Role::Sell');
    $s->quantity($quantity);
}
{

    package Finance::Robinhood::Forex::OrderBuilder::Role::Sell;
    use Mojo::Base-role, -signatures;
    around _dump => sub ( $orig, $s, $test = 0 ) {
        my %data = $orig->( $s, $test );
        (
            %data,
            side  => 'sell',
            price => $test ? '5.00' : $s->price // $s->_pair->quote->ask_price
        );
    };
}

sub _test_sell {
    t::Utility::stash('BTC_USD') // skip_all('No cached currency pair');
    my $order = t::Utility::stash('BTC_USD')->buy(32)->sell(3);
    is(
        { $order->_dump(1) },
        {
            account          => "--private--",
            currency_pair_id => "3d961844-d360-45fc-989b-f6fca761d511",
            price            => '5.00',
            quantity         => 3,
            ref_id           => "00000000-0000-0000-0000-000000000000",
            side             => "sell",
            time_in_force    => "gtc",
            type             => "market",
        },
        'dump is correct'
    );
}

# Time in force

=head2 C<gtc( )>

    $order->gtc( );

Use this to change the order's time in force value to Good-Till-Cancelled
(actually 90 days from submission).


=head2 C<ioc( )>

    $order->ioc( );

Use this to change the order's time in force value to Immediate-Or-Cancel.

This may require special permissions.

=cut 

sub gtc($s) {
    $s->with_roles('Finance::Robinhood::Forex::OrderBuilder::Role::GTC');
}
{

    package Finance::Robinhood::Forex::OrderBuilder::Role::GTC;
    use Mojo::Base-role, -signatures;
    around _dump => sub ( $orig, $s, $test = 0 ) {
        my %data = $orig->( $s, $test );
        ( %data, time_in_force => 'gtc' );
    };
}

sub _test_gtc {
    t::Utility::stash('BTC_USD') // skip_all('No cached currency pair');
    my $order = t::Utility::stash('BTC_USD')->sell(3)->gtc();
    is(
        { $order->_dump(1) },
        {
            account          => "--private--",
            currency_pair_id => "3d961844-d360-45fc-989b-f6fca761d511",
            price            => '5.00',
            quantity         => 3,
            ref_id           => "00000000-0000-0000-0000-000000000000",
            side             => "sell",
            time_in_force    => "gtc",
            type             => "market",
        },
        'dump is correct'
    );
}

sub ioc($s) {
    $s->with_roles('Finance::Robinhood::Forex::OrderBuilder::Role::IOC');
}
{

    package Finance::Robinhood::Forex::OrderBuilder::Role::IOC;
    use Mojo::Base-role, -signatures;
    around _dump => sub ( $orig, $s, $test = 0 ) {
        my %data = $orig->( $s, $test );
        ( %data, time_in_force => 'ioc' );
    };
}

sub _test_ioc {
    t::Utility::stash('BTC_USD') // skip_all('No cached currency pair');
    my $order = t::Utility::stash('BTC_USD')->sell(3)->ioc();
    is(
        { $order->_dump(1) },
        {
            account          => "--private--",
            currency_pair_id => "3d961844-d360-45fc-989b-f6fca761d511",
            price            => '5.00',
            quantity         => 3,
            ref_id           => "00000000-0000-0000-0000-000000000000",
            side             => "sell",
            time_in_force    => "ioc",
            type             => "market",
        },
        'dump is correct'
    );
}

# Do it!

=head2 C<submit( )>

    $order->submit( );

Use this to finally submit the order. On success, your builder is replaced by a
new Finance::Robinhood::Forex::Order object is returned. On failure, your
builder object is replaced by a Finance::Robinhood::Error object.

=cut

sub submit ($s) {
    my $res = $s->_rh->_post( 'https://nummus.robinhood.com/orders/', $s->_dump );
    $_[0]
        = $res->is_success
        ? Finance::Robinhood::Forex::Order->new( _rh => $s->_rh, %{ $res->json } )
        : Finance::Robinhood::Error->new(
        $res->is_server_error ? ( details => $res->message ) : $res->json );
}

sub _test_submit {
    t::Utility::stash('BTC_USD') // skip_all('No cached currency pair');

    # TODO: Skp these tests if we don't have enough cash on hand.
    my $ask = t::Utility::stash('BTC_USD')->quote->ask_price;

    # Orders must be within 10% of ask/bid
    my $order = t::Utility::stash('BTC_USD')->buy(.001)
        ->gtc->limit( sprintf '%.2f', $ask - ( $ask * .1 ) );

    isa_ok( $order->submit, 'Finance::Robinhood::Forex::Order' );

    #use Data::Dump;
    #ddx $order;
    $order->cancel;
}

# Do it! (And debug it...)
sub _dump ( $s, $test = 0 ) {
    (    # Defaults
        quantity         => $s->quantity,
        type             => 'market',
        currency_pair_id => $s->_pair->id,
        account          => $test ? '--private--' : $s->_account->id,
        time_in_force    => 'gtc',
        ref_id           => $test ? '00000000-0000-0000-0000-000000000000' : _gen_uuid()
    )
}

sub _gen_uuid() {
    CORE::state $srand;
    $srand = srand() if !$srand;
    my $retval = join '', map {
        pack 'I',
            ( int( rand(0x10000) ) % 0x10000 << 0x10 ) | int( rand(0x10000) ) % 0x10000
    } 1 .. 4;
    substr $retval, 6, 1, chr( ord( substr( $retval, 6, 1 ) ) & 0x0f | 0x40 );    # v4
    return join '-', map { unpack 'H*', $_ } map { substr $retval, 0, $_, '' } ( 4, 2, 2, 2, 6 );
}

sub _test__gen_uuid {
    like( _gen_uuid(), qr[^[0-9a-f]{8}(?:\-[0-9a-f]{4}){3}\-[0-9a-f]{12}$]i, 'generated uuid' );
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
