package Finance::Robinhood::Equity::OrderBuilder;

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
       account       => "https://api.robinhood.com/accounts/XXXXXXXXXX/",
       instrument    => "https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/",
       price         => "111.700000", # Automatically grabs last trade price quote
       quantity      => 4, # Actually the number of shares you requested
       side          => "buy", # Or sell
       symbol        => "MSFT", # Grabs ticker symbol automatically from instrument object
       time_in_force => "gfd",
       trigger       => "immediate",
       type          => "market"
     }

You may chain together several methods to generate and submit advanced order
types such as stop limits that are held up to 90 days:

    $order->stop(24.50)->gtc->limit->submit;

=cut

our $VERSION = '0.92_002';
use Mojo::Base-base, -signatures;
use Finance::Robinhood::Equity::Order;
use Finance::Robinhood::Utilities qw[gen_uuid];

sub _test__init {
    my $rh   = t::Utility::rh_instance(1);
    my $msft = $rh->equity_instrument_by_symbol('MSFT');
    t::Utility::stash( 'MSFT', $msft );    #  Store it for later
    isa_ok( $msft->buy(3),  __PACKAGE__ );
    isa_ok( $msft->sell(3), __PACKAGE__ );
}
#
has _rh => undef => weak => 1;

=head1 METHODS


=head2 C<account( ... )>

Expects a Finance::Robinhood::Equity::Account object.

=head2 C<instrument( ... )>

Expects a Finance::Robinhood::Equity::Instrument object.

=head2 C<quantity( ... )>

Expects a whole number of shares.

=cut

has _account    => undef;    # => weak => 1;
has _instrument => undef;    # => weak => 1;
has [ 'quantity', 'price' ];
#

=head2 C<stop( ... )>

    $order->stop( 45.20 );

Expects a price.

Use this to create stop limit or stop loss orders.

=cut

sub stop ( $s, $price ) {
    $s->with_roles('Finance::Robinhood::Equity::OrderBuilder::Role::Stop')->stop($price);
}
{

    package Finance::Robinhood::Equity::OrderBuilder::Role::Stop;
    use Mojo::Base-role, -signatures;
    has stop     => 0;
    around _dump => sub ( $orig, $s, $test = 0 ) {
        my %data = $orig->( $s, $test );
        ( %data, stop_price => $s->stop, trigger => 'stop' );
    };
    1;
}

sub _test_stop {
    t::Utility::stash('MSFT') // skip_all('No cached equity instrument');
    my $order = t::Utility::stash('MSFT')->buy(3)->stop(3.40);
    is(
        { $order->_dump(1) },
        {
            account => "--private--",
            instrument =>
                "https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/",
            price         => "5.00",
            quantity      => 3,
            ref_id        => "00000000-0000-0000-0000-000000000000",
            side          => "buy",
            symbol        => "MSFT",
            time_in_force => "gfd",
            trigger       => "stop",
            stop_price    => 3.40,
            type          => "market",
        },
        'dump is correct'
    );
}

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
    $s->with_roles('Finance::Robinhood::Equity::OrderBuilder::Role::Limit')->limit($price);
}
{

    package Finance::Robinhood::Equity::OrderBuilder::Role::Limit;
    use Mojo::Base-role, -signatures;
    has limit    => 0;
    around _dump => sub ( $orig, $s, $test = 0 ) {
        my %data = $orig->( $s, $test );
        ( %data, price => $s->limit, type => 'limit' );
    };
}

sub _test_limit {
    t::Utility::stash('MSFT') // skip_all('No cached equity instrument');
    my $order = t::Utility::stash('MSFT')->buy(3)->limit(3.40);
    is(
        { $order->_dump(1) },
        {
            account => "--private--",
            instrument =>
                "https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/",
            price         => 3.40,
            quantity      => 3,
            ref_id        => "00000000-0000-0000-0000-000000000000",
            side          => "buy",
            symbol        => "MSFT",
            time_in_force => "gfd",
            trigger       => "immediate",
            type          => "limit",
        },
        'dump is correct'
    );
}

sub market($s) {
    $s->with_roles('Finance::Robinhood::Equity::OrderBuilder::Role::Market');
}
{

    package Finance::Robinhood::Equity::OrderBuilder::Role::Market;
    use Mojo::Base-role, -signatures;
    around _dump => sub ( $orig, $s, $test = 0 ) {
        my %data = $orig->( $s, $test );
        ( %data, type => 'market' );
    };
}

sub _test_market {
    t::Utility::stash('MSFT') // skip_all('No cached equity instrument');
    my $order = t::Utility::stash('MSFT')->sell(3)->market();
    is(
        { $order->_dump(1) },
        {
            account => "--private--",
            instrument =>
                "https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/",
            price         => '5.00',
            quantity      => 3,
            ref_id        => "00000000-0000-0000-0000-000000000000",
            side          => "sell",
            symbol        => "MSFT",
            time_in_force => "gfd",
            trigger       => "immediate",
            type          => "market",
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
    $s->with_roles('Finance::Robinhood::Equity::OrderBuilder::Role::Buy');
    $s->quantity($quantity);
}
{

    package Finance::Robinhood::Equity::OrderBuilder::Role::Buy;
    use Mojo::Base-role, -signatures;
    around _dump => sub ( $orig, $s, $test = 0 ) {
        my %data = $orig->( $s, $test );
        ( %data, side => 'buy' );
    };
}

sub _test_buy {
    t::Utility::stash('MSFT') // skip_all('No cached equity instrument');
    my $order = t::Utility::stash('MSFT')->sell(32)->buy(3);
    is(
        { $order->_dump(1) },
        {
            account => "--private--",
            instrument =>
                "https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/",
            price         => '5.00',
            quantity      => 3,
            ref_id        => "00000000-0000-0000-0000-000000000000",
            side          => "buy",
            symbol        => "MSFT",
            time_in_force => "gfd",
            trigger       => "immediate",
            type          => "market",
        },
        'dump is correct'
    );
}

sub sell ( $s, $quantity = $s->quantity ) {
    $s->with_roles('Finance::Robinhood::Equity::OrderBuilder::Role::Sell');
    $s->quantity($quantity);
}
{

    package Finance::Robinhood::Equity::OrderBuilder::Role::Sell;
    use Mojo::Base-role, -signatures;
    around _dump => sub ( $orig, $s, $test = 0 ) {
        my %data = $orig->( $s, $test );
        ( %data, side => 'sell' );
    };
}

sub _test_sell {
    t::Utility::stash('MSFT') // skip_all('No cached equity instrument');
    my $order = t::Utility::stash('MSFT')->buy(32)->sell(3);
    is(
        { $order->_dump(1) },
        {
            account => "--private--",
            instrument =>
                "https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/",
            price         => '5.00',
            quantity      => 3,
            ref_id        => "00000000-0000-0000-0000-000000000000",
            side          => "sell",
            symbol        => "MSFT",
            time_in_force => "gfd",
            trigger       => "immediate",
            type          => "market",
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

sub gfd($s) {
    $s->with_roles('Finance::Robinhood::Equity::OrderBuilder::Role::GFD');
}
{

    package Finance::Robinhood::Equity::OrderBuilder::Role::GFD;
    use Mojo::Base-role, -signatures;
    around _dump => sub ( $orig, $s, $test = 0 ) {
        my %data = $orig->( $s, $test );
        ( %data, time_in_force => 'gfd' );
    };
}

sub _test_gfd {
    t::Utility::stash('MSFT') // skip_all('No cached equity instrument');
    my $order = t::Utility::stash('MSFT')->sell(3)->gfd();
    is(
        { $order->_dump(1) },
        {
            account => "--private--",
            instrument =>
                "https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/",
            price         => '5.00',
            quantity      => 3,
            ref_id        => "00000000-0000-0000-0000-000000000000",
            side          => "sell",
            symbol        => "MSFT",
            time_in_force => "gfd",
            trigger       => "immediate",
            type          => "market",
        },
        'dump is correct'
    );
}

sub gtc($s) {
    $s->with_roles('Finance::Robinhood::Equity::OrderBuilder::Role::GTC');
}
{

    package Finance::Robinhood::Equity::OrderBuilder::Role::GTC;
    use Mojo::Base-role, -signatures;
    around _dump => sub ( $orig, $s, $test = 0 ) {
        my %data = $orig->( $s, $test );
        ( %data, time_in_force => 'gtc' );
    };
}

sub _test_gtc {
    t::Utility::stash('MSFT') // skip_all('No cached equity instrument');
    my $order = t::Utility::stash('MSFT')->sell(3)->gtc();
    is(
        { $order->_dump(1) },
        {
            account => "--private--",
            instrument =>
                "https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/",
            price         => '5.00',
            quantity      => 3,
            ref_id        => "00000000-0000-0000-0000-000000000000",
            side          => "sell",
            symbol        => "MSFT",
            time_in_force => "gtc",
            trigger       => "immediate",
            type          => "market",
        },
        'dump is correct'
    );
}

sub fok($s) {
    $s->with_roles('Finance::Robinhood::Equity::OrderBuilder::Role::FOK');
}
{

    package Finance::Robinhood::Equity::OrderBuilder::Role::FOK;
    use Mojo::Base-role, -signatures;
    around _dump => sub ( $orig, $s, $test = 0 ) {
        my %data = $orig->( $s, $test );
        ( %data, time_in_force => 'fok' );
    };
}

sub _test_fok {
    t::Utility::stash('MSFT') // skip_all('No cached equity instrument');
    my $order = t::Utility::stash('MSFT')->sell(3)->fok();
    is(
        { $order->_dump(1) },
        {
            account => "--private--",
            instrument =>
                "https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/",
            price         => '5.00',
            quantity      => 3,
            ref_id        => "00000000-0000-0000-0000-000000000000",
            side          => "sell",
            symbol        => "MSFT",
            time_in_force => "fok",
            trigger       => "immediate",
            type          => "market",
        },
        'dump is correct'
    );
}

sub ioc($s) {
    $s->with_roles('Finance::Robinhood::Equity::OrderBuilder::Role::IOC');
}
{

    package Finance::Robinhood::Equity::OrderBuilder::Role::IOC;
    use Mojo::Base-role, -signatures;
    around _dump => sub ( $orig, $s, $test = 0 ) {
        my %data = $orig->( $s, $test );
        ( %data, time_in_force => 'ioc' );
    };
}

sub _test_ioc {
    t::Utility::stash('MSFT') // skip_all('No cached equity instrument');
    my $order = t::Utility::stash('MSFT')->sell(3)->ioc();
    is(
        { $order->_dump(1) },
        {
            account => "--private--",
            instrument =>
                "https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/",
            price         => '5.00',
            quantity      => 3,
            ref_id        => "00000000-0000-0000-0000-000000000000",
            side          => "sell",
            symbol        => "MSFT",
            time_in_force => "ioc",
            trigger       => "immediate",
            type          => "market",
        },
        'dump is correct'
    );
}

sub opg($s) {
    $s->with_roles('Finance::Robinhood::Equity::OrderBuilder::Role::OPG');
}
{

    package Finance::Robinhood::Equity::OrderBuilder::Role::OPG;
    use Mojo::Base-role, -signatures;
    around _dump => sub ( $orig, $s, $test = 0 ) {
        my %data = $orig->( $s, $test );
        ( %data, time_in_force => 'opg' );
    };
}

sub _test_opg {
    t::Utility::stash('MSFT') // skip_all('No cached equity instrument');
    my $order = t::Utility::stash('MSFT')->sell(3)->opg();
    is(
        { $order->_dump(1) },
        {
            account => "--private--",
            instrument =>
                "https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/",
            price         => '5.00',
            quantity      => 3,
            ref_id        => "00000000-0000-0000-0000-000000000000",
            side          => "sell",
            symbol        => "MSFT",
            time_in_force => "opg",
            trigger       => "immediate",
            type          => "market",
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

sub pre_ipo ( $s, $bool = 1 ) {
    $s->with_roles('Finance::Robinhood::Equity::OrderBuilder::Role::IPO');
    $s->_pre_ipo($bool);
}
{

    package Finance::Robinhood::Equity::OrderBuilder::Role::IPO;
    use Mojo::Base-role, -signatures;
    has _pre_ipo => 1;
    around _dump => sub ( $orig, $s, $test = 0 ) {
        my %data = $orig->( $s, $test );
        ( %data, isPreIpo => $s->_pre_ipo ? 'true' : 'false' );
    };
}

sub _test_pre_ipo {
    t::Utility::stash('MSFT') // skip_all('No cached equity instrument');
    my $order = t::Utility::stash('MSFT')->sell(3)->pre_ipo();
    is(
        { $order->_dump(1) },
        {
            account => "--private--",
            instrument =>
                "https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/",
            price         => '5.00',
            quantity      => 3,
            ref_id        => "00000000-0000-0000-0000-000000000000",
            side          => "sell",
            symbol        => "MSFT",
            time_in_force => "gfd",
            trigger       => "immediate",
            type          => "market",
            isPreIpo      => 'true'
        },
        'dump is correct (default)'
    );
    #
    $order = t::Utility::stash('MSFT')->sell(3)->pre_ipo(1);
    is(
        { $order->_dump(1) },
        {
            account => "--private--",
            instrument =>
                "https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/",
            price         => '5.00',
            quantity      => 3,
            ref_id        => "00000000-0000-0000-0000-000000000000",
            side          => "sell",
            symbol        => "MSFT",
            time_in_force => "gfd",
            trigger       => "immediate",
            type          => "market",
            isPreIpo      => 'true'
        },
        'dump is correct (true)'
    );
    #
    $order = t::Utility::stash('MSFT')->sell(3)->pre_ipo(0);
    is(
        { $order->_dump(1) },
        {
            account => "--private--",
            instrument =>
                "https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/",
            price         => '5.00',
            quantity      => 3,
            ref_id        => "00000000-0000-0000-0000-000000000000",
            side          => "sell",
            symbol        => "MSFT",
            time_in_force => "gfd",
            trigger       => "immediate",
            type          => "market",
            isPreIpo      => 'false'
        },
        'dump is correct (false)'
    );
}

=head2 C<override_day_trade_checks( [...] )>

    $order->override_day_trade_checks( );

Disables server side checks for possible day trade violations.

    $order->override_day_trade_checks( 1 );
    $order->override_day_trade_checks( 0 );

Enables or disables server side checks for possible day trade violations.

=cut

sub override_day_trade_checks ( $s, $bool = 1 ) {
    $s->with_roles('Finance::Robinhood::Equity::OrderBuilder::Role::IgnoreDT');
    $s->_overridePDT($bool);
}
{

    package Finance::Robinhood::Equity::OrderBuilder::Role::IgnoreDT;
    use Mojo::Base-role, -signatures;
    has _overridePDT => 1;
    around _dump     => sub ( $orig, $s, $test = 0 ) {
        my %data = $orig->( $s, $test );
        ( %data, override_day_trade_checks => $s->_overridePDT ? 'true' : 'false' );
    };
}

sub _test_override_day_trade_checks {
    t::Utility::stash('MSFT') // skip_all('No cached equity instrument');
    my $order = t::Utility::stash('MSFT')->sell(3)->override_day_trade_checks();
    is(
        { $order->_dump(1) },
        {
            account => "--private--",
            instrument =>
                "https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/",
            price                     => '5.00',
            quantity                  => 3,
            ref_id                    => "00000000-0000-0000-0000-000000000000",
            side                      => "sell",
            symbol                    => "MSFT",
            time_in_force             => "gfd",
            trigger                   => "immediate",
            type                      => "market",
            override_day_trade_checks => 'true'
        },
        'dump is correct (default)'
    );
    #
    $order = t::Utility::stash('MSFT')->sell(3)->override_day_trade_checks(1);
    is(
        { $order->_dump(1) },
        {
            account => "--private--",
            instrument =>
                "https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/",
            price                     => '5.00',
            quantity                  => 3,
            ref_id                    => "00000000-0000-0000-0000-000000000000",
            side                      => "sell",
            symbol                    => "MSFT",
            time_in_force             => "gfd",
            trigger                   => "immediate",
            type                      => "market",
            override_day_trade_checks => 'true'
        },
        'dump is correct (true)'
    );
    #
    $order = t::Utility::stash('MSFT')->sell(3)->override_day_trade_checks(0);
    is(
        { $order->_dump(1) },
        {
            account => "--private--",
            instrument =>
                "https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/",
            price                     => '5.00',
            quantity                  => 3,
            ref_id                    => "00000000-0000-0000-0000-000000000000",
            side                      => "sell",
            symbol                    => "MSFT",
            time_in_force             => "gfd",
            trigger                   => "immediate",
            type                      => "market",
            override_day_trade_checks => 'false'
        },
        'dump is correct (false)'
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

sub override_dtbp_checks ( $s, $bool = 1 ) {
    $s->with_roles('Finance::Robinhood::Equity::OrderBuilder::Role::IgnoreDTBP');
    $s->_ignore_dtbp($bool);
}
{

    package Finance::Robinhood::Equity::OrderBuilder::Role::IgnoreDTBP;
    use Mojo::Base-role, -signatures;
    has _ignore_dtbp => 1;
    around _dump     => sub ( $orig, $s, $test = 0 ) {
        my %data = $orig->( $s, $test );
        ( %data, override_dtbp_checks => $s->_ignore_dtbp ? 'true' : 'false' );
    };
}

sub _test_override_dtbp_checks {
    t::Utility::stash('MSFT') // skip_all('No cached equity instrument');
    my $order = t::Utility::stash('MSFT')->sell(3)->override_dtbp_checks();
    is(
        { $order->_dump(1) },
        {
            account => "--private--",
            instrument =>
                "https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/",
            price                => '5.00',
            quantity             => 3,
            ref_id               => "00000000-0000-0000-0000-000000000000",
            side                 => "sell",
            symbol               => "MSFT",
            time_in_force        => "gfd",
            trigger              => "immediate",
            type                 => "market",
            override_dtbp_checks => 'true'
        },
        'dump is correct (default)'
    );
    #
    $order = t::Utility::stash('MSFT')->sell(3)->override_dtbp_checks(1);
    is(
        { $order->_dump(1) },
        {
            account => "--private--",
            instrument =>
                "https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/",
            price                => '5.00',
            quantity             => 3,
            ref_id               => "00000000-0000-0000-0000-000000000000",
            side                 => "sell",
            symbol               => "MSFT",
            time_in_force        => "gfd",
            trigger              => "immediate",
            type                 => "market",
            override_dtbp_checks => 'true'
        },
        'dump is correct (true)'
    );
    #
    $order = t::Utility::stash('MSFT')->sell(3)->override_dtbp_checks(0);
    is(
        { $order->_dump(1) },
        {
            account => "--private--",
            instrument =>
                "https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/",
            price                => '5.00',
            quantity             => 3,
            ref_id               => "00000000-0000-0000-0000-000000000000",
            side                 => "sell",
            symbol               => "MSFT",
            time_in_force        => "gfd",
            trigger              => "immediate",
            type                 => "market",
            override_dtbp_checks => 'false'
        },
        'dump is correct (false)'
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

sub extended_hours ( $s, $bool = 1 ) {
    $s->with_roles('Finance::Robinhood::Equity::OrderBuilder::Role::ExtHours');
    $s->_ext_hrs($bool);
}
{

    package Finance::Robinhood::Equity::OrderBuilder::Role::ExtHours;
    use Mojo::Base-role, -signatures;
    has _ext_hrs => 1;
    around _dump => sub ( $orig, $s, $test = 0 ) {
        my %data = $orig->( $s, $test );
        ( %data, extended_hours => $s->_ext_hrs ? 'true' : 'false' );
    };
}

sub _test_extended_hours {
    t::Utility::stash('MSFT') // skip_all('No cached equity instrument');
    my $order = t::Utility::stash('MSFT')->sell(3)->extended_hours();
    is(
        { $order->_dump(1) },
        {
            account => "--private--",
            instrument =>
                "https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/",
            price          => '5.00',
            quantity       => 3,
            ref_id         => "00000000-0000-0000-0000-000000000000",
            side           => "sell",
            symbol         => "MSFT",
            time_in_force  => "gfd",
            trigger        => "immediate",
            type           => "market",
            extended_hours => 'true'
        },
        'dump is correct (default)'
    );
    #
    $order = t::Utility::stash('MSFT')->sell(3)->extended_hours(1);
    is(
        { $order->_dump(1) },
        {
            account => "--private--",
            instrument =>
                "https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/",
            price          => '5.00',
            quantity       => 3,
            ref_id         => "00000000-0000-0000-0000-000000000000",
            side           => "sell",
            symbol         => "MSFT",
            time_in_force  => "gfd",
            trigger        => "immediate",
            type           => "market",
            extended_hours => 'true'
        },
        'dump is correct (true)'
    );
    #
    $order = t::Utility::stash('MSFT')->sell(3)->extended_hours(0);
    is(
        { $order->_dump(1) },
        {
            account => "--private--",
            instrument =>
                "https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/",
            price          => '5.00',
            quantity       => 3,
            ref_id         => "00000000-0000-0000-0000-000000000000",
            side           => "sell",
            symbol         => "MSFT",
            time_in_force  => "gfd",
            trigger        => "immediate",
            type           => "market",
            extended_hours => 'false'
        },
        'dump is correct (false)'
    );
}

# Do it!

=head2 C<submit( )>

    $order->submit( );

Use this to finally submit the order. On success, your builder is replaced by a
new Finance::Robinhood::Equity::Order object is returned. On failure, your
builder object is replaced by a Finance::Robinhood::Error object.

=cut

sub submit ($s) {
    my $res = $s->_rh->_post( 'https://api.robinhood.com/orders/', $s->_dump );
    $_[0]
        = $res->is_success
        ? Finance::Robinhood::Equity::Order->new( _rh => $s->_rh, %{ $res->json } )
        : Finance::Robinhood::Error->new(
        $res->is_server_error ? ( details => $res->message ) : $res->json );
}

sub _test_submit {
    t::Utility::stash('MSFT') // skip_all('No cached equity instrument');
    my $order = t::Utility::stash('MSFT')->buy(4)->extended_hours->gtc->limit(4.01);
    isa_ok( $order->submit, 'Finance::Robinhood::Equity::Order' );
    $order->cancel;
}

# Do it! (And debug it...)
sub _dump ( $s, $test = 0 ) {
    (    # Defaults
        quantity      => $s->quantity,
        trigger       => 'immediate',
        type          => 'market',
        instrument    => $s->_instrument->url,
        symbol        => $s->_instrument->symbol,
        account       => $test ? '--private--' : $s->_account->url,
        time_in_force => 'gfd',
        price         => $test ? '5.00' : ( $s->price // $s->_instrument->quote->last_trade_price ),
        ref_id        => $test ? '00000000-0000-0000-0000-000000000000' : gen_uuid()
    )
}

# Advanced order tests
sub _test_z_advanced_orders {
    t::Utility::stash('MSFT') // skip_all('No cached equity instrument');

    # Stop limit
    my $order = t::Utility::stash('MSFT')->sell(3)->stop('4.00')->limit(3.55);
    is(
        { $order->_dump(1) },
        {
            account => "--private--",
            instrument =>
                "https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/",
            price         => '3.55',
            stop_price    => '4.00',
            quantity      => 3,
            ref_id        => "00000000-0000-0000-0000-000000000000",
            side          => "sell",
            symbol        => "MSFT",
            time_in_force => "gfd",
            trigger       => "stop",
            type          => "limit",
        },
        'stop limit'
    );
    $order = t::Utility::stash('MSFT')->sell(3)->stop('4.00')->gtc;
    is(
        { $order->_dump(1) },
        {
            account => "--private--",
            instrument =>
                "https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/",
            price         => '5.00',
            stop_price    => '4.00',
            quantity      => 3,
            ref_id        => "00000000-0000-0000-0000-000000000000",
            side          => "sell",
            symbol        => "MSFT",
            time_in_force => "gtc",
            trigger       => "stop",
            type          => "market",
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
