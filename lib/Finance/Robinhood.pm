package Finance::Robinhood;
use 5.008001;
use strict;
use warnings;
use Carp;
our $VERSION = "0.01";
use Data::Dump qw[ddx];
use Moo;
use HTTP::Tiny;
use JSON::Tiny qw[decode_json];
use strictures 2;
use namespace::clean;
#
use lib '../../lib';
use Finance::Robinhood::Account;
use Finance::Robinhood::Instrument;
use Finance::Robinhood::Order;
use Finance::Robinhood::Quote;
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
    my $acct = shift->_get_accounts();
    return $acct ? $acct->[0] : ();
}
#
my $base = 'https://api.robinhood.com/';

# Different endpoints we can call for the API
my %endpoints = ('accounts'                => 'accounts/',
                 'accounts/portfolio'      => 'accounts/%s/portfolio',
                 'accounts/positions'      => 'accounts/%s/positions',
                 'ach_deposit_schedules'   => 'ach/deposit_schedules/',
                 'ach_iav_auth'            => 'ach/iav/auth/',
                 'ach_relationships'       => 'ach/relationships/',
                 'ach_transfers'           => 'ach/transfers/',
                 'applications'            => 'applications/',
                 'dividends'               => 'dividends/',
                 'document_requests'       => 'upload/document_requests/',
                 'edocuments'              => 'documents/',
                 'fundamentals'            => 'fundamentals/%s',
                 'instruments'             => 'instruments/',
                 'login'                   => 'api-token-auth/',
                 'margin_upgrades'         => 'margin/upgrades/',
                 'markets'                 => 'markets/',
                 'notifications'           => 'notifications/',
                 'notifications/devices'   => 'notifications/devices/',
                 'orders'                  => 'orders/',
                 'password_reset'          => 'password_reset/request/',
                 'quote'                   => 'quote/',
                 'quotes'                  => 'quotes/',
                 'user'                    => 'user/',
                 'user/additional_info'    => 'user/additional_info/',
                 'user/basic_info'         => 'user/basic_info/',
                 'user/employment'         => 'user/employment/',
                 'user/investment_profile' => 'user/investment_profile/',
                 'watchlists'              => 'watchlists/'
);
$endpoints{$_} = $base . $endpoints{$_} for keys %endpoints;
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

sub login {
    my ($self, $username, $password) = @_;

    # Make API Call
    my $rt = _send_request(undef, 'GET',
                           $endpoints{login},
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
#
# Return the accounts of the user.
#
sub _get_accounts {
    my ($self) = @_;
    my $return = $self->_send_request('GET', $endpoints{'accounts'});
    $return // return !1;

    # TODO: Deal with next and previous results? Multiple accounts?
    return [
        map {
            #        ddx $self->_send_request($_->{url});
            #        ddx $self->_send_request($_->{portfolio});
            #        ddx $self->_send_request($_->{positions});
            Finance::Robinhood::Account->new($_)
        } @{$return->{results}}
    ];
}
#
# Returns the porfillo summery of an account by url.
#
sub get_portfolio {
    my ($self, $url) = @_;
    return $self->_send_request('GET', $url);
}
#
# Return the positions for an account.
# This is sort of a heavy call as it makes many API calls to populate all the data.
#
sub get_current_positions {
    my ($self, $account) = @_;
    my @rt;

    # Get the positions.
    my $pos =
        $self->_send_request('GET',
                             sprintf($endpoints{'accounts/positions'},
                                     $account->account_number()
                             )
        );

    # Now loop through and get the ticker information.
    for my $result (@{$pos->{results}}) {
        ddx $result;

        # We ignore past stocks that we traded.
        if ($result->{'quantity'} > 0) {

            # TODO: If the call fails, deal with it as ()
            my $instrument = Finance::Robinhood::Instrument->new('GET',
                               $self->_send_request($result->{'instrument'}));

            # Add on to the new array.
            push @rt, $instrument;
        }
    }
    return @rt;
}

=cut

    def get_account_number(self):
        ''' Returns the brokerage account number of the account logged in.
        This is currently only used for placing orders, so you can ignore
        method. '''
        res = self.session.get(self.endpoints['accounts'])
        if res.status_code == 200:
            accountURL = res.json()['results'][0]['url']
            account_number = accountURL[accountURL.index('accounts')+9:-1]
            return account_number
        else:
            raise Exception("Could not retrieve account number: " + res.text)
=cut

sub instrument {

#my $msft      = Finance::Robinhood::instrument('MSFT');
#my $msft      = $rh->instrument('MSFT');
#my ($results) = $rh->instrument({query  => 'FREE'});
#my ($results) = $rh->instrument({cursor => 'cD04NjQ5'});
#my $msft      = $rh->instrument({id     => '50810c35-d215-4866-9758-0ada4ac79ffa'});
    my $self = shift if ref $_[0] && ref $_[0] eq __PACKAGE__;
    my ($type) = @_;
    my $result = _send_request($self, 'GET',
                               $endpoints{instruments}
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
    my $self = ref $_[0] ? shift : ();    # might be undef but thtat's okay
    if (scalar @_ > 1) {
        my $quote =
            _send_request($self, 'GET',
                          $endpoints{quotes} . '?symbols=' . join ',', @_);
        return $quote
            ?
            (map { Finance::Robinhood::Quote->new($_) }
             @{$quote->{results}})
            : ();
    }
    my $quote
        = _send_request($self, 'GET', $endpoints{'quotes'} . shift . '/');
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

    #warn $endpoints{'orders'};
    #warn $endpoints{'accounts'} . $self->account()->account_number() . '/';
    # Make API Call
    ddx $instrument;
    my $rt = $self->_send_request(
        $endpoints{'orders'},
        {account => $endpoints{'accounts'}
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
    ddx $rt;
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

sub list_orders {
    my ($self, $type) = @_;
    my $result = $self->_send_request('GET',
                                      $endpoints{orders}
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
        return ();
    }

    # Decode the response.
    my $json = $res->{content};

    #ddx $res;
    #warn $res->{content};
    my $rt = $json ? decode_json($json) : ();

    # Return happy.
    return wantarray ? ($rt, $res) : $rt;
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

=head2 C<get_accounts( ... )>

Returns a list of Finance::Robinhood::Account objects related to the
currently logged in user.

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

=head2 C<quote( ... )>

    my %msft  = $rh->quote('MSFT');
    my $swa  = Finance::Robinhood::quote('LUV');

    my ($ios, $plus, $work) = $rh->quote('APPL', 'GOOG', 'MA');
    my ($bird, $plane, $superman) = Finance::Robinhood::quote('LUV', 'JBLU', 'DAL');

Requests current information about a security which is returned as a
Finance::Robinhood::Quote object. If C<quote( ... )> is given a list of
symbols, the objects are returned as a list.

This function has both functional and object oriented forms. The functional
form does not require an account and may be called without ever logging in.

=head1 LEGAL

This is a simple wrapper around the API used in the official apps. The author
provides no investment, legal, or tax advice and is not responsible for any
damages incured while using this software. Neither this software nor its
author are affiliated with Robinhood Financial LLC in any way.

For Robinhood's terms and disclosures, please see their website at http://robinhood.com/

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Other copyrights, terms, and conditions may apply to data transmitted through
this module. Please refer to the L<LEGAL> section.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut
