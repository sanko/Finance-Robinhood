package Finance::Robinhood {
    our $VERSION = '0.92_003';

=encoding utf-8

=for stopwords watchlist watchlists untradable urls forex

=head1 NAME

Finance::Robinhood - Banking, Stock, ETF, Options, and Cryptocurrency Trading
Without Fees or Commissions

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new();
    $rh->equity('MSFT')->buy(2)->limit(187.34)->submit;

=cut

    use strictures 2;
    use namespace::clean;
    use Moo;
    use Data::Dump;
    use HTTP::Tiny;
    use JSON::Tiny;
    use Types::Standard qw[ArrayRef Bool Dict Enum InstanceOf Maybe Num Str StrMatch];
    use Finance::Robinhood::Types qw[URL UUID Timestamp];
    use URI;
    use experimental 'signatures';
    #
    use Finance::Robinhood::Cash;
    use Finance::Robinhood::Cash::ATM;
    use Finance::Robinhood::Cash::Card;
    use Finance::Robinhood::Currency;
    use Finance::Robinhood::Currency::Account;
    use Finance::Robinhood::Currency::Activation;
    use Finance::Robinhood::Currency::Halt;
    use Finance::Robinhood::Currency::Position;
    use Finance::Robinhood::Currency::Order;
    use Finance::Robinhood::Currency::Portfolio;
    use Finance::Robinhood::Currency::Watchlist;
    use Finance::Robinhood::Equity;
    use Finance::Robinhood::Equity::Account;
    use Finance::Robinhood::Equity::Account::Portfolio;
    use Finance::Robinhood::Equity::Collection;
    use Finance::Robinhood::Equity::Earnings;
    use Finance::Robinhood::Equity::Fundamentals;
    use Finance::Robinhood::Equity::List;
    use Finance::Robinhood::Equity::Market;
    use Finance::Robinhood::Equity::Mover;
    use Finance::Robinhood::Equity::Order;
    use Finance::Robinhood::Equity::Position;
    use Finance::Robinhood::Equity::Watchlist;    # Subclass of Iterator
    use Finance::Robinhood::Inbox;
    use Finance::Robinhood::News;
    use Finance::Robinhood::Notification;
    use Finance::Robinhood::OAuth2Token;
    use Finance::Robinhood::Options;
    use Finance::Robinhood::Options::Contract;
    use Finance::Robinhood::Options::Event;
    use Finance::Robinhood::Options::Order;
    use Finance::Robinhood::Options::Position;
    use Finance::Robinhood::User;
    use Finance::Robinhood::Utilities::Iterator;
    use Finance::Robinhood::Utilities::Response;
    use Finance::Robinhood::Utilities qw[gen_uuid];

    # TODO: Remove this
    use Carp;

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
buy or sell or do almost anything else, you must log in.


To log in, you must pass a combination of the following parameters:

=head3 C<username =E<gt> ...>

Shh!

This is you. Be careful with you.

=head3 C<password =E<gt> ...>

Private!

To log in manually, you'll need to provide your password.

=head3 C<oauth2_token =E<gt> ...>

If you have previously authorized this package to access your account, passing
the OAuth2 tokens here will prevent you from having to log in with your user
data.

These tokens should be kept private.

=head3 C<device_token =E<gt> ...>

If you have previously authorized this package to access your account, passing
the assigned device ID here will prevent you from having to authorize it again
upon log in.

Like authorization tokens, this UUID should be kept private.

=head3 C<mfa_callback =E<gt> ...>

    my $rh = Finance::Robinhood->new(username => $user, password => $pass, mfa_callback => sub {
        # Do something like pop open an inputbox in TK, read from shell or whatever
    } );

If you have MFA enabled, you may (or must) also pass a callback. When the code
is called, a ref will be passed that will contain C<mfa_required> (a boolean
value) and C<mfa_type> which might be C<app>, C<sms>, etc. Your return value
must be the MFA code.

=head3 C<mfa_code =E<gt> ...>

    my $rh = Finance::Robinhood->new(username => $user, password => $pass, mfa_code => 980385);

If you already know the MFA code (for example if you have MFA enabled through
an app), you can pass that code directly and log in.

=head3 C<challenge_callback =E<gt> ...>

    my $rh = Finance::Robinhood->new(username => $user, password => $pass, challenge_callback => sub {
        my ($challenge) = @_;
        # Do something like pop open an inputbox in TK, read from shell or whatever
        $challenge->respond( ... );
        $challenge;
    } );

When logging in with a new client, you are required to authorize it to access
your account.

This callback should should expect a Finance::Robinhood::Device::Challenge
object and must return the object after validation.

=head3 C<scope =E<gt> ...>

Optional OAuth scopes as a single string or a list of values. If you don't know
what to pass here, passing nothing will force the client pretend to be an
official app and use the C<internal> scope with full access.

=cut

    has client => (
        is      => 'lazy',
        isa     => InstanceOf ['HTTP::Tiny'],
        default => sub ($s) {
            HTTP::Tiny->new(
                agent =>
                    sprintf( 'Perl/%s (%s) %s/%s', ( $^V =~ m[([\.\d]+)] ), $^O, ref $s, $VERSION ),
                default_headers => {
                    Accept                     => 'application/json',
                    'Accept-Language'          => 'en-us',
                    'X-Robinhood-API-Version'  => '1.280.0',
                    'X-Marketdata-API-Version' => '1.65.0',
                    'X-Midlands-API-Version'   => '1.64.2',
                    'X-Minerva-API-Version'    => '1.48.0',
                    'X-Nummus-API-Version'     => '1.39.5'
                }
            );
        }
    );
    has oauth2_token =>
        ( is => 'rwp', isa => InstanceOf ['Finance::Robinhood::OAuth2Token'], predicate => 1 );

    BEGIN {    # Hide giant UA from Data::Dump
        Data::Dump::Filtered::add_dump_filter(
            sub {
                my ( $ctx, $object ) = @_;
                $ctx->is_blessed || return ();
                $ctx->class eq 'HTTP::Tiny'
                    ? { 'dump' => 'HTTP::Tiny object [' . $object->agent . ']' }
                    :

                    #$ctx->class eq 'HTTP::Tiny' ? {'dump' => 'HTTP::Tiny object [' . $object->agent . ']'} :
                    ();
            }
        ) if $Data::Dump::VERSION && require Data::Dump::Filtered;
    }

    sub _req ( $s, $method, $url, %args ) {
        use Data::Dump;

        #ddx \%args;
        # TODO:
        # %args may contain the following keys
        #  - headers: key value pairs of http headers
        #  - x_no_auth: boolean value; if true, do not include auth bearer token
        #  - params: key value pairs that will be turned into query params; if value is a ref, it is encoded with json
        #  - json: key value pairs that will be turned into a json encoded body for POST, PUT, PATCH
        #  - form: key value pairs that will be turned into urlencoded body for POST, PUT, PATCH
        #  - query: key value pairs that will be URL encoded
        $args{query}{$_}
            = ref $args{query}{$_} eq 'ARRAY'
            ? join ',', @{ $args{query}{$_} }
            : $args{query}{$_}
            for keys %{ $args{query} };

        #ddx \%args;
        $url = ref $url ? $url->clone : URI->new($url)->clone;    # This clobbers $url otherwise

        #$args{query} //= $url->query_form;
        #ddx $url->query_form;
        $url->query_form( $url->query_form, %{ $args{query} } ) if $args{query};

        #die;
        if ( $method =~ m/^POST|PATCH|PUT$/ ) {
            if ( ref $args{json} ) {
                $args{content} = JSON::Tiny::encode_json( $args{json} );
                $args{headers}{'Content-Type'} = 'application/json; charset=utf-8';
            }
            elsif ( ref $args{form} ) {
                $args{content} = $s->client->www_form_urlencode( delete $args{form} );
                $args{headers}{'Content-Type'} = 'application/x-www-form-urlencoded';
            }
            $args{headers}{'Content-Length'} = length $args{content} if defined $args{content};
        }

        #ddx $s;
        if ( delete $args{no_auth_token} or $url !~ m[^https://[a-z0-9]+?\.robinhood.com/] ) {
            delete $args{headers}{Authorization};
        }
        elsif ( $s->has_oauth2_token ) {
            $args{headers}{Authorization} //= join ' ', $s->oauth2_token->token_type,
                $s->oauth2_token->access_token;
        }

        #carp "$method: $url";
        #ddx \%args;
        my $res = Finance::Robinhood::Utilities::Response->new(
            robinhood => $s,
            %{
                $s->client->request(
                    $method => $url,
                    {
                        $args{headers} ? ( headers => $args{headers} ) : (),
                        $args{content} ? ( content => $args{content} ) : (),
                    }
                )
            }
        );

        #ddx $res;
        $res;
    }

    sub _login ( $s, %opt ) {

        # OAUTH2
        $opt{device_token} //= gen_uuid();
        my $res = $s->_req(
            POST          => 'https://api.robinhood.com/oauth2/token/',
            no_auth_token => 1,                                           # NO AUTH INFO SENT!
            (
                $opt{challenge_id}
                ? (
                    headers => { 'X-Robinhood-Challenge-Response-ID' => delete $opt{challenge_id} }
                    )
                : ()
            ),
            json => {
                grant_type => ( $opt{grant_type} // 'password' ),
                defined $opt{grant_type}
                    && $opt{grant_type} eq 'refresh_token'
                    && defined $opt{refresh_token} ? ( refresh_token => $opt{refresh_token} ) : (
                    challenge_type => 'email',
                    device_token   => $opt{device_token},
                    expires_in     => 86400,
                    scope          => $opt{scope}
                    ? ( join ',', ref $opt{scope} ? @{ $opt{scope} } : $opt{scope} )
                    : 'internal',
                    ( $opt{username} ? ( username => $opt{username} ) : () ),
                    ( $opt{password} ? ( password => $opt{password} ) : () ),
                    ( $opt{mfa_code} ? ( mfa_code => $opt{mfa_code} ) : () ),
                    ),
                client_id => $opt{client_id} // sub {
                    my ( @k, $c ) = split //, shift;
                    map {    # cheap and easy
                        unshift @k, pop @k;
                        $c .= chr( ord ^ ord $k[0] );
                    } split //, "\aW];&Y55\35I[\a,6&>[5\34\36\f\2]]\$\x179L\\\x0B4<;,\"*&\5);";
                    $c;
                }
                    ->(__PACKAGE__)
            }
        );
        if ( $res->success ) {
            if ( $res->json->{mfa_required} ) {
                $opt{mfa_callback} // return $res;
                return $s->_login( %opt, mfa_code => $opt{mfa_callback}->( $res->json ) );
            }
            else {
                require Finance::Robinhood::OAuth2Token;
                return $s->_set_oauth2_token(
                    Finance::Robinhood::OAuth2Token->new( robinhood => $s, %{ $res->json } ) );
            }
        }
        elsif ( $res->status == 400 && $res->json->{challenge} ) {    # 400
            require Finance::Robinhood::Device::Challenge;
            return $res if !$opt{challenge_callback};
            my $challenge = $opt{challenge_callback}->(
                Finance::Robinhood::Device::Challenge->new(
                    robinhood => $s,
                    %{ $res->json->{challenge} }
                )
            );                                                        # Call it
            return $challenge->is_validated
                ? $s->_login( %opt, challenge_id => $challenge->id )
                : $challenge;
        }
        return $_[0] = $res;
    }

    sub _test_login {
        my $rh = t::Utility::rh_instance(1);
        isa_ok( $rh->oauth2_token, 'Finance::Robinhood::OAuth2Token' );
        #
        my $rh_bad = Finance::Robinhood->new(
            username => substr( crypt( $< / $), rand $$ ), 0, 5 + rand(6) ),
            password => 'hunter3'
        );    # Wrong, I hope
        ok( !$rh_bad, 'Bad password == bad response' );
    }

=head2 C<refresh_login_token( )>

OAuth2 authorization tokens expire after a defined amount of time (24 hours
from login). To continue your session, you must refresh this token by calling
this method.

=cut

    # Cannot test this without using the same token for 24hrs and letting it expire
    sub refresh_login_token ( $s, $refresh_token = $s->oauth2_token->refresh_token, %opt ) {
        $s->_login( %opt, refresh_token => $refresh_token, grant_type => 'refresh_token' );
    }

    sub _test_refresh_login_token {
        my $rh            = t::Utility::rh_instance(1);
        my $refresh_token = $rh->oauth2_token->refresh_token;
        $rh->refresh_login_token;
        isa_ok( $rh->oauth2_token, 'Finance::Robinhood::OAuth2Token' );
        isnt( $refresh_token, $rh->oauth2_token->refresh_token, 'refresh token is different' );
    }

=head2 C<search( ... )>

    my $results = $rh->search('microsoft');

Returns a set of search results by type. These types are sorted into hash keys:

=over

=item C<currency_pairs> - A list of Finance::Robinhood::Currency::Pair objects

=item C<equities> - A list of Finance::Robinhood::Equity objects

=item C<tags> - A list of Finance::Robinhood::Equity::Collection objects

=item C<lists> - A list of Finance::Robinhood::Equity::List objects

=back

You do not need to be logged in for this to work.

=cut

    sub search ( $s, $keyword ) {
        my $d = $s->_req(
            GET   => 'https://midlands.robinhood.com/search/',
            query => { query => $keyword }
        )->as(
            instruments    => 'Finance::Robinhood::Equity',
            currency_pairs => 'Finance::Robinhood::Currency::Pair',
            tags           => 'Finance::Robinhood::Equity::Collection',
            lists          => 'Finance::Robinhood::Equity::List'
        );

        # Make it look nice...
        $d->{equities} = delete $d->{instruments};
        $d->{tags}     = delete $d->{collections};
        $d->{tags} //= [];
        $d;
    }

    sub _test_search {
        my $rh     = t::Utility::rh_instance(1);
        my $search = $rh->search('tesla');
        ref_ok( $search, 'HASH' );

        # TODO: Check to make sure $TSLA is in $search->{equities}
    }

=head2 C<news( ... )>

    my $news = $rh->news('MSFT');
    my $news = $rh->news('1072fc76-1862-41ab-82c2-485837590762'); # Forex - USD

An iterator containing Finance::Robinhood::News objects is returned.

=cut

    sub news ( $s, $symbol_or_id ) {
        my $uri = URI->new('https://midlands.robinhood.com/news/');
        $uri->query_form(
            $symbol_or_id
                =~ /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
            ? 'currency_id'
            : 'symbol' => uc $symbol_or_id
        );
        Finance::Robinhood::Utilities::Iterator->new(
            robinhood => $s,
            url       => $uri,
            as        => 'Finance::Robinhood::News'
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
            robinhood => $s,
            url       => 'https://midlands.robinhood.com/feed/',
            as        => 'Finance::Robinhood::News'
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
            robinhood => $s,
            url       => 'https://midlands.robinhood.com/notifications/stack/',
            as        => 'Finance::Robinhood::Notification'
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
this to work and Robinhood has a terrible habit of relocating notifications so
that these ids are inconsistent.

=cut

    sub notification_by_id ( $s, $id ) {
        $s->_req( GET => 'https://midlands.robinhood.com/notifications/stack/' . $id . '/' )
            ->as('Finance::Robinhood::Notification');
    }

    sub _test_notification_by_id {
        skip_all('Notification IDs are no longer consistent.');
        my $rh   = t::Utility::rh_instance(1);
        my $card = $rh->notification_by_id( $rh->notifications->current->id );
        isa_ok( $card, 'Finance::Robinhood::Notification' );
    }

=head1 EQUITY METHODS

=head2 C<equity( ... )>

    my $msft = $rh->equity('MSFT');

Searches for an equity instrument by ticker symbol and returns a
Finance::Robinhood::Equity object.

=cut

    sub equity ( $s, $symbol ) { $s->equities( symbol => $symbol )->next }

    sub _test_equity {
        my $rh         = t::Utility::rh_instance(0);
        my $instrument = $rh->equity('MSFT');
        isa_ok( $instrument, 'Finance::Robinhood::Equity' );
    }

=head2 C<equities( [...] )>

    my $instruments = $rh->equities();

Returns an iterator containing equity instruments.

You may restrict, search, or modify the list of instruments returned with the
following optional arguments:

=over

=item C<symbol> - Ticker symbol

    my $msft = $rh->equities(symbol => 'MSFT')->next;

By the way, C<equity( )> exists as sugar around this and returns the instrument
itself rather than an iterator object with a single element.

=item C<query> - Keyword search

    my @solar = $rh->equities(query => 'solar')->all;

=item C<ids> - List of instrument ids

    my ( $msft, $tsla )
        = $rh->equities(
            ids => [ '50810c35-d215-4866-9758-0ada4ac79ffa',
                 'e39ed23a-7bd1-4587-b060-71988d9ef483' ] )
        ->all;

If you happen to know/store instrument ids, quickly get full equity objects
this way.

=item C<active> - Boolean value

    my ($active) = $rh->equities(active => 1)->all;

If you only want active equity instruments, set this to a true value.

=back

=cut

    sub equities ( $s, %filter ) {
        $filter{ids} = join ',', @{ $filter{ids} } if $filter{ids};    # Has to be done manually
        $filter{active_instruments_only} = delete $filter{active} ? 'true' : 'false'
            if defined $filter{active};
        my $url = URI->new('https://api.robinhood.com/instruments/');
        $url->query_form(%filter);
        Finance::Robinhood::Utilities::Iterator->new(
            robinhood => $s,
            as        => 'Finance::Robinhood::Equity',
            url       => $url
        );
    }

    sub _test_equities {
        my $rh          = t::Utility::rh_instance(0);
        my $instruments = $rh->equities;
        isa_ok( $instruments,       'Finance::Robinhood::Utilities::Iterator' );
        isa_ok( $instruments->next, 'Finance::Robinhood::Equity' );
        #
        {
            my $msft = $rh->equities( symbol => 'MSFT' )->current;
            isa_ok( $msft, 'Finance::Robinhood::Equity' );
            is( $msft->symbol, 'MSFT', 'equities(symbol => "MSFT") returned Microsoft' );
        }
        #
        {
            my $tsla = $rh->equities( query => 'tesla' )->current;
            isa_ok( $tsla, 'Finance::Robinhood::Equity' );
            is( $tsla->symbol, 'TSLA', 'equities(query => "tesla") returned Tesla' );
        }
        {
            my ( $msft, $tsla ) = $rh->equities(
                ids => [
                    '50810c35-d215-4866-9758-0ada4ac79ffa',
                    'e39ed23a-7bd1-4587-b060-71988d9ef483'
                ]
            )->all;
            isa_ok( $msft, 'Finance::Robinhood::Equity' );
            is( $msft->symbol, 'MSFT', 'equities( ids => ... ) returned Microsoft' );
            isa_ok( $tsla, 'Finance::Robinhood::Equity' );
            is( $tsla->symbol, 'TSLA', 'equities( ids => ... ) also returned Tesla' );
        }
    }

=head2 C<equity_by_id( ... )>

    my $instrument = $rh->equities_by_id('50810c35-d215-4866-9758-0ada4ac79ffa');

Simple wrapper around C<equities_by_id( ..., ... )> that expects only a single
ID because I can't remember to use the plural version.

=cut

    sub equity_by_id ( $s, $id ) { my @list = $s->equities_by_id($id); @list ? shift @list : () }

    sub _test_equity_by_id {
        my $rh         = t::Utility::rh_instance(0);
        my $instrument = $rh->equity_by_id('50810c35-d215-4866-9758-0ada4ac79ffa');
        isa_ok( $instrument, 'Finance::Robinhood::Equity' );
        is( $instrument->symbol, 'MSFT', 'equity_by_id( ... ) returned Microsoft' );
    }

=head2 C<equities_by_id( ..., ... )>

    my $instrument = $rh->equities_by_id(
		'50810c35-d215-4866-9758-0ada4ac79ffa',
		'e39ed23a-7bd1-4587-b060-71988d9ef483'
	);

Searches for a list of equity instruments by their instrument ids and returns a
list of Finance::Robinhood::Equity objects.

=cut

    sub equities_by_id ( $s, @ids ) {
        my @retval;    # Split ids into groups of 75 to keep URL length down
        push @retval, $s->equities( ids => [ splice @ids, 0, 75 ] )->all() while @ids;
        @retval;
    }

    sub _test_equities_by_id {
        my $rh = t::Utility::rh_instance(0);
        my ($instrument) = $rh->equities_by_id('50810c35-d215-4866-9758-0ada4ac79ffa');
        isa_ok( $instrument, 'Finance::Robinhood::Equity' );
        is( $instrument->symbol, 'MSFT', 'equities_by_id( ... ) returned Microsoft' );
    }

=head2 C<equity_positions( )>

    my $positions = $rh->equity_positions( );

Returns an iterator with Finance::Robinhood::Equity::Position objects.

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
        my $url = URI->new('https://api.robinhood.com/positions/');
        $url->query_form(%filters);
        Finance::Robinhood::Utilities::Iterator->new(
            robinhood => $s,
            url       => $url,
            as        => 'Finance::Robinhood::Equity::Position'
        );
    }

    sub _test_equity_positions {
        my $positions = t::Utility::rh_instance(1)->equity_positions;
        isa_ok( $positions,          'Finance::Robinhood::Utilities::Iterator' );
        isa_ok( $positions->current, 'Finance::Robinhood::Equity::Position' );
    }

=head2 C<equity_earnings( ... )>

Returns an iterator holding hash references which contain the following keys:

=over

=item C<call> - Hash reference containing the following keys:

=over

=item C<broadcast_url> - Link to a website to listen to the live earnings call

=item C<datetime> - Time::Moment object

=item C<replay_url> - Link to a website to listen to the replay of the earnings call

=back

=item C<eps> - Hash reference containing the following keys:

=over

=item C<actual> - Actual reported earnings

=item C<estimate> - Early estimated earnings

=back

=item C<instrument> - Instrument ID (UUID)

=item C<quarter> - C<1>, C<2>, C<3>, or C<4>

=item C<report> - Hash reference with the following values:

=over

=item C<date> - YYYY-MM-DD

=item C<timing> - C<am> or C<pm>

=item C<verified> - Boolean value

=back

=item C<symbol> - Ticker symbol

=item C<year> - YYYY

=back


    my $earnings = $rh->equity_earnings( symbol => 'MSFT' );

Returns an iterator holding hash references by ticker symbol.

    my $earnings = $rh->equity_earnings( instrument => $rh->equity('MSFT') );

Returns an iterator holding hash references by instrument object/url.

    my $earnings = $rh->equity_earnings( range => 7 );

Returns an iterator holding hash references for all expected earnings report
over the next C<X> days where C<X> is between C<-21...-1, 1...21>. Negative
values are days into the past. Positive are days into the future.

You must be logged in for any of these to work.

=cut

    sub equity_earnings ( $s, %filters ) {
        $filters{range} = $filters{range} . 'day'
            if defined $filters{range} && $filters{range} =~ m/^\-?\d+$/;
        my $url = URI->new('https://api.robinhood.com/marketdata/earnings/');
        $url->query_form(%filters);
        Finance::Robinhood::Utilities::Iterator->new(
            robinhood => $s,
            url       => $url,
            as        => 'Finance::Robinhood::Equity::Earnings'
        );
    }

    sub _test_equity_earnings {
        my $by_instrument = t::Utility::rh_instance(1)
            ->equity_earnings( instrument => t::Utility::rh_instance(1)->equity('MSFT') );
        isa_ok( $by_instrument,          'Finance::Robinhood::Utilities::Iterator' );
        isa_ok( $by_instrument->current, 'Finance::Robinhood::Equity::Earnings' );
        is( $by_instrument->current->symbol, 'MSFT', 'correct symbol (by instrument)' );
        #
        my $by_symbol = t::Utility::rh_instance(1)->equity_earnings( symbol => 'MSFT' );
        isa_ok( $by_symbol, 'Finance::Robinhood::Utilities::Iterator' );
        ref_ok( $by_symbol->current, 'HASH' );
        is( $by_symbol->current->symbol, 'MSFT', 'correct symbol (by symbol)' );

        # Positive range
        my $p_range = t::Utility::rh_instance(1)->equity_earnings( range => 7 );
        isa_ok( $p_range, 'Finance::Robinhood::Utilities::Iterator' );
        ref_ok( $p_range->current, 'HASH' );

        # Negative range
        my $n_range = t::Utility::rh_instance(1)->equity_earnings( range => -7 );
        isa_ok( $n_range, 'Finance::Robinhood::Utilities::Iterator' );
        ref_ok( $n_range->current, 'HASH' );
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
        my $url = URI->new('https://api.robinhood.com/orders/');
        $url->query_form(
            {
                $opts{instrument} ? ( instrument        => $opts{instrument}->url ) : (),
                $opts{before}     ? ( 'updated_at[lte]' => +$opts{before} )         : (),
                $opts{after}      ? ( 'updated_at[gte]' => +$opts{after} )          : ()
            }
        );
        Finance::Robinhood::Utilities::Iterator->new(
            robinhood => $s,
            url       => $url,
            as        => 'Finance::Robinhood::Equity::Order'
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
        $s->_req( GET => 'https://api.robinhood.com/orders/' . $id . '/' )
            ->as('Finance::Robinhood::Equity::Order');
    }

    sub _test_equity_order_by_id {
        my $rh    = t::Utility::rh_instance(1);
        my $order = $rh->equity_order_by_id( $rh->equity_orders->current->id );
        isa_ok( $order, 'Finance::Robinhood::Equity::Order' );
    }

=head2 C<equity_account( )>

    my $account = $rh->equity_account();

Returns the first Finance::Robinhood::Equity::Account objects. This is usually
what you want to use. You need to be logged in for this to work.

=cut

    has equity_account => (
        is      => 'ro',
        lazy    => 1,
        isa     => InstanceOf ['Finance::Robinhood::Equity::Account'],
        builder => sub ($s) {
            Finance::Robinhood::Utilities::Iterator->new(
                robinhood => $s,
                as        => 'Finance::Robinhood::Equity::Account',
                url       => 'https://api.robinhood.com/accounts/'
            )->current;
        }
    );

    sub _test_equity_account {
        my $rh      = t::Utility::rh_instance(1);
        my $account = $rh->equity_account;
        isa_ok( $account, 'Finance::Robinhood::Equity::Account' );
    }

=head2 C<equity_accounts( )>

    my $accounts = $rh->equity_accounts();

An iterator containing Finance::Robinhood::Equity::Account objects is returned.
There likely isn't more than a single account but Robinhood exposes an
iterative endpoint. You need to be logged in for this to work.

=cut

    sub equity_accounts ($s) {
        Finance::Robinhood::Utilities::Iterator->new(
            robinhood => $s,
            url       => 'https://api.robinhood.com/accounts/',
            as        => 'Finance::Robinhood::Equity::Account'
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
        $s->_req( GET => 'https://api.robinhood.com/accounts/' . $id . '/' )
            ->as('Finance::Robinhood::Equity::Account');
    }

    sub _test_equity_account_by_account_number {
        my $rh   = t::Utility::rh_instance(1);
        my $acct = $rh->equity_account_by_account_number(
            $rh->equity_accounts->current->account_number );
        isa_ok( $acct, 'Finance::Robinhood::Equity::Account' );
    }

=head2 C<equity_portfolio( )>

Returns the Finance::Robinhood::Equity::Account::Portfolio object related to
your primary equity account. You need to be logged in for this to work.

=cut

    has equity_portfolio => (
        is      => 'ro',
        lazy    => 1,
        isa     => InstanceOf ['Finance::Robinhood::Equity::Account::Portfolio'],
        builder => sub ($s) { $s->equity_portfolios->current }
    );

    sub _test_equity_portfolio {
        my $rh      = t::Utility::rh_instance(1);
        my $account = $rh->equity_portfolio;
        isa_ok( $account, 'Finance::Robinhood::Equity::Account::Portfolio' );
    }

=head2 C<equity_portfolios( )>

    my $equity_portfolios = $rh->equity_portfolios();

An iterator containing Finance::Robinhood::Equity::Account::Portfolio objects
is returned. You need to be logged in for this to work.

=cut

    sub equity_portfolios ($s) {
        Finance::Robinhood::Utilities::Iterator->new(
            robinhood => $s,
            url       => 'https://api.robinhood.com/portfolios/',
            as        => 'Finance::Robinhood::Equity::Account::Portfolio'
        );
    }

    sub _test_equity_portfolios {
        my $rh                = t::Utility::rh_instance(1);
        my $equity_portfolios = $rh->equity_portfolios;
        isa_ok( $equity_portfolios,          'Finance::Robinhood::Utilities::Iterator' );
        isa_ok( $equity_portfolios->current, 'Finance::Robinhood::Equity::Account::Portfolio' );
    }

=head2 C<equity_watchlist( )>

    my $watchlist = $rh->equity_watchlist;

Returns the default Finance::Robinhood::Equity::Watchlist object. You need to
be logged in for this to work.

=cut

    sub equity_watchlist($s) {
        $s->equity_watchlist_by_name('Default');
    }

    sub _test_equity_watchlist {
        my $rh        = t::Utility::rh_instance(1);
        my $watchlist = $rh->equity_watchlist;
        isa_ok( $watchlist, 'Finance::Robinhood::Equity::Watchlist' );
    }

=head2 C<equity_watchlists( )>

    my $watchlists = $rh->equity_watchlists();

An iterator containing Finance::Robinhood::Equity::Watchlist objects is
returned. You need to be logged in for this to work.

=cut

    sub equity_watchlists ($s) {
        Finance::Robinhood::Utilities::Iterator->new(
            robinhood => $s,
            url       => 'https://api.robinhood.com/watchlists/',
            as        => 'Finance::Robinhood::Equity::Watchlist'
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
        Finance::Robinhood::Equity::Watchlist->new(    # NOTICE: subclass of Iterator
            robinhood => $s,
            url       => 'https://api.robinhood.com/watchlists/' . $name . '/',
            as        => 'Finance::Robinhood::Equity::Watchlist::Element',
            name      => $name
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
        my $url = URI->new('https://api.robinhood.com/fundamentals/');
        $url->query_form(
            (
                grep {/[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}/i}
                    @symbols_or_ids_or_urls
            )
            ? ( grep {/^https?/i} @symbols_or_ids_or_urls )
                    ? 'instruments'
                    : 'ids'
            : 'symbols' => join( ',', @symbols_or_ids_or_urls )
        );
        Finance::Robinhood::Utilities::Iterator->new(
            robinhood => $s,
            url       => $url,
            as        => 'Finance::Robinhood::Equity::Fundamentals'
        );
    }

    sub _test_equity_fundamentals {
        my $rh = t::Utility::rh_instance(1);
        isa_ok(
            $rh->equity_fundamentals('MSFT')->current,
            'Finance::Robinhood::Equity::Fundamentals'
        );
        isa_ok(
            $rh->equity_fundamentals('50810c35-d215-4866-9758-0ada4ac79ffa')->current,
            'Finance::Robinhood::Equity::Fundamentals'
        );
        isa_ok(
            $rh->equity_fundamentals(
                'https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/')
                ->current,
            'Finance::Robinhood::Equity::Fundamentals',
        );
    }

=head2 C<equity_markets( )>

    my $markets = $rh->equity_markets()->all;

Returns an iterator containing Finance::Robinhood::Equity::Market objects.

=cut

    sub equity_markets ($s) {
        Finance::Robinhood::Utilities::Iterator->new(
            robinhood => $s,
            url       => 'https://api.robinhood.com/markets/',
            as        => 'Finance::Robinhood::Equity::Market'
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
        $s->_req( GET => 'https://api.robinhood.com/markets/' . $mic . '/' )
            ->as('Finance::Robinhood::Equity::Market');
    }

    sub _test_equity_market_by_mic {
        isa_ok(
            t::Utility::rh_instance(0)->equity_market_by_mic('XNAS'),
            'Finance::Robinhood::Equity::Market'
        );
    }

    # TODO:
    # $s->_req(# Paginated
    #	'https://api.robinhood.com/marketdata/quotes/',
    #	query => {bounds => 'trading', include_inactive => true, ids => $csv}
    #
    # $s->_req(# Paginated
    #	'https://api.robinhood.com/marketdata/quotes/',
    #	query => {bounds => 'trading', include_inactive => true, symbols => $csv}

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
        my $url = URI->new('https://midlands.robinhood.com/movers/sp500/');
        $url->query_form(%filter);
        Finance::Robinhood::Utilities::Iterator->new(
            robinhood => $s,
            url       => $url,
            as        => 'Finance::Robinhood::Equity::Mover'
        );
    }

    sub _test_top_movers {
        my $rh     = t::Utility::rh_instance(0);
        my $movers = $rh->top_movers;
        isa_ok( $movers,          'Finance::Robinhood::Utilities::Iterator' );
        isa_ok( $movers->current, 'Finance::Robinhood::Equity::Mover' );
    }

=head2 C<collections( ... )>

    my $tags = $rh->collections( 'food', 'oil' );

Returns a list of Finance::Robinhood::Equity::Collection objects.

=cut

    sub collections ( $s, @slugs ) {
        my $url = URI->new('https://midlands.robinhood.com/tags/');
        $url->query_form( slugs => join ',', @slugs );
        Finance::Robinhood::Utilities::Iterator->new(
            robinhood => $s,
            url       => $url,
            as        => 'Finance::Robinhood::Equity::Collection'
        )->all;
    }

    sub _test_collections {
        my $rh   = t::Utility::rh_instance(0);
        my @tags = $rh->collections('food');
        isa_ok( $tags[0], 'Finance::Robinhood::Equity::Collection' );
    }

=head2 C<discover_collections( ... )>

    my $tags = $rh->discover_collections( );

Returns an iterator containing Finance::Robinhood::Equity::Collection objects.

=cut

    sub discover_collections ( $s ) {
        Finance::Robinhood::Utilities::Iterator->new(
            robinhood => $s,
            url       => 'https://midlands.robinhood.com/tags/discovery/',
            as        => 'Finance::Robinhood::Equity::Collection'
        );
    }

    sub _test_discover_collections {
        my $rh   = t::Utility::rh_instance(0);
        my $tags = $rh->discover_collections();
        isa_ok( $tags,          'Finance::Robinhood::Utilities::Iterator' );
        isa_ok( $tags->current, 'Finance::Robinhood::Equity::Collection' );
    }

=head2 C<popular_collections( ... )>

    my $tags = $rh->popular_collections( );

Returns an iterator containing Finance::Robinhood::Equity::Collection objects.

=cut

    sub popular_collections ( $s ) {
        Finance::Robinhood::Utilities::Iterator->new(
            robinhood => $s,
            url       => 'https://midlands.robinhood.com/tags/popular/',
            as        => 'Finance::Robinhood::Equity::Collection'
        );
    }

    sub _test_popular_collections {
        my $rh   = t::Utility::rh_instance(0);
        my $tags = $rh->popular_collections();
        isa_ok( $tags,          'Finance::Robinhood::Utilities::Iterator' );
        isa_ok( $tags->current, 'Finance::Robinhood::Equity::Collection' );
    }

=head2 C<collection( ... )>

    my $tag = $rh->collection('food');

Locates a collection by its slug and returns a
Finance::Robinhood::Equity::Collection object.

=cut

    sub collection ( $s, $slug ) {
        $s->_req( GET => 'https://midlands.robinhood.com/tags/tag/' . $slug . '/' )
            ->as('Finance::Robinhood::Equity::Collection');
    }

    sub _test_tag {
        isa_ok(
            t::Utility::rh_instance(0)->collection('food'),
            'Finance::Robinhood::Equity::Collection'
        );
    }

=head1 OPTIONS METHODS

=head2 C<options( [...] )>

    my $chains = $rh->options;

Returns an iterator containing chain elements.

    $rh->options($rh->equity('MSFT'))->all;

You may limit the call by passing a list of Finance::Robinhood::Equity or
Finance::Robinhood::Options::Contract objects.

=cut

    sub options ( $s, @filter ) {
        my $url = URI->new('https://api.robinhood.com/options/chains/');

        #$url->query_form(
        #      (grep { ref $_ eq 'Finance::Robinhood::Equity' } @filter)
        #    ? (ids => [map { $_->tradable_chain_id } @filter])
        #    : (grep { ref $_ eq 'Finance::Robinhood::Options' } @filter)
        #    ? (ids => [map { $_->id } @filter])
        #    : (grep {
        #           ref $_ eq 'Finance::Robinhood::Options::Contract'
        #       } @filter
        #    ) ? (ids => [map { $_->chain_id } @filter]) : @filter
        #);
        $url->query_form(
            {
                  ( grep { ref $_ eq 'Finance::Robinhood::Equity' } @filter )
                ? ( equity_instrument_ids => [ map { $_->id } @filter ] )
                : ( grep { ref $_ eq 'Finance::Robinhood::Options::Contract' } @filter )
                ? ( ids => [ map { $_->chain_id } @filter ] )
                : @filter
            }
            ),
            Finance::Robinhood::Utilities::Iterator->new(
            robinhood => $s,
            url       => $url,
            as        => 'Finance::Robinhood::Options'
            );
    }

    sub _test_options {
        my $rh     = t::Utility::rh_instance(0);
        my $chains = $rh->options;
        isa_ok( $chains,       'Finance::Robinhood::Utilities::Iterator' );
        isa_ok( $chains->next, 'Finance::Robinhood::Options' );

        # Get by equity instrument
        $chains = $rh->options( $rh->equity('MSFT') );
        isa_ok( $chains,          'Finance::Robinhood::Utilities::Iterator' );
        isa_ok( $chains->current, 'Finance::Robinhood::Options' );
        is( $chains->current->symbol, 'MSFT' );

        # Get by options instrument
        my $instrument = $rh->equity('MSFT');
        my $options    = $rh->options_contracts(
            chain_id    => $instrument->tradable_chain_id,
            tradability => 'tradable'
        );
        $chains = $rh->options( $options->current );
        isa_ok( $chains,          'Finance::Robinhood::Utilities::Iterator' );
        isa_ok( $chains->current, 'Finance::Robinhood::Options' );
        is( $chains->current->symbol, 'MSFT' );
    }

=head2 C<options_contracts( )>

    my $options = $rh->options_contracts();

Returns an iterator containing Finance::Robinhood::Options::Contract objects.

    my $options = $rh->options_contracts( state => 'active', type => 'put' );

You can filter the results several ways. All of them are optional.

=over

=item C<state> - C<active>, C<inactive>, or C<expired>

=item C<type> - C<call> or C<put>

=item C<expiration_dates> - list of days; format is YYYY-M-DD

=item C<ids> - list of contract IDs

=item C<tradability> - either C<tradable> or C<untradable>

=item C<chain_id> - the options chain id

=item C<state> - C<active>, C<inactive>, or C<expired>

=back

=cut

    sub options_contracts ( $s, %filters ) {

        #    - ids - comma separated list of options ids (optional)
        #    - cursor - paginated list position (optional)
        #    - tradability - 'tradable' or 'untradable' (optional)
        #    - state - 'active', 'inactive', or 'expired' (optional)
        #    - type - 'put' or 'call' (optional)
        #    - expiration_dates - comma separated list of days (optional; YYYY-MM-DD)
        #    - chain_id - related options chain id (optional; UUID)
        my $url = URI->new('https://api.robinhood.com/options/instruments/');
        $filters{expiration_dates} = join ',', @{ $filters{expiration_dates} }
            if $filters{expiration_dates};
        $filters{ids} = join ',', @{ $filters{ids} } if $filters{ids};
        $url->query_form(%filters);
        Finance::Robinhood::Utilities::Iterator->new(
            robinhood => $s,
            url       => $url,
            as        => 'Finance::Robinhood::Options::Contract'
        );
    }

    sub _test_options_contracts {
        my $rh      = t::Utility::rh_instance(1);
        my $options = $rh->options_contracts(
            chain_id    => $rh->equity('MSFT')->tradable_chain_id,
            tradability => 'tradable',
            type        => 'call'
        );
        isa_ok( $options,       'Finance::Robinhood::Utilities::Iterator' );
        isa_ok( $options->next, 'Finance::Robinhood::Options::Contract' );
        is( $options->current->chain_symbol, 'MSFT' );
    }

=head2 C<options_positions( )>

    my $positions = $rh->options_positions( );

Returns the related paginated list object filled with
Finance::Robinhood::Options::Position objects.

You must be logged in.

    my $positions = $rh->options_positions( nonzero => 1 );

You can filter and modify the results. All options are optional.

=over

=item C<nonzero> - true or false. Default is false

=item C<chains> - list of options chain IDs or Finance::Robinhood::Options objects

=back

=cut

    sub options_positions ( $s, %filters ) {
        $filters{nonzero}   = !!$filters{nonzero} ? 'True' : 'False' if defined $filters{nonzero};
        $filters{chain_ids} = join ',',
            map { ref $_ eq 'Finance::Robinhood::Options::Chain' ? $_->id : $_ }
            @{ $filters{chains} }
            if defined $filters{chains};
        my $url = URI->new('https://api.robinhood.com/options/positions/');
        $url->query_form( \%filters );
        Finance::Robinhood::Utilities::Iterator->new(
            robinhood => $s,
            url       => $url,
            as        => 'Finance::Robinhood::Options::Position'
        );
    }

    sub _test_options_positions {
        my $positions = t::Utility::rh_instance(1)->options_positions;
        isa_ok( $positions,          'Finance::Robinhood::Utilities::Iterator' );
        isa_ok( $positions->current, 'Finance::Robinhood::Options::Position' );
    }

=head2 C<options_position_by_id( ... )>

    my $position = $rh->options_position_by_id('b5ad00c0-7861-4582-8e5e-48f635178cb9');

Searches for a single of options position by its id and returns a
Finance::Robinhood::Options::Position object.

=cut

    sub options_position_by_id ( $s, $id ) {
        my $res = $s->_get( 'https://api.robinhood.com/options/positions/' . $id . '/' );
        require Finance::Robinhood::Options::Position if $res->is_success;
        return $res->is_success
            ? Finance::Robinhood::Options::Position->new( robinhood => $s, %{ $res->json } )
            : $res;
    }

    sub _test_options_position_by_id {
        my $rh     = t::Utility::rh_instance(1);
        my $holder = $rh->options_positions->next;
        skip_all('No positions in our history') unless $holder;
        my $position = $rh->options_position_by_id( $holder->id );
        isa_ok( $position, 'Finance::Robinhood::Options::Position' );
    }

=head2 C<options_contract_by_id( ... )>

    $rh->options_contract_by_id('3b8f5513-600f-49b8-a4de-db56b52a82cf');

Searches for a single of options instrument by its instrument id and returns a
Finance::Robinhood::Options::Contract object.

=cut

    sub options_contract_by_id ( $s, $id ) {
        $s->_req( GET => 'https://api.robinhood.com/options/instruments/' . $id . '/' )
            ->as('Finance::Robinhood::Options::Contract');
    }

    sub _test_options_contract_by_id {
        my $rh         = t::Utility::rh_instance(1);
        my $instrument = $rh->options_contract_by_id('3b8f5513-600f-49b8-a4de-db56b52a82cf');
        isa_ok( $instrument, 'Finance::Robinhood::Options::Contract' );
        is(
            $instrument->id,
            '3b8f5513-600f-49b8-a4de-db56b52a82cf',
            'options_contract_by_id( ... ) returned Bank of America'
        );
    }

=head2 C<options_by_id( ... )>

    my $chain = $rh->options_by_id('55d7e31c-9105-488b-983c-93e09dd7ff35');

Searches for a single of options chain by its id and returns a
Finance::Robinhood::Options object.

=cut

    sub options_by_id ( $s, $id ) {
        $s->_req( GET => 'https://api.robinhood.com/options/chains/' . $id . '/' )
            ->as('Finance::Robinhood::Options');
    }

    sub _test_options_by_id {
        my $rh    = t::Utility::rh_instance(1);
        my $chain = $rh->options_by_id('55d7e31c-9105-488b-983c-93e09dd7ff35');
        isa_ok( $chain, 'Finance::Robinhood::Options' );
        is( $chain->symbol, 'BAC', 'options_by_id( ... ) returned Bank of America' );
    }

=head2 C<options_events( )>

    my $events = $rh->options_events();

Returns an iterator containing Finance::Robinhood::Options::Event objects.

=cut

    sub options_events ($s) {
        Finance::Robinhood::Utilities::Iterator->new(
            robinhood => $s,
            url       => 'https://api.robinhood.com/options/events/',
            as        => 'Finance::Robinhood::Options::Event'
        );
    }

    sub _test_options_events {
        my $rh     = t::Utility::rh_instance(1);
        my $events = $rh->options_events();
        isa_ok( $events,       'Finance::Robinhood::Utilities::Iterator' );
        isa_ok( $events->next, 'Finance::Robinhood::Options::Event' );
    }

=head2 C<options_orders( [...] )>

    my $orders = $rh->options_orders();

An iterator containing Finance::Robinhood::Options::Order objects is returned.
You need to be logged in for this to work.

    my $orders = $rh->options_orders(contract => $msft_call_130_Jun_2020);

If you would only like orders after a certain date, you can do that!

    my $orders = $rh->options_orders(after => Time::Moment->now->minus_days(7));
    # Also accepts ISO 8601

If you would only like orders before a certain date, you can do that!

    my $orders = $rh->options_orders(before => Time::Moment->now->minus_years(2));
    # Also accepts ISO 8601

=cut

    sub options_orders ( $s, %opts ) {

        #- `updated_at[gte]` - greater than or equal to a date; timestamp or ISO 8601
        #- `updated_at[lte]` - less than or equal to a date; timestamp or ISO 8601
        #- `contract` - options instrument URL
        my $url = URI->new('https://api.robinhood.com/options/orders/');
        $url->query_form(
            {
                $opts{instrument} ? ( instrument        => $opts{contract}->url ) : (),
                $opts{before}     ? ( 'updated_at[lte]' => +$opts{before} )       : (),
                $opts{after}      ? ( 'updated_at[gte]' => +$opts{after} )        : ()
            }
        );
        Finance::Robinhood::Utilities::Iterator->new(
            robinhood => $s,
            url       => $url,
            as        => 'Finance::Robinhood::Options::Order'
        );
    }

    sub _test_options_orders {
        my $rh     = t::Utility::rh_instance(1);
        my $orders = $rh->options_orders;
        isa_ok( $orders,       'Finance::Robinhood::Utilities::Iterator' );
        isa_ok( $orders->next, 'Finance::Robinhood::Options::Order' );
    }

=head2 C<options_order_by_id( ... )>

    my $order = $rh->options_order_by_id($id);

Returns a Finance::Robinhood::Options::Order object. You need to be logged in
for this to work.

=cut

    sub options_order_by_id ( $s, $id ) {
        $s->_req( GET => 'https://api.robinhood.com/options/orders/' . $id . '/' )
            ->as('Finance::Robinhood::Options::Order');
    }

    sub _test_options_order_by_id {
        my $rh    = t::Utility::rh_instance(1);
        my $order = $rh->options_order_by_id( $rh->options_orders->current->id );
        isa_ok( $order, 'Finance::Robinhood::Options::Order' );
    }

=head1 UNSORTED


=head2 C<user( )>

    my $me = $rh->user();

Returns a Finance::Robinhood::User object. You need to be logged in for this to
work.

=cut

    sub user ( $s ) {
        $s->_req( GET => 'https://api.robinhood.com/user/' )->as('Finance::Robinhood::User');
    }

    sub _test_user {
        my $rh = t::Utility::rh_instance(1);
        my $me = $rh->user();
        isa_ok( $me, 'Finance::Robinhood::User' );
    }

=head1 FOREX METHODS

Depending on your jurisdiction, your account may have access to Robinhood
Crypto. See https://crypto.robinhood.com/ for more.


=head2 C<currency_account( )>

    my $acct = $rh->currency_account;

Returns a Finance::Robinhood::Currency::Account object.

You need to be logged in and have access to Robinhood Crypto for this to work.

=cut

    has currency_account => (
        is        => 'ro',
        isa       => InstanceOf ['Finance::Robinhood::Currency::Account'],
        lazy      => 1,
        builder   => 1,
        predicate => 1,
        init_arg  => undef
    );

    sub _build_currency_account($s) {
        $s->currency_accounts->current;
    }

    sub _test_currency_account {
        my $acct = t::Utility::rh_instance(1)->currency_account;
        isa_ok( $acct, 'Finance::Robinhood::Currency::Account' );
    }

=head2 C<currency_accounts( )>

    my $accts = $rh->currency_accounts;

Returns an iterator full of Finance::Robinhood::Currency::Account objects.

You need to be logged in and have access to Robinhood Crypto for this to work.

=cut

    sub currency_accounts( $s ) {
        Finance::Robinhood::Utilities::Iterator->new(
            robinhood => $s,
            url       => 'https://nummus.robinhood.com/accounts/',
            as        => 'Finance::Robinhood::Currency::Account'
        );
    }

    sub _test_currency_accounts {
        my $accts = t::Utility::rh_instance(1)->currency_accounts;
        isa_ok( $accts,          'Finance::Robinhood::Utilities::Iterator' );
        isa_ok( $accts->current, 'Finance::Robinhood::Currency::Account' );
    }

=head2 C<currency_account_by_id( ... )>

    my $account = $rh->currency_account_by_id($id);

Returns a hash reference. You need to be logged in for this to work.

=cut

    sub currency_account_by_id ( $s, $id ) {
        $s->_req( GET => 'https://nummus.robinhood.com/accounts/' . $id . '/' )
            ->as('Finance::Robinhood::Currency::Account');
    }

    sub _test_currency_account_by_id {
        my $rh   = t::Utility::rh_instance(1);
        my $acct = $rh->currency_account_by_id( $rh->currency_account->id );
        isa_ok( $acct, 'Finance::Robinhood::Currency::Account' );
    }

=head2 C<currency_halts( [...] )>

    my $halts = $rh->currency_halts;
    # or
    $halts = $rh->currency_halts( active => 1 );

Returns an iterator full of Finance::Robinhood::Currency::Halt objects.

If you pass a true value to a key named C<active>, only active halts will be
returned.

You need to be logged in and have access to Robinhood Crypto for this to work.

=cut

    sub currency_halts ( $s, %filters ) {
        $filters{active} = $filters{active} ? 'true' : 'false' if defined $filters{active};
        my $url = URI->new('https://nummus.robinhood.com/halts/');
        $url->query_form(%filters);
        Finance::Robinhood::Utilities::Iterator->new(
            robinhood => $s,
            url       => $url,
            as        => 'Finance::Robinhood::Currency::Halt'
        );
    }

    sub _test_currency_halts {
        my $halts = t::Utility::rh_instance(1)->currency_halts;
        isa_ok( $halts,          'Finance::Robinhood::Utilities::Iterator' );
        isa_ok( $halts->current, 'Finance::Robinhood::Currency::Halt' );
        #
        #is( scalar $halts->all
        #        > scalar t::Utility::rh_instance(1)->currency_halts(active => 1)
        #        ->all,
        #    1,
        #    'active => 1 works'
        #);
    }

=head2 C<currency_halt_by_id( ... )>

    my $halts = $rh->currency_halt_by_id( '6a2a026a-e391-43cf-aadf-25826ea5432b' );


Returns an Finance::Robinhood::Currency::Halt object if a halt with this ID
exits.

If you pass a true value to a key named C<active>, only active halts will be
returned.

You need to be logged in and have access to Robinhood Crypto for this to work.

=cut

    sub currency_halt_by_id ( $s, $id ) {
        my $url = URI->new();
        $s->_req( GET => 'https://nummus.robinhood.com/halts/' . $id . '/' )
            ->as('Finance::Robinhood::Currency::Halt');
    }

    sub _test_currency_halt_by_id {
        my $halt = t::Utility::rh_instance(1)
            ->currency_halt_by_id('6a2a026a-e391-43cf-aadf-25826ea5432b');
        isa_ok( $halt, 'Finance::Robinhood::Currency::Halt' );
        is( $halt->id, '6a2a026a-e391-43cf-aadf-25826ea5432b', 'ids match' );
    }

=head2 C<currencies( )>

    my $currecies = $rh->currencies();

An iterator containing Finance::Robinhood::Forex::Currency objects is returned.
You need to be logged in for this to work.

=cut

    sub currencies ($s) {
        Finance::Robinhood::Utilities::Iterator->new(
            robinhood => $s,
            url       => 'https://nummus.robinhood.com/currencies/',
            as        => 'Finance::Robinhood::Currency'
        );
    }

    sub _test_currencies {
        my $rh         = t::Utility::rh_instance(1);
        my $currencies = $rh->currencies;
        isa_ok( $currencies,          'Finance::Robinhood::Utilities::Iterator' );
        isa_ok( $currencies->current, 'Finance::Robinhood::Currency' );
    }

=head2 C<currency_by_id( ... )>

    my $currency = $rh->currency_by_id($id);

Returns a Finance::Robinhood::Currency object. You need to be logged in for
this to work.

=cut

    sub currency_by_id ( $s, $id ) {
        $s->_req( GET => 'https://nummus.robinhood.com/currencies/' . $id . '/' )
            ->as('Finance::Robinhood::Currency');
    }

    sub _test_currency_by_id {
        my $rh  = t::Utility::rh_instance(1);
        my $usd = $rh->currency_by_id('1072fc76-1862-41ab-82c2-485837590762');
        isa_ok( $usd, 'Finance::Robinhood::Currency' );
    }

=head2 C<currency_pairs( )>

    my $pairs = $rh->currency_pairs( );

An iterator containing Finance::Robinhood::Currency::Pair objects is returned.
You need to be logged in for this to work.

=cut

    sub currency_pairs ($s) {
        Finance::Robinhood::Utilities::Iterator->new(
            robinhood => $s,
            url       => 'https://nummus.robinhood.com/currency_pairs/',
            as        => 'Finance::Robinhood::Currency::Pair'
        );
    }

    sub _test_currency_pairs {
        my $rh    = t::Utility::rh_instance(1);
        my $pairs = $rh->currency_pairs;
        isa_ok( $pairs,          'Finance::Robinhood::Utilities::Iterator' );
        isa_ok( $pairs->current, 'Finance::Robinhood::Currency::Pair' );
    }

=head2 C<currency_pair_by_id( ... )>

    my $watchlist = $rh->currency_pair_by_id($id);

Returns a Finance::Robinhood::Currency::Pair object. You need to be logged in
for this to work.

=cut

    sub currency_pair_by_id ( $s, $id ) {
        $s->_req( GET => 'https://nummus.robinhood.com/currency_pairs/' . $id . '/' )
            ->as('Finance::Robinhood::Currency::Pair');
    }

    sub _test_currency_pair_by_id {
        my $rh      = t::Utility::rh_instance(1);
        my $btc_usd = $rh->currency_pair_by_id('3d961844-d360-45fc-989b-f6fca761d511');    # BTC-USD
        isa_ok( $btc_usd, 'Finance::Robinhood::Currency::Pair' );
    }

=head2 C<currency_pair_by_name( ... )>

    my $bitcoin = $rh->currency_pair_by_name('Bitcoin');
       $bitcoin = $rh->currency_pair_by_name('BTC');

Returns a Finance::Robinhood::Currency::Pair object. You need to be logged in
for this to work.

=cut

    sub currency_pair_by_name ( $s, $id ) {
        [
            grep {
                my $asset = $_->asset_currency;
                ( $id eq $asset->code && $_->quote_currency->code eq 'USD' ) || $id eq $asset->name
            } @{ $s->search($id)->{currency_pairs} }
        ]->[0] // ();
    }

    sub _test_currency_pair_by_name {
        my $rh = t::Utility::rh_instance(1);
        #
        my $btc_usd = $rh->currency_pair_by_name('BTC');
        isa_ok( $btc_usd, 'Finance::Robinhood::Currency::Pair' );
        is( $btc_usd->id, '3d961844-d360-45fc-989b-f6fca761d511' );
        #
        $btc_usd = $rh->currency_pair_by_name('Bitcoin');
        isa_ok( $btc_usd, 'Finance::Robinhood::Currency::Pair' );
        is( $btc_usd->id, '3d961844-d360-45fc-989b-f6fca761d511' );
        #
        $btc_usd = $rh->currency_pair_by_name('Meh');
        is( $btc_usd, undef, 'Bad currency name' );
    }

=head2 C<currency_watchlists( )>

    my $watchlists = $rh->currency_watchlists();

Returns an iterator containing Finance::Robinhood::Currency::Watchlist objects.

You need to be logged in for this to work.

=cut

    sub currency_watchlists ($s) {
        Finance::Robinhood::Utilities::Iterator->new(
            robinhood => $s,
            url       => 'https://nummus.robinhood.com/watchlists/',
            as        => 'Finance::Robinhood::Currency::Watchlist'
        );
    }

    sub _test_currency_watchlists {
        my $rh         = t::Utility::rh_instance(1);
        my $watchlists = $rh->currency_watchlists;
        isa_ok( $watchlists,          'Finance::Robinhood::Utilities::Iterator' );
        isa_ok( $watchlists->current, 'Finance::Robinhood::Currency::Watchlist' );
    }

=head2 C<currency_watchlist_by_id( ... )>

    my $watchlist = $rh->currency_watchlist_by_id($id);

Returns a Finance::Robinhood::Currency::Watchlist object.

=cut

    sub currency_watchlist_by_id ( $s, $id ) {
        $s->_req( GET => 'https://nummus.robinhood.com/watchlists/' . $id . '/' )
            ->as('Finance::Robinhood::Currency::Watchlist');
    }

    sub _test_currency_watchlist_by_id {
        my $rh        = t::Utility::rh_instance(1);
        my $watchlist = $rh->currency_watchlist_by_id( $rh->currency_watchlists->current->id );
        isa_ok( $watchlist, 'Finance::Robinhood::Currency::Watchlist' );
    }

=head2 C<currency_activations( )>

    my $activations = $rh->currency_activations();

Returns an iterator containing Finance::Robinhood::Currency::Activation
objects.

=cut

    sub currency_activations ($s) {
        Finance::Robinhood::Utilities::Iterator->new(
            robinhood => $s,
            url       => 'https://nummus.robinhood.com/activations/',
            as        => 'Finance::Robinhood::Currency::Activation'
        );
    }

    sub _test_currency_activations {
        my $rh         = t::Utility::rh_instance(1);
        my $watchlists = $rh->currency_activations;
        isa_ok( $watchlists, 'Finance::Robinhood::Utilities::Iterator' );
        ref_ok( $watchlists->current, 'HASH' );
    }

=head2 C<currency_activation_by_id( ... )>

    my $activation = $rh->currency_activation_by_id($id);

Returns a Finance::Robinhood::Currency::Activation object.

=cut

    sub currency_activation_by_id ( $s, $id ) {
        $s->_req( GET => 'https://nummus.robinhood.com/activations/' . $id . '/' )
            ->as('Finance::Robinhood::Currency::Activation');
    }

    sub _test_currency_activation_by_id {
        my $rh           = t::Utility::rh_instance(1);
        my $activation_1 = $rh->currency_activations->current;
        my $activation_2 = $rh->currency_activation_by_id( $activation_1->id );    # Cheat
        isa_ok( $activation_2, 'Finance::Robinhood::Currency::Activation' );
    }

=head2 C<currency_portfolios( )>

    my $portfolios = $rh->currency_portfolios();

Returns an iterator containing Finance::Robinhood::Currency::Portfolio objects.

You need to be logged in for this to work.

=cut

    sub currency_portfolios ($s) {
        Finance::Robinhood::Utilities::Iterator->new(
            robinhood => $s,
            url       => 'https://nummus.robinhood.com/portfolios/',
            as        => 'Finance::Robinhood::Currency::Portfolio'
        );
    }

    sub _test_currency_portfolios {
        my $rh         = t::Utility::rh_instance(1);
        my $portfolios = $rh->currency_portfolios;
        isa_ok( $portfolios,          'Finance::Robinhood::Utilities::Iterator' );
        isa_ok( $portfolios->current, 'Finance::Robinhood::Currency::Portfolio' );
    }

=head2 C<currency_portfolio_by_id( ... )>

    my $portfolio = $rh->currency_portfolio_by_id($id);

Returns a Finance::Robinhood::Currency::Portfolio object.

You need to be logged in for this to work.

=cut

    sub currency_portfolio_by_id ( $s, $id ) {
        $s->_req( GET => 'https://nummus.robinhood.com/portfolios/' . $id . '/' )
            ->as('Finance::Robinhood::Currency::Portfolio');
    }

    sub _test_currency_portfolio_by_id {
        my $rh = t::Utility::rh_instance(1);
        my $portfolio
            = $rh->currency_portfolio_by_id( $rh->currency_portfolios->current->id );    # Cheat
        isa_ok( $portfolio, 'Finance::Robinhood::Currency::Portfolio' );
    }

=head2 C<new_currency_application( ... )>

    my $activation = $rh->new_currency_application( type => 'new_account' );

Submits an application to activate a new cryptocurrency account. You need to be
logged in for this to work.

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

    sub new_currency_application ( $s, %filters ) {
        $filters{speculative} = $filters{speculative} ? 'true' : 'false'
            if defined $filters{speculative};
        my $res
            = $s->_req( POST => 'https://nummus.robinhood.com/activations/', form => \%filters );
    }

    sub _test_new_currency_application {
        diag('This is one of those methods that is almost impossible to test from this side.');
        pass('Rather not have a million activation attempts attached to my account');
    }

=head2 C<currency_orders( )>

    my $orders = $rh->currency_orders( );

An iterator containing Finance::Robinhood::Forex::Order objects is returned.
You need to be logged in for this to work.

=cut

    sub currency_orders ($s) {
        Finance::Robinhood::Utilities::Iterator->new(
            robinhood => $s,
            url       => 'https://nummus.robinhood.com/orders/',
            as        => 'Finance::Robinhood::Currency::Order'
        );
    }

    sub _test_currency_orders {
        my $rh     = t::Utility::rh_instance(1);
        my $orders = $rh->currency_orders;
        isa_ok( $orders,          'Finance::Robinhood::Utilities::Iterator' );
        isa_ok( $orders->current, 'Finance::Robinhood::Currency::Order' );
    }

=head2 C<forex_order_by_id( ... )>

    my $order = $rh->forex_order_by_id($id);

Returns a Finance::Robinhood::Currency::Order object. You need to be logged in
for this to work.

=cut

    sub currency_order_by_id ( $s, $id ) {
        $s->_req( GET => 'https://nummus.robinhood.com/orders/' . $id . '/' )
            ->as('Finance::Robinhood::Currency::Order');
    }

    sub _test_currency_order_by_id {
        my $rh    = t::Utility::rh_instance(1);
        my $order = $rh->currency_orders->current;
        my $forex = $rh->currency_order_by_id( $order->id );    # Cheat
        isa_ok( $forex, 'Finance::Robinhood::Currency::Order' );
    }

=head2 C<currency_positions( [...] )>

    my $holdings = $rh->currency_positions( );

Returns an iterator filled with Finance::Robinhood::Currency::Position objects.

You must be logged in.

=cut

    sub currency_positions ( $s, %filters ) {
        $filters{nonzero} = !!$filters{nonzero} ? 'true' : 'false' if defined $filters{nonzero};
        my $url = URI->new('https://nummus.robinhood.com/holdings/');
        $url->query_form(%filters);    # Idk what nozero does here... nothing, it seems.
        Finance::Robinhood::Utilities::Iterator->new(
            robinhood => $s,
            url       => $url,
            as        => 'Finance::Robinhood::Currency::Position'
        );
    }

    sub _test_currency_positions {
        my $positions = t::Utility::rh_instance(1)->currency_positions;
        isa_ok( $positions,          'Finance::Robinhood::Utilities::Iterator' );
        isa_ok( $positions->current, 'Finance::Robinhood::Currency::Position' );
    }

=head2 C<currency_position_by_id( ... )>

    my $holding = $rh->currency_position_by_id($id);

Returns a Finance::Robinhood::Currency::Position object.

You need to be logged in for this to work.

=cut

    sub currency_position_by_id ( $s, $id ) {
        $s->_req( GET => 'https://nummus.robinhood.com/holdings/' . $id . '/' )
            ->as('Finance::Robinhood::Currency::Position');
    }

    sub _test_currency_positions_by_id {
        my $rh      = t::Utility::rh_instance(1);
        my $holding = $rh->currency_position_by_id( $rh->currency_positions->current->id );
        isa_ok( $holding, 'Finance::Robinhood::Currency::Position' );
    }

=head1 BANKING METHODS

Move money in and out of your brokerage account.

=cut

    # TODO

=head1 ACATS/TRANSFER METHODS

At some point, you might need to move assets from one firm to another.

=head2 C<acats_transfers( )>

    my $acats = $rh->acats_transfers();

An iterator containing Finance::Robinhood::ACATS::Transfer objects is returned.

You need to be logged in for this to work.

=cut

    sub acats_transfers ($s) {
        Finance::Robinhood::Utilities::Iterator->new(
            robinhood => $s,
            url       => 'https://api.robinhood.com/acats/',
            as        => 'Finance::Robinhood::ACATS'
        );
    }

    sub _test_acats_transfers {
        my $transfers = t::Utility::rh_instance(1)->acats_transfers;
        isa_ok( $transfers, 'Finance::Robinhood::Utilities::Iterator' );
        skip_all('No ACATS transfers found') if !$transfers->has_next;
        isa_ok( $transfers->current, 'Finance::Robinhood::ACATS::Transfer' );
    }

=head2 C<request_acats_transfer( ... )>

    my $done = $rh->request_acats_transfer(
        account => $rh->equity_account,

    )

Request an ACATS transfer. You may pass the following options:

=over

=item C<account> - Finance::Robinhood::Equity::Account object (optional; defaults to C<equity_account( )>)

=item C<contra_account_number> - Account number at the other end of the transfer (required)

=item C<contra_account_title> - String used to identify the account in UI (optional)

=item C<contra_brokerage_name> - String used to identify the other firm (optional)

=item C<contra_correspondent_number> - String used (required)

=back

=cut

    sub request_acats_transfer ( $s, %opts ) {
        $opts{account} //= $s->equity_account;
        $opts{account} = +$opts{account};    # Force scalar
        $s->_req( POST => 'https://api.robinhood.com/acats/', form => \%opts );
    }

=head1 INBOX METHODS

    @retrofit2.http.GET("inbox/threads/{threadId}/")
    io.reactivex.Single<com.robinhood.models.api.ApiThread> getThread(@retrofit2.http.Path("threadId") java.lang.String str);

    @retrofit2.http.GET("inbox/threads/{threadId}/messages/")
    io.reactivex.Single<com.robinhood.models.api.ApiMessageResult> getThreadMessages(@retrofit2.http.Path("threadId") java.lang.String str, @retrofit2.http.Query("before") java.lang.String str2, @retrofit2.http.Query("after") java.lang.String str3);

    @retrofit2.http.GET("inbox/settings/thread/{threadId}/")
    io.reactivex.Single<com.robinhood.models.api.ApiNotificationThreadSettingsItem> getThreadNotificationSettingsV4(@retrofit2.http.Path("threadId") java.lang.String str);

    @retrofit2.http.GET("inbox/settings/{threadId}/")
    io.reactivex.Single<com.robinhood.models.api.ApiNotificationSettingsV3> getThreadSettings(@retrofit2.http.Path("threadId") java.lang.String str);

    @retrofit2.http.GET("inbox/threads/")
    io.reactivex.Single<com.robinhood.models.PaginatedResult<com.robinhood.models.api.ApiThread>> getThreads();

=cut

    sub inbox ($s) {

        # Finance::Robinhood::Inbox;
        Finance::Robinhood::Inbox->new( robinhood => $s );
    }

=head1 Cash Management


=head2 C<cash_accounts( )>

Returns an iterator filled with C<Finance::Robinhood::Cash> objects.

=cut

    sub cash_accounts( $s ) {
        Finance::Robinhood::Utilities::Iterator->new(
            robinhood => $s,
            url       => 'https://minerva.robinhood.com/accounts/',
            as        => 'Finance::Robinhood::Cash'
        );
    }

=head2 C<cash_account_by_id( $id )>

Returns the related Finance::Robinhood::Cash object.

=cut

    sub cash_account_by_id ( $s, $id ) {
        $s->_req( GET => 'https://minerva.robinhood.com/accounts/' . $id . '/' )
            ->as('Finance::Robinhood::Cash');
    }

=head2 C<atms( $latitude, $longitude )>

Returns an iterator filled with Finance::Robinhood::Cash::ATM objects.

C<$latitude> and C<$longitude> coordinates must be in decimal degrees.

=cut

    sub atms ( $s, $latitude, $longitude ) {
        Finance::Robinhood::Utilities::Iterator->new(
            robinhood => $s,
            url       => sprintf(
                'https://minerva.robinhood.com/atms/?latitude=%4.8f&longitude=%4.8f',
                $latitude, $longitude
            ),

            # Note: As of today, even though Robinhood returns value in a paginated list with a defined next page,
            # grabbing that second page results in a server error.
            as => 'Finance::Robinhood::Cash::ATM'
        );
    }

=head2 C<atm_by_id( $UUID )>

	$rh->atm_by_id('2fb3fac0-96ef-4154-830f-21d4b8affbca');

Returns a Finance::Robinhood::Cash::ATM object.

=cut

    sub atm_by_id ( $s, $uuid ) {
        $s->_req( GET => 'https://minerva.robinhood.com/atms/' . $uuid . '/' )
            ->as('Finance::Robinhood::Cash::ATM');
    }

=head2 C<cash_flow( )>

Returns a hash reference with two keys: C<cash_in> and C<cash_out>. They both
contain these keys:

=over

=item C<amount> - This is a dollar amount.

=item C<currency_code> - Currency type (C<USD>)

=item C<currency_id> - UUID

=back

=cut

    sub cash_flow( $s ) {
        $s->_req( GET => 'https://minerva.robinhood.com/history/cash_flow/' )->as(
            Dict [
                cash_in  => Dict [ amount => Num, currency_code => Str, currency_id => UUID ],
                cash_out => Dict [ amount => Num, currency_code => Str, currency_id => UUID ]
            ]
        );
    }

    sub _test_cash_flow {
        my $rh       = t::Utility::rh_instance(1);
        my $balances = $rh->cash_flow();
        ref_ok( $balances, 'HASH' );

        #ddx $balances;
        #die;
        ref_ok( $balances->{$_}, 'HASH' ) for qw[cash_in cash_out];
    }

=head2 C<debit_cards( )>

Returns an iterator filled with C<Finance::Robinhood::Cash::Card> objects.

=cut

    sub debit_cards( $s ) {
        Finance::Robinhood::Utilities::Iterator->new(
            robinhood => $s,
            url       => 'https://minerva.robinhood.com/cards/',
            as        => 'Finance::Robinhood::Cash::Card'
        );
    }

=head2 C<debit_card_by_id( ... )>

Returns a C<Finance::Robinhood::Cash::Card> object.

=cut

    sub debit_card_by_id ( $s, $id ) {
        $s->_req( GET => sprintf 'https://minerva.robinhood.com/cards/%s/', $id )
            ->as('Finance::Robinhood::Cash::Card');
    }

=head1 'FUN' METHODS


=cut

    # Fun stuff - Cash Management aka McDuckling
    sub getTailgateSpot ($s) {
        $s->_req( GET => 'https://midlands.robinhood.com/tailgate/mighty_duck/spot/' );
    }

    sub bumpTailgateSpot ( $s, $num_spots = 1 ) {
        $s->_req(
            POST => 'https://midlands.robinhood.com/tailgate/mighty_duck/spot/bump/',
            form => { num_spots => $num_spots }
        );
    }

    # Autologin by fudging with params to new()
    # Must be after all 'has' calls...
    around new => sub ( $orig, $class, %args ) {

        # TODO: I need to make this work with different forms of login info...
        my $s = $orig->( $class, @_ );
        $s->refresh_login_token( delete $args{refresh_token}, %args )
            if $s && defined $args{refresh_token};

        #($s, $refresh_token = $s->oauth2_token->refresh_token,
        #                         %opt)
        $s->_login(%args) if $s && %args && !defined $s->oauth2_token;
        $s;
    };

#    @retrofit2.http.FormUrlEncoded
#    @retrofit2.http.POST("tailgate/mighty_duck/spot/bump/")
#    io.reactivex.Single<com.robinhood.models.api.minerva.ApiMcDucklingTailgateSpot> bumpTailgateSpot(@retrofit2.http.Field("num_spots") int i);
#
#    @retrofit2.http.POST("tailgate/mighty_duck/spot/")
#    io.reactivex.Single<com.robinhood.models.api.minerva.ApiMcDucklingTailgateSpot>
#   createTailgateSpot(@retrofit2.http.Body com.robinhood.models.api.minerva.ApiMcDucklingTailgateSpot.Request request);
#
#    @retrofit2.http.GET("tailgate/mighty_duck/is_live/")
#    io.reactivex.Single<com.robinhood.models.api.ApiTailgateAccess> getAccess();
#
#    @retrofit2.http.GET("tailgate/mighty_duck/spot/")
#    io.reactivex.Single<com.robinhood.models.api.minerva.ApiMcDucklingTailgateSpot> getTailgateSpot();
#
#    @retrofit2.http.GET("tailgate/mighty_duck/spot/{email}/")
#    io.reactivex.Single<com.robinhood.models.api.minerva.ApiMcDucklingTailgateSpot> getTailgateSpotByEmail(@retrofit2.http.Path("email") java.lang.String str);
#
#    @retrofit2.http.FormUrlEncoded
#    @retrofit2.http.PATCH("tailgate/mighty_duck/spot/update/")
#    io.reactivex.Single<com.robinhood.models.api.minerva.ApiMcDucklingTailgateSpot>
#   updateTailgateSpot(@retrofit2.http.Field("card_color") com.robinhood.models.db.mcduckling.CardColor cardColor);

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
}
