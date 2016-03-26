package Finance::Robinhood;
use 5.010;
use strict;
use warnings;
use Carp;
our $VERSION = "0.01";
#use Data::Dump qw[ddx];
use Moo;
use HTTP::Tiny '0.056';
use JSON::Tiny qw[decode_json];
use strictures 2;
use namespace::clean;
use DateTime;
#
use lib '../../lib';
use Finance::Robinhood::Account;
use Finance::Robinhood::Instrument;
use Finance::Robinhood::Order;
use Finance::Robinhood::Position;
use Finance::Robinhood::Quote;
use Finance::Robinhood::Watchlist;
#
has token => (is => 'ro', writer => '_set_token');
has account => (
    is  => 'ro',
    isa => sub {
        die "$_[0] is not an ::Account!"
            unless ref $_[0] eq 'Finance::Robinhood::Account';
    },
    builder => 1,
    lazy    => 1
);

sub _build_account {
    my $acct = shift->_accounts();
    return $acct ? $acct->[0] : ();
}
#
my $base = 'https://api.robinhood.com/';

# Different endpoints we can call for the API
my %endpoints = (
                'accounts'              => 'accounts/',
                'accounts/portfolios'   => 'portfolios/',
                'accounts/positions'    => 'accounts/%s/positions/',
                'ach_deposit_schedules' => 'ach/deposit_schedules/',
                'ach_iav_auth'          => 'ach/iav/auth/',
                'ach_relationships'     => 'ach/relationships/',
                'ach_transfers'         => 'ach/transfers/',
                'applications'          => 'applications/',
                'dividends'             => 'dividends/',
                'document_requests'     => 'upload/document_requests/',
                'edocuments'            => 'documents/',
                'fundamentals'          => 'fundamentals/%s',
                'instruments'           => 'instruments/',
                'login'                 => 'api-token-auth/',
                'logout'                => 'api-token-logout/',
                'margin_upgrades'       => 'margin/upgrades/',
                'markets'               => 'markets/',
                'notifications'         => 'notifications/',
                'notifications/devices' => 'notifications/devices/',
                'cards'                 => 'midlands/notifications/stack/',
                'cards/dismiss' => 'midlands/notifications/stack/%s/dismiss/',
                'orders'        => 'orders/',
                'password_reset'          => 'password_reset/request/',
                'quote'                   => 'quote/',
                'quotes'                  => 'quotes/',
                'quotes/historicals'      => 'quotes/historicals/',
                'user'                    => 'user/',
                'user/additional_info'    => 'user/additional_info/',
                'user/basic_info'         => 'user/basic_info/',
                'user/employment'         => 'user/employment/',
                'user/investment_profile' => 'user/investment_profile/',
                'watchlists'              => 'watchlists/',
                'watchlists/bulk_add'     => 'watchlists/%s/bulk_add/'
);

sub endpoint {
    $endpoints{$_[0]} ?
        'https://api.robinhood.com/' . $endpoints{+shift}
        : ();
}
#
# Send a username and password to Robinhood to get back a token.
#
my ($client, $res);
my %headers = (
    'Accept' => '*/*',

    #'Accept-Encoding' => 'gzip, deflate',
    'Accept-Language' =>
        'en;q=1, fr;q=0.9, de;q=0.8, ja;q=0.7, nl;q=0.6, it;q=0.5',
    'Content-Type' => 'application/x-www-form-urlencoded; charset=utf-8',
    'X-Robinhood-API-Version' => '1.0.0',
    'Connection'              => 'keep-alive',
    'User-Agent' => 'Robinhood/823 (iPhone; iOS 7.1.2; Scale/2.00)'
);
sub errors { shift; carp shift; }

sub login {
    my ($self, $username, $password) = @_;

    # Make API Call
    my $rt = _send_request(undef, 'POST',
                           Finance::Robinhood::endpoint('login'),
                           {username => $username,
                            password => $password
                           }
    );

    # Make sure we have a token.
    if (!$rt || !defined($rt->{token})) {
        $self->errors('auth(): Robinhood API did not return a valid token.');
        return !1;
    }

    # Set the token we just received.
    return $self->_set_token($rt->{token});
}

sub logout {
    my ($self, $username, $password) = @_;

    # Make API Call
    my $rt = _send_request(undef, 'POST',
                           Finance::Robinhood::endpoint('logout'));

    # The old token is now invalid, so we might as well delete it
    return $self->_set_token(());
}

sub accounts {
    my ($self) = @_;

    # TODO: Deal with next and previous results? Multiple accounts?
    my $return = $self->_send_request('GET',
                                      Finance::Robinhood::endpoint('accounts')
    );
    return $self->_paginate($return, 'Finance::Robinhood::Account');
}
#
# Returns the porfillo summery of an account by url.
#
#sub get_portfolio {
#    my ($self, $url) = @_;
#    return $self->_send_request('GET', $url);
#}
#
# Return the positions for an account.
# This is sort of a heavy call as it makes many API calls to populate all the data.
#
#sub get_current_positions {
#    my ($self, $account) = @_;
#    my @rt;
#
#    # Get the positions.
#    my $pos =
#        $self->_send_request('GET',
#                             sprintf(Finance::Robinhood::endpoint(
#                                                        'accounts/positions'),
#                                     $account->account_number()
#                             )
#        );
#
#    # Now loop through and get the ticker information.
#    for my $result (@{$pos->{results}}) {
#        ddx $result;
#
#        # We ignore past stocks that we traded.
#        if ($result->{'quantity'} > 0) {
#
#            # TODO: If the call fails, deal with it as ()
#            my $instrument = Finance::Robinhood::Instrument->new('GET',
#                               $self->_send_request($result->{'instrument'}));
#
#            # Add on to the new array.
#            push @rt, $instrument;
#        }
#    }
#    return @rt;
#}
sub instrument {

#my $msft      = Finance::Robinhood::instrument('MSFT');
#my $msft      = $rh->instrument('MSFT');
#my ($results) = $rh->instrument({query  => 'FREE'});
#my ($results) = $rh->instrument({cursor => 'cD04NjQ5'});
#my $msft      = $rh->instrument({id     => '50810c35-d215-4866-9758-0ada4ac79ffa'});
    my $self = shift if ref $_[0] && ref $_[0] eq __PACKAGE__;
    my ($type) = @_;
    my $result = _send_request($self, 'GET',
                               Finance::Robinhood::endpoint('instruments')
                                   . (  !defined $type ? ''
                                      : !ref $type     ? '?query=' . $type
                                      : ref $type eq 'HASH'
                                          && defined $type->{cursor}
                                      ? '?cursor=' . $type->{cursor}
                                      : ref $type eq 'HASH'
                                          && defined $type->{query}
                                      ? '?query=' . $type->{query}
                                      : ref $type eq 'HASH'
                                          && defined $type->{id}
                                      ? $type->{id} . '/'
                                      : ''
                                   )
    );
    $result // return !1;

    #ddx $result;
    my $retval = ();
    if (defined $type && !ref $type) {
        ($retval) = map { Finance::Robinhood::Instrument->new($_) }
            grep { $_->{symbol} eq $type } @{$result->{results}};
    }
    elsif (defined $type && ref $type eq 'HASH' && defined $type->{id}) {
        $retval = Finance::Robinhood::Instrument->new($result);
    }
    else {
        $result->{previous} =~ m[\?cursor=(.+)]
            if defined $result->{previous};
        my $prev = $1 // ();
        $result->{next} =~ m[\?cursor=(.+)] if defined $result->{next};
        my $next = $1 // ();
        $retval = {results => [map { Finance::Robinhood::Instrument->new($_) }
                                   @{$result->{results}}
                   ],
                   previous => $prev,
                   next     => $next
        };
    }
    return $retval;
}

sub quote {
    my $self = ref $_[0] ? shift : ();    # might be undef but that's okay
    if (scalar @_ > 1) {
        my $return =
            _send_request($self, 'GET',
              Finance::Robinhood::endpoint('quotes') . '?symbols=' . join ',',
              @_);
        return _paginate($self, $return, 'Finance::Robinhood::Quote');
    }
    my $quote =
        _send_request($self, 'GET',
                      Finance::Robinhood::endpoint('quotes') . shift . '/');
    return $quote ?
        Finance::Robinhood::Quote->new($quote)
        : ();
}

sub quote_price {
    return shift->quote(shift)->[0]{last_trade_price};
}

sub _place_order {
    my ($self, $instrument, $quantity, $side, $order_type, $bid_price,
        $time_in_force, $stop_price)
        = @_;
    $time_in_force //= 'gfd';    # Good For Day

#warn Finance::Robinhood::endpoint('orders');
#warn Finance::Robinhood::endpoint('accounts') . $self->account()->account_number() . '/';
# Make API Call
    #ddx $instrument;
    my $rt = $self->_send_request(
        'GET',
        Finance::Robinhood::endpoint('orders'),
        {account => Finance::Robinhood::endpoint('accounts')
             . $self->account()->account_number() . '/',
         instrument    => $instrument->url(),
         quantity      => $quantity,
         side          => $side,
         symbol        => $instrument->symbol(),
         time_in_force => $time_in_force,
         trigger       => 'immediate',
         type          => $order_type,
         ($order_type eq 'market' ?
              (    #price => $instrument->bid_price()
              )
          : $order_type eq 'limit'     ? (price      => $bid_price)
          : $order_type eq 'stop_loss' ? (stop_price => $stop_price)
          : $order_type eq 'stop_limit'
          ? (price => $bid_price, stop_price => $stop_price)
          :

            # TODO: stop_limit and stop_loss order types are works in progress
              ()
         )
        }
    );
    #ddx $rt;
    return $rt ? Finance::Robinhood::Order->new($rt) : ();
}

sub place_buy_order {    # TODO: Test and document
    my ($self, $instrument, $quantity, $order_type, $bid_price) = @_;

# TODO: Make this accept a hash with keys:
# { bid_price  => $int,
#   quantity   => $int,
#   instrument => Finance::Robinhood::Instrument,
#   # Optional w/ defaults
#   trigger    => 'gfd' (Good For Day, other options are 'gtc' Good Till Cancelled, 'oco' Order Cancels Other)
#   time       => 'immediate' (execute trade now or cancel, other option is 'day' where the trade is canceled if not executed by day's end)
#   type       => 'market'
# }
#    def place_sell_order(self, symbol, quantity, order_type=None, bid_price=None):
#
    return
        $self->_place_order($instrument, $quantity, 'buy',
                            $order_type, $bid_price);
}

sub place_sell_order {    # TODO: Test and document
    my ($self, $instrument, $quantity, $order_type, $bid_price) = @_;

#    def place_sell_order(self, symbol, quantity, order_type=None, bid_price=None):
#
    return
        $self->_place_order($instrument, $quantity, 'sell',
                            $order_type, $bid_price);
}

sub order {
    my ($self, $order_id) = @_;
    my $result = $self->_send_request('GET',
                    Finance::Robinhood::endpoint('orders') . $order_id . '/');
    return $result ?
        Finance::Robinhood::Order->new(rh => $self, %$result)
        : ();
}

sub list_orders {
    my ($self, $type) = @_;
    my $result = $self->_send_request('GET',
                                      Finance::Robinhood::endpoint('orders')
                                          . (ref $type
                                                 && ref $type eq 'HASH'
                                                 && defined $type->{cursor}
                                             ?
                                                 '?cursor=' . $type->{cursor}
                                             : ''
                                          )
    );
    $result // return !1;
    return () if !$result;
    $result->{previous} =~ m[\?cursor=(.+)$] if defined $result->{previous};
    my $prev = $1 // ();
    $result->{next} =~ m[\?cursor=(.+)$] if defined $result->{next};
    my $next = $1 // ();
    return {
          results => [
              map { Finance::Robinhood::Order->new($_) } @{$result->{results}}
          ],
          previous => $prev,
          next     => $next
    };
}

sub cancel_order {
    my ($self, $order) = @_;
    return $self->_send_request('GET', $order->_get_cancel(), {});
}

# TODO:
#Pulls user info from API and stores it in Robinhood object

#sub get_user_info {
#    my $self = shift;
#    my $response
#        = $self->_send_request('GET', Finance::Robinhood::endpoint('user'));
    #ddx $response;
    #ddx $self->_send_request('GET', $response->{additional_info});
    #ddx $self->_send_request('GET', $response->{basic_info});
    #ddx $self->_send_request('GET', $response->{employment});
    #ddx $self->_send_request('GET', $response->{id_info});
    #ddx $self->_send_request('GET', $response->{international_info});
    #ddx $self->_send_request('GET', $response->{investment_profile});

    #res = self.session.get(self.endpoints['user'])
    #if res.status_code == 200:
    #    self.first_name = res.json()['first_name']
    #    self.last_name = res.json()['last_name']
    #else:
    #    raise Exception("Could not get user info: " + res.text)
    #res = self.session.get(self.endpoints['user/basic_info'])
    #if res.status_code == 200:
    #    res = res.json()
    #    self.phone_number = res['phone_number']
    #    self.city = res['city']
    #    self.number_dependents = res['number_dependents']
    #    self.citizenship = res['citizenship']
    #    self.marital_status = res['marital_status']
    #    self.zipcode = res['zipcode']
    #    self.state_residence = res['state']
    #    self.date_of_birth = res['date_of_birth']
    #    self.address = res['address']
    #    self.tax_id_ssn = res['tax_id_ssn']
    #else:
    #    raise Exception("Could not get basic user info: " + res.text)
#}

# Methods under construction
sub cards {
    return shift->_send_request('GET', Finance::Robinhood::endpoint('cards'));
}

sub dividends {
    return
        shift->_send_request('GET',
                             Finance::Robinhood::endpoint('dividends'));
}

sub notifications {
    return
        shift->_send_request('GET',
                             Finance::Robinhood::endpoint('notifications'));
}

sub notifications_devices {
    return
        shift->_send_request('GET',
                             Finance::Robinhood::endpoint(
                                                      'notifications/devices')
        );
}

sub create_watchlist {
    my ($self, $name) = @_;
    my $result = $self->_send_request('POST',
                                      Finance::Robinhood::endpoint(
                                                                'watchlists'),
                                      {name => $name}
    );
    return $result ?
        Finance::Robinhood::Watchlist->new(rh => $self, %$result)
        : ();
}

sub delete_watchlist {
    my ($self, $watchlist) = @_;
    my ($result, $response)
        = $self->_send_request('DELETE',
                               Finance::Robinhood::endpoint('watchlists')
                                   . $watchlist->name() . '/'
        );
    return $result->{status} == 204 ? 1 : !1;
}

sub watchlists {
    my ($self, $cursor) = @_;
    my $result = $self->_send_request('GET',
                                      Finance::Robinhood::endpoint(
                                                                 'watchlists')
                                          . (
                                            ref $cursor
                                                && ref $cursor eq 'HASH'
                                                && defined $cursor->{cursor}
                                            ?
                                                '?cursor=' . $cursor->{cursor}
                                            : ''
                                          )
    );
    $result // return !1;
    return () if !$result;
    return $self->_paginate($result, 'Finance::Robinhood::Watchlist');
}

sub _paginate {    # Paginates results
    my ($self, $res, $class) = @_;
    $res->{previous} =~ m[\?cursor=(.+)$] if defined $res->{previous};
    my $prev = $1 // ();
    $res->{next} =~ m[\?cursor=(.+)$] if defined $res->{next};
    my $next = $1 // ();
    return {results => [map { $class->new(%$_, ($self ? (rh => $self) : ())) }
                            @{$res->{results}}
            ],
            previous => $prev,
            next     => $next
    };
}

# ---------------- Private Helper Functions --------------- //
# Send request to API.
#
sub _send_request {

    # TODO: Expose errors (400:{detail=>'Not enough shares to sell'}, etc.)
    my ($self, $verb, $url, $data) = @_;

    # Make sure we have a token.
    if (defined $self && !defined($self->token)) {
        carp
            'No API token set. Please authorize by using ->login($user, $pass) or passing a token to ->new(...).';
        return !1;
    }

    # Setup request client.
    $client = HTTP::Tiny->new() if !defined $client;

    # Make API call.
    #warn $url;
    #ddx($verb, $url,
    #    {headers => {%headers,
    #                 ($self && defined $self->token()
    #                  ? (Authorization => 'Token ' . $self->token())
    #                  : ()
    #                 )
    #     },
    #     (defined $data ? (content => $client->www_form_urlencode($data))
    #      : ()
    #     )
    #    }
    #);

    #warn $post;
    $res = $client->request($verb, $url,
                            {headers => {%headers,
                                         ($self && defined $self->token()
                                          ? (Authorization => 'Token '
                                             . $self->token())
                                          : ()
                                         )
                             },
                             (defined $data
                              ? (content =>
                                  $client->www_form_urlencode($data))
                              : ()
                             )
                            }
    );

    # Make sure the API returned happy
    #ddx $res;
    if ($res->{status} != 200 && $res->{status} != 201) {
        carp 'Robinhood did not return a status code of 200 or 201. ('
            . $res->{status} . ')';
        #ddx $res;
        return wantarray ? ((), $res) : ();
    }

    # Decode the response.
    my $json = $res->{content};

    #ddx $res;
    #warn $res->{content};
    my $rt = $json ? decode_json($json) : ();

    # Return happy.
    return wantarray ? ($rt, $res) : $rt;
}

# Coerce strings into DateTime objects
sub _2_datetime {
    $_[0]
        =~ m[(\d{4})-(\d\d)-(\d\d)(?:T(\d\d):(\d\d):(\d\d)(?:\.(\d+))?(.+))?];

    # "2016-03-11T17:59:48.026546Z",
    #warn 'Y:' . $1;
    #warn 'M:' . $2;
    #warn 'D:' . $3;
    #warn 'h:' . $4;
    #warn 'm:' . $5;
    #warn 's:' . $6;
    #warn 'n:' . $7;
    #warn 'z:' . $8;
    DateTime->new(year  => $1,
                  month => $2,
                  day   => $3,
                  (defined $7 ? (hour       => $4) : ()),
                  (defined $7 ? (minute     => $5) : ()),
                  (defined $7 ? (second     => $6) : ()),
                  (defined $7 ? (nanosecond => $7) : ()),
                  (defined $7 ? (time_zone  => $8) : ())
    );
}
1;

#__END__

=encoding utf-8

=head1 NAME

Finance::Robinhood - Trade stocks and ETFs with free brokerage Robinhood

=head1 SYNOPSIS

    use Finance::Robinhood;

    my $rh = Finance::Robinhood->new();

    my $token = $rh->login($user, $password); # Store it for later

    $rh->quote('MSFT');
    Finance::Robinhood::quote('APPL');
    # ????
    # Profit

=head1 DESCRIPTION

This modules allows you to buy, sell, and gather information related to stocks
and ETFs traded in the U.S. Please see the L<Legal|LEGAL> section below.

=head1 METHODS

Finance::Robinhood is...

=head2 C<new( ... )>

    my $rh = Finance::Robinhood->new( ); # Reqires ->login(...) call
    my $rh = Finance::Robinhood->new( token => ... );

With no arguments, this creates a new Finance::Quote object without account
information. Before you can buy or sell, you must L<login( ... )|log in> which
will will return an authorization token which may be used for future logins
without your username and password.

=head2 C<login( ... )>

    my $token = $rh->login($user, $password);
    # Save the token somewhere

Logging in allows you to buy and sell securities with your Robinhood account.
You must do this if you do not have an authorization token.

If login was sucessful, a valid token is returned which should be stored for
use in future calls to C<new( ... )>.

=head2 C<logout( )>

    my $token = $rh->login($user, $password);
    $rh->logout( ); # Goodbye!

Logs you out of Robinhood by invalidating the token returned by
C<login( ... )> and passed to C<new(...)>.

=head2 C<accounts( ... )>

Returns a paginated list of Finance::Robinhood::Account objects related to the
currently logged in user.

I<Note>: Not sure why the API returns a paginated list of accounts. Perhaps
in the future a single user will have access to multiple accounts?

=head2 C<instrument( ... )>

    my $msft = $rh->instrument('MSFT');
    my $msft = Finance::Robinhood::instrument('MSFT');

When a single string is passed, only the exact match for the given symbol is
returned as a Finance::Robinhood::Instrument object.

    my $msft = $rh->instrument({id => '50810c35-d215-4866-9758-0ada4ac79ffa'});
    my $msft = Finance::Robinhood::instrument({id => '50810c35-d215-4866-9758-0ada4ac79ffa'});

If a hash reference is passed with an C<id> key, the single result is returned
as a Finance::Robinhood::Instrument object.

    my $results = $rh->instrument({query => 'solar'});
    my $results = Finance::Robinhood::instrument({query => 'solar'});

If a hash reference is passed with a C<query> key, results are returned as a
hash reference with cursor keys (C<next> and C<previous>). The matching
securities are Finance::Robinhood::Instrument objects which may be found in
the C<results> key as a list.

    my $results = $rh->instrument({cursor => 'cD04NjQ5'});
    my $results = Finance::Robinhood::instrument({cursor => 'cD04NjQ5'});

Results to a query may generate more than a single page of results. To gather
them, use the C<next> or C<previous> values.

    my $results = $rh->instrument( );
    my $results = Finance::Robinhood::instrument( );

Returns a sample list of top securities as Finance::Robinhood::Instrument
objects along with C<next> and C<previous> cursor values.

=head2 C<place_buy_order( ... )>

    $rh->place_buy_order($instrument, $number, $type);

Puts in an order to buy a given C<$number> of shares of the given
C<$instrument>. Currently, only C<'market'> type sales have been tested. A
Finance::Robinhood::Order object is returned if the order was sucessful.

=head2 C<place_sell_order( ... )>

    $rh->place_sell_order($instrument, $number, $type);

Puts in an order to sell a given C<$number> of shares of the given
C<$instrument>. Currently, only C<'market'> type sales have been tested. A
Finance::Robinhood::Order object is returned if the order was sucessful.

=head2 C<cancel_order( ... )>

    my $order = $rh->place_sell_order($instrument, $number, $type);
    $rh->cancel_order( $order ); # Whoops! Nevermind!

Cancels a buy or sell order if called before the order is executed.

=head2 C<list_orders( ... )>

    my $orders = $rh->list_orders( );

Requests a list of all orders ordered from newest to oldest. Executed and even
cancelled orders are returned in a C<results> key as Finance::Robinhood::Order
objects. Cursor keys C<next> and C<previous> may also be present.

    my $more_orders = $rh->list_orders({ cursor => $orders->{next} });

You'll likely generate more than a hand full of buy and sell orders which
would generate more than a single page of results. To gather them, use the
C<next> or C<previous> values.

=head2 C<order( ... )>

    my $order = $rh->order( $order_id );

Returns a Finance::Robinhood::Order object which contains information about an
order and its status.

=head2 C<quote( ... )>

    my %msft = $rh->quote('MSFT');
    my $swa  = Finance::Robinhood::quote('LUV');

    my $quotes = $rh->quote('APPL', 'GOOG', 'MA');
    my $quotes = Finance::Robinhood::quote('LUV', 'JBLU', 'DAL');

Requests current information about a security which is returned as a
Finance::Robinhood::Quote object. If C<quote( ... )> is given a list of
symbols, the objects are returned as a paginated list.

This function has both functional and object oriented forms. The functional
form does not require an account and may be called without ever logging in.

=head2 C<create_watchlist( ... )>

    my $watchlist = $rh->create_watchlist( 'Energy' );

You can create new Finance::Robinhood::Watchlist objects.

=head2 C<delete_watchlist( ... )>

    $rh->delete_watchlist( $watchlist );

You may remove a watchlist with this method.

=head2 C<watchlists( ... )>

    my $watchlists = $rh->watchlists( );

Returns all your current watchlists as a paginated list of
Finance::Robinhood::Watchlists.

    my $more = $rh->watchlists( { cursor => $watchlists->{next} } );

In case where you have more than one page of watchlists, use the C<next> and
C<previous> cursor strings.

=head2 C<cards( )>

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

* Please note that the C<url> provided by the API is incorrect! Rather than
C<"https://api.robinhood.com/notifications/stack/4494b413-33db-4ed3-a9d0-714a4acd38de/">,
it should be
C<<"https://api.robinhood.com/B<midlands/>notifications/stack/4494b413-33db-4ed3-a9d0-714a4acd38de/">>.

=head2 C<dividends( )>

Gathers a paginated list of dividends due (or recently paid) for your account.

C<results> currently contains a list of hashes which look a lot like this:

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

=head1 LEGAL

This is a simple wrapper around the API used in the official apps. The author
provides no investment, legal, or tax advice and is not responsible for any
damages incured while using this software. Neither this software nor its
author are affiliated with Robinhood Financial LLC in any way.

For Robinhood's terms and disclosures, please see their website at http://robinhood.com/

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify
it under the terms found in the Artistic License 2.

Other copyrights, terms, and conditions may apply to data transmitted through
this module. Please refer to the L<LEGAL> section.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut
