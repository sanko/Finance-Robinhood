package Finance::Robinhood;
use 5.012;
use strict;
use warnings;
use Carp;
our $VERSION = "0.06";
use Moo;
use HTTP::Tiny '0.056';
use JSON::Tiny qw[decode_json];
use strictures 2;
use namespace::clean;
use DateTime;
our $DEBUG = !1;
require Data::Dump if $DEBUG;
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
#
my $base = 'https://api.robinhood.com/';

# Different endpoints we can call for the API
my %endpoints = (
                'accounts'               => 'accounts/',
                'accounts/positions'     => 'accounts/%s/positions/',
                'portfolios'             => 'portfolios/',
                'portfolios/historicals' => 'portfolios/historicals/',
                'ach_deposit_schedules'  => 'ach/deposit_schedules/',
                'ach_iav_auth'           => 'ach/iav/auth/',
                'ach_relationships'      => 'ach/relationships/',
                'ach_transfers'          => 'ach/transfers/',
                'applications'           => 'applications/',
                'dividends'              => 'dividends/',
                'document_requests'      => 'upload/document_requests/',
                'edocuments'             => 'documents/',
                'fundamentals'           => 'fundamentals/%s',
                'instruments'            => 'instruments/',
                'login'                  => 'api-token-auth/',
                'logout'                 => 'api-token-logout/',
                'margin_upgrades'        => 'margin/upgrades/',
                'markets'                => 'markets/',
                'notifications'          => 'notifications/',
                'notifications/devices'  => 'notifications/devices/',
                'cards'                  => 'midlands/notifications/stack/',
                'cards/dismiss' => 'midlands/notifications/stack/%s/dismiss/',
                'orders'        => 'orders/',
                'password_reset'          => 'password_reset/',
                'password_reset/request'  => 'password_reset/request/',
                'quote'                   => 'quote/',
                'quotes'                  => 'quotes/',
                'quotes/historicals'      => 'quotes/historicals/',
                'user'                    => 'user/',
                'user/id'                 => 'user/id/',
                'user/additional_info'    => 'user/additional_info/',
                'user/basic_info'         => 'user/basic_info/',
                'user/employment'         => 'user/employment/',
                'user/investment_profile' => 'user/investment_profile/',
                'user/identity_mismatch'  => 'user/identity_mismatch',
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
         'Accept-Language' =>
             'en;q=1, fr;q=0.9, de;q=0.8, ja;q=0.7, nl;q=0.6, it;q=0.5',
         'Content-Type' => 'application/x-www-form-urlencoded; charset=utf-8',
         'X-Robinhood-API-Version' => '1.70.0',
         'User-Agent' => 'Robinhood/823 (iPhone; iOS 7.1.2; Scale/2.00)'
);
sub errors { shift; carp shift; }

sub login {
    my ($self, $username, $password) = @_;

    # Make API Call
    my ($status, $data, $raw)
        = _send_request(undef, 'POST',
                        Finance::Robinhood::endpoint('login'),
                        {username => $username,
                         password => $password
                        }
        );

    # Make sure we have a token.
    if ($status != 200 || !defined($data->{token})) {
        $self->errors(join ' ', @{$data->{non_field_errors}});
        return !1;
    }

    # Set the token we just received.
    return $self->_set_token($data->{token});
}

sub logout {
    my ($self) = @_;

    # Make API Call
    my ($status, $rt, $raw)
        = $self->_send_request('POST',
                               Finance::Robinhood::endpoint('logout'));
    return $status == 200 ?

        # The old token is now invalid, so we might as well delete it
        $self->_set_token(())
        : ();
}

sub forgot_password {
    my $self = shift if ref $_[0] && ref $_[0] eq __PACKAGE__;
    my ($email) = @_;

    # Make API Call
    my ($status, $rt, $raw)
        = _send_request(undef, 'POST',
                       Finance::Robinhood::endpoint('password_reset/request'),
                       {email => $email});
    return $status == 200;
}

sub change_password {
    my $self = shift if ref $_[0] && ref $_[0] eq __PACKAGE__;
    my ($user, $password, $token) = @_;

    # Make API Call
    my ($status, $rt, $raw)
        = _send_request(undef, 'POST',
                        Finance::Robinhood::endpoint('password_reset'),
                        {username => $user,
                         password => $password,
                         token    => $token
                        }
        );
    return $status == 200;
}

sub user_info {
    my ($self) = @_;
    my ($status, $data, $raw)
        = $self->_send_request('GET', Finance::Robinhood::endpoint('user'));
    return $status == 200 ?
        map { $_ => $data->{$_} } qw[email id last_name first_name username]
        : ();
}

sub user_id {
    my ($self) = @_;
    my ($status, $data, $raw)
        = $self->_send_request('GET',
                               Finance::Robinhood::endpoint('user/id'));
    return $status == 200 ? $data->{id} : ();
}

sub basic_info {
    my ($self) = @_;
    my ($status, $data, $raw)
        = $self->_send_request('GET',
                             Finance::Robinhood::endpoint('user/basic_info'));
    return $status != 200 ?
        ()
        : ((map { $_ => _2_datetime(delete $data->{$_}) }
                qw[date_of_birth updated_at]
           ),
           map { m[url] ? () : ($_ => $data->{$_}) } keys %$data
        );
}

sub additional_info {
    my ($self) = @_;
    my ($status, $data, $raw)
        = $self->_send_request('GET',
                               Finance::Robinhood::endpoint(
                                                       'user/additional_info')
        );
    return $status != 200 ?
        ()
        : ((map { $_ => _2_datetime(delete $data->{$_}) } qw[updated_at]),
           map { m[user] ? () : ($_ => $data->{$_}) } keys %$data);
}

sub employment_info {
    my ($self) = @_;
    my ($status, $data, $raw)
        = $self->_send_request('GET',
                             Finance::Robinhood::endpoint('user/employment'));
    return $status != 200 ?
        ()
        : ((map { $_ => _2_datetime(delete $data->{$_}) } qw[updated_at]),
           map { m[user] ? () : ($_ => $data->{$_}) } keys %$data);
}

sub investment_profile {
    my ($self) = @_;
    my ($status, $data, $raw)
        = $self->_send_request('GET',
                               Finance::Robinhood::endpoint(
                                                    'user/investment_profile')
        );
    return $status != 200 ?
        ()
        : ((map { $_ => _2_datetime(delete $data->{$_}) } qw[updated_at]),
           map { m[user] ? () : ($_ => $data->{$_}) } keys %$data);
}

sub identity_mismatch {
    my ($self) = @_;
    my ($status, $data, $raw)
        = $self->_send_request('GET',
                               Finance::Robinhood::endpoint(
                                                     'user/identity_mismatch')
        );
    return $status == 200 ? $self->_paginate($data) : ();
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

sub historicals {
    my $self = ref $_[0] ? shift : ();    # might be undef but that's okay
    my ($symbol, $interval, $span) = @_;
    my ($status, $data, $raw)
        = _send_request($self,
                        'GET',
                        Finance::Robinhood::endpoint('quotes/historicals')
                            . "$symbol/?interval=$interval&$span"
        );
    return if $status != 200;
    for (@{$data->{historicals}}) {
        $_->{begins_at} = _2_datetime($_->{begins_at});
    }
    return $data->{historicals};
}

sub locate_order {
    my ($self, $order_id) = @_;
    my $result = $self->_send_request('GET',
                    Finance::Robinhood::endpoint('orders') . $order_id . '/');
    return $result ?
        Finance::Robinhood::Order->new(rh => $self, %$result)
        : ();
}

sub list_orders {
    my ($self, $type) = @_;
    my $result =
        $self->_send_request('GET',
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
    return $self->_paginate($result, 'Finance::Robinhood::Order');
}

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
    my ($status, $result)
        = $self->_send_request('POST',
                               Finance::Robinhood::endpoint('watchlists'),
                               {name => $name});
    return $status == 201
        ?
        Finance::Robinhood::Watchlist->new(rh => $self, %$result)
        : ();
}

sub delete_watchlist {
    my ($self, $watchlist) = @_;
    my ($status, $result, $response)
        = $self->_send_request('DELETE',
                               Finance::Robinhood::endpoint('watchlists')
                                   . (ref $watchlist ?
                                          $watchlist->name()
                                      : $watchlist
                                   )
                                   . '/'
        );
    return $status == 204;
}

sub watchlists {
    my ($self, $cursor) = @_;
    my $result =
        $self->_send_request('GET',
                             Finance::Robinhood::endpoint('watchlists')
                                 . (ref $cursor
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

sub watchlist {
    my ($self, $name) = @_;
    my ($status, $result)
        = $self->_send_request('GET',
                       Finance::Robinhood::endpoint('watchlists') . "$name/");
    return $status == 200 ?
        Finance::Robinhood::Watchlist->new(name => $name,
                                           rh   => $self,
                                           %$result
        )
        : ();
}

# ---------------- Private Helper Functions --------------- //
# Send request to API.
#
sub _paginate {    # Paginates results
    my ($self, $res, $class) = @_;
    my ($prev)
        = defined $res->{previous} ?
        ($res->{previous} =~ m[\?cursor=(.+)$])
        : ();
    my ($next)
        = defined $res->{next} ? ($res->{next} =~ m[\?cursor=(.+)$]) : ();
    return {
        results => (
            defined $class ?
                [
                map {
                    $class->new(%$_, ($self ? (rh => $self) : ()))
                } @{$res->{results}}
                ]
            : $res->{results}
        ),
        previous => $prev,
        next     => $next
    };
}

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
    if ($DEBUG) {
        warn "$verb $url";
        require Data::Dump;
        Data::Dump::ddx($verb, $url,
                        {headers => {%headers,
                                     ($self && defined $self->token()
                                      ? (Authorization => 'Token '
                                          . $self->token())
                                      : ()
                                     )
                         },
                         (defined $data
                          ? (content => $client->www_form_urlencode($data))
                          : ()
                         )
                        }
        );
    }

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
    if ($DEBUG) {
        require Data::Dump;
        Data::Dump::ddx($res);
    }

    #if ($res->{status} != 200 && $res->{status} != 201) {
    #    carp 'Robinhood did not return a status code of 200 or 201. ('
    #        . $res->{status} . ')';
    #    #ddx $res;
    #    return wantarray ? ((), $res) : ();
    #}
    # Decode the response.
    my $json = $res->{content};

    #ddx $res;
    #warn $res->{content};
    my $rt = $json ? decode_json($json) : ();

    # Return happy.
    return wantarray ? ($res->{status}, $rt, $res) : $rt;
}

# Coerce ISO 8601-ish strings into DateTime objects
sub _2_datetime {
    return if !$_[0];
    $_[0]
        =~ m[(\d{4})-(\d\d)-(\d\d)(?:T(\d\d):(\d\d):(\d\d)(?:\.(\d+))?(.+))?];
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

Finance::Robinhood - Trade Stocks and ETFs with Commission Free Brokerage Robinhood

=head1 SYNOPSIS

    use Finance::Robinhood;

    my $rh = Finance::Robinhood->new();

    my $token = $rh->login($user, $password); # Store it for later

    $rh->quote('MSFT');
    Finance::Robinhood::quote('APPL');
    # ????
    # Profit

=head1 DESCRIPTION

Finance::Robinhood allows you to buy, sell, and gather information related to
stocks and ETFs traded in the U.S. Before we get into how, please read the
L<Legal|LEGAL> section below. It's really important.

Okay. This package is organized into very easy to understand parts:

=over

=item * Orders to buy and sell are created in L<Finance::Robinhood::Order>. If
you're looking to make this as simple as possible, go check out the
L<cheat sheet|Finance::Robinhood::Order/"Order Cheat Sheet">. You'll find
recipes for market, limit, as well as stop loss and stop limit order types.

=item * Quote information can be access in L<Finance::Robinhood::Quote>.

=item * Account information is handled by L<Finance::Robinhood::Account>. If
you'd like to view or edit any of the information Robinhood has, start there.

=item * Individual securities are represented by Finance::Robinhood::Instrument
objects. Gathering quote and fundamental information is only the beginning.

=item * L<Finance::Robinhood::Watchlist> objects represent persistant lists of
securities you'd like to keep track of.

=back

By the way, if you're wondering how to buy and sell without lot of reading,
head over to the L<Finance::Robinhood::Order> and pay special attention to the
L<order cheat sheet|Finance::Robinhood::Order/"Order Cheat Sheet">.

=head1 METHODS

Finance::Robinhood wraps a powerfully capable API which has many options.
There are parts of this package that are object oriented and others which are
functional. I've attempted to organize everything according to how and when
they are used... Let's start at the very beginning: Let's log in!

=head1 Logging In

Robinhood requires an authorization token for most API calls. To get this
token, you must either pass it as an argument to C<new( ... )> or log in with
your username and password.

=head2 C<new( ... )>

    # Passing the token is the preferred way of handling authorization
    my $rh = Finance::Robinhood->new( token => ... );

This would create a new Finance::Robinhood object ready to go.

    # Requires ->login(...) call :(
    my $rh = Finance::Robinhood->new( );

With no arguments, this creates a new Finance::Robinhood object without
account information. Before you can buy or sell or do almost anything else,
you must log in manually.

On the bright side, for future logins, you can store the authorization token
and use it rather than having to pass your username and password around
anymore.

=head2 C<login( ... )>

    my $token = $rh->login($user, $password);
    # Save the token somewhere

Logging in allows you to buy and sell securities with your Robinhood account.
You must do this if you do not have an authorization token.

If login was successful, a valid token is returned and may also be had by
calling C<token( )>. The token should be kept secret and stored for use in
future calls to C<new( ... )>.

=head2 C<token( )>

Now that you've logged in, you might want to securely store authorization info
to pass to C<new( ... )> next time. Get the authorization token here.

=head2 C<logout( )>

    my $token = $rh->login($user, $password);
    # ...do some stuff... buy... sell... idk... stuff... and then...
    $rh->logout( ); # Goodbye!

Logs you out of Robinhood by forcing the token returned by C<login( ... )> or
passed to C<new(...)> to expire.

I<Note>: This will log you out I<everywhere> because Robinhood generates a
single authorization token per account at a time! This is good in rare case
your token is stolen.

=head2 C<forgot_password( ... )>

    Finance::Robinhood::forgot_password('contact@example.com');

It happens. This requests a password reset email to be sent from Robinhood.

=head2 C<change_password( ... )>

    Finance::Robinhood::change_password( $username, $password, $token );

When you've forgotten your password, the email Robinhood send contains a link
to an online form where you may change your password. That link has a token
you may use here to change the password as well.

=head1 User Information

Brokerage firms must collect a lot of information about their customers due to
IRS and SEC regulations. They also keep data to identify you internally.
Here's how to access all of the data you entered when during registration and
beyond.

=head2 C<user_id( )>

    my $user_id = $rh->user_id( );

Returns the ID Robinhood uses to identify this particular account. You could
also gather this information with the C<user_info( )> method.

=head2 C<user_info( )>

    my %info = $rh->user_info( );
    say 'My name is ' . $info{first_name} . ' ' . $info{last_name};

Returns very basic information (name, email address, etc.) about the currently
logged in account as a hash.

=head2 C<basic_info( )>

This method grabs basic but more private information about the user including
their date of birth, marital status, and the last four digits of their social
security number.

=head2 C<additional_info( )>

This method grabs information about the user that the SEC would like to know
including any affiliations with publicly traded securities.

=head2 C<employment_info( )>

This method grabs information about the user's current employment status and
(if applicable) current job.

=head2 C<investment_profile( )>

This method grabs answers about the user's investment experience gathered by
the survey performed during registration.

=head2 C<identity_mismatch( )>

Returns a paginated list of identification information.

=head1 Accounts

A user may have access to more than a single Robinhood account. Each account
is represented by a Finance::Robinhood::Account object internally. Orders to
buy and sell securities require an account object. The object also contains
information about your financial standing.

For more on how to use these objects, please see the
Finance::Robinhood::Account docs.

=head2 C<accounts( ... )>

This method returns a paginated list of Finance::Robinhood::Account objects
related to the currently logged in user.

I<Note>: Not sure why the API returns a paginated list of accounts. Perhaps
in the future a single user will have access to multiple accounts?

=head1 Financial Instruments

Financial Instrument is a fancy term for any equity, asset, debt, loan, etc.
but we'll strictly be referring to securities (stocks and ETFs) as financial
instruments.

We use blessed Finance::Robinhood::Instrument objects to represent securities
in order transactions, watchlists, etc. It's how we'll refer to a security so
looking over the documentation found in Finance::Robinhood::Instrument would
be a wise thing to do.

=head2 C<instrument( ... )>

    my $msft = $rh->instrument('MSFT');
    my $msft = Finance::Robinhood::instrument('MSFT');

When a single string is passed, only the exact match for the given symbol is
returned as a Finance::Robinhood::Instrument object.

    my $msft = $rh->instrument({id => '50810c35-d215-4866-9758-0ada4ac79ffa'});
    my $msft = Finance::Robinhood::instrument({id => '50810c35-d215-4866-9758-0ada4ac79ffa'});

If a hash reference is passed with an C<id> key, the single result is returned
as a Finance::Robinhood::Instrument object. The unique ID is how Robinhood
identifies securities internally.

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

=head1 Orders

Now that you've L<logged in|/"Logging In"> and
L<found the particular stock|/"Financial Instruments"> you're interested in,
you probably want to buy or sell something. You do this by placing orders.

Orders are created by using the constructor found in Finance::Robinhood::Order
directly so have a look at the documentation there (especially the small cheat
sheet).

Once you've place the order, you'll want to keep track of them somehow. To do
this, you may use either of the following methods.

=head2 C<locate_order( ... )>

    my $order = $rh->locate_order( $order_id );

Returns a blessed Finance::Robinhood::Order object related to the buy or sell
order with the given id if it exits.

=head2 C<list_orders( ... )>

    my $orders = $rh->list_orders( );

Requests a list of all orders ordered from newest to oldest. Executed and even
canceled orders are returned in a C<results> key as Finance::Robinhood::Order
objects. Cursor keys C<next> and C<previous> may also be present.

    my $more_orders = $rh->list_orders({ cursor => $orders->{next} });

You'll likely generate more than a hand full of buy and sell orders which
would generate more than a single page of results. To gather them, use the
C<next> or C<previous> values.

=head1 Quotes and Historical Data

If you're doing anything beyond randomly choosing stocks with a symbol
generator, you'll want to know a little more. Robinhood provides access to
both current and historical data on securities.

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

=head2 C<historicals( ... )>

    # Snapshots of basic quote data for every five minutes of the previous day
    my $msft = $rh->historicals('MSFT', '5minute', 'day');

You may retrieve historical quote data with this method. The first argument is
a symbol. The second is an interval time and must be either C<5minute>,
C<10minute>, C<day>, or C<week>.

The third argument is a span of time indicating how far into the past you
would like to retrieve and may be one of the following: C<day>, C<week>,
C<year>, or C<5year>.

So, to get five years of weekly historical data for Apple, you would write...

    my $iHist = $rh->historicals('AAPL', 'week', '5year');
    my $gates = Finance::Robinhood::historicals('MSFT', 'week', '5year');

This method returns a list of hashes which in turn contain the following keys:

=over

=item C<begins_at> - A DateTime object indicating the timestamp of this block
of data.

=item C<close_price> - The most recent close price during this interval.

=item C<high_price> - The most recent high price during this interval.

=item C<interpolated> - Indicates whether the data was a statistical estimate.
This is a boolean value.

=item C<low_price> - The most recent low price during this interval.

=item C<open_price> - The most recent open price during this interval.

=item C<volume> - The trading volume during this interval.

=back

Note that if you already have a Finance::Robinhood::Instrument object, you may
want to just call the object's C<historicals( $interval, $span )> method which
wraps this.

This function has both functional and object oriented forms. The functional
form does not require an account and may be called without ever logging in.

=head1 Informational Cards and Notifications

TODO

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

=head1 Dividends

TODO

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

=head1 Watchlists

You can keep track of a list of securities by adding them to a watchlist. The
watchlist used by the official Robinhood apps and preloaded with popular
securities is named 'Default'. You may create new watchlists for
organizational reasons but the official apps currently only display the
'Default' watchlist.

Each watchlist is represented by a Finance::Robinhood::Watchlist object.
Please read the docs for that package to find out how to add and remove
individual securities.

=head2 C<watchlist( ... )>

    my $hotlist = $rh->watchlist( 'Blue Chips' );

Returns a blessed Finance::Robinhood::Watchlist if the watchlist with the
given name exists.

=head2 C<create_watchlist( ... )>

    my $watchlist = $rh->create_watchlist( 'Energy' );

You can create new Finance::Robinhood::Watchlist objects with this. Here, your
code would create a new one named "Energy".

Note that only alphanumeric characters and understore are allowed in watchlist
names. No whitespace, etc.

=head2 C<delete_watchlist( ... )>

    my $watchlist = $rh->create_watchlist( 'Energy' );
    $rh->delete_watchlist( $watchlist );

    $rh->create_watchlist( 'Energy' );
    $rh->delete_watchlist( 'Energy' );

You may remove a watchlist with this method. The argument may either be a
Finance::Robinhood::Watchlist object or the name of the watchlist as a string.

If you clobber the watchlist named 'Default', it will be recreated with
popular securities the next time you open any of the official apps.

=head2 C<watchlists( ... )>

    my $watchlists = $rh->watchlists( );

Returns all your current watchlists as a paginated list of
Finance::Robinhood::Watchlists.

    my $more = $rh->watchlists( { cursor => $watchlists->{next} } );

In case where you have more than one page of watchlists, use the C<next> and
C<previous> cursor strings.

=head1 LEGAL

This is a simple wrapper around the API used in the official apps. The author
provides no investment, legal, or tax advice and is not responsible for any
damages incurred while using this software. Neither this software nor its
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
