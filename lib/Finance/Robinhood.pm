package Finance::Robinhood;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood - Trade Stocks, ETFs, Options, and Cryptocurrency without
Commission

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;

=cut

our $VERSION = '0.92_001';
#
use Mojo::Base-base, -signatures;
use Mojo::UserAgent;
use Mojo::URL;
#
BEGIN { use lib '../../lib/' }
use Finance::Robinhood::Account;
use Finance::Robinhood::Forex::Pair;
use Finance::Robinhood::Data::OAuth2::Token;
use Finance::Robinhood::Equity::Fundamentals;
use Finance::Robinhood::Equity::Instrument;
use Finance::Robinhood::Equity::Order;
use Finance::Robinhood::Equity::Quote;
use Finance::Robinhood::News;
use Finance::Robinhood::Options::Chain;
use Finance::Robinhood::Options::Chain::Underlying;
use Finance::Robinhood::Options::Instrument;
use Finance::Robinhood::Tag;
use Finance::Robinhood::Utility::Iterator;
use Finance::Robinhood::Error;

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

=cut

has _ua => sub { Mojo::UserAgent->new };
has '_token';

sub _test_new {
    plan( tests => 1 );
    my $rh = new_ok('Finance::Robinhood');
    done_testing();
}

sub _get ( $s, $url, %data ) {
    $url = Mojo::URL->new($url);
    $url->query( \%data );
    use Data::Dump;
    ddx $s->_token;
    $s->_ua->get(
        $url => {
            $s->_token ? (
                'Authorization' => ucfirst join ' ',
                $s->_token->token_type, $s->_token->access_token
                ) :
                ()
        }
    )->result;
}

sub _test_get {
    plan( tests => 3 );
    my $rh  = new_ok('Finance::Robinhood');
    my $res = $rh->_get('https://jsonplaceholder.typicode.com/todos/1');
    isa_ok( $res, 'Mojo::Message::Response', '_get(...) returned Mojo response' );
    is( $res->json->{title}, 'delectus aut autem', '_post(...) works!' );
    done_testing();
}

sub _post ( $s, $url, %data ) {
    $s->_ua->post(
        Mojo::URL->new($url) => {
            $s->_token ? (
                'Authorization' => ucfirst join ' ',
                $s->_token->token_type, $s->_token->access_token
                ) :
                ()
        } => form => \%data
    )->result;
}

sub _test_post {
    plan( tests => 3 );
    my $rh  = new_ok('Finance::Robinhood');
    my $res = $rh->_post(
        'https://jsonplaceholder.typicode.com/posts/',
        title  => 'Whoa',
        body   => 'This is a test',
        userId => 13,
        id     => 755
    );
    isa_ok( $res, 'Mojo::Message::Response', '_get(...) returned Mojo response' );
    is_deeply(
        $res->json,
        { body => 'This is a test', title => 'Whoa', userId => 13, id => 755 },
        '_post(...) works!'
    );
    done_testing();
}

=head2 C<login( ... )>

    my $rh = Finance::Robinhood->new()->login($user, $pass);

A new Finance::Robinhood object is created without credentials. Before you can
buy or sell or do almost anything else, you must L<log in|/"login( ... )">.

	my $rh = Finance::Robinhood->new()->login($user, $pass, mfa_callback => sub {
		# Do something like pop open an inputbox in TK or whatever
	} );

If you have MFA enabled, you may (or must) also pass a callback. When the code
is called, a ref will be passed that will contain C<mfa_required> (a boolean
value) and C<mfa_type> which might be C<app>, C<sms>, etc. Your return value
must be the MFA code.

	my $rh = Finance::Robinhood->new()->login($user, $pass, mfa_code => 980385);

If you already know the MFA code (for example if you have MFA enabled through
an app), you can pass that code directly and log in.

=cut

sub login ( $s, $u, $p, %opt ) {

    # OAUTH2
    my $res = $s->_post(
        'https://api.robinhood.com/oauth2/token/',
        scope    => 'internal',
        username => $u,
        password => $p,
        ( $opt{mfa_code} ? ( mfa_code => $opt{mfa_code} ) : () ),
        grant_type => ( $opt{grant_type} // 'password' ),
        client_id  => $opt{client_id} // sub {
            my ( @k, $c ) = split //, shift;
            map {    # cheap and easy
                unshift @k, pop @k;
                $c .= chr( ord ^ ord $k[0] );
            } split //, "\aW];&Y55\35I[\a,6&>[5\34\36\f\2]]\$\x179L\\\x0B4<;,\"*&\5);";
            $c;
        }
            ->(__PACKAGE__),
    );
    if ( $res->is_success ) {
        if ( $res->json->{mfa_required} ) {
            return $opt{mfa_callback} ?
                Finance::Robinhood::Error->new( description => 'You must pass an mfa_callback.' ) :
                $s->login( $u, $p, %opt, mfa_code => $opt{mfa_callback}->( $res->json ) );
        }
        else {
            $s->_token( Finance::Robinhood::Data::OAuth2::Token->new( $res->json ) );
        }
    }
    else {
        return Finance::Robinhood::Error->new( $res->json );
    }
    $s;
}

sub _test_login {
    plan( tests => 2 );
    my $rh = new_ok('Finance::Robinhood');
SKIP: {    # XXX - Doesn't work with MFA, obviously
        my ( $user, $pass ) = ( $ENV{RHUSER}, $ENV{RHPASS} );
        skip( 'No auth info in environment', 1 ) unless $user && $pass;
        $rh->login( $user, $pass );
        isa_ok(
            $rh->_token,
            'Finance::Robinhood::Data::OAuth2::Token',
            'login( ... ) worked; we have a valid token'
        );
    }
    done_testing();
}

=head2 C<instruments( )>

    my $instruments = $rh->instruments();

Returns an iterator containing equity instruments.

=cut

sub instruments($s) {
    Finance::Robinhood::Utility::Iterator->new(
        _rh        => $s,
        _next_page => 'https://api.robinhood.com/instruments/',
        _class     => 'Finance::Robinhood::Equity::Instrument'
    );
}

sub _test_instruments {
    plan( tests => 3 );
    my $rh          = new_ok('Finance::Robinhood');
    my $instruments = $rh->instruments;
    isa_ok( $instruments, 'Finance::Robinhood::Utility::Iterator', '...instruments call works' );
    isa_ok( $instruments->next, 'Finance::Robinhood::Equity::Instrument' );
    done_testing();
}

=head2 C<instrument_by_symbol( )>

    my $instrument = $rh->instrument_by_symbol();

Searches for an equity instrument by ticker symbol and returns a
Finance::Robinhood::Equity::Instrument.

=cut

sub instrument_by_symbol ( $s, $symbol ) {
    Finance::Robinhood::Utility::Iterator->new(
        _rh => $s,
        _next_page =>
            Mojo::URL->new('https://api.robinhood.com/instruments/')->query( symbol => $symbol ),
        _class => 'Finance::Robinhood::Equity::Instrument'
    )->current;
}

sub _test_instrument_by_symbol {
    plan( tests => 2 );
    my $rh         = new_ok('Finance::Robinhood');
    my $instrument = $rh->instrument_by_symbol('MSFT');
    isa_ok( $instrument, 'Finance::Robinhood::Equity::Instrument' );
    done_testing();
}

=head2 C<options_chains( )>

    my $chains = $rh->options_chains->all;

Returns an iterator containing chain elements.

	my $equity = $rh->search('MSFT')->{instruments}[0]->options_chains->all;

You may limit the call by passing a list of options instruments or a list of
equity instruments.

=cut

sub options_chains ( $s, @filter ) {
    Finance::Robinhood::Utility::Iterator->new(
        _rh        => $s,
        _next_page => Mojo::URL->new('https://api.robinhood.com/options/chains/')->query(
            {   ( grep { ref $_ eq 'Finance::Robinhood::Equity::Instrument' } @filter ) ?
                    ( equity_instrument_ids => join ',', map { $_->id } @filter ) :
                    ( grep { ref $_ eq 'Finance::Robinhood::Options::Instrument' } @filter ) ?
                    ( ids => join ',', map { $_->chain_id } @filter ) :
                    ()
            }
        ),
        _class => 'Finance::Robinhood::Options::Chain'
    );
}

sub _test_options_chains {
    plan( tests => 9 );
    my $rh     = new_ok('Finance::Robinhood');
    my $chains = $rh->options_chains;
    isa_ok( $chains, 'Finance::Robinhood::Utility::Iterator', '...options_chains call works' );
    isa_ok( $chains->next, 'Finance::Robinhood::Options::Chain' );

    # Get by equity instrument
    $chains = $rh->options_chains( $rh->search('MSFT')->{instruments}[0] );
    isa_ok(
        $chains,
        'Finance::Robinhood::Utility::Iterator',
        '...options_chains($equity) call works'
    );
    isa_ok( $chains->next, 'Finance::Robinhood::Options::Chain' );
    is( $chains->current->symbol, 'MSFT', '...correct chain by equity instrument' );

    # Get by options instrument
    my $options = $rh->options_instruments(
        chain_id    => $rh->search('MSFT')->{instruments}[0]->tradable_chain_id,
        tradability => 'tradable'
    );
    $chains = $rh->options_chains( $options->next );
    isa_ok(
        $chains,
        'Finance::Robinhood::Utility::Iterator',
        '...options_chains($option) call works'
    );
    isa_ok( $chains->next, 'Finance::Robinhood::Options::Chain' );
    is( $chains->current->symbol, 'MSFT', '...correct chain by equity instrument' );
    done_testing();
}

=head2 C<orders( )>

    my $orders = $rh->orders();

An iterator containing Finance::Robinhood::Equity::Order objects is returned.
You need to be logged in for this to work.

=cut

sub orders($s) {
    Finance::Robinhood::Utility::Iterator->new(
        _rh        => $s,
        _next_page => 'https://api.robinhood.com/orders/',
        _class     => 'Finance::Robinhood::Equity::Order'
    );
}

sub _test_orders {
    plan( tests => 3 );
    my $rh = new_ok('Finance::Robinhood');
SKIP: {
        my ( $user, $pass ) = ( $ENV{RHUSER}, $ENV{RHPASS} );
        skip( 'No auth info in environment', 2 ) unless $user && $pass;
        $rh->login( $user, $pass );
        my $orders = $rh->orders;
        isa_ok( $orders, 'Finance::Robinhood::Utility::Iterator', '...instruments call works' );
        isa_ok( $orders->next, 'Finance::Robinhood::Equity::Order' );
    }
    done_testing();
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
    Finance::Robinhood::Utility::Iterator->new(
        _rh => $s,
        _next_page =>
            Mojo::URL->new('https://api.robinhood.com/options/instruments/')->query(%filters),
        _class => 'Finance::Robinhood::Options::Instrument'
    );
}

sub _test_options_instruments {
    plan( tests => 4 );
    my $rh = new_ok('Finance::Robinhood');
SKIP: {
        my $options = $rh->options_instruments(
            chain_id    => $rh->search('MSFT')->{instruments}[0]->tradable_chain_id,
            tradability => 'tradable'
        );
        isa_ok(
            $options,
            'Finance::Robinhood::Utility::Iterator',
            '...options_instruments() call works'
        );
        isa_ok( $options->next, 'Finance::Robinhood::Options::Instrument' );
        is( $options->current->chain_symbol, 'MSFT', '...Microsoft options instrument retured' );
    }
    done_testing();
}

=head2 C<accounts( )>

    my $accounts = $rh->accounts();

An iterator containing Finance::Robinhood::Account objects is returned. You
need to be logged in for this to work.

=cut

sub accounts ($s) {
    Finance::Robinhood::Utility::Iterator->new(
        _rh        => $s,
        _next_page => 'https://api.robinhood.com/accounts/',
        _class     => 'Finance::Robinhood::Account'
    );
}

sub _test_accounts {
    plan( tests => 3 );
    my $rh = new_ok('Finance::Robinhood');
SKIP: {
        my ( $user, $pass ) = ( $ENV{RHUSER}, $ENV{RHPASS} );
        skip( 'No auth info in environment', 2 ) unless $user && $pass;
        $rh->login( $user, $pass );
        my $accounts = $rh->accounts;
        isa_ok( $accounts, 'Finance::Robinhood::Utility::Iterator', '...instruments call works' );
        isa_ok( $accounts->next, 'Finance::Robinhood::Account' );
    }
    done_testing();
}

=head2 C<search( ... )>

    my $results = $rh->search('microsoft');

Returns a set of search results. Depending on the results, you'll get a list of
Finance::Robinhood::Equity::Instrument objects in a key named C<instruments>, a
list of Finance::Robinhood::Tag objects in a key named C<tags>, and a list of
currency pairs in the aptly named C<currency_pairs> key.

        $rh->search('New on Robinhood')->{tags};
        $rh->search('bitcoin')->{currency_pairs};

You do not need to be logged in for this to work.

=cut

sub search ( $s, $keyword ) {
    my $res = $s->_get( 'https://midlands.robinhood.com/search/', query => $keyword );
    if ( $res->is_success ) {
        my $json = $res->json;
        return {
            tags => [ map { Finance::Robinhood::Tag->new( _rh => $s, %$_ ) } @{ $json->{tags} } ],
            currency_pairs => [
                map { Finance::Robinhood::Forex::Pair->new( _rh => $s, %$_ ) }
                    @{ $json->{currency_pairs} }
            ],
            instruments => [
                map { Finance::Robinhood::Equity::Instrument->new( _rh => $s, %$_ ) }
                    @{ $json->{instruments} }
            ]
        };
    }
    Finance::Robinhood::Error->new( $res->json );
}

sub _test_search {
    plan( tests => 5 );
    my $rh = new_ok('Finance::Robinhood');
    isa_ok(
        $rh->search('microsoft')->{instruments}[0],
        'Finance::Robinhood::Equity::Instrument',
        'searching for "microsoft" returns the correct instrument',
    );
    isa_ok(
        $rh->search('New on Robinhood')->{tags}[0],
        'Finance::Robinhood::Tag',
        'searching for "New on Robinhood" returns the correct instrument',
    );
    isa_ok(
        $rh->search('bitcoin')->{currency_pairs}[0],
        'Finance::Robinhood::Forex::Pair',
        'searching for "bitcoin" returns the correct currecy pairs',
    );
    is_deeply(
        $rh->search('LOnfs98jio'),
        { currency_pairs => [], instruments => [], tags => [] },
        'searching for "LOnfs98jio" returns empty lists',
    );
    done_testing();
}

=head2 C<news( ... )>

    my $news = $rh->news('MSFT');

An iterator containing Finance::Robinhood::News objects is returned.

You do not need to be logged in for this to work.

=cut

sub news ( $s, $symbol_or_id ) {
    Finance::Robinhood::Utility::Iterator->new(
        _rh        => $s,
        _next_page => Mojo::URL->new('https://midlands.robinhood.com/news/')->query(
            {   (
                    $symbol_or_id
                        =~ /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
                    ? 'currency_id' :
                        'symbol'
                ) => $symbol_or_id
            }
        ),
        _class => 'Finance::Robinhood::News'
    );
}

sub _test_news {
    plan( tests => 5 );
    my $rh   = new_ok('Finance::Robinhood');
    my $msft = $rh->news('MSFT');
    isa_ok(
        $msft,
        'Finance::Robinhood::Utility::Iterator',
        '...->news("MSFT") call works for MSFT'
    );
    $msft->has_next ? isa_ok( $msft->next, 'Finance::Robinhood::News' ) :
        pass('Fake it... Might not be any news on the weekend');
TODO: {
        todo_skip( 'crypto news? Hahaha! Yeah, right...', 2 );
        my $btc = $rh->news('3d961844-d360-45fc-989b-f6fca761d511');
        isa_ok(
            $btc,
            'Finance::Robinhood::Utility::Iterator',
            '...->news("3d961844-d360-45fc-989b-f6fca761d511") call works for BTC'
        );
        isa_ok( $btc->next, 'Finance::Robinhood::News' );
    }
    done_testing();
}

=head2 C<feed( )>

    my $feed = $rh->feed();

An iterator containing Finance::Robinhood::News objects is returned. This list
will be filled with news related to instruments in your watchlist and
portfolio.

You need to be logged in for this to work.

=cut

sub feed ($s) {
    Finance::Robinhood::Utility::Iterator->new(
        _rh        => $s,
        _next_page => 'https://midlands.robinhood.com/feed/',
        _class     => 'Finance::Robinhood::News'
    );
}

sub _test_feed {
    plan( tests => 3 );
    my $rh = new_ok('Finance::Robinhood');
SKIP: {
        my ( $user, $pass ) = ( $ENV{RHUSER}, $ENV{RHPASS} );
        skip( 'No auth info in environment', 2 ) unless $user && $pass;
        $rh->login( $user, $pass );
        my $feed = $rh->feed;
        isa_ok( $feed, 'Finance::Robinhood::Utility::Iterator', '...feed() call works' );
        isa_ok( $feed->next, 'Finance::Robinhood::News' );
    }
    done_testing();
}

=head2 C<fundamentals( )>

    my $fundamentals = $rh->fundamentals('MSFT', 'TSLA');

An iterator containing Finance::Robinhood::Equity::Fundamentals objects is
returned.

You do not need to be logged in for this to work.

=cut

sub fundamentals ( $s, @symbols_or_ids_or_urls ) {
    Finance::Robinhood::Utility::Iterator->new(
        _rh        => $s,
        _next_page => Mojo::URL->new('https://api.robinhood.com/fundamentals/')->query(
            {   (
                    grep {
                        /[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}/i
                    } @symbols_or_ids_or_urls
                    ) ?
                    ( grep {/^https?/i} @symbols_or_ids_or_urls ) ?
                    'instruments' :
                        'ids' :
                    'symbols' => join( ',', @symbols_or_ids_or_urls )
            }
            ),
            _class => 'Finance::Robinhood::Equity::Fundamentals'
    );
}

sub _test_fundamentals {
    plan( tests => 4 );
    my $rh = new_ok('Finance::Robinhood');
    isa_ok(
        $rh->fundamentals('MSFT')->next,
        'Finance::Robinhood::Equity::Fundamentals',
        '...->fundamentals("MSFT") works',
    );
    isa_ok(
        $rh->fundamentals('50810c35-d215-4866-9758-0ada4ac79ffa')->next,
        'Finance::Robinhood::Equity::Fundamentals',
        '...->fundamentals("50810c35-d215-4866-9758-0ada4ac79ffa") works',
    );
    isa_ok(
        $rh->fundamentals(
            'https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/')->next,
        'Finance::Robinhood::Equity::Fundamentals',
        '...->fundamentals("https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/") works',
    );
    done_testing();
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
