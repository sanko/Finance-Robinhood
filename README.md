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

## `get_accounts( ... )`

Returns a list of Financial::Robinhood::Account objects related to the
currently logged in user.

## `quote( ... )`

    my %msft  = $rh->quote('MSFT');
    my %quotes = $rh->quote('APPL', 'GOOG', 'MA');

    my $swa  = Financial::Robinhood::quote('LUV');
    my %quotes = Financial::Robinhood::quote('LUV');

Requests current information about a security which is returned as a hash.
Data is organized by symbol which in turn contains the following keys:

    adjusted_previous_close
    ask_price
    ask_size
    bid_price
    bid_size
    last_extended_hours_trade_price
    last_trade_price
    previous_close
    previous_close_date
    trading_halted
    updated_at

This function has both functional and object oriented forms. The functional
form does not require an account and may be called without ever logging in.

# LEGAL

This is a simple wrapper around the API used in the official apps. The author
provides no investment, legal, or tax advice and is not responsible for any
damages incured while using this software.

For Robinhood's terms and disclosures, please see their website at http://robinhood.com/

# LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Other copyrights, terms, and conditions may apply to data transmitted through
this module. Please refer to the [LEGAL](https://metacpan.org/pod/LEGAL) section.

# AUTHOR

Sanko Robinson &lt;sanko@cpan.org>
