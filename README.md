[![Build Status](https://travis-ci.org/sanko/Finance-Robinhood.svg?branch=master)](https://travis-ci.org/sanko/Finance-Robinhood)
# NAME

Finance::Robinhood - Trade Stocks, ETFs, Options, and Cryptocurrency without Commission

# SYNOPSIS

    use Finance::Robinhood;

    my $rh = Finance::Robinhood->new();

    $rh->login($user, $password); # Store it for later

# METHODS

Finance::Robinhood wraps a several APIs. There are parts of this package that
are object oriented (because they require persistant login information) and
others which may also be used functionally (because they do not require login
information). I've attempted to organize everything according to how and when
they are used... Let's start at the very beginning: let's log in!

# Logging In

Robinhood requires an authorization token for most API calls. To get this
token, you must either pass it as an argument to `new( ... )` or log in with
your username and password.

## `new( )`

    # Requires ->login(...) call :(
    my $rh = Finance::Robinhood->new( );

A new Finance::Robinhood object is created without credentials. Before you can
buy or sell or do almost anything else, you must [log in manually](#login).

## `login( ... )`

    my $token = $rh->login($user, $password);
    # Save the token somewhere

Logging in allows you to buy and sell securities with your Robinhood account.

## `logout( )`

    my $token = $rh->login($user, $password);
    # ...do some stuff... buy... sell... idk... stuff... and then...
    $rh->logout( ); # Goodbye!

This method logs you out of Robinhood by forcing the old skool token to expire.

_Note_: This will log you out _everywhere_ that uses the old skool token because
Robinhood generated a single authorization token per account at a time! All logged in
clients will be logged out. This is good in rare case your device or the token itself is
stolen.

## `recover_password( ... )`

    my $token = $rh->recover_password('rh@example.com', sub {...});

Start the password recovery process. If everything goes as planned, this returns a true value.

The token callback should expect a string to display in your
application and return a list with the following data:

- `username` - Username attached to the email address
- `password` - New password
- `token` - Reset token provided by Robinhood in the reset link

## `migrate_token( ... )`

    my $ok = $rh->migrate_token();

Convert your old skool token to an OAuth2 token.

## `equity_quote( ... )`

    my $msft_quote = $rh->quote('MSFT');

Gather quote data as a [Finance::Robinhood::Equity::Quote](https://metacpan.org/pod/Finance::Robinhood::Equity::Quote) object.

    my $msft_quote = $rh->quote('MSFT', bounds => 'extended');

An argument called `bounds` is also supported when you want a certain range of quote data.
This value must be `extended`, `regular`, or `trading` which is the default.

## `equity_quotes( ... )`

    my $inst = $rh->equity_quotes( symbols => ['MSFT', 'X'] );
    my $all = $inst->all;

Gather info about multiple equities by symbol. This is returned as a `Finance::Robinhood::Utils::Paginated` object.

    my $inst = $rh->instruments( instruments =>  ['50810c35-d215-4866-9758-0ada4ac79ffa', 'b060f19f-0d24-4bf2-bf8c-d57ba33993e5'] );
    my $all = $inst->all;

Gather info about a several instruments by their ids; data is returned as a `Finance::Robinhood::Utils::Paginated` object.

Request either by symbol or by instrument id! Other arguments are also supported:

- `bounds` - which must be `extended`, `regular`, or `trading` which is the default

## `equity_instruments( ... )`

    my $ok = $rh->equity_instruments();
    my $all = $ok->all;

Gather info about listed stocks and etfs. This is returned as a `Finance::Robinhood::Utils::Paginated` object.

    my $inst = $rh->equity_instruments( symbol => 'MSFT' );
    my $all = $inst->all;

Gather info about a single instrument returned as a `Finance::Robinhood::Utils::Paginated` object.

    my $minstsft = $rh->equity_instruments( query => 'oil' );
    my $all = $inst->all;

Gather info about a single instrument returned as a `Finance::Robinhood::Utils::Paginated` object.

    my $inst = $rh->equity_instruments( ids =>  ['50810c35-d215-4866-9758-0ada4ac79ffa', 'b060f19f-0d24-4bf2-bf8c-d57ba33993e5'] );
    my $all = $inst->all;

Gather info about a several instruments by their ids; data is returned as a `Finance::Robinhood::Utils::Paginated` object.

Other arguments such as the boolean values for `nocache` and `active_instruments_only` are also supported.

## `equity_instrument( ... )`

    my $labu = $rh->equity_instrument('6a17083e-2867-4a20-9b78-a0a46b422279');

Gather data as a [Finance::Robinhood::Instrument](https://metacpan.org/pod/Finance::Robinhood::Instrument) object.

## `options_chains( ... )`

    my $ok = $rh->options_chains();

Gather info about all supported options chains. This is returned as a `Finance::Robinhood::Utils::Paginated` object.

    my $inst = $rh->options_chains( ids =>  ['0c0959c2-eb3a-4e3b-8310-04d7eda4b35c'] );
    my $all = $inst->all;

Gather info about several options chains at once by id. This is returned as a `Finance::Robinhood::Utils::Paginated` object.

    my $inst = $rh->options_chains( equity_instrument_ids => ['6a17083e-2867-4a20-9b78-a0a46b422279'] );
    my $all = $inst->all;

Gather  options chains related to a security by the security's  id. This is returned as a `Finance::Robinhood::Utils::Paginated` object.

## `options_instruments( ... )`

    my $ok = $rh->options_instruments();

Gather info about all supported options instruments. This is returned as a `Finance::Robinhood::Utils::Paginated` object.

    my $inst = $rh->options_instruments( ids =>  ['73f75306-ad07-4734-972b-22ab9dec6693'] );
    my $all = $inst->all;

Gather info about several options chains at once by instrument id. This is returned as a `Finance::Robinhood::Utils::Paginated` object.

    my $inst = $rh->options_instruments( tradability => 'tradable' );
    my $all = $inst->all;

Gather info about several options chains at once but only those that are currently 'tradable' or 'untradable'.
This is returned as a `Finance::Robinhood::Utils::Paginated` object.

    my $inst = $rh->options_instruments( state => 'active' );
    my $all = $inst->all;

Gather info about several options chains at once but only those that are currently 'active', 'inactive', or 'expired'.
This is returned as a `Finance::Robinhood::Utils::Paginated` object.

Other supported arguments include:

- `type` - 'call' or 'put'
- `expiration_dates` - an array ref of dates in the form 'YYYY-MM-DD'
- `chain_id` - options chain's UUID

## `options_suitability( ... )`

    my $account = $rh->options_suitability();

Find out if your account is eligible to move to any of the supported options levels.

The returned data is a hash containing the max level and any changes to your profile that needs to be updated.

## `place_options_order( ... )`

## `options_order( ... )`

    my $order = $rh->options_order('0adf9278-095d-ef93-eac37a8199fe');
    $order->cancel;

Gather a single order by id. This is returned as a new `Finance::Robinhood::Options::Order` object.

## `options_orders( ... )`

    my $ok = $rh->options_orders();

Gather info about all options orders. This is returned as a `Finance::Robinhood::Utils::Paginated` object.

    my $inst = $rh->options_chains( 'since' =>  '2018-10-01' );
    my $all = $inst->all;

Gather info about options orders after a certain date. This is returned as a `Finance::Robinhood::Utils::Paginated` object.

## `options_positions( ... )`

    my $ok = $rh->options_positions();

Gather info about all options orders. This is returned as a `Finance::Robinhood::Utils::Paginated` object.

Possible parameters are:

- `chain_ids` - list of ids
- `type` - 'long' or 'short'

## `options_position( ... )`

    my $labu = $rh->options_position('6a17083e-2867-4a20-9b78-a0a46b422279');

Gather data as a [Finance::Robinhood::Options::Position](https://metacpan.org/pod/Finance::Robinhood::Options::Position) object.

## `options_events( ... )`

    my $ok = $rh->options_events();

Gather info about recent options events. This is returned as a `Finance::Robinhood::Utils::Paginated` object.

## `account( ... )`

    my $account = $rh->accounts();

Gather info about all brokerage accounts.

Please note that this will be a cached value. If you need updated information, use `accounts( )`.

## `accounts( ... )`

    my $account = $rh->accounts()->next;

Gather info about all brokerage accounts. This is returned as a `Finance::Robinhood::Utils::Paginated` object.

This is rather useless seeing as we're only allowed a single account per signup.

## `ach_relationships( ... )`

    my $ok = $rh->ach_relationships();

Gather info about all attached bank accounts. This is returned as a `Finance::Robinhood::Utils::Paginated` object.

## `create_ach_relationship( ... )`

    my $ok = $rh->create_ach_relationship(
        bank_routing_number => '026009593', 
        bank_account_number => '009872784317963',
        bank_account_type => 'checking', 
        bank_account_holder_name => 'John Smith
    );

Attach a bank accounts to your Robinhood account. This is returned as a `Finance::Robinhood::ACH` object if everything goes well.

All arguments are required. `bank_account_type` is either `'checking'` or `'savings'`.

## `ach_deposit_schedules( ... )`

    my $ok = $rh->ach_deposit_schedules();
    my $all = $ok->all;

Gather info about scheduled ACH deposits. This is returned as a `Finance::Robinhood::Utils::Paginated` object.

# LEGAL

This is a simple wrapper around the API used in the official apps. The author
provides no investment, legal, or tax advice and is not responsible for any
damages incurred while using this software. Neither this software nor its
author are affiliated with Robinhood Financial LLC in any way.

For Robinhood's terms and disclosures, please see their website at http://robinhood.com/

# LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify
it under the terms found in the Artistic License 2.
Other copyrights, terms, and conditions may apply to data transmitted through
this module. Please refer to the [LEGAL](https://metacpan.org/pod/LEGAL) section.

# AUTHOR

Sanko Robinson <sanko@cpan.org>
