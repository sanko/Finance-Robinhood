[![Build Status](https://travis-ci.org/sanko/Finance-Robinhood.svg?branch=master)](https://travis-ci.org/sanko/Finance-Robinhood)
# NAME

Finance::Robinhood - Trade Stocks and ETFs with Commission Free Brokerage Robinhood

# SYNOPSIS

    use Finance::Robinhood;

    my $rh = Finance::Robinhood->new();

    my $token = $rh->login($user, $password); # Store it for later

    $rh->quote('MSFT');
    Finance::Robinhood::quote('AAPL');
    # ????
    # Profit

# Examples

Some people have really only be reading this to get an automated stock trading
bot up and running. If that's you, the quickest way to get in without a load
of looking through documentation would be to move over to any of the example
scripts that I've included with this distributio:

- `eg/buy.pl`

    Buy stocks from the command line

        buy.pl -username=getMoney -password=*** -symbol=MSFT -quantity=2000

    Currently only market orders are supported but adding all the different limit
    order types is really rather simple. I might update it myself if I find a
    round tuit somewhere this summer. Might even add a sell script...

- `eg/export_orders.pl`

    Export your entire Robinhood order history to a CSV file from the command line

        buy -username=getMoney -password=*** -output=Robinhood.csv

    You can dump the CSV to STDOUT by leaving `-output` undefined.

Both scripts provide help when called without arguments. In addition to those
examples, you should check out the unofficial documentation of Robinhood
trade's API. Find it on github:
[https://github.com/sanko/Finance-Robinhood/blob/master/API.md](https://github.com/sanko/Finance-Robinhood/blob/master/API.md)

# DESCRIPTION

Finance::Robinhood allows you to buy, sell, and gather information related to
stocks and ETFs traded in the U.S commission free. Before we get into how,
please read the [Legal](https://metacpan.org/pod/LEGAL) section below. It's really important.

Okay. This package is organized into very easy to understand parts:

- Orders to buy and sell are created in [Finance::Robinhood::Order](https://metacpan.org/pod/Finance::Robinhood::Order). If
you're looking to make this as simple as possible, go check out the
[cheat sheet](https://metacpan.org/pod/Finance::Robinhood::Order#Order-Cheat-Sheet). You'll find
recipes for market, limit, as well as stop loss and stop limit order types.
- Quote information can be accessed with [Finance::Robinhood::Quote](https://metacpan.org/pod/Finance::Robinhood::Quote).
- Account information is handled by [Finance::Robinhood::Account](https://metacpan.org/pod/Finance::Robinhood::Account). If
you'd like to view or edit any of the information Robinhood has on you, start
there.
- Individual securities are represented by
[Finance::Robinhood::Instrument](https://metacpan.org/pod/Finance::Robinhood::Instrument) objects. Gathering quote and fundamental
information is only the beginning.
- [Finance::Robinhood::Watchlist](https://metacpan.org/pod/Finance::Robinhood::Watchlist) objects represent persistant lists of
securities you'd like to keep track of. Organize your watchlists by type!

If you're looking to just buy and sell without lot of reading, head over to
the [Finance::Robinhood::Order](https://metacpan.org/pod/Finance::Robinhood::Order) and pay special attention to the
[order cheat sheet](https://metacpan.org/pod/Finance::Robinhood::Order#Order-Cheat-Sheet) and apply
what you learn to the `eg/buy.pl` example script.

# METHODS

Finance::Robinhood wraps a powerfully capable API which has many options.
There are parts of this package that are object oriented (because they require
persistant login information) and others which may also be used functionally
(because they do not require login information). I've attempted to organize
everything according to how and when they are used... Let's start at the very
beginning: let's log in!

# Logging In

Robinhood requires an authorization token for most API calls. To get this
token, you must either pass it as an argument to `new( ... )` or log in with
your username and password.

## `new( ... )`

    # Passing the token is the preferred way of handling authorization
    my $rh = Finance::Robinhood->new( token => ... );

This would create a new Finance::Robinhood object ready to go.

    # Requires ->login(...) call :(
    my $rh = Finance::Robinhood->new( );

Without arguments, a new Finance::Robinhood object is created without account
information. Before you can buy or sell or do almost anything else, you must
[log in manually](#login).

On the bright side, for future logins, you can store the authorization token
and use it rather than having to pass your username and password around
anymore.

## `login( ... )`

    my $token = $rh->login($user, $password);
    # Save the token somewhere

Logging in allows you to buy and sell securities with your Robinhood account.
You must do this if you do not have an authorization token.

If login was successful, a valid token is returned and may also be had by
calling `token( )`. The token should be kept secret and stored for use in
future calls to `new( ... )`.

## `token( )`

If you logged in with a username/password combo but later decided you might
want to securely store authorization info to pass to `new( ... )` next time.
Get the authorization token here.

## `logout( )`

    my $token = $rh->login($user, $password);
    # ...do some stuff... buy... sell... idk... stuff... and then...
    $rh->logout( ); # Goodbye!

Logs you out of Robinhood by forcing the token returned by `login(...)` or
passed to `new(...)` to expire.

_Note_: This will log you out _everywhere_ because Robinhood generates a
single authorization token per account at a time! All logged in clients will
be logged out. This is good in rare case your device or the token itself is
stolen.

## `forgot_password( ... )`

    Finance::Robinhood::forgot_password('contact@example.com');

It happens. This requests a password reset email to be sent from Robinhood.

## `change_password( ... )`

    Finance::Robinhood::change_password( $username, $password, $token );

When you've forgotten your password, the email Robinhood send contains a link
to an online form where you may change your password. That link has a token
you may use here to change the password as well.

# User Information

Brokerage firms must collect a lot of information about their customers due to
IRS and SEC regulations. They also keep data to identify you internally.
Here's how to access all of the data you entered when during registration and
beyond.

## `user_id( )`

    my $user_id = $rh->user_id( );

Returns the ID Robinhood uses to identify this particular account. You could
also gather this information with the `user_info( )` method.

## `user_info( )`

    my %info = $rh->user_info( );
    say 'My name is ' . $info{first_name} . ' ' . $info{last_name};

Returns very basic information (name, email address, etc.) about the currently
logged in account as a hash.

## `basic_info( )`

This method grabs basic but more private information about the user including
their date of birth, marital status, and the last four digits of their social
security number.

## `additional_info( )`

This method grabs information about the user that the SEC would like to know
including any affiliations with publicly traded securities.

## `employment_info( )`

This method grabs information about the user's current employment status and
(if applicable) current job.

## `investment_profile( )`

This method grabs answers about the user's investment experience gathered by
the survey performed during registration.

## `identity_mismatch( )`

Returns a paginated list of identification information.

# Accounts

A user may have access to more than a single Robinhood account. Each account
is represented by a Finance::Robinhood::Account object internally. Orders to
buy and sell securities require an account object. The object also contains
information about your financial standing.

For more on how to use these objects, please see the
Finance::Robinhood::Account docs.

## `accounts( ... )`

This method returns a paginated list of Finance::Robinhood::Account objects
related to the currently logged in user.

_Note_: Not sure why the API returns a paginated list of accounts. Perhaps
in the future a single user will have access to multiple accounts?

# Financial Instruments

Financial Instrument is a fancy term for any equity, asset, debt, loan, etc.
but we'll strictly be referring to securities (stocks and ETFs) as financial
instruments.

We use blessed Finance::Robinhood::Instrument objects to represent securities
in order transactions, watchlists, etc. It's how we'll refer to a security so
looking over the documentation found in Finance::Robinhood::Instrument would
be a wise thing to do.

## `instrument( ... )`

    my $msft = $rh->instrument('MSFT');
    my $msft = Finance::Robinhood::instrument('MSFT');

When a single string is passed, only the exact match for the given symbol is
returned as a Finance::Robinhood::Instrument object.

    my $msft = $rh->instrument({id => '50810c35-d215-4866-9758-0ada4ac79ffa'});
    my $msft = Finance::Robinhood::instrument({id => '50810c35-d215-4866-9758-0ada4ac79ffa'});

If a hash reference is passed with an `id` key, the single result is returned
as a Finance::Robinhood::Instrument object. The unique ID is how Robinhood
identifies securities internally.

    my $results = $rh->instrument({query => 'solar'});
    my $results = Finance::Robinhood::instrument({query => 'solar'});

If a hash reference is passed with a `query` key, results are returned as a
hash reference with cursor keys (`next` and `previous`). The matching
securities are Finance::Robinhood::Instrument objects which may be found in
the `results` key as a list.

    my $results = $rh->instrument({cursor => 'cD04NjQ5'});
    my $results = Finance::Robinhood::instrument({cursor => 'cD04NjQ5'});

Results to a query may generate more than a single page of results. To gather
them, use the `next` or `previous` values.

    my $results = $rh->instrument( );
    my $results = Finance::Robinhood::instrument( );

Returns a paginated list of securities as Finance::Robinhood::Instrument
objects along with `next` and `previous` cursor values. The list is sorted
in reverse by their listing date. Use this to track securities that are new!

# Orders

Now that you've [logged in](#logging-in) and
[found the particular stock](#financial-instruments) you're interested in,
you probably want to buy or sell something. You do this by placing orders.

Orders are created by using the constructor found in Finance::Robinhood::Order
directly so have a look at the documentation there (especially the small cheat
sheet).

Once you've place the order, you'll want to keep track of them somehow. To do
this, you may use either of the following methods.

## `locate_order( ... )`

    my $order = $rh->locate_order( $order_id );

Returns a blessed Finance::Robinhood::Order object related to the buy or sell
order with the given id if it exits.

## `list_orders( ... )`

    my $orders = $rh->list_orders( );

Requests a list of all orders ordered from newest to oldest. Executed and even
canceled orders are returned in a `results` key as Finance::Robinhood::Order
objects. Cursor keys `next` and `previous` may also be present.

    my $more_orders = $rh->list_orders({ cursor => $orders->{next} });

You'll likely generate more than a hand full of buy and sell orders which
would generate more than a single page of results. To gather them, use the
`next` or `previous` values.

    my $new_orders = $rh->list_orders({ since => 1489273695 });

To gather orders placed after a certain date or time, use the `since`
parameter.

    my $new_orders = $rh->list_orders({ instrument => $msft });

Gather only orders related to a certain instrument. Pass a full
Finance::Robinhood::Instrument object.

# Quotes and Historical Data

If you're doing anything beyond randomly choosing stocks with a symbol
generator, you'll want to know a little more. Robinhood provides access to
both current and historical data on securities.

## `quote( ... )`

    my %msft = $rh->quote('MSFT');
    my $swa  = Finance::Robinhood::quote('LUV');

    my $quotes = $rh->quote('AAPL', 'GOOG', 'MA');
    my $quotes = Finance::Robinhood::quote('LUV', 'JBLU', 'DAL');

Requests current information about a security which is returned as a
Finance::Robinhood::Quote object. If `quote( ... )` is given a list of
symbols, the objects are returned as a paginated list.

This function has both functional and object oriented forms. The functional
form does not require an account and may be called without ever logging in.

## `fundamentals( ... )`

    my %msft = $rh->fundamentals('MSFT');
    my $swa  = Finance::Robinhood::fundamentals('LUV');

    my $fundamentals = $rh->fundamentals('AAPL', 'GOOG', 'MA');
       $fundamentals = Finance::Robinhood::fundamentals('LUV', 'JBLU', 'DAL');

Requests current information about a security which is returned as a
Finance::Robinhood::Fundamentals object. If `fundamentals( ... )`
is given a list of symbols, the objects are returned as a paginated list. The
API will accept up to ten (10) symbols at a time.

This function has both functional and object oriented forms. The functional
form does not require an account and may be called without ever logging in.

## `historicals( ... )`

    # Snapshots of basic quote data for every five minutes of the previous day
    my $msft = $rh->historicals('MSFT', '5minute', 'day');

You may retrieve historical quote data with this method. The first argument is
a symbol. The second is an interval time and must be either `5minute`,
`10minute`, `day`, or `week`. The third argument is a span of time
indicating how far into the past you would like to retrieve and may be one of
the following: `day`, `week`, `year`, `5year`, or `all`. The fourth is a
bounds which is one of the following: `extended`, `regular`, `trading`.

All are optional and may be filled with an undefined value.

So, to get five years of weekly historical data for Apple, you would write...

    my $iHist = $rh->historicals('AAPL', 'week', '5year');
    my $gates = Finance::Robinhood::historicals('MSFT', 'week', '5year');

This method returns a list of hashes which in turn contain the following keys:

- `begins_at` - A Time::Piece or DateTime object indicating the timestamp
of this block of data.
- `close_price` - The most recent close price during this interval.
- `high_price` - The most recent high price during this interval.
- `interpolated` - Indicates whether the data was a statistical estimate.
This is a boolean value.
- `low_price` - The most recent low price during this interval.
- `open_price` - The most recent open price during this interval.
- `volume` - The trading volume during this interval.

Note that if you already have a Finance::Robinhood::Instrument object, you may
want to just call the object's `historicals( $interval, $span )` method which
wraps this.

This function has both functional and object oriented forms. The functional
form does not require an account and may be called without ever logging in.

# Informational Cards and Notifications

TODO

## `cards( )`

    my $cards = $rh->cards( );

Returns the informational cards the Robinhood apps display. These are links to
news, typically. Currently, these are returned as a paginated list of hashes
which look like this:

    {   action => "robinhood://web?url=https://finance.yahoo.com/news/spotify-agreement-win-artists-company-003248363.html",
        call_to_action => "View Article",
        fixed => bless(do{\(my $o = 0)}, "JSON::Tiny::_Bool"),
        icon => "news",
        message => "Spotify Agreement A 'win' For Artists, Company :Billboard Editor",
        relative_time => "2h",
        show_if_unsupported => 'fix',
        time => "2016-03-19T00:32:48Z",
        title => "Reuters",
        type => "news",
        url => "https://api.robinhood.com/notifications/stack/4494b413-33db-4ed3-a9d0-714a4acd38de/",
    }

\* Please note that the `url` provided by the API is incorrect! Rather than
`"https://api.robinhood.com/notifications/stack/4494b413-33db-4ed3-a9d0-714a4acd38de/"`,
it should be
`<"https://api.robinhood.com/**midlands/**notifications/stack/4494b413-33db-4ed3-a9d0-714a4acd38de/"`>.

# Dividends

TODO

## `dividends( )`

Gathers a paginated list of dividends due (or recently paid) for your account.

`results` currently contains a list of hashes which look a lot like this:

    { account => "https://api.robinhood.com/accounts/XXXXXXXX/",
      amount => 0.23,
      id => "28a46be1-db41-4f75-bf89-76c803a151ef",
      instrument => "https://api.robinhood.com/instruments/39ff611b-84e7-425b-bfb8-6fe2a983fcf3/",
      paid_at => undef,
      payable_date => "2016-04-25",
      position => "1.0000",
      rate => "0.2300000000",
      record_date => "2016-02-29",
      url => "https://api.robinhood.com/dividends/28a46be1-db41-4f75-bf89-76c803a151ef/",
      withholding => "0.00",
    }

# Watchlists

You can keep track of a list of securities by adding them to a watchlist. The
watchlist used by the official Robinhood apps and preloaded with popular
securities is named 'Default'. You may create new watchlists for
organizational reasons but the official apps currently only display the
'Default' watchlist.

Each watchlist is represented by a Finance::Robinhood::Watchlist object.
Please read the docs for that package to find out how to add and remove
individual securities.

## `watchlist( ... )`

    my $hotlist = $rh->watchlist( 'Blue_Chips' );

Returns a blessed Finance::Robinhood::Watchlist if the watchlist with the
given name exists.

## `create_watchlist( ... )`

    my $watchlist = $rh->create_watchlist( 'Energy' );

You can create new Finance::Robinhood::Watchlist objects with this. Here, your
code would create a new one named "Energy".

Note that only alphanumeric characters and understore are allowed in watchlist
names. No whitespace, etc.

## `delete_watchlist( ... )`

    my $watchlist = $rh->create_watchlist( 'Energy' );
    $rh->delete_watchlist( $watchlist );

    $rh->create_watchlist( 'Energy' );
    $rh->delete_watchlist( 'Energy' );

You may remove a watchlist with this method. The argument may either be a
Finance::Robinhood::Watchlist object or the name of the watchlist as a string.

If you clobber the watchlist named 'Default', it will be recreated with
popular securities the next time you open any of the official apps.

## `watchlists( ... )`

    my $watchlists = $rh->watchlists( );

Returns all your current watchlists as a paginated list of
Finance::Robinhood::Watchlists.

    my $more = $rh->watchlists( { cursor => $watchlists->{next} } );

In case where you have more than one page of watchlists, use the `next` and
`previous` cursor strings.

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
