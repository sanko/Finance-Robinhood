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
    $rh->logout( ); # Goodbye!

Logs you out of Robinhood by invalidating the token returned by
`login( ... )` and passed to `new(...)`.

## `get_accounts( ... )`

Returns a list of Finance::Robinhood::Account objects related to the
currently logged in user.

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

## `place_buy_order( ... )`

    $rh->place_buy_order($instrument, $number, $type);

Puts in an order to buy a given `$number` of shares of the given
`$instrument`. Currently, only `'market'` type sales have been tested. A
Finance::Robinhood::Order object is returned if the order was sucessful.

## `place_sell_order( ... )`

    $rh->place_sell_order($instrument, $number, $type);

Puts in an order to sell a given `$number` of shares of the given
`$instrument`. Currently, only `'market'` type sales have been tested. A
Finance::Robinhood::Order object is returned if the order was sucessful.

## `cancel_order( ... )`

    my $order = $rh->place_sell_order($instrument, $number, $type);
    $rh->cancel_order( $order ); # Whoops! Nevermind!

Cancels a buy or sell order if called before the order is executed.

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

# LEGAL

This is a simple wrapper around the API used in the official apps. The author
provides no investment, legal, or tax advice and is not responsible for any
damages incured while using this software. Neither this software nor its
author are affiliated with Robinhood Financial LLC in any way.

For Robinhood's terms and disclosures, please see their website at http://robinhood.com/

# LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Other copyrights, terms, and conditions may apply to data transmitted through
this module. Please refer to the [LEGAL](https://metacpan.org/pod/LEGAL) section.

# AUTHOR

Sanko Robinson &lt;sanko@cpan.org>
