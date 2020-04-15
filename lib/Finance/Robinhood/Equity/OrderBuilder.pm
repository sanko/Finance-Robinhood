package Finance::Robinhood::Equity::OrderBuilder;
our $VERSION = '0.92_003';

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Equity::OrderBuilder - Provides a Sugary Builder-type
Interface for Generating an Equity Order

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;
    my $msft = $rh->instruments_by_symbol('MSFT');

    # This package isn't used directly; instead, try this...
    my $order = $msft->buy(3)->post;

=head1 DESCRIPTION

This is cotton candy for creating valid order structures.

Without any additional method calls, this will create a simple market order
that looks like this:

    {
       account       => 'https://api.robinhood.com/accounts/XXXXXXXXXX/',
       instrument    => 'https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/',
       price         => '111.700000', # Automatically grabs last trade price quote
       quantity      => 4, # Actually the number of shares you requested
       side          => 'buy', # Or sell
       symbol        => 'MSFT', # Grabs ticker symbol automatically from instrument object
       time_in_force => 'gfd',
       trigger       => 'immediate',
       type          => 'market'
     }

You may chain together several methods to generate and submit advanced order
types such as stop limits that are held up to 90 days:

    $order->stop(24.50)->gtc->limit->submit;

=cut

use strictures 2;
use namespace::clean;
use HTTP::Tiny;
use JSON::Tiny;
use Moo;
use MooX::ChainedAttributes;
use Types::Standard qw[Bool Dict Enum InstanceOf Maybe Num Str StrMatch];
use Finance::Robinhood::Utilities qw[gen_uuid];
use experimental 'signatures';
use Finance::Robinhood::Equity::Order;
#
has robinhood => ( is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood'] );
has account =>
    ( is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood::Equity::Account'] );
has instrument => ( is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood::Equity'] );

sub _test__init {
    my $rh   = t::Utility::rh_instance(1);
    my $msft = $rh->equity('MSFT');
    t::Utility::stash( 'MSFT', $msft );    #  Store it for later
    isa_ok( $msft->buy(3),  __PACKAGE__ );
    isa_ok( $msft->sell(3), __PACKAGE__ );
}
#

=head1 METHODS


=head2 C<account( ... )>

Expects a Finance::Robinhood::Equity::Account object.

=head2 C<instrument( ... )>

Expects a Finance::Robinhood::Equity::Instrument object.

=head2 C<quantity( ... )>

Expects a whole number of shares.

=cut

#
has side     => ( is => 'rw', isa => Enum [qw[buy sell]], required => 1, chained => 1 );
has quantity => ( is => 'rw', isa => Num, required => 1, chained => 1 );
has limit    => ( is => 'rw', predicate => 1, isa => Num, chained => 1 );
has stop     => (
    is        => 'rw',
    predicate => 1,
    isa       => Num,
    clearer   => '_clear_stop',
    trigger   => sub ( $s, $value ) {
        $s->trigger('stop');
    },
    chained => 1
);
has trigger => (
    is      => 'rw',
    isa     => Enum [qw[immediate on_close stop]],
    handles => [qw[is_immediate is_on_close is_stop]],
    default => 'immediate',
    chained => 1
);
sub immediate($s) { $s->trigger('immediate'); $s->_clear_stop; $s; }
sub on_close ($s) { $s->trigger('on_close');  $s->_clear_stop; $s }
has time_in_force =>
    ( is => 'rw', isa => Enum [qw[fok gfd gtc ioc opg]], default => 'gfd', chained => 1 );
sub fok($s) { $s->time_in_force('fok') }
sub gfd($s) { $s->time_in_force('gfd') }
sub gtc($s) { $s->time_in_force('gtc') }
sub ioc($s) { $s->time_in_force('ioc') }
sub opg($s) { $s->time_in_force('opg') }
#
has is_extended_hours =>
    ( is => 'rw', isa => Bool, default => !1, required => 1, clearer => 'no_extended_hours' );

sub extended_hours ($s) {
    $s->is_extended_hours(1);
    $s;
}
has is_override_dtbp_checks =>
    ( is => 'rw', isa => Bool, default => !1, required => 1, clearer => 'no_override_dtbp_checks' );

sub override_dtbp_checks ($s) {
    $s->is_override_dtbp_checks(1);
    $s;
}
has is_override_day_trade_checks => (
    is       => 'rw',
    isa      => Bool,
    default  => !1,
    required => 1,
    clearer  => 'no_override_day_trade_checks'
);

sub override_day_trade_checks ($s) {
    $s->is_override_day_trade_checks(1);
    $s;
}
has is_preIpo => ( is => 'rw', isa => Bool, default => !1, required => 1, clearer => 'not_preIpo' );

sub pre_ipo ($s) {
    $s->is_preIpo(1);
    $s;
}

# Do it! (And debug it...)
sub _as_price($price) { sprintf( ( $price >= 1 ? '%.02f' : '%.04f' ), $price ) }

sub _dump ( $s, $test = 0 ) {
    account           => ( $test ? '--private--' : $s->account->url ),
        instrument    => $s->instrument->url,
        symbol        => $s->instrument->symbol,
        side          => $s->side,
        quantity      => $s->quantity,
        time_in_force => $s->time_in_force,
        ref_id        => $test ? '00000000-0000-0000-0000-000000000000' : gen_uuid(),
        $test
        ? (
        price => _as_price( $s->has_limit ? $s->limit : '5.00' ),
        type  => $s->has_limit ? 'limit' : 'market'
        )
        : $s->has_limit() ? ( price => $s->limit, type => 'limit' )
        : ( price => $s->instrument->prices( live => 0 )->price, type => 'market' ),
        $s->has_stop() ? ( stop_price => _as_price( $s->stop ) ) : (),
        trigger => $s->trigger,
        $s->is_extended_hours            ? ( extended_hours            => 'true' )           : (),
        $s->is_override_dtbp_checks      ? ( override_dtbp_checks      => 'true' )           : (),
        $s->is_override_day_trade_checks ? ( override_day_trade_checks => 'true' )           : (),
        $s->is_preIpo                    ? ( isPreIpo                  => 'true' )           : (),
        $s->has_trailing_peg             ? ( trailing_peg              => $s->trailing_peg ) : ();
}

=head2 C<stop( ... )>

    $order->stop( 45.20 );

Expects a price.

Use this to create stop limit or stop loss orders.

=cut

sub _test_stop {
    t::Utility::stash('MSFT') // skip_all('No cached equity instrument');
    my $order = t::Utility::stash('MSFT')->buy(3)->stop(3.40);
    is(
        { $order->_dump(1) },
        {
            account => '--private--',
            instrument =>
                'https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/',
            price         => '5.00',
            quantity      => 3,
            ref_id        => '00000000-0000-0000-0000-000000000000',
            side          => 'buy',
            symbol        => 'MSFT',
            time_in_force => 'gfd',
            trigger       => 'stop',
            stop_price    => '3.40',
            type          => 'market',
        },
        'dump is correct'
    );
}

# Trailing orders
has trailing_peg => (
    is      => 'rw',
    chained => 1,
    isa     => Maybe [
        Dict [ type => StrMatch [qr'percentage'], percentage => Num ] | Dict [
            type  => StrMatch [qr'price'],
            price => Dict [
                amount        => Num,
                currency_code => Str,
                currency_id   => StrMatch [
                    qr[^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$]i]
            ]
        ]
    ],
    predicate => 1
);

=head2 C<trailing_stop( ... )>

	$sell->trailing_stop('4%');

You may set a percentage based trailing stop with this.

	$sell->trailing_stop(4.49);

You may set a dollar amount based trailing stop with this.

=cut

sub trailing_stop (
    $s, $offset,
    $trailing_stop_price = $s->stop // $s->instrument->prices( live => 0 )->price
) {
    $s->trailing_peg(
        $offset =~ m[^(\d+)\%] ? { type => 'percentage', percentage => $offset } : {
            type  => 'price',
            price => {
                amount        => _as_price($offset),
                currency_code => 'USD',
                currency_id   => '1072fc76-1862-41ab-82c2-485837590762'
            }
        }
    );
    $s->stop($trailing_stop_price);
    $s;
}

sub _test_trailing_stop {
    t::Utility::stash('MSFT') // skip_all('No cached equity instrument');

    # Trailing stop limit
    my $order = t::Utility::stash('MSFT')->buy(3)->stop(3.40)->trailing_stop(1)->limit(4.93);
    is(
        { $order->_dump(1) },
        {
            account => '--private--',
            instrument =>
                'https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/',
            price         => '4.93',
            quantity      => 3,
            ref_id        => '00000000-0000-0000-0000-000000000000',
            side          => 'buy',
            symbol        => 'MSFT',
            time_in_force => 'gfd',
            trigger       => 'stop',
            stop_price    => '3.40',
            type          => 'limit',
            trailing_peg  => {
                type  => 'price',
                price => {
                    amount        => '1.00',
                    currency_code => 'USD',
                    currency_id   => '1072fc76-1862-41ab-82c2-485837590762'
                }
            }
        },
        'dump is correct'
    );
}

# Type

=head2 C<limit( ... )>

    $order->limit( 17.98 );

Expects a price.

Use this to create limit and stop limit orders.

=cut

sub _test_limit {
    t::Utility::stash('MSFT') // skip_all('No cached equity instrument');
    my $order = t::Utility::stash('MSFT')->buy(3)->limit(3.40);
    is(
        { $order->_dump(1) },
        {
            account => '--private--',
            instrument =>
                'https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/',
            price         => '3.40',
            quantity      => 3,
            ref_id        => '00000000-0000-0000-0000-000000000000',
            side          => 'buy',
            symbol        => 'MSFT',
            time_in_force => 'gfd',
            trigger       => 'immediate',
            type          => 'limit',
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
sub _test_buy {
    t::Utility::stash('MSFT') // skip_all('No cached equity instrument');
    my $order = t::Utility::stash('MSFT')->buy(3);
    is(
        { $order->_dump(1) },
        {
            account => '--private--',
            instrument =>
                'https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/',
            price         => '5.00',
            quantity      => 3,
            ref_id        => '00000000-0000-0000-0000-000000000000',
            side          => 'buy',
            symbol        => 'MSFT',
            time_in_force => 'gfd',
            trigger       => 'immediate',
            type          => 'market',
        },
        'dump is correct'
    );
}

sub _test_sell {
    t::Utility::stash('MSFT') // skip_all('No cached equity instrument');
    my $order = t::Utility::stash('MSFT')->sell(3);
    is(
        { $order->_dump(1) },
        {
            account => '--private--',
            instrument =>
                'https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/',
            price         => '5.00',
            quantity      => 3,
            ref_id        => '00000000-0000-0000-0000-000000000000',
            side          => 'sell',
            symbol        => 'MSFT',
            time_in_force => 'gfd',
            trigger       => 'immediate',
            type          => 'market',
        },
        'dump is correct'
    );
}

# Time in force

=head2 C<gfd( )>

    $order->gfd( );

Use this to change the order's time in force value to Good-For-Day.

=head2 C<gtc( )>

    $order->gtc( );

Use this to change the order's time in force value to Good-Till-Cancelled
(actually 90 days from submission).

=head2 C<fok( )>

    $order->fok( );

Use this to change the order's time in force value to Fill-Or-Kill.

This may require special permissions.

=head2 C<ioc( )>

    $order->ioc( );

Use this to change the order's time in force value to Immediate-Or-Cancel.

This may require special permissions.

=head2 C<opg( )>

    $order->opg( );

Use this to change the order's time in force value to Market-On-Open or
Limit-On-Open orders.

This is not valid for orders marked for execution during extended hours.

=cut

sub _test_gfd {
    t::Utility::stash('MSFT') // skip_all('No cached equity instrument');
    my $order = t::Utility::stash('MSFT')->sell(3)->gfd();
    is(
        { $order->_dump(1) },
        {
            account => '--private--',
            instrument =>
                'https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/',
            price         => '5.00',
            quantity      => 3,
            ref_id        => '00000000-0000-0000-0000-000000000000',
            side          => 'sell',
            symbol        => 'MSFT',
            time_in_force => 'gfd',
            trigger       => 'immediate',
            type          => 'market'
        },
        'dump is correct'
    );
}

sub _test_gtc {
    t::Utility::stash('MSFT') // skip_all('No cached equity instrument');
    my $order = t::Utility::stash('MSFT')->sell(3)->gtc();
    is(
        { $order->_dump(1) },
        {
            account => '--private--',
            instrument =>
                'https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/',
            price         => '5.00',
            quantity      => 3,
            ref_id        => '00000000-0000-0000-0000-000000000000',
            side          => 'sell',
            symbol        => 'MSFT',
            time_in_force => 'gtc',
            trigger       => 'immediate',
            type          => 'market'
        },
        'dump is correct'
    );
}

sub _test_fok {
    t::Utility::stash('MSFT') // skip_all('No cached equity instrument');
    my $order = t::Utility::stash('MSFT')->sell(3)->fok();
    is(
        { $order->_dump(1) },
        {
            account => '--private--',
            instrument =>
                'https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/',
            price         => '5.00',
            quantity      => 3,
            ref_id        => '00000000-0000-0000-0000-000000000000',
            side          => 'sell',
            symbol        => 'MSFT',
            time_in_force => 'fok',
            trigger       => 'immediate',
            type          => 'market'
        },
        'dump is correct'
    );
}

sub _test_ioc {
    t::Utility::stash('MSFT') // skip_all('No cached equity instrument');
    my $order = t::Utility::stash('MSFT')->sell(3)->ioc();
    is(
        { $order->_dump(1) },
        {
            account => '--private--',
            instrument =>
                'https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/',
            price         => '5.00',
            quantity      => 3,
            ref_id        => '00000000-0000-0000-0000-000000000000',
            side          => 'sell',
            symbol        => 'MSFT',
            time_in_force => 'ioc',
            trigger       => 'immediate',
            type          => 'market'
        },
        'dump is correct'
    );
}

sub _test_opg {
    t::Utility::stash('MSFT') // skip_all('No cached equity instrument');
    my $order = t::Utility::stash('MSFT')->sell(3)->opg();
    is(
        { $order->_dump(1) },
        {
            account => '--private--',
            instrument =>
                'https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/',
            price         => '5.00',
            quantity      => 3,
            ref_id        => '00000000-0000-0000-0000-000000000000',
            side          => 'sell',
            symbol        => 'MSFT',
            time_in_force => 'opg',
            trigger       => 'immediate',
            type          => 'market'
        },
        'dump is correct'
    );
}

# Bonus!

=head2 C<pre_ipo( [...] )>

    $order->pre_ipo( );

Enables special pre-IPO submission of orders.

    $order->pre_ipo( 1 );
    $order->pre_ipo( 0 );

Enable or disables pre-IPO submission of orders.

=cut

sub _test_pre_ipo {
    t::Utility::stash('MSFT') // skip_all('No cached equity instrument');
    my $order = t::Utility::stash('MSFT')->sell(3)->pre_ipo();
    is(
        { $order->_dump(1) },
        {
            account => '--private--',
            instrument =>
                'https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/',
            price         => '5.00',
            quantity      => 3,
            ref_id        => '00000000-0000-0000-0000-000000000000',
            side          => 'sell',
            symbol        => 'MSFT',
            time_in_force => 'gfd',
            trigger       => 'immediate',
            type          => 'market',
            isPreIpo      => 'true'
        },
        'dump is correct (default)'
    );
    #
    $order = t::Utility::stash('MSFT')->sell(3)->pre_ipo();
    is(
        { $order->_dump(1) },
        {
            account => '--private--',
            instrument =>
                'https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/',
            price         => '5.00',
            quantity      => 3,
            ref_id        => '00000000-0000-0000-0000-000000000000',
            side          => 'sell',
            symbol        => 'MSFT',
            time_in_force => 'gfd',
            trigger       => 'immediate',
            type          => 'market',
            isPreIpo      => 'true'
        },
        'dump is correct (true)'
    );
}

=head2 C<override_day_trade_checks( [...] )>

    $order->override_day_trade_checks( );

Disables server side checks for possible day trade violations.

    $order->override_day_trade_checks( 1 );
    $order->override_day_trade_checks( 0 );

Enables or disables server side checks for possible day trade violations.

=cut

sub _test_override_day_trade_checks {
    t::Utility::stash('MSFT') // skip_all('No cached equity instrument');
    my $order = t::Utility::stash('MSFT')->sell(3)->override_day_trade_checks();
    is(
        { $order->_dump(1) },
        {
            account => '--private--',
            instrument =>
                'https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/',
            price                     => '5.00',
            quantity                  => 3,
            ref_id                    => '00000000-0000-0000-0000-000000000000',
            side                      => 'sell',
            symbol                    => 'MSFT',
            time_in_force             => 'gfd',
            trigger                   => 'immediate',
            type                      => 'market',
            override_day_trade_checks => 'true'
        },
        'dump is correct (default)'
    );
    #
    $order = t::Utility::stash('MSFT')->sell(3)->override_day_trade_checks;
    is(
        { $order->_dump(1) },
        {
            account => '--private--',
            instrument =>
                'https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/',
            price                     => '5.00',
            quantity                  => 3,
            ref_id                    => '00000000-0000-0000-0000-000000000000',
            side                      => 'sell',
            symbol                    => 'MSFT',
            time_in_force             => 'gfd',
            trigger                   => 'immediate',
            type                      => 'market',
            override_day_trade_checks => 'true'
        },
        'dump is correct (true)'
    );
}

=head2 C<override_dtbp_checks( )>

    $order->override_dtbp_checks( );

Disables server side checks for possible day trade buying power violations.

    $order->override_dtbp_checks( 1 );
    $order->override_dtbp_checks( 0 );

Enables or disables server side checks for possible day trade buying power
violations.

=cut

sub _test_override_dtbp_checks {
    t::Utility::stash('MSFT') // skip_all('No cached equity instrument');
    my $order = t::Utility::stash('MSFT')->sell(3)->override_dtbp_checks();
    is(
        { $order->_dump(1) },
        {
            account => '--private--',
            instrument =>
                'https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/',
            price                => '5.00',
            quantity             => 3,
            ref_id               => '00000000-0000-0000-0000-000000000000',
            side                 => 'sell',
            symbol               => 'MSFT',
            time_in_force        => 'gfd',
            trigger              => 'immediate',
            type                 => 'market',
            override_dtbp_checks => 'true'
        },
        'dump is correct (default)'
    );
    #
    $order = t::Utility::stash('MSFT')->sell(3)->override_dtbp_checks;
    is(
        { $order->_dump(1) },
        {
            account => '--private--',
            instrument =>
                'https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/',
            price                => '5.00',
            quantity             => 3,
            ref_id               => '00000000-0000-0000-0000-000000000000',
            side                 => 'sell',
            symbol               => 'MSFT',
            time_in_force        => 'gfd',
            trigger              => 'immediate',
            type                 => 'market',
            override_dtbp_checks => 'true'
        },
        'dump is correct (true)'
    );
}

=head2 C<extended_hours( [...] )>

    $order->extended_hours( )

Enables order execution during pre- and after-hours.

    $order->extended_hours( 1 );
    $order->extended_hours( 0 );

Enables or disables execution during pre- and after-hours.

Note that the market orders may be converted to a limit orders (at or near the
current price) by the API server's back end. You would be wise to set your own
limit price instead.

=cut

sub _test_extended_hours {
    t::Utility::stash('MSFT') // skip_all('No cached equity instrument');
    my $order = t::Utility::stash('MSFT')->sell(3)->extended_hours;
    is(
        { $order->_dump(1) },
        {
            account => '--private--',
            instrument =>
                'https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/',
            price          => '5.00',
            quantity       => 3,
            ref_id         => '00000000-0000-0000-0000-000000000000',
            side           => 'sell',
            symbol         => 'MSFT',
            time_in_force  => 'gfd',
            trigger        => 'immediate',
            type           => 'market',
            extended_hours => 'true'
        },
        'dump is correct (default)'
    );
    #
    $order = t::Utility::stash('MSFT')->sell(3)->extended_hours;
    is(
        { $order->_dump(1) },
        {
            account => '--private--',
            instrument =>
                'https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/',
            price          => '5.00',
            quantity       => 3,
            ref_id         => '00000000-0000-0000-0000-000000000000',
            side           => 'sell',
            symbol         => 'MSFT',
            time_in_force  => 'gfd',
            trigger        => 'immediate',
            type           => 'market',
            extended_hours => 'true'
        },
        'dump is correct (true)'
    );
}
#
# Do it!

=head2 C<submit( )>

    $order->submit( );

Use this to finally submit the order. On success, your builder is replaced by a
new Finance::Robinhood::Equity::Order object is returned. On failure, your
builder object is replaced by a Finance::Robinhood::Error object.

=cut

sub submit ($s) {
    $_[0]
        = $s->robinhood->_req( POST => 'https://api.robinhood.com/orders/', form => { $s->_dump }, )
        ->as('Finance::Robinhood::Equity::Order');
}

sub _test_submit {
    t::Utility::stash('MSFT') // skip_all('No cached equity instrument');
    {
        my $order = t::Utility::stash('MSFT')->buy(4)->gtc->limit(4.01);
        isa_ok( $order->submit, 'Finance::Robinhood::Equity::Order' );
        $order->cancel;
    }
    {
        my $order = t::Utility::stash('MSFT')->buy(4)->gtc->limit(4.01)->stop(4000.30)
            ->trailing_stop(1000.99);
        isa_ok( $order->submit, 'Finance::Robinhood::Equity::Order' );
        $order->cancel;
    }
}

# Advanced order tests
sub _test_z_advanced_orders {
    t::Utility::stash('MSFT') // skip_all('No cached equity instrument');

    # Stop limit
    my $order = t::Utility::stash('MSFT')->sell(3)->stop('4.00')->limit(3.55);
    is(
        { $order->_dump(1) },
        {
            account => '--private--',
            instrument =>
                'https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/',
            price         => '3.55',
            stop_price    => '4.00',
            quantity      => 3,
            ref_id        => '00000000-0000-0000-0000-000000000000',
            side          => 'sell',
            symbol        => 'MSFT',
            time_in_force => 'gfd',
            trigger       => 'stop',
            type          => 'limit'
        },
        'stop limit'
    );
    $order = t::Utility::stash('MSFT')->sell(3)->stop('4.00')->gtc;
    is(
        { $order->_dump(1) },
        {
            account => '--private--',
            instrument =>
                'https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/',
            price         => '5.00',
            stop_price    => '4.00',
            quantity      => 3,
            ref_id        => '00000000-0000-0000-0000-000000000000',
            side          => 'sell',
            symbol        => 'MSFT',
            time_in_force => 'gtc',
            trigger       => 'stop',
            type          => 'market'
        },
        'stop loss gtc'
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
