package Finance::Robinhood;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls forex

=head1 NAME

Finance::Robinhood - Trade Stocks, ETFs, Options, and Cryptocurrency without
Commission

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new();

=cut

our $VERSION = '0.92_002';
#
use Mojo::Base-base, -signatures;
use Mojo::UserAgent;
use Mojo::URL;
#

use Finance::Robinhood::Error;
use Finance::Robinhood::Utilities qw[gen_uuid];
use Finance::Robinhood::Utilities::Iterator;
use Finance::Robinhood::OAuth2::Token;

=head1 METHODS

Finance::Robinhood wraps several APIs. There are parts of this package that
will not apply because your account does not have access to certain features.

=head2 C<new( )>

Robinhood requires an authorization token for most API calls. To get this
token, you must log in with your username and password. But we'll get into that
later. For now, let's create a client object...

    # You can look up some basic instrument data with this
    my $rh = Finance::Robinhood->new();

A new Finance::Robinhood object is created without credentials. Before you can
buy or sell or do almost anything else, you must L<log in|/"login( ... )">.

=head3 C<token =E<gt> ...>

If you have previously authorized this package to access your account, passing
the OAuth2 tokens here will prevent you from having to C<login( ... )> with
your user data.

These tokens should be kept private.

=head3 C<device_token =E<gt> ...>

If you have previously authorized this package to access your account, passing
the assigned device ID here will prevent you from having to authorize it again
upon C<login( ... )>.

Like authorization tokens, this UUID should be kept private.

=cut

has _ua => sub {
    my $x = Mojo::UserAgent->new;
    $x->transactor->name(
        sprintf 'Perl/%s (%s) %s/%s', ( $^V =~ m[([\.\d]+)] ), $^O, __PACKAGE__,
        $VERSION
    );
    $x;
};
has 'oauth2_token';
has 'device_token' => sub { gen_uuid() };

sub _test_new {
    ok( t::Utility::rh_instance(1) );
}

sub _get ( $s, $url, %data ) {

    $data{$_} = ref $data{$_} eq 'ARRAY' ? join ',', @{ $data{$_} } : $data{$_} for keys %data;
    $url = Mojo::URL->new($url);
    $url->query( \%data );

    #warn 'GET  ' . $url;

    #warn '  Auth: ' . (
    #    ( $s->oauth2_token && $url =~ m[^https://[a-z]+\.robinhood\.com/.+$] ) ? $s->oauth2_token->token_type :
    #        'none' );
    my $retval = $s->_ua->get(
        $url => {
            ( $s->oauth2_token && $url =~ m[^https://[a-z]+\.robinhood\.com/.+$] )
            ? (
                'Authorization' => ucfirst join ' ',
                $s->oauth2_token->token_type, $s->oauth2_token->access_token
                )
            : ()
        }
    );

    #use Data::Dump;
    #warn '  Result: ' . $retval->res->code;
    #die if $retval->res->code == 401;
    #use Data::Dump;
    #ddx $retval->res->headers;

    #ddx $retval;
    #warn $retval->res->code;
    #ddx $retval->res;
    #warn $retval->res->body;

    return $s->_get( $url, %data )
        if $retval->res->code == 401 && $s->_refresh_login_token;

    $retval->result;
}

sub _test_get {
    my $rh  = t::Utility::rh_instance(0);
    my $res = $rh->_get('https://jsonplaceholder.typicode.com/todos/1');
    isa_ok( $res, 'Mojo::Message::Response' );
    is( $res->json->{title}, 'delectus aut autem', '_post(...) works!' );

    #
    $res = $rh->_get('https://httpstat.us/500');
    isa_ok( $res, 'Mojo::Message::Response' );
    ok( !$res->is_success );
}

sub _options ( $s, $url, %data ) {
    my $retval = $s->_ua->options(
        Mojo::URL->new($url) => {
            ( $s->oauth2_token && $url =~ m[^https://[a-z]+\.robinhood\.com/.+$] )
            ? (
                'Authorization' => ucfirst join ' ',
                $s->oauth2_token->token_type, $s->oauth2_token->access_token
                )
            : ()
        } => json => \%data
    );

    return $s->_options( $url, %data )
        if $retval->res->code == 401 && $s->_refresh_login_token;

    $retval->result;
}

sub _test_options {
    my $rh  = t::Utility::rh_instance(0);
    my $res = $rh->_options('https://jsonplaceholder.typicode.com/');
    isa_ok( $res, 'Mojo::Message::Response' );
    is( $res->json, () );
}

sub _post ( $s, $url, %data ) {

    #warn 'POST ' . $url;
    #use Data::Dump;
    #ddx \%data;
    #$data{$_} = ref $data{$_} eq 'ARRAY' ? join ',', @{ $data{$_} } : $data{$_} for keys %data;
    #warn '  Auth: ' . (($s->oauth2_token && $url =~ m[^https://[a-z]+\.robinhood\.com/.+$]) ? $s->oauth2_token->token_type : 'none');
    my $retval = $s->_ua->post(
        Mojo::URL->new($url) => {
            ( $s->oauth2_token && $url =~ m[^https://[a-z]+\.robinhood\.com/.+$] )
                && !delete $data{'no_auth_token'}
            ? (
                'Authorization' => ucfirst join ' ',
                $s->oauth2_token->token_type, $s->oauth2_token->access_token
                )
            : (),
            (
                $data{challenge_id}
                ? ( 'X-Robinhood-Challenge-Response-ID' => delete $data{challenge_id} )
                : ()
            )
        } => json => \%data
    );

    #use Data::Dump;
    #warn '  Result: ' . $retval->res->code;
    #die if $retval->res->code == 401;
    #use Data::Dump;
    #ddx $retval->res->headers;

    #ddx $retval;
    #warn $retval->res->code;
    #ddx $retval->res;
    #warn $retval->res->body;
    return $s->_post( $url, %data )    # Retry with new auth info
        if $retval->res->code == 401 && $s->_refresh_login_token;
    $retval->res;
}

sub _test_post {
    my $rh  = t::Utility::rh_instance(0);
    my $res = $rh->_post(
        'https://jsonplaceholder.typicode.com/posts/',
        title  => 'Whoa',
        body   => 'This is a test',
        userId => 13
    );
    isa_ok( $res, 'Mojo::Message::Response' );
    is( $res->json, { body => 'This is a test', title => 'Whoa', userId => 13, id => 101 } );
}

sub _patch ( $s, $url, %data ) {

    #$data{$_} = ref $data{$_} eq 'ARRAY' ? join ',', @{ $data{$_} } : $data{$_} for keys %data;
    my $retval = $s->_ua->patch(
        Mojo::URL->new($url) => {
            ( $s->oauth2_token && $url =~ m[^https://[a-z]+\.robinhood\.com/.+$] )
                && !delete $data{'no_auth_token'}
            ? (
                'Authorization' => ucfirst join ' ',
                $s->oauth2_token->token_type, $s->oauth2_token->access_token
                )
            : ()
        } => json => \%data
    );

    return $s->_post( $url, %data )
        if $retval->res->code == 401 && $s->_refresh_login_token;

    $retval->result;
}

sub _test_patch {
    my $rh  = t::Utility::rh_instance(0);
    my $res = $rh->_patch( 'https://jsonplaceholder.typicode.com/posts/9/', title => 'Updated' );
    isa_ok( $res, 'Mojo::Message::Response' );
    is( $res->json->{title}, 'Updated' );
}

sub _delete ( $s, $url, %data ) {

    #$data{$_} = ref $data{$_} eq 'ARRAY' ? join ',', @{ $data{$_} } : $data{$_} for keys %data;
    my $retval = $s->_ua->delete(
        Mojo::URL->new($url) => {
            ( $s->oauth2_token && $url =~ m[^https://[a-z]+\.robinhood\.com/.+$] )
                && !delete $data{'no_auth_token'}
            ? (
                'Authorization' => ucfirst join ' ',
                $s->oauth2_token->token_type, $s->oauth2_token->access_token
                )
            : ()
        } => json => \%data
    );

    return $s->_delete( $url, %data )
        if $retval->res->code == 401 && $s->_refresh_login_token;

    $retval->result;
}

sub _test_delete {
    my $rh  = t::Utility::rh_instance(0);
    my $res = $rh->_patch('https://jsonplaceholder.typicode.com/posts/1/');
    isa_ok( $res, 'Mojo::Message::Response' );
    ok( $res->is_success, 'Deleted' );    # Lies
}

=head2 C<login( ... )>

    my $rh = Finance::Robinhood->new()->login($user, $pass);

A new Finance::Robinhood object is created without credentials. Before you can
buy or sell or do almost anything else, you must L<log in|/"login( ... )">.

=head3 C<mfa_callback =E<gt> ...>

    my $rh = Finance::Robinhood->new()->login($user, $pass, mfa_callback => sub {
        # Do something like pop open an inputbox in TK, read from shell or whatever
    } );

If you have MFA enabled, you may (or must) also pass a callback. When the code
is called, a ref will be passed that will contain C<mfa_required> (a boolean
value) and C<mfa_type> which might be C<app>, C<sms>, etc. Your return value
must be the MFA code.

=head3 C<mfa_code =E<gt> ...>

    my $rh = Finance::Robinhood->new()->login($user, $pass, mfa_code => 980385);

If you already know the MFA code (for example if you have MFA enabled through
an app), you can pass that code directly and log in.

=head3 C<challenge_callback =E<gt> ...>

	my $rh = Finance::Robinhood->new()->login($user, $pass, challenge_callback => sub {
		# Do something like pop open an inputbox in TK, read from shell or whatever
	} );

When logging in with a new client, you are required to authorize it to access
your account.

This callback should return the six digit code sent to you via sms or email.

=head2 C<device_token( [...] )>

	my $token = $rh->device_token;
	# Store it

To prevent your client from having to be reauthorized to access your account
every time it is run, call this method which returns the device token which
should be passed to C<new( ... )>.

	# Reload token from storage
	my $device = ...;
	$rh->device_token($device);

To prevent your client from having to reauthorize every time it is run, call
this to reload the same ID.

=head2 C<oauth2_token( [...] )>

	my $token $rh->oauth2_token;
	# Store it

To prevent your client from having to log in every time it is run, call this
method which returns the authorization tokens which should be passed to C<new(
... )>.

This method returns a Finance::Robinhood::OAuth2::Token object.

	# Load token object from storage
	my $oauth = ...;
	$rh->oauth2_token($token);

Reload OAuth2 tokens. You can skip logging in with your username and password
if this is successful.

This method expects a Finance::Robinhood::OAuth2::Token object.

=cut

sub login ( $s, $u, $p, %opt ) {

    # OAUTH2
    my $res = $s->_post(
        'https://api.robinhood.com/oauth2/token/',
        no_auth_token  => 1,         # NO AUTH INFO SENT!
        challenge_type => 'email',
        ( $opt{challenge_id} ? ( challenge_id => $opt{challenge_id} ) : () ),
        device_token => $s->device_token,
        expires_in   => 86400,
        scope        => 'internal',
        username     => $u,
        password     => $p,
        ( $opt{mfa_code} ? ( mfa_code => $opt{mfa_code} ) : () ),
        grant_type => ( $opt{grant_type} // 'password' ),
        client_id  => $opt{client_id} // sub {
            my ( @k, $c ) = split //, shift;
            map {                    # cheap and easy
                unshift @k, pop @k;
                $c .= chr( ord ^ ord $k[0] );
            } split //, "\aW];&Y55\35I[\a,6&>[5\34\36\f\2]]\$\x179L\\\x0B4<;,\"*&\5);";
            $c;
        }
            ->(__PACKAGE__)
    );
    if ( $res->is_success ) {
        if ( $res->json->{mfa_required} ) {
            return $opt{mfa_callback}
                ? Finance::Robinhood::Error->new( description => 'You must pass an mfa_callback.' )
                : $s->login( $u, $p, %opt, mfa_code => $opt{mfa_callback}->( $res->json ) );
        }
        else {
            require Finance::Robinhood::OAuth2::Token;
            $s->oauth2_token( Finance::Robinhood::OAuth2::Token->new( $res->json ) );
        }
    }
    elsif ( $res->json->{challenge} ) {    # 400
        return Finance::Robinhood::Error->new(
            description => 'You must pass a challenge_callback.' )
            if !$opt{challenge_callback};
        my $id = $res->json->{challenge}{id};
        return $s->_challenge_response( $id, $opt{challenge_callback}->( $res->json->{challenge} ) )
            ->is_success
            ? $s->login( $u, $p, %opt, challenge_id => $id )
            : Finance::Robinhood::Error->new(
            $res->is_server_error ? ( details => $res->message ) : $res->json );
    }
    else {
        return Finance::Robinhood::Error->new(
            $res->is_server_error ? ( details => $res->message ) : $res->json );
    }
    $s;
}

sub _test_login {
    my $rh = t::Utility::rh_instance(1);
    isa_ok( $rh->oauth2_token, 'Finance::Robinhood::OAuth2::Token' );
}

# Cannot test this without logging in, getting a challenge, and then entering the private data
sub _challenge_response ( $s, $id, $response ) {
    $s->_post(
        sprintf( 'https://api.robinhood.com/challenge/%s/respond/', $id ),
        response => $response
    );
}

# Cannot test this without using the same token for 24hrs and letting it expire
sub _refresh_login_token ( $s, %opt ) {    # TODO: Store %opt from login and reuse it here
    $s->oauth2_token // return;            # OAUTH2
    my $res = $s->_post(
        'https://api.robinhood.com/oauth2/token/',
        no_auth_token => 1,                                    # NO AUTH INFO SENT!
        scope         => 'internal',
        refresh_token => $s->oauth2_token->refresh_token,
        grant_type    => ( $opt{grant_type} // 'password' ),
        client_id     => $opt{client_id} // sub {
            my ( @k, $c ) = split //, shift;
            map {                                              # cheap and easy
                unshift @k, pop @k;
                $c .= chr( ord ^ ord $k[0] );
            } split //, "\aW];&Y55\35I[\a,6&>[5\34\36\f\2]]\$\x179L\\\x0B4<;,\"*&\5);";
            $c;
        }
            ->(__PACKAGE__),
    );
    if ( $res->is_success ) {

        require Finance::Robinhood::OAuth2::Token;
        $s->oauth2_token( Finance::Robinhood::OAuth2::Token->new( $res->json ) );

    }
    else {
        return Finance::Robinhood::Error->new(
            $res->is_server_error ? ( details => $res->message ) : $res->json );
    }
    $s;
}

=head2 C<search( ... )>

    my $results = $rh->search('microsoft');

Returns a set of search results as a Finance::Robinhood::Search object.

You do not need to be logged in for this to work.

=cut

sub search ( $s, $keyword ) {
    my $res = $s->_get( 'https://midlands.robinhood.com/search/', query => $keyword );
    require Finance::Robinhood::Search;
    $res->is_success
        ? Finance::Robinhood::Search->new( _rh => $s, %{ $res->json } )
        : Finance::Robinhood::Error->new(
        $res->is_server_error ? ( details => $res->message ) : $res->json );
}

sub _test_search {
    my $rh = t::Utility::rh_instance(1);
    isa_ok(
        $rh->search('tesla'),
        'Finance::Robinhood::Search'
    );
}

=head2 C<news( ... )>

    my $news = $rh->news('MSFT');
    my $news = $rh->news('1072fc76-1862-41ab-82c2-485837590762'); # Forex - USD

An iterator containing Finance::Robinhood::News objects is returned.

=cut

sub news ( $s, $symbol_or_id ) {
    Finance::Robinhood::Utilities::Iterator->new(
        _rh        => $s,
        _next_page => Mojo::URL->new('https://midlands.robinhood.com/news/')->query(
            {
                (
                    $symbol_or_id
                        =~ /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
                    ? 'currency_id'
                    : 'symbol'
                ) => $symbol_or_id
            }
        ),
        _class => 'Finance::Robinhood::News'
    );
}

sub _test_news {
    my $rh   = t::Utility::rh_instance();
    my $msft = $rh->news('MSFT');
    isa_ok( $msft, 'Finance::Robinhood::Utilities::Iterator' );
    $msft->has_next
        ? isa_ok( $msft->next, 'Finance::Robinhood::News' )
        : pass('Fake it... Might not be any news on the weekend');

    my $btc = $rh->news('d674efea-e623-4396-9026-39574b92b093');
    isa_ok( $btc, 'Finance::Robinhood::Utilities::Iterator' );
    $btc->has_next
        ? isa_ok( $btc->next, 'Finance::Robinhood::News' )
        : pass('Fake it... Might not be any news on the weekend');
}

=head2 C<feed( )>

    my $feed = $rh->feed();

An iterator containing Finance::Robinhood::News objects is returned. This list
will be filled with news related to instruments in your watchlist and
portfolio.

You need to be logged in for this to work.

=cut

sub feed ($s) {
    Finance::Robinhood::Utilities::Iterator->new(
        _rh        => $s,
        _next_page => 'https://midlands.robinhood.com/feed/',
        _class     => 'Finance::Robinhood::News'
    );
}

sub _test_feed {
    my $feed = t::Utility::rh_instance(1)->feed;
    isa_ok( $feed,          'Finance::Robinhood::Utilities::Iterator' );
    isa_ok( $feed->current, 'Finance::Robinhood::News' );
}

=head2 C<notifications( )>

    my $cards = $rh->notifications();

An iterator containing Finance::Robinhood::Notification objects is returned.

You need to be logged in for this to work.

=cut

sub notifications ($s) {
    Finance::Robinhood::Utilities::Iterator->new(
        _rh        => $s,
        _next_page => 'https://midlands.robinhood.com/notifications/stack/',
        _class     => 'Finance::Robinhood::Notification'
    );
}

sub _test_notifications {
    my $cards = t::Utility::rh_instance(1)->notifications;
    isa_ok( $cards,          'Finance::Robinhood::Utilities::Iterator' );
    isa_ok( $cards->current, 'Finance::Robinhood::Notification' );
}

=head2 C<notification_by_id( ... )>

    my $card = $rh->notification_by_id($id);

Returns a Finance::Robinhood::Notification object. You need to be logged in for
this to work.

=cut

sub notification_by_id ( $s, $id ) {
    my $res = $s->_get( 'https://midlands.robinhood.com/notifications/stack/' . $id . '/' );
    require Finance::Robinhood::Notification if $res->is_success;
    return $res->is_success
        ? Finance::Robinhood::Notification->new( _rh => $s, %{ $res->json } )
        : Finance::Robinhood::Error->new(
        $res->is_server_error ? ( details => $res->message ) : $res->json );
}

sub _test_notification_by_id {
    my $rh   = t::Utility::rh_instance(1);
    my $card = $rh->notification_by_id( $rh->notifications->current->id );
    isa_ok( $card, 'Finance::Robinhood::Notification' );
}

=head1 EQUITY METHODS


=head2 C<equity_instruments( )>

    my $instruments = $rh->equity_instruments();

Returns an iterator containing equity instruments.

You may restrict, search, or modify the list of instruments returned with the
following optional arguments:

=over

=item C<symbol> - Ticker symbol

    my $msft = $rh->equity_instruments(symbol => 'MSFT')->next;

By the way, C<instrument_by_symbol( )> exists as sugar. It returns the
instrument itself rather than an iterator object with a single element.

=item C<query> - Keyword search

    my @solar = $rh->equity_instruments(query => 'solar')->all;

=item C<ids> - List of instrument ids

    my ( $msft, $tsla )
        = $rh->equity_instruments(
        ids => [ '50810c35-d215-4866-9758-0ada4ac79ffa', 'e39ed23a-7bd1-4587-b060-71988d9ef483' ] )
        ->all;

If you happen to know/store instrument ids, quickly get full instrument objects
this way.

=back

=cut

sub equity_instruments ( $s, %filter ) {
    $filter{ids} = join ',', @{ $filter{ids} } if $filter{ids};    # Has to be done manually
    Finance::Robinhood::Utilities::Iterator->new(
        _rh        => $s,
        _next_page => Mojo::URL->new('https://api.robinhood.com/instruments/')->query( \%filter ),
        _class     => 'Finance::Robinhood::Equity::Instrument'
    );
}

sub _test_equity_instruments {
    my $rh          = t::Utility::rh_instance(0);
    my $instruments = $rh->equity_instruments;
    isa_ok( $instruments,       'Finance::Robinhood::Utilities::Iterator' );
    isa_ok( $instruments->next, 'Finance::Robinhood::Equity::Instrument' );
    #
    {
        my $msft = $rh->equity_instruments( symbol => 'MSFT' )->current;
        isa_ok( $msft, 'Finance::Robinhood::Equity::Instrument' );
        is( $msft->symbol, 'MSFT', 'equity_instruments(symbol => "MSFT") returned Microsoft' );
    }
    #
    {
        my $tsla = $rh->equity_instruments( query => 'tesla' )->current;
        isa_ok( $tsla, 'Finance::Robinhood::Equity::Instrument' );
        is( $tsla->symbol, 'TSLA', 'equity_instruments(query => "tesla") returned Tesla' );
    }
    {
        my ( $msft, $tsla )
            = $rh->equity_instruments( ids =>
                [ '50810c35-d215-4866-9758-0ada4ac79ffa', 'e39ed23a-7bd1-4587-b060-71988d9ef483' ] )
            ->all;
        isa_ok( $msft, 'Finance::Robinhood::Equity::Instrument' );
        is( $msft->symbol, 'MSFT', 'equity_instruments( ids => ... ) returned Microsoft' );
        isa_ok( $tsla, 'Finance::Robinhood::Equity::Instrument' );
        is( $tsla->symbol, 'TSLA', 'equity_instruments( ids => ... ) also returned Tesla' );
    }
}

=head2 C<equity_instrument_by_symbol( ... )>

    my $instrument = $rh->equity_instrument_by_symbol('MSFT');

Searches for an equity instrument by ticker symbol and returns a
Finance::Robinhood::Equity::Instrument.

=cut

sub equity_instrument_by_symbol ( $s, $symbol ) {
    $s->equity_instruments( symbol => $symbol )->current;
}

sub _test_equity_instrument_by_symbol {
    my $rh         = t::Utility::rh_instance(0);
    my $instrument = $rh->equity_instrument_by_symbol('MSFT');
    isa_ok( $instrument, 'Finance::Robinhood::Equity::Instrument' );
}

=head2 C<equity_instrument_by_id( ... )>

    my $instrument = $rh->equity_instrument_by_id('50810c35-d215-4866-9758-0ada4ac79ffa');

Searches for a single of equity instrument by its instrument id and returns a
Finance::Robinhood::Equity::Instrument object.

=cut

sub equity_instrument_by_id ( $s, $id ) {
    $s->equity_instruments( ids => [$id] )->next();
}

sub _test_equity_instrument_by_id {
    my $rh         = t::Utility::rh_instance(0);
    my $instrument = $rh->equity_instrument_by_id('50810c35-d215-4866-9758-0ada4ac79ffa');
    isa_ok( $instrument, 'Finance::Robinhood::Equity::Instrument' );
    is( $instrument->symbol, 'MSFT', 'equity_instruments( ids => ... ) returned Microsoft' );
}

=head2 C<equity_instruments_by_id( ... )>

    my $instrument = $rh->equity_instruments_by_id('50810c35-d215-4866-9758-0ada4ac79ffa');

Searches for a list of equity instruments by their instrument ids and returns a
list of Finance::Robinhood::Equity::Instrument objects.

=cut

sub equity_instruments_by_id ( $s, @ids ) {

    # Split ids into groups of 75 to keep URL length down
    my @retval;
    push @retval, $s->equity_instruments( ids => [ splice @ids, 0, 75 ] )->all() while @ids;
    @retval;
}

sub _test_equity_instruments_by_id {
    my $rh = t::Utility::rh_instance(0);
    my ($instrument) = $rh->equity_instruments_by_id('50810c35-d215-4866-9758-0ada4ac79ffa');
    isa_ok( $instrument, 'Finance::Robinhood::Equity::Instrument' );
    is( $instrument->symbol, 'MSFT', 'equity_instruments( ids => ... ) returned Microsoft' );
}

=head2 C<equity_orders( [...] )>

    my $orders = $rh->equity_orders();

An iterator containing Finance::Robinhood::Equity::Order objects is returned.
You need to be logged in for this to work.

    my $orders = $rh->equity_orders(instrument => $msft);

If you would only like orders after a certain date, you can do that!

    my $orders = $rh->equity_orders(after => Time::Moment->now->minus_days(7));
    # Also accepts ISO 8601

If you would only like orders before a certain date, you can do that!

    my $orders = $rh->equity_orders(before => Time::Moment->now->minus_years(2));
    # Also accepts ISO 8601

=cut

sub equity_orders ( $s, %opts ) {

    #- `updated_at[gte]` - greater than or equal to a date; timestamp or ISO 8601
    #- `updated_at[lte]` - less than or equal to a date; timestamp or ISO 8601
    #- `instrument` - equity instrument URL
    Finance::Robinhood::Utilities::Iterator->new(
        _rh        => $s,
        _next_page => Mojo::URL->new('https://api.robinhood.com/orders/')->query(
            {
                $opts{instrument} ? ( instrument        => $opts{instrument}->url ) : (),
                $opts{before}     ? ( 'updated_at[lte]' => +$opts{before} )         : (),
                $opts{after}      ? ( 'updated_at[gte]' => +$opts{after} )          : ()
            }
        ),
        _class => 'Finance::Robinhood::Equity::Order'
    );
}

sub _test_equity_orders {
    my $rh     = t::Utility::rh_instance(1);
    my $orders = $rh->equity_orders;
    isa_ok( $orders,       'Finance::Robinhood::Utilities::Iterator' );
    isa_ok( $orders->next, 'Finance::Robinhood::Equity::Order' );
}

=head2 C<equity_order_by_id( ... )>

    my $order = $rh->equity_order_by_id($id);

Returns a Finance::Robinhood::Equity::Order object. You need to be logged in
for this to work.

=cut

sub equity_order_by_id ( $s, $id ) {
    my $res = $s->_get( 'https://api.robinhood.com/orders/' . $id . '/' );
    require Finance::Robinhood::Equity::Order if $res->is_success;
    return $res->is_success
        ? Finance::Robinhood::Equity::Order->new( _rh => $s, %{ $res->json } )
        : Finance::Robinhood::Error->new(
        $res->is_server_error ? ( details => $res->message ) : $res->json );
}

sub _test_equity_order_by_id {
    my $rh    = t::Utility::rh_instance(1);
    my $order = $rh->equity_order_by_id( $rh->equity_orders->current->id );
    isa_ok( $order, 'Finance::Robinhood::Equity::Order' );
}

=head2 C<equity_accounts( )>

    my $accounts = $rh->equity_accounts();

An iterator containing Finance::Robinhood::Equity::Account objects is returned.
You need to be logged in for this to work.

=cut

sub equity_accounts ($s) {
    Finance::Robinhood::Utilities::Iterator->new(
        _rh        => $s,
        _next_page => 'https://api.robinhood.com/accounts/',
        _class     => 'Finance::Robinhood::Equity::Account'
    );
}

sub _test_equity_accounts {
    my $rh       = t::Utility::rh_instance(1);
    my $accounts = $rh->equity_accounts;
    isa_ok( $accounts,          'Finance::Robinhood::Utilities::Iterator' );
    isa_ok( $accounts->current, 'Finance::Robinhood::Equity::Account' );
}

=head2 C<equity_account_by_account_number( ... )>

    my $account = $rh->equity_account_by_account_number($id);

Returns a Finance::Robinhood::Equity::Account object. You need to be logged in
for this to work.

=cut

sub equity_account_by_account_number ( $s, $id ) {
    my $res = $s->_get( 'https://api.robinhood.com/accounts/' . $id . '/' );
    require Finance::Robinhood::Equity::Account if $res->is_success;
    return $res->is_success
        ? Finance::Robinhood::Equity::Account->new( _rh => $s, %{ $res->json } )
        : Finance::Robinhood::Error->new(
        $res->is_server_error ? ( details => $res->message ) : $res->json );
}

sub _test_equity_account_by_account_number {
    my $rh = t::Utility::rh_instance(1);
    my $acct
        = $rh->equity_account_by_account_number( $rh->equity_accounts->current->account_number );
    isa_ok( $acct, 'Finance::Robinhood::Equity::Account' );
}

=head2 C<equity_portfolios( )>

    my $equity_portfolios = $rh->equity_portfolios();

An iterator containing Finance::Robinhood::Equity::Account::Portfolio objects
is returned. You need to be logged in for this to work.

=cut

sub equity_portfolios ($s) {
    Finance::Robinhood::Utilities::Iterator->new(
        _rh        => $s,
        _next_page => 'https://api.robinhood.com/portfolios/',
        _class     => 'Finance::Robinhood::Equity::Account::Portfolio'
    );
}

sub _test_equity_portfolios {
    my $rh                = t::Utility::rh_instance(1);
    my $equity_portfolios = $rh->equity_portfolios;
    isa_ok( $equity_portfolios,          'Finance::Robinhood::Utilities::Iterator' );
    isa_ok( $equity_portfolios->current, 'Finance::Robinhood::Equity::Account::Portfolio' );
}

=head2 C<equity_watchlists( )>

    my $watchlists = $rh->equity_watchlists();

An iterator containing Finance::Robinhood::Equity::Watchlist objects is
returned. You need to be logged in for this to work.

=cut

sub equity_watchlists ($s) {
    Finance::Robinhood::Utilities::Iterator->new(
        _rh        => $s,
        _next_page => 'https://api.robinhood.com/watchlists/',
        _class     => 'Finance::Robinhood::Equity::Watchlist'
    );
}

sub _test_equity_watchlists {
    my $rh         = t::Utility::rh_instance(1);
    my $watchlists = $rh->equity_watchlists;
    isa_ok( $watchlists,          'Finance::Robinhood::Utilities::Iterator' );
    isa_ok( $watchlists->current, 'Finance::Robinhood::Equity::Watchlist' );
}

=head2 C<equity_watchlist_by_name( ... )>

    my $watchlist = $rh->equity_watchlist_by_name('Default');

Returns a Finance::Robinhood::Equity::Watchlist object. You need to be logged
in for this to work.

=cut

sub equity_watchlist_by_name ( $s, $name ) {
    require Finance::Robinhood::Equity::Watchlist;    # Subclass of Iterator
    Finance::Robinhood::Equity::Watchlist->new(
        _rh        => $s,
        _next_page => 'https://api.robinhood.com/watchlists/' . $name . '/',
        _class     => 'Finance::Robinhood::Equity::Watchlist::Element',
        name       => $name
    );
}

sub _test_equity_watchlist_by_name {
    my $rh        = t::Utility::rh_instance(1);
    my $watchlist = $rh->equity_watchlist_by_name('Default');
    isa_ok( $watchlist, 'Finance::Robinhood::Equity::Watchlist' );
}

=head2 C<equity_fundamentals( )>

    my $fundamentals = $rh->equity_fundamentals('MSFT', 'TSLA');

An iterator containing Finance::Robinhood::Equity::Fundamentals objects is
returned.

You do not need to be logged in for this to work.

=cut

sub equity_fundamentals ( $s, @symbols_or_ids_or_urls ) {
    Finance::Robinhood::Utilities::Iterator->new(
        _rh        => $s,
        _next_page => Mojo::URL->new('https://api.robinhood.com/fundamentals/')->query(
            {
                (
                    grep {
                        /[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}/i
                    } @symbols_or_ids_or_urls
                    )
                ? ( grep {/^https?/i} @symbols_or_ids_or_urls )
                        ? 'instruments'
                        : 'ids'
                : 'symbols' => join( ',', @symbols_or_ids_or_urls )
            }
            ),
            _class => 'Finance::Robinhood::Equity::Fundamentals'
    );
}

sub _test_equity_fundamentals {
    my $rh = t::Utility::rh_instance(1);
    isa_ok(
        $rh->equity_fundamentals('MSFT')->current, 'Finance::Robinhood::Equity::Fundamentals',
    );
    isa_ok(
        $rh->equity_fundamentals('50810c35-d215-4866-9758-0ada4ac79ffa')->current,
        'Finance::Robinhood::Equity::Fundamentals',
    );
    isa_ok(
        $rh->equity_fundamentals(
            'https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/')->current,
        'Finance::Robinhood::Equity::Fundamentals',
    );
}

=head2 C<equity_markets( )>

    my $markets = $rh->equity_markets()->all;

Returns an iterator containing Finance::Robinhood::Equity::Market objects.

=cut

sub equity_markets ($s) {
    Finance::Robinhood::Utilities::Iterator->new(
        _rh        => $s,
        _next_page => 'https://api.robinhood.com/markets/',
        _class     => 'Finance::Robinhood::Equity::Market'
    );
}

sub _test_equity_markets {
    my $markets = t::Utility::rh_instance(0)->equity_markets;
    isa_ok( $markets, 'Finance::Robinhood::Utilities::Iterator' );
    skip_all('No equity markets found') if !$markets->has_next;
    isa_ok( $markets->current, 'Finance::Robinhood::Equity::Market' );
}

=head2 C<equity_market_by_mic( )>

    my $markets = $rh->equity_market_by_mic('XNAS'); # NASDAQ

Locates an exchange by its Market Identifier Code and returns a
Finance::Robinhood::Equity::Market object.

See also https://en.wikipedia.org/wiki/Market_Identifier_Code

=cut

sub equity_market_by_mic ( $s, $mic ) {
    my $res = $s->_get( 'https://api.robinhood.com/markets/' . $mic . '/' );
    require Finance::Robinhood::Equity::Market if $res->is_success;
    return $res->is_success
        ? Finance::Robinhood::Equity::Market->new( _rh => $s, %{ $res->json } )
        : Finance::Robinhood::Error->new(
        $res->is_server_error ? ( details => $res->message ) : $res->json );
}

sub _test_equity_market_by_mic {
    isa_ok(
        t::Utility::rh_instance(0)->equity_market_by_mic('XNAS'),
        'Finance::Robinhood::Equity::Market'
    );
}

=head2 C<top_movers( [...] )>

    my $instruments = $rh->top_movers( );

Returns an iterator containing members of the S&P 500 with large price changes
during market hours as Finance::Robinhood::Equity::Movers objects.

You may define whether or not you want the best or worst performing instruments
with the following option:

=over

=item C<direction> - C<up> or C<down>

    $rh->top_movers( direction => 'up' );

Returns the best performing members. This is the default.

    $rh->top_movers( direction => 'down' );

Returns the worst performing members.

=back

=cut

sub top_movers ( $s, %filter ) {
    $filter{direction} //= 'up';
    Finance::Robinhood::Utilities::Iterator->new(
        _rh => $s,
        _next_page =>
            Mojo::URL->new('https://midlands.robinhood.com/movers/sp500/')->query( \%filter ),
        _class => 'Finance::Robinhood::Equity::Mover'
    );
}

sub _test_top_movers {
    my $rh     = t::Utility::rh_instance(0);
    my $movers = $rh->top_movers;
    isa_ok( $movers,          'Finance::Robinhood::Utilities::Iterator' );
    isa_ok( $movers->current, 'Finance::Robinhood::Equity::Mover' );
}

=head2 C<tags( ... )>

    my $tags = $rh->tags( 'food', 'oil' );

Returns an iterator containing Finance::Robinhood::Equity::Tag objects.

=cut

sub tags ( $s, @slugs ) {
    Finance::Robinhood::Utilities::Iterator->new(
        _rh        => $s,
        _next_page => Mojo::URL->new('https://midlands.robinhood.com/tags/')
            ->query( { slugs => join ',', @slugs } ),
        _class => 'Finance::Robinhood::Equity::Tag'
    );
}

sub _test_tags {
    my $rh   = t::Utility::rh_instance(0);
    my $tags = $rh->tags('food');
    isa_ok( $tags,          'Finance::Robinhood::Utilities::Iterator' );
    isa_ok( $tags->current, 'Finance::Robinhood::Equity::Tag' );
}

=head2 C<tags_discovery( ... )>

    my $tags = $rh->tags_discovery( );

Returns an iterator containing Finance::Robinhood::Equity::Tag objects.

=cut

sub tags_discovery ( $s ) {
    Finance::Robinhood::Utilities::Iterator->new(
        _rh        => $s,
        _next_page => Mojo::URL->new('https://midlands.robinhood.com/tags/discovery/'),
        _class     => 'Finance::Robinhood::Equity::Tag'
    );
}

sub _test_tags_discovery {
    my $rh   = t::Utility::rh_instance(0);
    my $tags = $rh->tags_discovery();
    isa_ok( $tags,          'Finance::Robinhood::Utilities::Iterator' );
    isa_ok( $tags->current, 'Finance::Robinhood::Equity::Tag' );
}

=head2 C<tags_popular( ... )>

    my $tags = $rh->tags_popular( );

Returns an iterator containing Finance::Robinhood::Equity::Tag objects.

=cut

sub tags_popular ( $s ) {
    Finance::Robinhood::Utilities::Iterator->new(
        _rh        => $s,
        _next_page => Mojo::URL->new('https://midlands.robinhood.com/tags/discovery/'),
        _class     => 'Finance::Robinhood::Equity::Tag'
    );
}

sub _test_tags_popular {
    my $rh   = t::Utility::rh_instance(0);
    my $tags = $rh->tags_popular();
    isa_ok( $tags,          'Finance::Robinhood::Utilities::Iterator' );
    isa_ok( $tags->current, 'Finance::Robinhood::Equity::Tag' );
}

=head2 C<tag( ... )>

    my $tag = $rh->tag('food');

Locates a tag by its slug and returns a Finance::Robinhood::Equity::Tag object.

=cut

sub tag ( $s, $slug ) {
    my $res = $s->_get( 'https://midlands.robinhood.com/tags/tag/' . $slug . '/' );
    require Finance::Robinhood::Equity::Tag if $res->is_success;
    return $res->is_success
        ? Finance::Robinhood::Equity::Tag->new( _rh => $s, %{ $res->json } )
        : Finance::Robinhood::Error->new(
        $res->is_server_error ? ( details => $res->message ) : $res->json );
}

sub _test_tag {
    isa_ok(
        t::Utility::rh_instance(0)->tag('food'),
        'Finance::Robinhood::Equity::Tag'
    );
}

=head1 OPTIONS METHODS

=head2 C<options_chains( )>

    my $chains = $rh->options_chains->all;

Returns an iterator containing chain elements.

    my $equity = $rh->search('MSFT')->equity_instruments->[0]->options_chains->all;

You may limit the call by passing a list of options instruments or a list of
equity instruments.

=cut

sub options_chains ( $s, @filter ) {
    Finance::Robinhood::Utilities::Iterator->new(
        _rh        => $s,
        _next_page => Mojo::URL->new('https://api.robinhood.com/options/chains/')->query(
            {
                  ( grep { ref $_ eq 'Finance::Robinhood::Equity::Instrument' } @filter )
                ? ( equity_instrument_ids => [ map { $_->id } @filter ] )
                : ( grep { ref $_ eq 'Finance::Robinhood::Options::Instrument' } @filter )
                ? ( ids => [ map { $_->chain_id } @filter ] )
                : ()
            }
        ),
        _class => 'Finance::Robinhood::Options::Chain'
    );
}

sub _test_options_chains {
    my $rh     = t::Utility::rh_instance(0);
    my $chains = $rh->options_chains;
    isa_ok( $chains,       'Finance::Robinhood::Utilities::Iterator' );
    isa_ok( $chains->next, 'Finance::Robinhood::Options::Chain' );

    # Get by equity instrument
    $chains = $rh->options_chains( $rh->search('MSFT')->equity_instruments );
    isa_ok( $chains,       'Finance::Robinhood::Utilities::Iterator' );
    isa_ok( $chains->next, 'Finance::Robinhood::Options::Chain' );
    is( $chains->current->symbol, 'MSFT' );

    # Get by options instrument
    my ($instrument) = $rh->search('MSFT')->equity_instruments;
    my $options = $rh->options_instruments(
        chain_id    => $instrument->tradable_chain_id,
        tradability => 'tradable'
    );
    $chains = $rh->options_chains( $options->next );
    isa_ok( $chains,       'Finance::Robinhood::Utilities::Iterator' );
    isa_ok( $chains->next, 'Finance::Robinhood::Options::Chain' );
    is( $chains->current->symbol, 'MSFT' );
}

=head2 C<options_instruments( )>

    my $options = $rh->options_instruments();

Returns an iterator containing Finance::Robinhood::Options::Instrument objects.

	my $options = $rh->options_instruments( state => 'active', type => 'put' );

You can filter the results several ways. All of them are optional.

=over

=item C<state> - C<active>, C<inactive>, or C<expired>

=item C<type> - C<call> or C<put>

=item C<expiration_dates> - comma separated list of days; format is YYYY-M-DD

=back

=cut

sub options_instruments ( $s, %filters ) {

    #$filters{chain_id} = $filters{chain}->chain_id if $filters{chain};
    #    - ids - comma separated list of options ids (optional)
    #    - cursor - paginated list position (optional)
    #    - tradability - 'tradable' or 'untradable' (optional)
    #    - state - 'active', 'inactive', or 'expired' (optional)
    #    - type - 'put' or 'call' (optional)
    #    - expiration_dates - comma separated list of days (optional; YYYY-MM-DD)
    #    - chain_id - related options chain id (optional; UUID)
    Finance::Robinhood::Utilities::Iterator->new(
        _rh => $s,
        _next_page =>
            Mojo::URL->new('https://api.robinhood.com/options/instruments/')->query( \%filters ),
        _class => 'Finance::Robinhood::Options::Instrument'
    );
}

sub _test_options_instruments {
    my $rh      = t::Utility::rh_instance(1);
    my $options = $rh->options_instruments(
        chain_id    => $rh->equity_instrument_by_symbol('MSFT')->tradable_chain_id,
        tradability => 'tradable'
    );
    isa_ok( $options,       'Finance::Robinhood::Utilities::Iterator' );
    isa_ok( $options->next, 'Finance::Robinhood::Options::Instrument' );
    is( $options->current->chain_symbol, 'MSFT' );
}

=head1 UNSORTED


=head2 C<user( )>

    my $me = $rh->user();

Returns a Finance::Robinhood::User object. You need to be logged in for this to
work.

=cut

sub user ( $s ) {
    my $res = $s->_get('https://api.robinhood.com/user/');
    require Finance::Robinhood::User if $res->is_success;
    return $res->is_success
        ? Finance::Robinhood::User->new( _rh => $s, %{ $res->json } )
        : Finance::Robinhood::Error->new(
        $res->is_server_error ? ( details => $res->message ) : $res->json );
}

sub _test_user {
    my $rh = t::Utility::rh_instance(1);
    my $me = $rh->user();
    isa_ok( $me, 'Finance::Robinhood::User' );
}

=head2 C<acats_transfers( )>

    my $acats = $rh->acats_transfers();

An iterator containing Finance::Robinhood::ACATS::Transfer objects is returned.

You need to be logged in for this to work.

=cut

sub acats_transfers ($s) {
    Finance::Robinhood::Utilities::Iterator->new(
        _rh        => $s,
        _next_page => 'https://api.robinhood.com/acats/',
        _class     => 'Finance::Robinhood::ACATS::Transfer'
    );
}

sub _test_acats_transfers {
    my $transfers = t::Utility::rh_instance(1)->acats_transfers;
    isa_ok( $transfers, 'Finance::Robinhood::Utilities::Iterator' );
    skip_all('No ACATS transfers found') if !$transfers->has_next;
    isa_ok( $transfers->current, 'Finance::Robinhood::ACATS::Transfer' );
}

=head2 C<equity_positions( )>

    my $positions = $rh->equity_positions( );

Returns the related paginated list object filled with
Finance::Robinhood::Equity::Position objects.

You must be logged in.

    my $positions = $rh->equity_positions( nonzero => 1 );

You can filter and modify the results. All options are optional.

=over

=item C<nonzero> - true or false. Default is false

=item C<ordering> - list of equity instruments

=back

=cut

sub equity_positions ( $s, %filters ) {
    $filters{nonzero} = !!$filters{nonzero} ? 'true' : 'false' if defined $filters{nonzero};
    Finance::Robinhood::Utilities::Iterator->new(
        _rh        => $s,
        _next_page => Mojo::URL->new('https://api.robinhood.com/positions/')->query( \%filters ),
        _class     => 'Finance::Robinhood::Equity::Position'
    );
}

sub _test_equity_positions {
    my $positions = t::Utility::rh_instance(1)->equity_positions;
    isa_ok( $positions,          'Finance::Robinhood::Utilities::Iterator' );
    isa_ok( $positions->current, 'Finance::Robinhood::Equity::Position' );
}

=head2 C<equity_earnings( ... )>

    my $earnings = $rh->equity_earnings( symbol => 'MSFT' );

Returns the related paginated list object filled with
Finance::Robinhood::Equity::Earnings objects by ticker symbol.

    my $earnings = $rh->equity_earnings( instrument => $rh->equity_instrument_by_symbol('MSFT') );

Returns the related paginated list object filled with
Finance::Robinhood::Equity::Earnings objects by instrument object/url.

    my $earnings = $rh->equity_earnings( range=> 7 );

Returns a paginated list object filled with
Finance::Robinhood::Equity::Earnings objects for all expected earnings report
over the next C<X> days where C<X> is between C<-21...-1, 1...21>. Negative
values are days into the past. Positive are days into the future.

You must be logged in for any of these to work.

=cut

sub equity_earnings ( $s, %filters ) {
    $filters{range} = $filters{range} . 'day'
        if defined $filters{range} && $filters{range} =~ m[^\-?\d+$];
    Finance::Robinhood::Utilities::Iterator->new(
        _rh => $s,
        _next_page =>
            Mojo::URL->new('https://api.robinhood.com/marketdata/earnings/')->query( \%filters ),
        _class => 'Finance::Robinhood::Equity::Earnings'
    );
}

sub _test_equity_earnings {
    my $by_instrument
        = t::Utility::rh_instance(1)
        ->equity_earnings(
        instrument => t::Utility::rh_instance(1)->equity_instrument_by_symbol('MSFT') );
    isa_ok( $by_instrument,          'Finance::Robinhood::Utilities::Iterator' );
    isa_ok( $by_instrument->current, 'Finance::Robinhood::Equity::Earnings' );
    is( $by_instrument->current->symbol, 'MSFT', 'correct symbol (by instrument)' );
    #
    my $by_symbol = t::Utility::rh_instance(1)->equity_earnings( symbol => 'MSFT' );
    isa_ok( $by_symbol,          'Finance::Robinhood::Utilities::Iterator' );
    isa_ok( $by_symbol->current, 'Finance::Robinhood::Equity::Earnings' );
    is( $by_symbol->current->symbol, 'MSFT', 'correct symbol (by symbol)' );

    # Positive range
    my $p_range = t::Utility::rh_instance(1)->equity_earnings( range => 7 );
    isa_ok( $p_range,          'Finance::Robinhood::Utilities::Iterator' );
    isa_ok( $p_range->current, 'Finance::Robinhood::Equity::Earnings' );

    # Negative range
    my $n_range = t::Utility::rh_instance(1)->equity_earnings( range => -7 );
    isa_ok( $n_range,          'Finance::Robinhood::Utilities::Iterator' );
    isa_ok( $n_range->current, 'Finance::Robinhood::Equity::Earnings' );
}

=head1 FOREX METHODS

Depending on your jurisdiction, your account may have access to Robinhood
Crypto. See https://crypto.robinhood.com/ for more.


=head2 C<forex_accounts( )>

    my $halts = $rh->forex_accounts;

Returns an iterator full of Finance::Robinhood::Forex::Account objects.

You need to be logged in and have access to Robinhood Crypto for this to work.

=cut

sub forex_accounts( $s ) {
    Finance::Robinhood::Utilities::Iterator->new(
        _rh        => $s,
        _next_page => Mojo::URL->new('https://nummus.robinhood.com/accounts/'),
        _class     => 'Finance::Robinhood::Forex::Account'
    );
}

sub _test_forex_accounts {
    my $halts = t::Utility::rh_instance(1)->forex_accounts;
    isa_ok( $halts,          'Finance::Robinhood::Utilities::Iterator' );
    isa_ok( $halts->current, 'Finance::Robinhood::Forex::Account' );
}

=head2 C<forex_account_by_id( ... )>

    my $account = $rh->forex_account_by_id($id);

Returns a Finance::Robinhood::Forex::Account object. You need to be logged in
for this to work.

=cut

sub forex_account_by_id ( $s, $id ) {
    my $res = $s->_get( 'https://nummus.robinhood.com/accounts/' . $id . '/' );
    require Finance::Robinhood::Forex::Account if $res->is_success;
    return $res->is_success
        ? Finance::Robinhood::Forex::Account->new( _rh => $s, %{ $res->json } )
        : Finance::Robinhood::Error->new(
        $res->is_server_error ? ( details => $res->message ) : $res->json );
}

sub _test_forex_account_by_id {
    my $rh   = t::Utility::rh_instance(1);
    my $acct = $rh->forex_account_by_id( $rh->forex_accounts->current->id );
    isa_ok( $acct, 'Finance::Robinhood::Forex::Account' );
}

=head2 C<forex_halts( [...] )>

    my $halts = $rh->forex_halts;
    # or
    $halts = $rh->forex_halts( active => 1 );

Returns an iterator full of Finance::Robinhood::Forex::Halt objects.

If you pass a true value to a key named C<active>, only active halts will be
returned.

You need to be logged in and have access to Robinhood Crypto for this to work.

=cut

sub forex_halts ( $s, %filters ) {
    $filters{active} = $filters{active} ? 'true' : 'false' if defined $filters{active};
    Finance::Robinhood::Utilities::Iterator->new(
        _rh        => $s,
        _next_page => Mojo::URL->new('https://nummus.robinhood.com/halts/')->query( \%filters ),
        _class     => 'Finance::Robinhood::Forex::Halt'
    );
}

sub _test_forex_halts {
    my $halts = t::Utility::rh_instance(1)->forex_halts;
    isa_ok( $halts,          'Finance::Robinhood::Utilities::Iterator' );
    isa_ok( $halts->current, 'Finance::Robinhood::Forex::Halt' );
    #
    is(
        scalar $halts->all > scalar t::Utility::rh_instance(1)->forex_halts( active => 1 )->all,
        1, 'active => 1 works'
    );
}

=head2 C<forex_currencies( )>

    my $currecies = $rh->forex_currencies();

An iterator containing Finance::Robinhood::Forex::Currency objects is returned.
You need to be logged in for this to work.

=cut

sub forex_currencies ($s) {
    Finance::Robinhood::Utilities::Iterator->new(
        _rh        => $s,
        _next_page => 'https://nummus.robinhood.com/currencies/',
        _class     => 'Finance::Robinhood::Forex::Currency'
    );
}

sub _test_forex_currencies {
    my $rh         = t::Utility::rh_instance(1);
    my $currencies = $rh->forex_currencies;
    isa_ok( $currencies,          'Finance::Robinhood::Utilities::Iterator' );
    isa_ok( $currencies->current, 'Finance::Robinhood::Forex::Currency' );
}

=head2 C<forex_currency_by_id( ... )>

    my $currency = $rh->forex_currency_by_id($id);

Returns a Finance::Robinhood::Forex::Currency object. You need to be logged in
for this to work.

=cut

sub forex_currency_by_id ( $s, $id ) {
    my $res = $s->_get( 'https://nummus.robinhood.com/currencies/' . $id . '/' );
    require Finance::Robinhood::Forex::Currency if $res->is_success;
    return $res->is_success
        ? Finance::Robinhood::Forex::Currency->new( _rh => $s, %{ $res->json } )
        : Finance::Robinhood::Error->new(
        $res->is_server_error ? ( details => $res->message ) : $res->json );
}

sub _test_forex_currency_by_id {
    my $rh  = t::Utility::rh_instance(1);
    my $usd = $rh->forex_currency_by_id('1072fc76-1862-41ab-82c2-485837590762');
    isa_ok( $usd, 'Finance::Robinhood::Forex::Currency' );
}

=head2 C<forex_pairs( )>

    my $pairs = $rh->forex_pairs();

An iterator containing Finance::Robinhood::Forex::Pair objects is returned. You
need to be logged in for this to work.

=cut

sub forex_pairs ($s) {
    Finance::Robinhood::Utilities::Iterator->new(
        _rh        => $s,
        _next_page => 'https://nummus.robinhood.com/currency_pairs/',
        _class     => 'Finance::Robinhood::Forex::Pair'
    );
}

sub _test_forex_pairs {
    my $rh         = t::Utility::rh_instance(1);
    my $watchlists = $rh->forex_pairs;
    isa_ok( $watchlists,          'Finance::Robinhood::Utilities::Iterator' );
    isa_ok( $watchlists->current, 'Finance::Robinhood::Forex::Pair' );
}

=head2 C<forex_pair_by_id( ... )>

    my $watchlist = $rh->forex_pair_by_id($id);

Returns a Finance::Robinhood::Forex::Pair object. You need to be logged in for
this to work.

=cut

sub forex_pair_by_id ( $s, $id ) {
    my $res = $s->_get( 'https://nummus.robinhood.com/currency_pairs/' . $id . '/' );
    require Finance::Robinhood::Forex::Pair if $res->is_success;
    return $res->is_success
        ? Finance::Robinhood::Forex::Pair->new( _rh => $s, %{ $res->json } )
        : Finance::Robinhood::Error->new(
        $res->is_server_error ? ( details => $res->message ) : $res->json );
}

sub _test_forex_pair_by_id {
    my $rh      = t::Utility::rh_instance(1);
    my $btc_usd = $rh->forex_pair_by_id('3d961844-d360-45fc-989b-f6fca761d511');    # BTC-USD
    isa_ok( $btc_usd, 'Finance::Robinhood::Forex::Pair' );
}

=head2 C<forex_pair_by_symbol( ... )>

    my $btc = $rh->forex_pair_by_symbol('BTCUSD');

Returns a Finance::Robinhood::Forex::Pair object. You need to be logged in for
this to work.

=cut

sub forex_pair_by_symbol ( $s, $id ) {
    my $res = $s->_get( 'https://nummus.robinhood.com/currency_pairs/?symbols=' . $id );
    require Finance::Robinhood::Forex::Pair if $res->is_success;
    return $res->is_success
        ? Finance::Robinhood::Forex::Pair->new( _rh => $s, %{ $res->json } )
        : Finance::Robinhood::Error->new(
        $res->is_server_error ? ( details => $res->message ) : $res->json );
}

sub _test_forex_pair_by_symbol {
    my $rh      = t::Utility::rh_instance(1);
    my $btc_usd = $rh->forex_pair_by_symbol('BTCUSD');    # BTC-USD
    isa_ok( $btc_usd, 'Finance::Robinhood::Forex::Pair' );
}

=head2 C<forex_watchlists( )>

    my $watchlists = $rh->forex_watchlists();

An iterator containing Finance::Robinhood::Forex::Watchlist objects is
returned. You need to be logged in for this to work.

=cut

sub forex_watchlists ($s) {
    Finance::Robinhood::Utilities::Iterator->new(
        _rh        => $s,
        _next_page => 'https://nummus.robinhood.com/watchlists/',
        _class     => 'Finance::Robinhood::Forex::Watchlist'
    );
}

sub _test_forex_watchlists {
    my $rh         = t::Utility::rh_instance(1);
    my $watchlists = $rh->forex_watchlists;
    isa_ok( $watchlists,          'Finance::Robinhood::Utilities::Iterator' );
    isa_ok( $watchlists->current, 'Finance::Robinhood::Forex::Watchlist' );
}

=head2 C<forex_watchlist_by_id( ... )>

    my $watchlist = $rh->forex_watchlist_by_id($id);

Returns a Finance::Robinhood::Forex::Watchlist object. You need to be logged in
for this to work.

=cut

sub forex_watchlist_by_id ( $s, $id ) {
    my $res = $s->_get( 'https://nummus.robinhood.com/watchlists/' . $id . '/' );
    require Finance::Robinhood::Forex::Watchlist if $res->is_success;
    return $res->is_success
        ? Finance::Robinhood::Forex::Watchlist->new( _rh => $s, %{ $res->json } )
        : Finance::Robinhood::Error->new(
        $res->is_server_error ? ( details => $res->message ) : $res->json );
}

sub _test_forex_watchlist_by_id {
    my $rh        = t::Utility::rh_instance(1);
    my $watchlist = $rh->forex_watchlist_by_id( $rh->forex_watchlists->current->id );
    isa_ok( $watchlist, 'Finance::Robinhood::Forex::Watchlist' );
}

=head2 C<forex_activations( )>

    my $activations = $rh->forex_activations();

An iterator containing Finance::Robinhood::Forex::Activation objects is
returned. You need to be logged in for this to work.

=cut

sub forex_activations ($s) {
    Finance::Robinhood::Utilities::Iterator->new(
        _rh        => $s,
        _next_page => 'https://nummus.robinhood.com/activations/',
        _class     => 'Finance::Robinhood::Forex::Activation'
    );
}

sub _test_forex_activations {
    my $rh         = t::Utility::rh_instance(1);
    my $watchlists = $rh->forex_activations;
    isa_ok( $watchlists,          'Finance::Robinhood::Utilities::Iterator' );
    isa_ok( $watchlists->current, 'Finance::Robinhood::Forex::Activation' );
}

=head2 C<forex_activation_by_id( ... )>

    my $activation = $rh->forex_activation_by_id($id);

Returns a Finance::Robinhood::Forex::Activation object. You need to be logged
in for this to work.

=cut

sub forex_activation_by_id ( $s, $id ) {
    my $res = $s->_get( 'https://nummus.robinhood.com/activations/' . $id . '/' );
    require Finance::Robinhood::Forex::Activation if $res->is_success;
    return $res->is_success
        ? Finance::Robinhood::Forex::Activation->new( _rh => $s, %{ $res->json } )
        : Finance::Robinhood::Error->new(
        $res->is_server_error ? ( details => $res->message ) : $res->json );
}

sub _test_forex_activation_by_id {
    my $rh         = t::Utility::rh_instance(1);
    my $activation = $rh->forex_activations->current;
    my $forex      = $rh->forex_activation_by_id( $activation->id );    # Cheat
    isa_ok( $forex, 'Finance::Robinhood::Forex::Activation' );
}

=head2 C<forex_portfolios( )>

    my $portfolios = $rh->forex_portfolios();

An iterator containing Finance::Robinhood::Forex::Portfolio objects is
returned. You need to be logged in for this to work.

=cut

sub forex_portfolios ($s) {
    Finance::Robinhood::Utilities::Iterator->new(
        _rh        => $s,
        _next_page => 'https://nummus.robinhood.com/portfolios/',
        _class     => 'Finance::Robinhood::Forex::Portfolio'
    );
}

sub _test_forex_portfolios {
    my $rh         = t::Utility::rh_instance(1);
    my $portfolios = $rh->forex_portfolios;
    isa_ok( $portfolios,          'Finance::Robinhood::Utilities::Iterator' );
    isa_ok( $portfolios->current, 'Finance::Robinhood::Forex::Portfolio' );
}

=head2 C<forex_portfolio_by_id( ... )>

    my $portfolio = $rh->forex_portfolio_by_id($id);

Returns a Finance::Robinhood::Forex::Portfolio object. You need to be logged in
for this to work.

=cut

sub forex_portfolio_by_id ( $s, $id ) {
    my $res = $s->_get( 'https://nummus.robinhood.com/portfolios/' . $id . '/' );
    require Finance::Robinhood::Forex::Portfolio if $res->is_success;
    return $res->is_success
        ? Finance::Robinhood::Forex::Portfolio->new( _rh => $s, %{ $res->json } )
        : Finance::Robinhood::Error->new(
        $res->is_server_error ? ( details => $res->message ) : $res->json );
}

sub _test_forex_portfolio_by_id {
    my $rh        = t::Utility::rh_instance(1);
    my $portfolio = $rh->forex_portfolios->current;
    my $forex     = $rh->forex_portfolio_by_id( $portfolio->id );    # Cheat
    isa_ok( $forex, 'Finance::Robinhood::Forex::Portfolio' );
}

=head2 C<forex_activation_request( ... )>

    my $activation = $rh->forex_activation_request( type => 'new_account' );

Submits an application to activate a new forex account. If successful, a new
Fiance::Robinhood::Forex::Activation object is returned. You need to be logged
in for this to work.

The following options are accepted:

=over

=item C<type>

This is required and must be one of the following:

=over

=item C<new_account>

=item C<reactivation>

=back

=item C<speculative>

This is an optional boolean value.

=back

=cut

sub forex_activation_request ( $s, %filters ) {
    $filters{type} = $filters{type} ? 'true' : 'false' if defined $filters{type};
    my $res = $s->_post('https://nummus.robinhood.com/activations/')->query( \%filters );
    require Finance::Robinhood::Forex::Activation if $res->is_success;
    return $res->is_success
        ? Finance::Robinhood::Forex::Activation->new( _rh => $s, %{ $res->json } )
        : Finance::Robinhood::Error->new(
        $res->is_server_error ? ( details => $res->message ) : $res->json );
}

sub _test_forex_activation_request {
    diag('This is one of those methods that is almost impossible to test from this side.');
    pass('Rather not have a million activation attempts attached to my account');
}

=head2 C<forex_orders( )>

    my $orders = $rh->forex_orders( );

An iterator containing Finance::Robinhood::Forex::Order objects is returned.
You need to be logged in for this to work.

=cut

sub forex_orders ($s) {
    Finance::Robinhood::Utilities::Iterator->new(
        _rh        => $s,
        _next_page => Mojo::URL->new('https://nummus.robinhood.com/orders/'),
        _class     => 'Finance::Robinhood::Forex::Order'
    );
}

sub _test_forex_orders {
    my $rh     = t::Utility::rh_instance(1);
    my $orders = $rh->forex_orders;
    isa_ok( $orders,          'Finance::Robinhood::Utilities::Iterator' );
    isa_ok( $orders->current, 'Finance::Robinhood::Forex::Order' );
}

=head2 C<forex_order_by_id( ... )>

    my $order = $rh->forex_order_by_id($id);

Returns a Finance::Robinhood::Forex::Order object. You need to be logged in for
this to work.

=cut

sub forex_order_by_id ( $s, $id ) {
    my $res = $s->_get( 'https://nummus.robinhood.com/orders/' . $id . '/' );
    require Finance::Robinhood::Forex::Order if $res->is_success;
    return $res->is_success
        ? Finance::Robinhood::Forex::Order->new( _rh => $s, %{ $res->json } )
        : Finance::Robinhood::Error->new(
        $res->is_server_error ? ( details => $res->message ) : $res->json );
}

sub _test_forex_order_by_id {
    my $rh    = t::Utility::rh_instance(1);
    my $order = $rh->forex_orders->current;
    my $forex = $rh->forex_order_by_id( $order->id );    # Cheat
    isa_ok( $forex, 'Finance::Robinhood::Forex::Order' );
}

=head2 C<forex_holdings( )>

    my $holdings = $rh->forex_holdings( );

Returns the related paginated list object filled with
Finance::Robinhood::Forex::Holding objects.

You must be logged in.

    my $holdings = $rh->forex_holdings( nonzero => 1 );

You can filter and modify the results. All options are optional.

=over

=item C<nonzero> - true or false. Default is false.

=back

=cut

sub forex_holdings ( $s, %filters ) {
    $filters{nonzero} = !!$filters{nonzero} ? 'true' : 'false' if defined $filters{nonzero};
    Finance::Robinhood::Utilities::Iterator->new(
        _rh        => $s,
        _next_page => Mojo::URL->new('https://nummus.robinhood.com/holdings/')->query( \%filters ),
        _class     => 'Finance::Robinhood::Forex::Holding'
    );
}

sub _test_forex_holdings {
    my $positions = t::Utility::rh_instance(1)->forex_holdings;
    isa_ok( $positions,          'Finance::Robinhood::Utilities::Iterator' );
    isa_ok( $positions->current, 'Finance::Robinhood::Forex::Holding' );
}

=head2 C<forex_holding_by_id( ... )>

    my $holding = $rh->forex_holding_by_id($id);

Returns a Finance::Robinhood::Forex::Holding object. You need to be logged in
for this to work.

=cut

sub forex_holding_by_id ( $s, $id ) {
    my $res = $s->_get( 'https://nummus.robinhood.com/holdings/' . $id . '/' );
    require Finance::Robinhood::Forex::Holding if $res->is_success;
    return $res->is_success
        ? Finance::Robinhood::Forex::Holding->new( _rh => $s, %{ $res->json } )
        : Finance::Robinhood::Error->new(
        $res->is_server_error ? ( details => $res->message ) : $res->json );
}

sub _test_forex_holding_by_id {
    my $rh      = t::Utility::rh_instance(1);
    my $holding = $rh->forex_holding_by_id( $rh->forex_holdings->current->id );
    isa_ok( $holding, 'Finance::Robinhood::Forex::Holding' );
}

=head1 LEGAL

This is a simple wrapper around the API used in the official apps. The author
provides no investment, legal, or tax advice and is not responsible for any
damages incurred while using this software. This software is not affiliated
with Robinhood Financial LLC in any way.

For Robinhood's terms and disclosures, please see their website at
https://robinhood.com/legal/

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module. Please refer to
the L<LEGAL> section.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut

1;
