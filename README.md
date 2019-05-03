[![Build Status](https://travis-ci.org/sanko/Finance-Robinhood.svg?branch=master)](https://travis-ci.org/sanko/Finance-Robinhood) [![MetaCPAN Release](https://badge.fury.io/pl/Finance-Robinhood.svg)](https://metacpan.org/release/Finance-Robinhood)
# NAME

Finance::Robinhood - Trade Stocks, ETFs, Options, and Cryptocurrency without
Commission

# SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new();

# METHODS

Finance::Robinhood wraps several APIs. There are parts of this package that
will not apply because your account does not have access to certain features.

## `new( )`

Robinhood requires an authorization token for most API calls. To get this
token, you must log in with your username and password. But we'll get into that
later. For now, let's create a client object...

    # You can look up some basic instrument data with this
    my $rh = Finance::Robinhood->new();

A new Finance::Robinhood object is created without credentials. Before you can
buy or sell or do almost anything else, you must [log in](#login).

### `token =` ...>

If you have previously authorized this package to access your account, passing
the OAuth2 tokens here will prevent you from having to `login( ... )` with
your user data.

These tokens should be kept private.

### `device_token =` ...>

If you have previously authorized this package to access your account, passing
the assigned device ID here will prevent you from having to authorize it again
upon `login( ... )`.

Like authorization tokens, this UUID should be kept private.

## `login( ... )`

    my $rh = Finance::Robinhood->new()->login($user, $pass);

A new Finance::Robinhood object is created without credentials. Before you can
buy or sell or do almost anything else, you must [log in](#login).

### `mfa_callback =` ...>

    my $rh = Finance::Robinhood->new()->login($user, $pass, mfa_callback => sub {
        # Do something like pop open an inputbox in TK, read from shell or whatever
    } );

If you have MFA enabled, you may (or must) also pass a callback. When the code
is called, a ref will be passed that will contain `mfa_required` (a boolean
value) and `mfa_type` which might be `app`, `sms`, etc. Your return value
must be the MFA code.

### `mfa_code =` ...>

    my $rh = Finance::Robinhood->new()->login($user, $pass, mfa_code => 980385);

If you already know the MFA code (for example if you have MFA enabled through
an app), you can pass that code directly and log in.

### `challenge_callback =` ...>

When logging in with a new client, you are required to authorize it to access
your account.

This callback should return the six digit code sent to you via sms or email.

## `device_token( [...] )`

        my $token = $rh->device_token;
        # Store it

To prevent your client from having to be reauthorized to access your account
every time it is run, call this method which returns the device token which
should be passed to `new( ... )`.

        # Reload token from storage
        my $device = ...;
        $rh->device_token($device);

To prevent your client from having to reauthorize every time it is run, call
this to reload the same ID.

## `oauth2_token( [...] )`

        my $token $rh->oauth2_token;
        # Store it

To prevent your client from having to log in every time it is run, call this
method which returns the authorization tokens which should be passed to `new(
... )`.

This method returns a Finance::Robinhood::OAuth2::Token object.

        # Load token object from storage
        my $oauth = ...;
        $rh->oauth2_token($token);

Reload OAuth2 tokens. You can skip logging in with your username and password
if this is successful.

This method expects a Finance::Robinhood::OAuth2::Token object.

## `search( ... )`

    my $results = $rh->search('microsoft');

Returns a set of search results as a Finance::Robinhood::Search object.

You do not need to be logged in for this to work.

## `news( ... )`

    my $news = $rh->news('MSFT');
    my $news = $rh->news('1072fc76-1862-41ab-82c2-485837590762'); # Forex - USD

An iterator containing Finance::Robinhood::News objects is returned.

## `feed( )`

    my $feed = $rh->feed();

An iterator containing Finance::Robinhood::News objects is returned. This list
will be filled with news related to instruments in your watchlist and
portfolio.

You need to be logged in for this to work.

## `notifications( )`

    my $cards = $rh->notifications();

An iterator containing Finance::Robinhood::Notification objects is returned.

You need to be logged in for this to work.

## `notification_by_id( ... )`

    my $card = $rh->notification_by_id($id);

Returns a Finance::Robinhood::Notification object. You need to be logged in for
this to work.

# EQUITY METHODS

## `equity_instruments( )`

    my $instruments = $rh->equity_instruments();

Returns an iterator containing equity instruments.

You may restrict, search, or modify the list of instruments returned with the
following optional arguments:

- `symbol` - Ticker symbol

        my $msft = $rh->equity_instruments(symbol => 'MSFT')->next;

    By the way, `instrument_by_symbol( )` exists as sugar. It returns the
    instrument itself rather than an iterator object with a single element.

- `query` - Keyword search

        my @solar = $rh->equity_instruments(query => 'solar')->all;

- `ids` - List of instrument ids

        my ( $msft, $tsla )
            = $rh->equity_instruments(
            ids => [ '50810c35-d215-4866-9758-0ada4ac79ffa', 'e39ed23a-7bd1-4587-b060-71988d9ef483' ] )
            ->all;

    If you happen to know/store instrument ids, quickly get full instrument objects
    this way.

## `equity_instrument_by_symbol( ... )`

    my $instrument = $rh->equity_instrument_by_symbol('MSFT');

Searches for an equity instrument by ticker symbol and returns a
Finance::Robinhood::Equity::Instrument.

## `equity_instrument_by_id( ... )`

    my $instrument = $rh->equity_instrument_by_id('50810c35-d215-4866-9758-0ada4ac79ffa');

Searches for a single of equity instrument by its instrument id and returns a
Finance::Robinhood::Equity::Instrument object.

## `equity_instruments_by_id( ... )`

    my $instrument = $rh->equity_instruments_by_id('50810c35-d215-4866-9758-0ada4ac79ffa');

Searches for a list of equity instruments by their instrument ids and returns a
list of Finance::Robinhood::Equity::Instrument objects.

## `equity_orders( [...] )`

    my $orders = $rh->equity_orders();

An iterator containing Finance::Robinhood::Equity::Order objects is returned.
You need to be logged in for this to work.

    my $orders = $rh->equity_orders(instrument => $msft);

If you would only like orders after a certain date, you can do that!

    my $orders = $rh->equity_orders(after => Time::Moment->now->minus_days(7));
    # Also accepts ISO 8601

If you would only like orders before a certain date, you can do that!

    my $orders = $rh->equity_orders(before => Time::Moment->now->minus_years(2));
    # Also accepts ISO 8601

## `equity_order_by_id( ... )`

    my $order = $rh->equity_order_by_id($id);

Returns a Finance::Robinhood::Equity::Order object. You need to be logged in
for this to work.

## `equity_accounts( )`

    my $accounts = $rh->equity_accounts();

An iterator containing Finance::Robinhood::Equity::Account objects is returned.
You need to be logged in for this to work.

## `equity_account_by_account_number( ... )`

    my $account = $rh->equity_account_by_account_number($id);

Returns a Finance::Robinhood::Equity::Account object. You need to be logged in
for this to work.

## `equity_portfolios( )`

    my $equity_portfolios = $rh->equity_portfolios();

An iterator containing Finance::Robinhood::Equity::Account::Portfolio objects
is returned. You need to be logged in for this to work.

## `equity_watchlists( )`

    my $watchlists = $rh->equity_watchlists();

An iterator containing Finance::Robinhood::Equity::Watchlist objects is
returned. You need to be logged in for this to work.

## `equity_watchlist_by_name( ... )`

    my $watchlist = $rh->equity_watchlist_by_name('Default');

Returns a Finance::Robinhood::Equity::Watchlist object. You need to be logged
in for this to work.

## `equity_fundamentals( )`

    my $fundamentals = $rh->equity_fundamentals('MSFT', 'TSLA');

An iterator containing Finance::Robinhood::Equity::Fundamentals objects is
returned.

You do not need to be logged in for this to work.

## `equity_markets( )`

    my $markets = $rh->equity_markets()->all;

Returns an iterator containing Finance::Robinhood::Equity::Market objects.

## `equity_market_by_mic( )`

    my $markets = $rh->equity_market_by_mic('XNAS'); # NASDAQ

Locates an exchange by its Market Identifier Code and returns a
Finance::Robinhood::Equity::Market object.

See also https://en.wikipedia.org/wiki/Market\_Identifier\_Code

## `top_movers( [...] )`

    my $instruments = $rh->top_movers( );

Returns an iterator containing members of the S&P 500 with large price changes
during market hours as Finance::Robinhood::Equity::Movers objects.

You may define whether or not you want the best or worst performing instruments
with the following option:

- `direction` - `up` or `down`

        $rh->top_movers( direction => 'up' );

    Returns the best performing members. This is the default.

        $rh->top_movers( direction => 'down' );

    Returns the worst performing members.

## `tags( ... )`

    my $tags = $rh->tags( 'food', 'oil' );

Returns an iterator containing Finance::Robinhood::Equity::Tag objects.

## `tags_discovery( ... )`

    my $tags = $rh->tags_discovery( );

Returns an iterator containing Finance::Robinhood::Equity::Tag objects.

## `tags_popular( ... )`

    my $tags = $rh->tags_popular( );

Returns an iterator containing Finance::Robinhood::Equity::Tag objects.

## `tag( ... )`

    my $tag = $rh->tag('food');

Locates a tag by its slug and returns a Finance::Robinhood::Equity::Tag object.

# OPTIONS METHODS

## `options_chains( )`

    my $chains = $rh->options_chains->all;

Returns an iterator containing chain elements.

    my $equity = $rh->search('MSFT')->equity_instruments->[0]->options_chains->all;

You may limit the call by passing a list of options instruments or a list of
equity instruments.

## `options_instruments( )`

    my $options = $rh->options_instruments();

Returns an iterator containing Finance::Robinhood::Options::Instrument objects.

        my $options = $rh->options_instruments( state => 'active', type => 'put' );

You can filter the results several ways. All of them are optional.

- `state` - `active`, `inactive`, or `expired`
- `type` - `call` or `put`
- `expiration_dates` - comma separated list of days; format is YYYY-M-DD

# UNSORTED

## `user( )`

    my $me = $rh->user();

Returns a Finance::Robinhood::User object. You need to be logged in for this to
work.

## `acats_transfers( )`

    my $acats = $rh->acats_transfers();

An iterator containing Finance::Robinhood::ACATS::Transfer objects is returned.

You need to be logged in for this to work.

## `equity_positions( )`

    my $positions = $rh->equity_positions( );

Returns the related paginated list object filled with
Finance::Robinhood::Equity::Position objects.

You must be logged in.

    my $positions = $rh->equity_positions( nonzero => 1 );

You can filter and modify the results. All options are optional.

- `nonzero` - true or false. Default is false
- `ordering` - list of equity instruments

## `equity_earnings( ... )`

    my $earnings = $rh->equity_earnings( symbol => 'MSFT' );

Returns the related paginated list object filled with
Finance::Robinhood::Equity::Earnings objects by ticker symbol.

    my $earnings = $rh->equity_earnings( instrument => $rh->equity_instrument_by_symbol('MSFT') );

Returns the related paginated list object filled with
Finance::Robinhood::Equity::Earnings objects by instrument object/url.

    my $earnings = $rh->equity_earnings( range=> 7 );

Returns a paginated list object filled with
Finance::Robinhood::Equity::Earnings objects for all expected earnings report
over the next `X` days where `X` is between `-21...-1, 1...21`. Negative
values are days into the past. Positive are days into the future.

You must be logged in for any of these to work.

# FOREX METHODS

Depending on your jurisdiction, your account may have access to Robinhood
Crypto. See https://crypto.robinhood.com/ for more.

## `forex_accounts( )`

    my $halts = $rh->forex_accounts;

Returns an iterator full of Finance::Robinhood::Forex::Account objects.

You need to be logged in and have access to Robinhood Crypto for this to work.

## `forex_account_by_id( ... )`

    my $account = $rh->forex_account_by_id($id);

Returns a Finance::Robinhood::Forex::Account object. You need to be logged in
for this to work.

## `forex_halts( [...] )`

    my $halts = $rh->forex_halts;
    # or
    $halts = $rh->forex_halts( active => 1 );

Returns an iterator full of Finance::Robinhood::Forex::Halt objects.

If you pass a true value to a key named `active`, only active halts will be
returned.

You need to be logged in and have access to Robinhood Crypto for this to work.

## `forex_currencies( )`

    my $currecies = $rh->forex_currencies();

An iterator containing Finance::Robinhood::Forex::Currency objects is returned.
You need to be logged in for this to work.

## `forex_currency_by_id( ... )`

    my $currency = $rh->forex_currency_by_id($id);

Returns a Finance::Robinhood::Forex::Currency object. You need to be logged in
for this to work.

## `forex_pairs( )`

    my $pairs = $rh->forex_pairs();

An iterator containing Finance::Robinhood::Forex::Pair objects is returned. You
need to be logged in for this to work.

## `forex_pair_by_id( ... )`

    my $watchlist = $rh->forex_pair_by_id($id);

Returns a Finance::Robinhood::Forex::Pair object. You need to be logged in for
this to work.

## `forex_pair_by_symbol( ... )`

    my $btc = $rh->forex_pair_by_symbol('BTCUSD');

Returns a Finance::Robinhood::Forex::Pair object. You need to be logged in for
this to work.

## `forex_watchlists( )`

    my $watchlists = $rh->forex_watchlists();

An iterator containing Finance::Robinhood::Forex::Watchlist objects is
returned. You need to be logged in for this to work.

## `forex_watchlist_by_id( ... )`

    my $watchlist = $rh->forex_watchlist_by_id($id);

Returns a Finance::Robinhood::Forex::Watchlist object. You need to be logged in
for this to work.

## `forex_activations( )`

    my $activations = $rh->forex_activations();

An iterator containing Finance::Robinhood::Forex::Activation objects is
returned. You need to be logged in for this to work.

## `forex_activation_by_id( ... )`

    my $activation = $rh->forex_activation_by_id($id);

Returns a Finance::Robinhood::Forex::Activation object. You need to be logged
in for this to work.

## `forex_portfolios( )`

    my $portfolios = $rh->forex_portfolios();

An iterator containing Finance::Robinhood::Forex::Portfolio objects is
returned. You need to be logged in for this to work.

## `forex_portfolio_by_id( ... )`

    my $portfolio = $rh->forex_portfolio_by_id($id);

Returns a Finance::Robinhood::Forex::Portfolio object. You need to be logged in
for this to work.

## `forex_activation_request( ... )`

    my $activation = $rh->forex_activation_request( type => 'new_account' );

Submits an application to activate a new forex account. If successful, a new
Fiance::Robinhood::Forex::Activation object is returned. You need to be logged
in for this to work.

The following options are accepted:

- `type`

    This is required and must be one of the following:

    - `new_account`
    - `reactivation`

- `speculative`

    This is an optional boolean value.

## `forex_orders( )`

    my $orders = $rh->forex_orders( );

An iterator containing Finance::Robinhood::Forex::Order objects is returned.
You need to be logged in for this to work.

## `forex_order_by_id( ... )`

    my $order = $rh->forex_order_by_id($id);

Returns a Finance::Robinhood::Forex::Order object. You need to be logged in for
this to work.

## `forex_holdings( )`

    my $holdings = $rh->forex_holdings( );

Returns the related paginated list object filled with
Finance::Robinhood::Forex::Holding objects.

You must be logged in.

    my $holdings = $rh->forex_holdings( nonzero => 1 );

You can filter and modify the results. All options are optional.

- `nonzero` - true or false. Default is false.

## `forex_holding_by_id( ... )`

    my $holding = $rh->forex_holding_by_id($id);

Returns a Finance::Robinhood::Forex::Holding object. You need to be logged in
for this to work.

# LEGAL

This is a simple wrapper around the API used in the official apps. The author
provides no investment, legal, or tax advice and is not responsible for any
damages incurred while using this software. This software is not affiliated
with Robinhood Financial LLC in any way.

For Robinhood's terms and disclosures, please see their website at
https://robinhood.com/legal/

# LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module. Please refer to
the [LEGAL](https://metacpan.org/pod/LEGAL) section.

# AUTHOR

Sanko Robinson <sanko@cpan.org>
