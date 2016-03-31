[![Build Status](https://travis-ci.org/sanko/Finance-Robinhood.svg?branch=master)](https://travis-ci.org/sanko/Finance-Robinhood)
# NAME

Finance::Robinhood - Trade stocks and ETFs with free brokerage Robinhood

# SYNOPSIS

    use Finance::Robinhood;

    my $rh = Finance::Robinhood->new();

    my $token = $rh->login($user, $password); # Store it for later

    $rh->quote('MSFT');
    Finance::Robinhood::quote('APPL');
    # ????
    # Profit

# DESCRIPTION

This modules allows you to buy, sell, and gather information related to stocks
and ETFs traded in the U.S. Please see the [Legal](https://metacpan.org/pod/LEGAL) section below.

# METHODS

Finance::Robinhood is...

## `new( ... )`

    my $rh = Finance::Robinhood->new( ); # Reqires ->login(...) call
    my $rh = Finance::Robinhood->new( token => ... );

With no arguments, this creates a new Finance::Quote object without account
information. Before you can buy or sell, you must [login( ... )](https://metacpan.org/pod/log&#x20;in) which
will will return an authorization token which may be used for future logins
without your username and password.

## `login( ... )`

    my $token = $rh->login($user, $password);
    # Save the token somewhere

Logging in allows you to buy and sell securities with your Robinhood account.
You must do this if you do not have an authorization token.

If login was sucessful, a valid token is returned which should be stored for
use in future calls to `new( ... )`.

## `logout( )`

    my $token = $rh->login($user, $password);
    # ...do some stuff... buy... sell... idk... stuff... and then...
    $rh->logout( ); # Goodbye!

Logs you out of Robinhood by forcing the token returned by
`login( ... )` or passed to `new(...)` to expire.

_Note_: This will log you out _everywhere_ because Robinhood generates a
single authorization token per account at a time!

## `forgot_password( ... )`

    Finance::Robinhood::forgot_password('contact@example.com');

This requests a password reset email to be sent from Robinhood.

## `change_password( ... )`

    Finance::Robinhood::change_password( $username, $password, $token );

Robinhood sends a link to the registered email address when the
`password_reset( ... )` function is called. In the email there is a link with
the username and a token. You must provide a new password.

## `user_info( )`

    my %info = $rh->user_info( );
    say 'My name is ' . $info{first_name} . ' ' . $info{last_name};

Returns very basic information (name, email address, etc.) about the currently
logged in account as a hash.

## `user_id( )`

    my $user_id = $rh->user_id( );

Returns the ID Robinhood uses to identify this particular account. You could
also gather this information with the `user_info( )` method.

## `basic_info( )`

This method grabs more private information about the user including their date
of birth, marital status, and the last four digits of their social security
number.

## `additional_info( )`

This method grabs information about the user that the SEC would like to know
including any affilations with publically traded securities.

## `employment_info( )`

This method grabs information about the user's current employment status and
(if applicable) current job.

## `investment_profile( )`

This method grabs answers about the user's investment experience gathered by
the survey performed during registration.

## `identity_mismatch( )`

Returns a paginated list of identification information.

## `accounts( ... )`

Returns a paginated list of Finance::Robinhood::Account objects related to the
currently logged in user.

_Note_: Not sure why the API returns a paginated list of accounts. Perhaps
in the future a single user will have access to multiple accounts?

## `instrument( ... )`

    my $msft = $rh->instrument('MSFT');
    my $msft = Finance::Robinhood::instrument('MSFT');

When a single string is passed, only the exact match for the given symbol is
returned as a Finance::Robinhood::Instrument object.

    my $msft = $rh->instrument({id => '50810c35-d215-4866-9758-0ada4ac79ffa'});
    my $msft = Finance::Robinhood::instrument({id => '50810c35-d215-4866-9758-0ada4ac79ffa'});

If a hash reference is passed with an `id` key, the single result is returned
as a Finance::Robinhood::Instrument object.

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

Returns a sample list of top securities as Finance::Robinhood::Instrument
objects along with `next` and `previous` cursor values.

## `locate_order( ... )`

    my $order = $rh->locate_order( $order_id );

Returns a blessed Finance::Robinhood::Order object related to the about the
buy or sell order with the given id.

## `list_orders( ... )`

    my $orders = $rh->list_orders( );

Requests a list of all orders ordered from newest to oldest. Executed and even
cancelled orders are returned in a `results` key as Finance::Robinhood::Order
objects. Cursor keys `next` and `previous` may also be present.

    my $more_orders = $rh->list_orders({ cursor => $orders->{next} });

You'll likely generate more than a hand full of buy and sell orders which
would generate more than a single page of results. To gather them, use the
`next` or `previous` values.

## `quote( ... )`

    my %msft = $rh->quote('MSFT');
    my $swa  = Finance::Robinhood::quote('LUV');

    my $quotes = $rh->quote('APPL', 'GOOG', 'MA');
    my $quotes = Finance::Robinhood::quote('LUV', 'JBLU', 'DAL');

Requests current information about a security which is returned as a
Finance::Robinhood::Quote object. If `quote( ... )` is given a list of
symbols, the objects are returned as a paginated list.

This function has both functional and object oriented forms. The functional
form does not require an account and may be called without ever logging in.

## `create_watchlist( ... )`

    my $watchlist = $rh->create_watchlist( 'Energy' );

You can create new Finance::Robinhood::Watchlist objects.

## `delete_watchlist( ... )`

    $rh->delete_watchlist( $watchlist );

You may remove a watchlist with this method.

## `watchlists( ... )`

    my $watchlists = $rh->watchlists( );

Returns all your current watchlists as a paginated list of
Finance::Robinhood::Watchlists.

    my $more = $rh->watchlists( { cursor => $watchlists->{next} } );

In case where you have more than one page of watchlists, use the `next` and
`previous` cursor strings.

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

# LEGAL

This is a simple wrapper around the API used in the official apps. The author
provides no investment, legal, or tax advice and is not responsible for any
damages incured while using this software. Neither this software nor its
author are affiliated with Robinhood Financial LLC in any way.

For Robinhood's terms and disclosures, please see their website at http://robinhood.com/

# LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify
it under the terms found in the Artistic License 2.

Other copyrights, terms, and conditions may apply to data transmitted through
this module. Please refer to the [LEGAL](https://metacpan.org/pod/LEGAL) section.

# AUTHOR

Sanko Robinson &lt;sanko@cpan.org>
