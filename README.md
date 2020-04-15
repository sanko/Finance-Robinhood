[![Build Status](https://travis-ci.org/sanko/Finance-Robinhood.svg?branch=master)](https://travis-ci.org/sanko/Finance-Robinhood) [![MetaCPAN Release](https://badge.fury.io/pl/Finance-Robinhood.svg)](https://metacpan.org/release/Finance-Robinhood)
# NAME

Finance::Robinhood - Banking, Stock, ETF, Options, and Cryptocurrency Trading
Without Fees or Commissions

# SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new();
    $rh->equity('MSFT')->buy(2)->limit(187.34)->submit;

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
buy or sell or do almost anything else, you must log in.

To log in, you must pass a combination of the following parameters:

### `username => ...`

Shh!

This is you. Be careful with you.

### `password => ...`

Private!

To log in manually, you'll need to provide your password.

### `oauth2_token => ...`

If you have previously authorized this package to access your account, passing
the OAuth2 tokens here will prevent you from having to log in with your user
data.

These tokens should be kept private.

### `device_token => ...`

If you have previously authorized this package to access your account, passing
the assigned device ID here will prevent you from having to authorize it again
upon log in.

Like authorization tokens, this UUID should be kept private.

### `mfa_callback => ...`

    my $rh = Finance::Robinhood->new(username => $user, password => $pass, mfa_callback => sub {
        # Do something like pop open an inputbox in TK, read from shell or whatever
    } );

If you have MFA enabled, you may (or must) also pass a callback. When the code
is called, a ref will be passed that will contain `mfa_required` (a boolean
value) and `mfa_type` which might be `app`, `sms`, etc. Your return value
must be the MFA code.

### `mfa_code => ...`

    my $rh = Finance::Robinhood->new(username => $user, password => $pass, mfa_code => 980385);

If you already know the MFA code (for example if you have MFA enabled through
an app), you can pass that code directly and log in.

### `challenge_callback => ...`

    my $rh = Finance::Robinhood->new(username => $user, password => $pass, challenge_callback => sub {
        my ($challenge) = @_;
        # Do something like pop open an inputbox in TK, read from shell or whatever
        $challenge->respond( ... );
        $challenge;
    } );

When logging in with a new client, you are required to authorize it to access
your account.

This callback should should expect a Finance::Robinhood::Device::Challenge
object and must return the object after validation.

### `scope => ...`

Optional OAuth scopes as a single string or a list of values. If you don't know
what to pass here, passing nothing will force the client pretend to be an
official app and use the `internal` scope with full access.

## `refresh_login_token( )`

OAuth2 authorization tokens expire after a defined amount of time (24 hours
from login). To continue your session, you must refresh this token by calling
this method.

## `search( ... )`

    my $results = $rh->search('microsoft');

Returns a set of search results by type. These types are sorted into hash keys:

- `currency_pairs` - A list of Finance::Robinhood::Currency::Pair objects
- `equities` - A list of Finance::Robinhood::Equity objects
- `tags` - A list of Finance::Robinhood::Equity::Collection objects
- `lists` - A list of Finance::Robinhood::Equity::List objects

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
this to work and Robinhood has a terrible habit of relocating notifications so
that these ids are inconsistent.

# EQUITY METHODS

## `equity( ... )`

    my $msft = $rh->equity('MSFT');

Searches for an equity instrument by ticker symbol and returns a
Finance::Robinhood::Equity object.

## `equities( [...] )`

    my $instruments = $rh->equities();

Returns an iterator containing equity instruments.

You may restrict, search, or modify the list of instruments returned with the
following optional arguments:

- `symbol` - Ticker symbol

        my $msft = $rh->equities(symbol => 'MSFT')->next;

    By the way, `equity( )` exists as sugar around this and returns the instrument
    itself rather than an iterator object with a single element.

- `query` - Keyword search

        my @solar = $rh->equities(query => 'solar')->all;

- `ids` - List of instrument ids

        my ( $msft, $tsla )
            = $rh->equities(
                ids => [ '50810c35-d215-4866-9758-0ada4ac79ffa',
                     'e39ed23a-7bd1-4587-b060-71988d9ef483' ] )
            ->all;

    If you happen to know/store instrument ids, quickly get full equity objects
    this way.

- `active` - Boolean value

        my ($active) = $rh->equities(active => 1)->all;

    If you only want active equity instruments, set this to a true value.

## `equity_by_id( ... )`

    my $instrument = $rh->equities_by_id('50810c35-d215-4866-9758-0ada4ac79ffa');

Simple wrapper around `equities_by_id( ..., ... )` that expects only a single
ID because I can't remember to use the plural version.

## `equities_by_id( ..., ... )`

    my $instrument = $rh->equities_by_id(
                '50810c35-d215-4866-9758-0ada4ac79ffa',
                'e39ed23a-7bd1-4587-b060-71988d9ef483'
        );

Searches for a list of equity instruments by their instrument ids and returns a
list of Finance::Robinhood::Equity objects.

## `equity_positions( )`

    my $positions = $rh->equity_positions( );

Returns an iterator with Finance::Robinhood::Equity::Position objects.

You must be logged in.

    my $positions = $rh->equity_positions( nonzero => 1 );

You can filter and modify the results. All options are optional.

- `nonzero` - true or false. Default is false
- `ordering` - list of equity instruments

## `equity_earnings( ... )`

Returns an iterator holding hash references which contain the following keys:

- `call` - Hash reference containing the following keys:
    - `broadcast_url` - Link to a website to listen to the live earnings call
    - `datetime` - Time::Moment object
    - `replay_url` - Link to a website to listen to the replay of the earnings call
- `eps` - Hash reference containing the following keys:
    - `actual` - Actual reported earnings
    - `estimate` - Early estimated earnings
- `instrument` - Instrument ID (UUID)
- `quarter` - `1`, `2`, `3`, or `4`
- `report` - Hash reference with the following values:
    - `date` - YYYY-MM-DD
    - `timing` - `am` or `pm`
    - `verified` - Boolean value
- `symbol` - Ticker symbol
- `year` - YYYY

    my $earnings = $rh->equity_earnings( symbol => 'MSFT' );

Returns an iterator holding hash references by ticker symbol.

    my $earnings = $rh->equity_earnings( instrument => $rh->equity('MSFT') );

Returns an iterator holding hash references by instrument object/url.

    my $earnings = $rh->equity_earnings( range => 7 );

Returns an iterator holding hash references for all expected earnings report
over the next `X` days where `X` is between `-21...-1, 1...21`. Negative
values are days into the past. Positive are days into the future.

You must be logged in for any of these to work.

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

## `equity_account( )`

    my $account = $rh->equity_account();

Returns the first Finance::Robinhood::Equity::Account objects. This is usually
what you want to use. You need to be logged in for this to work.

## `equity_accounts( )`

    my $accounts = $rh->equity_accounts();

An iterator containing Finance::Robinhood::Equity::Account objects is returned.
There likely isn't more than a single account but Robinhood exposes an
iterative endpoint. You need to be logged in for this to work.

## `equity_account_by_account_number( ... )`

    my $account = $rh->equity_account_by_account_number($id);

Returns a Finance::Robinhood::Equity::Account object. You need to be logged in
for this to work.

## `equity_portfolio( )`

Returns the Finance::Robinhood::Equity::Account::Portfolio object related to
your primary equity account. You need to be logged in for this to work.

## `equity_portfolios( )`

    my $equity_portfolios = $rh->equity_portfolios();

An iterator containing Finance::Robinhood::Equity::Account::Portfolio objects
is returned. You need to be logged in for this to work.

## `equity_watchlist( )`

    my $watchlist = $rh->equity_watchlist;

Returns the default Finance::Robinhood::Equity::Watchlist object. You need to
be logged in for this to work.

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

## `collections( ... )`

    my $tags = $rh->collections( 'food', 'oil' );

Returns a list of Finance::Robinhood::Equity::Collection objects.

## `discover_collections( ... )`

    my $tags = $rh->discover_collections( );

Returns an iterator containing Finance::Robinhood::Equity::Collection objects.

## `popular_collections( ... )`

    my $tags = $rh->popular_collections( );

Returns an iterator containing Finance::Robinhood::Equity::Collection objects.

## `collection( ... )`

    my $tag = $rh->collection('food');

Locates a collection by its slug and returns a
Finance::Robinhood::Equity::Collection object.

# OPTIONS METHODS

## `options( [...] )`

    my $chains = $rh->options;

Returns an iterator containing chain elements.

    $rh->options($rh->equity('MSFT'))->all;

You may limit the call by passing a list of Finance::Robinhood::Equity or
Finance::Robinhood::Options::Contract objects.

## `options_contracts( )`

    my $options = $rh->options_contracts();

Returns an iterator containing Finance::Robinhood::Options::Contract objects.

    my $options = $rh->options_contracts( state => 'active', type => 'put' );

You can filter the results several ways. All of them are optional.

- `state` - `active`, `inactive`, or `expired`
- `type` - `call` or `put`
- `expiration_dates` - list of days; format is YYYY-M-DD
- `ids` - list of contract IDs
- `tradability` - either `tradable` or `untradable`
- `chain_id` - the options chain id
- `state` - `active`, `inactive`, or `expired`

## `options_positions( )`

    my $positions = $rh->options_positions( );

Returns the related paginated list object filled with
Finance::Robinhood::Options::Position objects.

You must be logged in.

    my $positions = $rh->options_positions( nonzero => 1 );

You can filter and modify the results. All options are optional.

- `nonzero` - true or false. Default is false
- `chains` - list of options chain IDs or Finance::Robinhood::Options objects

## `options_position_by_id( ... )`

    my $position = $rh->options_position_by_id('b5ad00c0-7861-4582-8e5e-48f635178cb9');

Searches for a single of options position by its id and returns a
Finance::Robinhood::Options::Position object.

## `options_contract_by_id( ... )`

    $rh->options_contract_by_id('3b8f5513-600f-49b8-a4de-db56b52a82cf');

Searches for a single of options instrument by its instrument id and returns a
Finance::Robinhood::Options::Contract object.

## `options_by_id( ... )`

    my $chain = $rh->options_by_id('55d7e31c-9105-488b-983c-93e09dd7ff35');

Searches for a single of options chain by its id and returns a
Finance::Robinhood::Options object.

## `options_events( )`

    my $events = $rh->options_events();

Returns an iterator containing Finance::Robinhood::Options::Event objects.

## `options_orders( [...] )`

    my $orders = $rh->options_orders();

An iterator containing Finance::Robinhood::Options::Order objects is returned.
You need to be logged in for this to work.

    my $orders = $rh->options_orders(contract => $msft_call_130_Jun_2020);

If you would only like orders after a certain date, you can do that!

    my $orders = $rh->options_orders(after => Time::Moment->now->minus_days(7));
    # Also accepts ISO 8601

If you would only like orders before a certain date, you can do that!

    my $orders = $rh->options_orders(before => Time::Moment->now->minus_years(2));
    # Also accepts ISO 8601

## `options_order_by_id( ... )`

    my $order = $rh->options_order_by_id($id);

Returns a Finance::Robinhood::Options::Order object. You need to be logged in
for this to work.

# UNSORTED

## `user( )`

    my $me = $rh->user();

Returns a Finance::Robinhood::User object. You need to be logged in for this to
work.

# FOREX METHODS

Depending on your jurisdiction, your account may have access to Robinhood
Crypto. See https://crypto.robinhood.com/ for more.

## `currency_account( )`

    my $acct = $rh->currency_account;

Returns a Finance::Robinhood::Currency::Account object.

You need to be logged in and have access to Robinhood Crypto for this to work.

## `currency_accounts( )`

    my $accts = $rh->currency_accounts;

Returns an iterator full of Finance::Robinhood::Currency::Account objects.

You need to be logged in and have access to Robinhood Crypto for this to work.

## `currency_account_by_id( ... )`

    my $account = $rh->currency_account_by_id($id);

Returns a hash reference. You need to be logged in for this to work.

## `currency_halts( [...] )`

    my $halts = $rh->currency_halts;
    # or
    $halts = $rh->currency_halts( active => 1 );

Returns an iterator full of Finance::Robinhood::Currency::Halt objects.

If you pass a true value to a key named `active`, only active halts will be
returned.

You need to be logged in and have access to Robinhood Crypto for this to work.

## `currency_halt_by_id( ... )`

    my $halts = $rh->currency_halt_by_id( '6a2a026a-e391-43cf-aadf-25826ea5432b' );

Returns an Finance::Robinhood::Currency::Halt object if a halt with this ID
exits.

If you pass a true value to a key named `active`, only active halts will be
returned.

You need to be logged in and have access to Robinhood Crypto for this to work.

## `currencies( )`

    my $currecies = $rh->currencies();

An iterator containing Finance::Robinhood::Forex::Currency objects is returned.
You need to be logged in for this to work.

## `currency_by_id( ... )`

    my $currency = $rh->currency_by_id($id);

Returns a Finance::Robinhood::Currency object. You need to be logged in for
this to work.

## `currency_pairs( )`

    my $pairs = $rh->currency_pairs( );

An iterator containing Finance::Robinhood::Currency::Pair objects is returned.
You need to be logged in for this to work.

## `currency_pair_by_id( ... )`

    my $watchlist = $rh->currency_pair_by_id($id);

Returns a Finance::Robinhood::Currency::Pair object. You need to be logged in
for this to work.

## `currency_pair_by_name( ... )`

    my $bitcoin = $rh->currency_pair_by_name('Bitcoin');
       $bitcoin = $rh->currency_pair_by_name('BTC');

Returns a Finance::Robinhood::Currency::Pair object. You need to be logged in
for this to work.

## `currency_watchlists( )`

    my $watchlists = $rh->currency_watchlists();

Returns an iterator containing Finance::Robinhood::Currency::Watchlist objects.

You need to be logged in for this to work.

## `currency_watchlist_by_id( ... )`

    my $watchlist = $rh->currency_watchlist_by_id($id);

Returns a Finance::Robinhood::Currency::Watchlist object.

## `currency_activations( )`

    my $activations = $rh->currency_activations();

Returns an iterator containing Finance::Robinhood::Currency::Activation
objects.

## `currency_activation_by_id( ... )`

    my $activation = $rh->currency_activation_by_id($id);

Returns a Finance::Robinhood::Currency::Activation object.

## `currency_portfolios( )`

    my $portfolios = $rh->currency_portfolios();

Returns an iterator containing Finance::Robinhood::Currency::Portfolio objects.

You need to be logged in for this to work.

## `currency_portfolio_by_id( ... )`

    my $portfolio = $rh->currency_portfolio_by_id($id);

Returns a Finance::Robinhood::Currency::Portfolio object.

You need to be logged in for this to work.

## `new_currency_application( ... )`

    my $activation = $rh->new_currency_application( type => 'new_account' );

Submits an application to activate a new cryptocurrency account. You need to be
logged in for this to work.

The following options are accepted:

- `type`

    This is required and must be one of the following:

    - `new_account`
    - `reactivation`

- `speculative`

    This is an optional boolean value.

## `currency_orders( )`

    my $orders = $rh->currency_orders( );

An iterator containing Finance::Robinhood::Forex::Order objects is returned.
You need to be logged in for this to work.

## `forex_order_by_id( ... )`

    my $order = $rh->forex_order_by_id($id);

Returns a Finance::Robinhood::Currency::Order object. You need to be logged in
for this to work.

## `currency_positions( [...] )`

    my $holdings = $rh->currency_positions( );

Returns an iterator filled with Finance::Robinhood::Currency::Position objects.

You must be logged in.

## `currency_position_by_id( ... )`

    my $holding = $rh->currency_position_by_id($id);

Returns a Finance::Robinhood::Currency::Position object.

You need to be logged in for this to work.

# BANKING METHODS

Move money in and out of your brokerage account.

# ACATS/TRANSFER METHODS

At some point, you might need to move assets from one firm to another.

## `acats_transfers( )`

    my $acats = $rh->acats_transfers();

An iterator containing Finance::Robinhood::ACATS::Transfer objects is returned.

You need to be logged in for this to work.

## `request_acats_transfer( ... )`

    my $done = $rh->request_acats_transfer(
        account => $rh->equity_account,

    )

Request an ACATS transfer. You may pass the following options:

- `account` - Finance::Robinhood::Equity::Account object (optional; defaults to `equity_account( )`)
- `contra_account_number` - Account number at the other end of the transfer (required)
- `contra_account_title` - String used to identify the account in UI (optional)
- `contra_brokerage_name` - String used to identify the other firm (optional)
- `contra_correspondent_number` - String used (required)

# INBOX METHODS

    @retrofit2.http.GET("inbox/threads/{threadId}/")
    io.reactivex.Single<com.robinhood.models.api.ApiThread> getThread(@retrofit2.http.Path("threadId") java.lang.String str);

    @retrofit2.http.GET("inbox/threads/{threadId}/messages/")
    io.reactivex.Single<com.robinhood.models.api.ApiMessageResult> getThreadMessages(@retrofit2.http.Path("threadId") java.lang.String str, @retrofit2.http.Query("before") java.lang.String str2, @retrofit2.http.Query("after") java.lang.String str3);

    @retrofit2.http.GET("inbox/settings/thread/{threadId}/")
    io.reactivex.Single<com.robinhood.models.api.ApiNotificationThreadSettingsItem> getThreadNotificationSettingsV4(@retrofit2.http.Path("threadId") java.lang.String str);

    @retrofit2.http.GET("inbox/settings/{threadId}/")
    io.reactivex.Single<com.robinhood.models.api.ApiNotificationSettingsV3> getThreadSettings(@retrofit2.http.Path("threadId") java.lang.String str);

    @retrofit2.http.GET("inbox/threads/")
    io.reactivex.Single<com.robinhood.models.PaginatedResult<com.robinhood.models.api.ApiThread>> getThreads();

# Cash Management

## `cash_accounts( )`

Returns an iterator filled with `Finance::Robinhood::Cash` objects.

## `cash_account_by_id( $id )`

Returns the related Finance::Robinhood::Cash object.

## `atms( $latitude, $longitude )`

Returns an iterator filled with Finance::Robinhood::Cash::ATM objects.

`$latitude` and `$longitude` coordinates must be in decimal degrees.

## `atm_by_id( $UUID )`

        $rh->atm_by_id('2fb3fac0-96ef-4154-830f-21d4b8affbca');

Returns a Finance::Robinhood::Cash::ATM object.

## `cash_flow( )`

Returns a hash reference with two keys: `cash_in` and `cash_out`. They both
contain these keys:

- `amount` - This is a dollar amount.
- `currency_code` - Currency type (`USD`)
- `currency_id` - UUID

## `debit_cards( )`

Returns an iterator filled with `Finance::Robinhood::Cash::Card` objects.

## `debit_card_by_id( ... )`

Returns a `Finance::Robinhood::Cash::Card` object.

# 'FUN' METHODS

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
