[![Build Status](https://travis-ci.org/sanko/Finance-Robinhood.svg?branch=master)](https://travis-ci.org/sanko/Finance-Robinhood) [![MetaCPAN Release](https://badge.fury.io/pl/Finance-Robinhood.svg)](https://metacpan.org/release/Finance-Robinhood) [![Build Status](https://img.shields.io/appveyor/ci/sanko/Finance-Robinhood/master.svg?logo=appveyor)](https://ci.appveyor.com/project/sanko/Finance-Robinhood/branch/master)
# NAME

Finance::Robinhood - Trade Stocks, ETFs, Options, and Cryptocurrency without
Commission

# SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;

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

## `login( ... )`

    my $rh = Finance::Robinhood->new()->login($user, $pass);

A new Finance::Robinhood object is created without credentials. Before you can
buy or sell or do almost anything else, you must [log in](#login).

        my $rh = Finance::Robinhood->new()->login($user, $pass, mfa_callback => sub {
                # Do something like pop open an inputbox in TK or whatever
        } );

If you have MFA enabled, you may (or must) also pass a callback. When the code
is called, a ref will be passed that will contain `mfa_required` (a boolean
value) and `mfa_type` which might be `app`, `sms`, etc. Your return value
must be the MFA code.

        my $rh = Finance::Robinhood->new()->login($user, $pass, mfa_code => 980385);

If you already know the MFA code (for example if you have MFA enabled through
an app), you can pass that code directly and log in.

## `instruments( )`

    my $instruments = $rh->instruments();

Returns an iterator containing equity instruments.

## `instrument_by_symbol( )`

    my $instrument = $rh->instrument_by_symbol();

Searches for an equity instrument by ticker symbol and returns a
Finance::Robinhood::Equity::Instrument.

## `options_chains( )`

    my $chains = $rh->options_chains->all;

Returns an iterator containing chain elements.

        my $equity = $rh->search('MSFT')->{instruments}[0]->options_chains->all;

You may limit the call by passing a list of options instruments or a list of
equity instruments.

## `orders( )`

    my $orders = $rh->orders();

An iterator containing Finance::Robinhood::Equity::Order objects is returned.
You need to be logged in for this to work.

## `options_instruments( )`

    my $options = $rh->options_instruments();

Returns an iterator containing Finance::Robinhood::Options::Instrument objects.

        my $options = $rh->options_instruments( state => 'active', type => 'put' );

You can filter the results several ways. All of them are optional.

- `state` - `active`, `inactive`, or `expired`
- `type` - `call` or `put`
- `expiration_dates` - comma separated list of days; format is YYYY-M-DD

## `accounts( )`

    my $accounts = $rh->accounts();

An iterator containing Finance::Robinhood::Account objects is returned. You
need to be logged in for this to work.

## `search( ... )`

    my $results = $rh->search('microsoft');

Returns a set of search results. Depending on the results, you'll get a list of
Finance::Robinhood::Equity::Instrument objects in a key named `instruments`, a
list of Finance::Robinhood::Tag objects in a key named `tags`, and a list of
currency pairs in the aptly named `currency_pairs` key.

        $rh->search('New on Robinhood')->{tags};
        $rh->search('bitcoin')->{currency_pairs};

You do not need to be logged in for this to work.

## `news( ... )`

    my $news = $rh->news('MSFT');

An iterator containing Finance::Robinhood::News objects is returned.

You do not need to be logged in for this to work.

## `feed( )`

    my $feed = $rh->feed();

An iterator containing Finance::Robinhood::News objects is returned. This list
will be filled with news related to instruments in your watchlist and
portfolio.

You need to be logged in for this to work.

## `fundamentals( )`

    my $fundamentals = $rh->fundamentals('MSFT', 'TSLA');

An iterator containing Finance::Robinhood::Equity::Fundamentals objects is
returned.

You do not need to be logged in for this to work.

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
