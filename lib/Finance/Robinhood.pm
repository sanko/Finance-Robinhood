package Finance::Robinhood;
use 5.008001;
use strict;
use warnings;
use Carp;
our $VERSION = "0.01";
use Data::Dump qw[ddx];
use Moo;
use JSON::Tiny qw[decode_json];
use strictures 2;
use namespace::clean;
#
use lib '../../lib';
use Finance::Robinhood::Account;
use Finance::Robinhood::Instrument;
#
has token => (is => 'ro', writer => '_set_token');
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
    my $rt = _send_request(undef,
                           $base . $endpoints{login},
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
# Return the account of the user.
#
sub get_account {
    my ($self, $url) = @_;
    return $self->_send_request($url);
}
#
# Return the accounts of the user.
#
sub get_accounts {
    my ($self) = @_;
    my $return = $self->_send_request($base . $endpoints{'accounts'});
    $return // return !1;
    ddx $return;

    # TODO: Deal with next and previous results? Multiple accounts?
    return map {
        ddx $self->_send_request($_->{url});
        ddx $self->_send_request($_->{portfolio});
        ddx $self->_send_request($_->{positions});
        Finance::Robinhood::Account->new($_)
    } @{$return->{results}};
}
#
# Returns the porfillo summery of an account by url.
#
sub get_portfolio {
    my ($self, $url) = @_;
    return $self->_send_request($url);
}
#
# Return the positions for an account.
# This is sort of a heavy call as it makes many API calls to populate all the data.
#
sub get_current_positions {
    my ($self, $account) = @_;
    my @rt;

    # Get the positions.
    my $pos = $self->_send_request($base
                                       . sprintf(
                                             $endpoints{'accounts/positions'},
                                             $account->account_number()
                                       )
    );

    # Now loop through and get the ticker information.
    for my $result (@{$pos->{results}}) {
        ddx $result;

        # We ignore past stocks that we traded.
        if ($result->{'quantity'} > 0) {

            # TODO: If the call fails, deal with it as ()
            my $instrument = Finance::Robinhood::Instrument->new(
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
    # TODO: Make this functional without login(...)
    my ($self, $symbol) = @_;
    my $result = $self->_send_request(
                       $base . $endpoints{instruments} . '?query=' . $symbol);
    return $result ?
        map { Finance::Robinhood::Instrument->new($_) } @{$result->{results}}
        : ();
}

sub get_quote {
    my $self = ref $_[0] ? shift : ();    # might be undef but thtat's okay
    if (scalar @_ > 1) {
        my $quote =
            _send_request($self,
                          $base . $endpoints{quotes} . '?symbols=' . join ',',
                          @_);
        return $quote
            ?
            {map { delete $_->{symbol} => $_ } @{$quote->{results}}}
            : ();
    }
    my $quote
        = _send_request($self, $base . $endpoints{'quotes'} . shift . '/');
    return $quote ? {delete $quote->{symbol} => $quote} : ();
}

sub quote_price {
    return shift->get_quote(shift)->[0]{last_trade_price};
}

# ---------------- Private Helper Functions --------------- //
# Send request to API.
#
sub _send_request {
    my ($self, $url, $post) = @_;

    # Make sure we have a token.
    if (defined $self && !defined($self->token)) {
        carp
            'No API token set. Please authorize by using ->login($user, $pass) or passing a token to ->new(...).';
        return !1;
    }

    # Setup request client.
    $client = HTTP::Tiny->new() if !defined $client;

    #$url = $url =~ m[$base] ? $url : $base .$url;
    # Make API call.
    warn $url;

    #warn $post;
    $res = $client->request((defined $post ? 'POST' : 'GET'),
                            $url,
                            {'headers' => {%headers,
                                           ($self && defined $self->token()
                                            ? ('Authorization' => 'Token '
                                               . $self->token())
                                            : ()
                                           )
                             },
                             (defined $post
                              ? (content =>
                                  $client->www_form_urlencode($post))
                              : ()
                             )
                            }
    );

    # Make sure the API returned happy
    #ddx $res;
    if ($res->{status} != 200 && $res->{status} != 201) {
        carp 'Robinhood did not return a status code of 200 or 201. ('
            . $res->{status} . ')';
        return !1;
    }

    # Decode the response.
    my $json = $res->{content};

    #ddx $res;
    #warn $res->{content};
    my $rt = decode_json($json);

    # Return happy.
    return $rt;
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

Returns a list of Financial::Robinhood::Account objects related to the
currently logged in user.

=head2 C<instrument( ... )>

    my $msft = $rh->instrument('MSFT');

Generates a new Finance::Robinhood::Instrument object related to the security
identified.

=head2 C<quote( ... )>

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

=head1 LEGAL

This is a simple wrapper around the API used in the official apps. The author
provides no investment, legal, or tax advice and is not responsible for any
damages incured while using this software.

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
