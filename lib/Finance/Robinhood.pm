package Finance::Robinhood;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood - Trade Stocks, ETFs, Options, and Cryptocurrency without
Commission

=head1 SYNOPSIS

    use Finance::Robinhood;

    my $rh = Finance::Robinhood->new(
      username => $user,
      password => $password
    );

=cut

use strict;
use warnings;
use Moo;
our $VERSION = '0.90_001';
#
use Finance::Robinhood::Account;
use Finance::Robinhood::ACH;
use Finance::Robinhood::Dividend;
use Finance::Robinhood::Equity::Fundamentals;
use Finance::Robinhood::Equity::Instrument::Historicals;
use Finance::Robinhood::Equity::Instrument;
use Finance::Robinhood::Equity::Quote;
use Finance::Robinhood::Equity::Position;
use Finance::Robinhood::Equity::Order;
use Finance::Robinhood::Equity::Order::Execution;
use Finance::Robinhood::Forex::AssetCurrency;
use Finance::Robinhood::Forex::CurrencyPair;
use Finance::Robinhood::Forex::QuoteCurrency;
use Finance::Robinhood::Options::Chain::Ticks;
use Finance::Robinhood::Options::Chain::UnderlyingInstrument;
use Finance::Robinhood::Options::Chain;
use Finance::Robinhood::Options::Event;
use Finance::Robinhood::Options::Instrument;
use Finance::Robinhood::Options::Order;
use Finance::Robinhood::Options::Position;
use Finance::Robinhood::Options::Quote;
use Finance::Robinhood::Tag;
use Finance::Robinhood::User::AdditionalInfo;
use Finance::Robinhood::User::BasicInfo;
use Finance::Robinhood::User::Employment;
use Finance::Robinhood::User::Id;
use Finance::Robinhood::User::InvestmentProfile;
use Finance::Robinhood::User;
use Finance::Robinhood::Utils 'v4_uuid' => { -as => 'uuid' };
use Finance::Robinhood::Utils::Client;
use Finance::Robinhood::Utils::Credentials;
use Finance::Robinhood::Utils::Paginated;
use Finance::Robinhood::Watchlist;
use Finance::Robinhood::Watchlist::Item;
#
my %_api = (
    'fundamentals'                               => 'fundamentals/',
    'fundamentals/{symbol}'                      => 'fundamentals/%s/',
    'watchlists'                                 => 'watchlists/',
    'watchlists/{name}'                          => 'watchlists/%s/',
    'orders'                                     => 'orders/',
    'orders/{id}'                                => 'orders/%s/',
    'positions'                                  => 'positions/',
    'positions/{accountID}/{id}'                 => 'positions/%s/%s/',
    'user'                                       => 'user/',
    'user/investment_profile'                    => 'user/investment_profile/',
    'user/additional_info'                       => 'user/additional_info/',
    'user/employment'                            => 'user/employment/',
    'dividends'                                  => 'dividends/',
    'dividends/{id}'                             => 'dividends/%s/',
    'api-token-auth'                             => 'api-token-auth/',
    'api-token-logout'                           => 'api-token-logout/',
    'oauth2/token'                               => 'oauth2/token/',
    'accounts'                                   => 'accounts/',
    'ach/deposit_schedules'                      => 'ach/deposit_schedules/',
    'ach/relationships'                          => 'ach/relationships/',
    'instruments'                                => 'instruments/',
    'instruments/{id}'                           => 'instruments/%s/',
    'password_reset/request'                     => 'password_reset/request/',
    'password_reset'                             => 'password_reset/',
    'marketdata/quotes'                          => 'marketdata/quotes/',
    'marketdata/quotes/{symbol}'                 => 'marketdata/quotes/%s/',
    'oauth2/migrate_token'                       => 'oauth2/migrate_token/',
    'oauth2/authorize'                           => 'oauth2/authorize/',
    'options/chains'                             => 'options/chains/',
    'options/instruments'                        => 'options/instruments/',
    'options/orders'                             => 'options/orders/',
    'options/orders/{id}'                        => 'options/orders/%s/',
    'options/orders/day_trade_checks'            => 'options/orders/day_trade_checks/',
    'marketdata/options'                         => 'marketdata/options/',
    'marketdata/options/{id}'                    => 'marketdata/options/%s/',
    'options/orders/{id}/cancel'                 => 'api/options/orders/%s/cancel/',
    'marketdata/options/historicals/{id}'        => 'marketdata/options/historicals/%s/',
    'marketdata/options/historicals'             => 'marketdata/options/historicals/',
    'options/suitability'                        => 'options/suitability/',
    'options/events'                             => 'options/events/',
    'options/positions'                          => 'options/positions/',
    'options/positions/{id}'                     => 'options/positions/%s/',
    'accounts/{accountNumber}/recent_day_trades' => 'accounts/%s/recent_day_trades/',
    'marketdata/historicals'                     => 'marketdata/historicals/',
    'marketdata/historicals/{symbol}'            => 'marketdata/historicals/%s/',
    'portfolios/historicals/{accountNumber}'     => 'portfolios/historicals/%s/'
);
my %_midlands = ( 'midlands/search' => '/search/', );
our %Endpoints = (
    ( map { $_ => 'https://api.robinhood.com/' . $_api{$_} } keys %_api ),
    map { $_ => 'https://midlands.robinhood.com/' . $_midlands{$_} } keys %_midlands,
);

sub BUILD {
    my ( $s, $args ) = @_;
    if ( $args->{username} && $args->{password} ) {
        if ( $args->{client_id} ) {    #OAuth2
            $s->login_oauth2(

                #my ($s, $username, $password, $mfa_cb, $client_id, $scope) = @_;
                $args->{username}, $args->{password}, $args->{mfa_callback}, $args->{client_id},
                $args->{scope}
            );
        }
        else {                         # Old skool
            $s->login( $args->{username}, $args->{password}, $args->{mfa_callback} );
        }
    }
}

=head1 METHODS

Finance::Robinhood wraps a several APIs. There are parts of this package that
are object oriented (because they require login information) and others which
may also be used functionally (because they do not require login information).
I've attempted to organize everything according to how and when they are
used... Let's start at the very beginning: let's log in!

=head1 Logging In

Robinhood requires an authorization token for most API calls. To get this
token, you must either pass it as an argument to C<new( ... )> or log in with
your username and password.

=head2 C<new( )>

    # Login on object creation :)
    my $rh = Finance::Robinhood->new(
      username => 'mark98009',
      password => 'Om39mfsdah93m'
    );

    # Requires ->login(...) call :(
    my $rh = Finance::Robinhood->new( );
    $rh->login('mark98009', 'Om39mfsdah93m');

A new Finance::Robinhood object is created without credentials. Before you can
buy or sell or do almost anything else, you must L<log in manually|/"login( ...
)">.

=cut

#
has 'credentials' => (
    is      => 'rw',
    builder => sub { Finance::Robinhood::Utils::Credentials->instance },
    handles => [qw[token]],
    lazy    => 1
);
has 'client' => (
    is      => 'ro',
    builder => sub { Finance::Robinhood::Utils::Client->instance },
    handles => [qw[get post options account]],
    lazy    => 1
);

=head2 C<login( ... )>

    my $token = $rh->login($user, $password);
    # Save the token somewhere

Logging in allows you to buy and sell securities with your Robinhood account.

    my $token = $rh->login($user, $password, \&mfa_callback);

    sub mfa_callback {
        my ($auth) = @_;
        print "Enter MFA code: ";
        my $code = <>; chomp $code;
        return $code
    }

If your account has MFA enabled, you must also provide a callback which should
return the code sent to you via SMS or in your token app.

=cut

#
sub login {
    my ( $s, $username, $password, $mfa_cb ) = @_;
    my ( $status, $auth )
        = $s->post( $Endpoints{'api-token-auth'},
        { username => $username, password => $password } );
    if ( $auth->{mfa_required} ) {
        return !warn 'Login requires a MFA callback.' if !$mfa_cb;
        ( $status, $auth ) = $s->post(
            $Endpoints{'api-token-auth'},
            { username => $username, password => $password, mfa_code => $mfa_cb->($auth) }

            #backup_code =>
        );
    }
    $status == 200 ? !!$s->credentials->old_skool( $auth->{token} ) : 0;
}

sub login_oauth2 {
    my ( $s, $username, $password, $mfa_cb, $client_id, $scope ) = @_;
    $scope //= 'internal';
    my ( $status, $auth ) = $s->post(
        $Endpoints{'oauth2/token'},
        {   username   => $username,
            password   => $password,
            grant_type => 'password',
            scope      => $scope,
            client_id  => $client_id,
        }
    );
    if ( $auth->{mfa_required} ) {
        return !warn 'Login requires a MFA callback.' if !$mfa_cb;
        ( $status, $auth ) = $s->post(
            $Endpoints{'oauth2/token'},
            {   username   => $username,
                password   => $password,
                grant_type => 'password',
                scope      => $scope,
                client_id  => $client_id,
                mfa_code   => $mfa_cb->($auth),

                #backup_code =>
            }
        );
    }
    $status == 200 ?
        !!$s->credentials->oauth( { %$auth, client_id => $client_id, _birth => time } ) :
        0;
}

=head2 C<logout( )>

    my $token = $rh->login($user, $password);
    # ...do some stuff... buy... sell... idk... stuff... and then...
    $rh->logout( ); # Goodbye!

This method logs you out of Robinhood by forcing the old skool token to expire.

I<Note>: This will log you out I<everywhere> that uses the old skool token
because Robinhood generated a single authorization token per account at a time!
All logged in clients will be logged out. This is good in rare case your device
or the token itself is stolen.

=cut

sub logout {
    my ($s) = @_;
    my ( $status, $auth ) = $s->post( $Endpoints{'api-token-logout'} );
    $status == 200 ? !!$s->credentials->clear_old_skool() : 0;
}

=head2 C<recover_password( ... )>

    my $token = $rh->recover_password('rh@example.com', sub {...});

Start the password recovery process. If everything goes as planned, this
returns a true value.

The token callback should expect a string to display in your application and
return a list with the following data:

=over

=item * C<username> - Username attached to the email address

=item * C<password> - New password

=item * C<token> - Reset token provided by Robinhood in the reset link

=back

=cut

#
sub recover_password {
    my ( $s, $email, $reset_cb ) = @_;
    my ( $status, $resp ) = $s->post( $Endpoints{'password_reset/request'}, { email => $email } );
    if ( $resp->{link} ) {
        return !warn 'Password reset requires a token callback.' if !$reset_cb;
        my ( $user, $pass, $token ) = $reset_cb->( $resp->{detail} );
        ( $status, $resp ) = $s->post( $Endpoints{'password_reset'},
            { username => $user, password => $pass, token => $token } );
    }
    $status == 200;
}

=head2 C<migrate_token( ... )>

    my $ok = $rh->migrate_token();

Convert your old skool token to an OAuth2 token.

=cut

sub migrate_token {
    my ($s) = @_;
    Finance::Robinhood::Utils::Credentials->instance->migrate();
}

=head2 C<user( )>

    my $ok = $rh->user( );

Gather very basic info about your account. This is returned as a
C<Finance::Robinhood::User> object.

=cut

sub user {
    my ($s) = @_;
    my ( $status, $data ) = $s->get( $Endpoints{'user'} );
    $status == 200 ? Finance::Robinhood::User->new($data) : $data;
}

=head2 C<watchlists( [...] )>

    my @watchlists = $rh->watchlists->all;

Gather the list of watchlists connected to this account. This is returned
as a C<Finance::Robinhood::Utils::Paginated> object.

	my $watchlist = $rh->watchlists(name => 'Default');

Grab a specific watchlist by name. This is returned as a
C<Finance::Robinhood::Watchlist> object.

Use this like so:

    my @instruments = $rh->watchlists(name => 'Default')->instruments->all;

... to gather the list of instruments in a watchlist. This is returned
as a C<Finance::Robinhood::Utils::Paginated> object.

=cut

sub watchlists {
    my ( $s, %args ) = @_;
    if ( $args{name} ) {
        return Finance::Robinhood::Watchlist->new(

            #$data
            %args
        );
    }
    Finance::Robinhood::Utils::Paginated->new(
        class => 'Finance::Robinhood::Watchlist',
        next  => $Endpoints{'watchlists'}
    );
}

=head2 C<equity_quote( ... )>

    my $msft_quote = $rh->quote('MSFT');

Gather quote data as a L<Finance::Robinhood::Equity::Quote> object.

    my $msft_quote = $rh->quote('MSFT', bounds => 'extended');

An argument called C<bounds> is also supported when you want a certain range of
quote data. This value must be C<extended>, C<regular>, or C<trading> which is
the default.

=cut

sub equity_quote {
    my ( $s, $symbol, %args ) = @_;
    my ( $status, $data )
        = $s->get( sprintf( $Endpoints{'marketdata/quotes/{symbol}'}, $symbol ), \%args );
    $status == 200 ? Finance::Robinhood::Equity::Quote->new($data) : $data;
}

=head2 C<equity_quotes( ... )>

    my $inst = $rh->equity_quotes( symbols => ['MSFT', 'X'] );
    my $all = $inst->all;

Gather info about multiple equities by symbol. This is returned as a
C<Finance::Robinhood::Utils::Paginated> object.

    my $inst = $rh->equity_quotes( instruments =>  ['50810c35-d215-4866-9758-0ada4ac79ffa', 'b060f19f-0d24-4bf2-bf8c-d57ba33993e5'] );
    my $all = $inst->all;

Gather info about a several instruments by their ids; data is returned as a
C<Finance::Robinhood::Utils::Paginated> object.

Request either by symbol or by instrument id! Other arguments are also
supported:

=over

=item C<bounds> - which must be C<extended>, C<regular>, or C<trading> which is the default

=back

=cut

sub equity_quotes {
    my ( $s, %args ) = @_;
    my ( @instruments, @groups );
    if ( $args{instruments} ) {
        @instruments = @{ delete $args{instruments} };
        @instruments = map {
            $_ =~ $Finance::Robinhood::Endpoints{'instruments'} ? $_ :
                sprintf $Finance::Robinhood::Endpoints{'instruments/{id}'}, $_
        } map { $_ = ref $_ ? $_->url : $_ } @instruments;
        push @groups, [ splice @instruments, 0, 75 ] while @instruments;
    }
    Finance::Robinhood::Utils::Paginated->new(
        class => 'Finance::Robinhood::Equity::Quote',
        next  => [
            @groups ?
                map {
                Finance::Robinhood::Utils::Client::__url_and_args(
                    $Finance::Robinhood::Endpoints{'marketdata/quotes'},
                    { %args, ( $_ ? ( instruments => $_ ) : () ) }
                    )
                } @groups :
                Finance::Robinhood::Utils::Client::__url_and_args(
                $Finance::Robinhood::Endpoints{'marketdata/quotes'}, {%args}
                )
        ]
    );
}

=head2 C<fundamentals( ... )>

    my $inst = $rh->fundamentals( symbols => ['MSFT', 'X'] );
    my $all = $inst->all;

Gather info about multiple equities by symbol, by instrument object, by
instrument id, or by instrument url. This is returned as a
C<Finance::Robinhood::Utils::Paginated> object.

    my $inst = $rh->fundamentals( ids =>  ['50810c35-d215-4866-9758-0ada4ac79ffa', 'b060f19f-0d24-4bf2-bf8c-d57ba33993e5'] );
    my $all = $inst->all;

Gather info about a several instruments by their ids; data is returned as a
C<Finance::Robinhood::Utils::Paginated> object.

=cut

sub fundamentals {
    my ( $s, %args ) = @_;
    my ( @instruments, @groups );
    if ( $args{instruments} ) {
        @instruments = @{ delete $args{instruments} };
        @instruments = @instruments = map {
            $_ =~ $Finance::Robinhood::Endpoints{'instruments'} ? $_ :
                sprintf $Finance::Robinhood::Endpoints{'instruments/{id}'}, $_
        } map { $_ = ref $_ ? $_->url : $_ } @instruments;
        push @groups, [ splice @instruments, 0, 75 ] while @instruments;
    }
    Finance::Robinhood::Utils::Paginated->new(
        class => 'Finance::Robinhood::Equity::Fundamentals',
        next  => [
            @groups ?
                map {
                Finance::Robinhood::Utils::Client::__url_and_args(
                    $Finance::Robinhood::Endpoints{'fundamentals'},
                    { %args, ( $_ ? ( instruments => $_ ) : () ) }
                    )
                } @groups :
                Finance::Robinhood::Utils::Client::__url_and_args(
                $Finance::Robinhood::Endpoints{'fundamentals'}, {%args}
                )
        ]
    );
}

=head2 C<equity_historicals( ... )>

    my $inst = $rh->equity_historicals( symbols => ['MSFT', 'X'], interval => 'week' );
    my $all = $inst->all;

Gather historical info about multiple equities by symbol. This is returned as a
C<Finance::Robinhood::Utils::Paginated> object.

Expected arguments:

=over

=item C<symbols> - required list of ticker symbols to look for

=item C<interval> - required argument which must be C<5minute>, C<10minute>, C<hour>, C<day>, C<week>, or C<month>

=item C<span> - which must be C<week>, C<year>, C<5year>, or C<10year> and is optional

=item C<bounds> - which must be C<extended>, C<regular>, or C<trading> which is the default

=back

=cut

sub equity_historicals {
    my ( $s, %args ) = @_;
    my @symbols = @{ delete $args{symbols} };
    @symbols = map { $_ = ref $_ ? $_->symbol : $_ } @symbols;
    my @groups;
    push @groups, [ splice @symbols, 0, 75 ] while @symbols;
    Finance::Robinhood::Utils::Paginated->new(
        class => 'Finance::Robinhood::Equity::Instrument::Historicals',
        next  => [
            map {
                Finance::Robinhood::Utils::Client::__url_and_args(
                    $Finance::Robinhood::Endpoints{'marketdata/historicals'},
                    { %args, ( $_ ? ( symbols => $_ ) : () ) } )
            } @groups
        ]
    );
}

=head2 C<equity_positions( )>


=cut

sub equity_positions {
    my ( $s, %args ) = @_;

#@GET("/positions/?nonzero=true")    Completable reorderPositions(@Query("ordering") String str);
#@GET("/positions/?nonzero=true")    Single<PaginatedResult<ApiPosition>> getPositions(@Query("cursor") String str);
    Finance::Robinhood::Utils::Paginated->new(
        class => 'Finance::Robinhood::Equity::Position',
        next => Finance::Robinhood::Utils::Client::__url_and_args( $Endpoints{'positions'}, \%args )
    );
}

=head2 C<equity_position( )>


=cut

sub equity_position {
    my ( $s,      $id )   = @_;
    my ( $status, $data ) = $s->get( sprintf $Endpoints{'positions/{accountID}/{id}'},
        $s->account->account_number, $id );
    $status == 200 ? Finance::Robinhood::Equity::Position->new($data) : $data;
}

=head2 C<equity_orders( )>


=cut

sub equity_orders {
    my ( $s, %args ) = @_;
    $args{'updated_at[gte]'} = delete $args{'since'}  if defined $args{'since'};
    $args{'updated_at[lte]'} = delete $args{'before'} if defined $args{'before'};
    $args{'instrument'}
        = ref $args{'instrument'}                        ? $args{'instrument'}->url :
        $args{'instrument'} =~ $Endpoints{'instruments'} ? $args{'instrument'} :
        sprintf $Endpoints{'instruments/{id}'}, $args{'instrument'}
        if $args{'instrument'};
    Finance::Robinhood::Utils::Paginated->new(
        class => 'Finance::Robinhood::Equity::Order',
        next  => Finance::Robinhood::Utils::Client::__url_and_args( $Endpoints{'orders'}, \%args )
    );
}

=head2 C<equity_order( )>


=cut

sub equity_order {
    my ( $s, $id ) = @_;
    warn $id;
    my ( $status, $data ) = $s->get( sprintf $Endpoints{'orders/{id}'}, $id );
    $status == 200 ? Finance::Robinhood::Equity::Order->new($data) : $data;
}

=head2 C<equity_instruments( ... )>

    my $ok = $rh->equity_instruments();
    my $all = $ok->all;

Gather info about listed stocks and etfs. This is returned as a
C<Finance::Robinhood::Utils::Paginated> object.

    my $inst = $rh->equity_instruments( symbol => 'MSFT' );
    my $all = $inst->all;

Gather info about a single instrument returned as a
C<Finance::Robinhood::Utils::Paginated> object.

    my $minstsft = $rh->equity_instruments( query => 'oil' );
    my $all = $inst->all;

Gather info about a single instrument returned as a
C<Finance::Robinhood::Utils::Paginated> object.

    my $inst = $rh->equity_instruments( ids =>  ['50810c35-d215-4866-9758-0ada4ac79ffa', 'b060f19f-0d24-4bf2-bf8c-d57ba33993e5'] );
    my $all = $inst->all;

Gather info about a several instruments by their ids; data is returned as a
C<Finance::Robinhood::Utils::Paginated> object.

Other arguments such as the boolean values for C<nocache> and
C<active_instruments_only> are also supported.

=cut

sub equity_instruments {
    my ( $s, %args ) = @_;
    Finance::Robinhood::Utils::Paginated->new(
        class => 'Finance::Robinhood::Equity::Instrument',
        next =>
            Finance::Robinhood::Utils::Client::__url_and_args( $Endpoints{'instruments'}, \%args )
    );
}

=head2 C<equity_instrument( ... )>

    my $labu = $rh->equity_instrument('6a17083e-2867-4a20-9b78-a0a46b422279');

Gather data as a L<Finance::Robinhood::Instrument> object.

=cut

sub equity_instrument {
    my ( $s, $id ) = @_;
    warn $id;
    my ( $status, $data ) = $s->get( sprintf $Endpoints{'instruments/{id}'}, $id );
    $status == 200 ? Finance::Robinhood::Equity::Instrument->new($data) : $data;
}

=head2 C<options_chains( ... )>

    my $ok = $rh->options_chains();

Gather info about all supported options chains. This is returned as a
C<Finance::Robinhood::Utils::Paginated> object.

    my $inst = $rh->options_chains( ids =>  ['0c0959c2-eb3a-4e3b-8310-04d7eda4b35c'] );
    my $all = $inst->all;

Gather info about several options chains at once by id. This is returned as a
C<Finance::Robinhood::Utils::Paginated> object.

    my $inst = $rh->options_chains( equity_instrument_ids => ['6a17083e-2867-4a20-9b78-a0a46b422279'] );
    my $all = $inst->all;

Gather options chains related to a security by the security's  id. This is
returned as a C<Finance::Robinhood::Utils::Paginated> object.

=cut

sub options_chains {
    my ( $s, %args ) = @_;
    Finance::Robinhood::Utils::Paginated->new(
        class => 'Finance::Robinhood::Options::Chain',
        next  => Finance::Robinhood::Utils::Client::__url_and_args(
            $Endpoints{'options/chains'}, \%args
        )
    );
}

=head2 C<options_instruments( ... )>

    my $ok = $rh->options_instruments();

Gather info about all supported options instruments. This is returned as a
C<Finance::Robinhood::Utils::Paginated> object.

    my $inst = $rh->options_instruments( ids =>  ['73f75306-ad07-4734-972b-22ab9dec6693'] );
    my $all = $inst->all;

Gather info about several options chains at once by instrument id. This is
returned as a C<Finance::Robinhood::Utils::Paginated> object.

    my $inst = $rh->options_instruments( tradability => 'tradable' );
    my $all = $inst->all;

Gather info about several options chains at once but only those that are
currently 'tradable' or 'untradable'. This is returned as a
C<Finance::Robinhood::Utils::Paginated> object.

    my $inst = $rh->options_instruments( state => 'active' );
    my $all = $inst->all;

Gather info about several options chains at once but only those that are
currently 'active', 'inactive', or 'expired'. This is returned as a
C<Finance::Robinhood::Utils::Paginated> object.

Supported arguments include:

=over

=item C<tradability> - 'tradable' or 'untradable'

=item C<state> - 'active', 'inactive', or 'expired'

=item C<type> - 'call' or 'put'

=item C<expiration_dates> - an array ref of dates in the form 'YYYY-MM-DD'

=item C<chain_id> - options chain's UUID

=back

=cut

sub options_instruments {
    my ( $s, %args ) = @_;
    Finance::Robinhood::Utils::Paginated->new(
        class => 'Finance::Robinhood::Options::Instrument',
        next  => Finance::Robinhood::Utils::Client::__url_and_args(
            $Endpoints{'options/instruments'}, \%args
        )
    );
}

=head2 C<options_quote( ... )>

    my $msft_quote = $rh->options_quote('...');

Gather quote data as a L<Finance::Robinhood::Options::Quote> object.

    my $msft_quote = $rh->options_quote('...', bounds => 'extended');

An argument called C<bounds> is also supported when you want a certain range of
quote data. This value must be C<extended>, C<regular>, or C<trading> which is
the default.

=cut

sub options_quote {
    my ( $s, $id, %args ) = @_;
    my ( $status, $data )
        = $s->get( sprintf( $Endpoints{'marketdata/options/{id}'}, $id ), \%args );
    $status == 200 ? Finance::Robinhood::Options::Quote->new($data) : $data;
}

=head2 C<options_quotes( ... )>

    my $inst = $rh->options_quotes( symbols => ['MSFT', 'X'] );
    my $all = $inst->all;

Gather info about multiple equities by symbol. This is returned as a
C<Finance::Robinhood::Utils::Paginated> object.

    my $inst = $rh->options_quotes( instruments =>  ['50810c35-d215-4866-9758-0ada4ac79ffa', 'b060f19f-0d24-4bf2-bf8c-d57ba33993e5'] );
    my $all = $inst->all;

Gather info about a several instruments by their ids; data is returned as a
C<Finance::Robinhood::Utils::Paginated> object.

Request either by symbol or by instrument id! Other arguments are also
supported:

=over

=item C<instruments> - array ref of options instrument objects or urls

=back

=cut

sub options_quotes {
    my ( $s, %args ) = @_;
    my @instruments = map {
        ref $_                                      ? $_->url :
            $_ =~ $Endpoints{'options/instruments'} ? $_ :
            sprintf $Endpoints{'options/instruments/{id}'}, $_
    } @{ $args{'instruments'} };
    delete $args{'instruments'};
    my @groups;
    push @groups, [ splice @instruments, 0, 25 ] while @instruments;
    Finance::Robinhood::Utils::Paginated->new(
        class => 'Finance::Robinhood::Options::Quote',
        next  => [
            map {
                Finance::Robinhood::Utils::Client::__url_and_args( $Endpoints{'marketdata/options'},
                    { %args, ( $_ ? ( instruments => $_ ) : () ) } )
            } @groups
        ]
    );
}

=head2 C<optioins_historical( ... )>

    my $inst = $rh->equity_quotes( instruments => [''], interval => 'week' );
    my $all = $inst->all;

Gather historical info about multiple options chains by ID. This is returned as a
C<Finance::Robinhood::Utils::Paginated> object.

Expected arguments:

=over

=item C<instruments> - required list of UUIDs to look for

=item C<interval> - required argument which must be C<hour>, C<day>, C<week>, or C<month>

=item C<span> - which must be C<week>, C<year>, C<5year>, or C<10year> and is optional

=item C<bounds> - which must be C<extended>, C<regular>, or C<trading> which is the default

=back

=cut

sub options_historicals {
    my ( $s, %args ) = @_;
    map { $_ = ref $_ ? $_->id : $_ } @{ $args{'instruments'} } if $args{'instruments'};
    Finance::Robinhood::Utils::Paginated->new(
        class => 'Finance::Robinhood::Options::Instrument::Historicals',
        next  => Finance::Robinhood::Utils::Client::__url_and_args(
            $Endpoints{'marketdata/options/historicals'}, \%args
        )
    );
}

=head2 C<options_suitability( ... )>

    my $account = $rh->options_suitability();

Find out if your account is eligible to move to any of the supported options
levels.

The returned data is a hash containing the max level and any changes to your
profile that needs to be updated.

=cut

sub options_suitability {
    my ( $s, %args ) = @_;
    $s->get( $Endpoints{'options/suitability'} );
}

=head2 C<place_options_order( ... )>


=cut

sub place_options_order {
    my ( $s, %args ) = @_;
    $args{'account'}
        = ( $args{'account'} // Finance::Robinhood::Utils::Client->instance->account )->url;
    $_->{'option'} = $_->{'option'}->url for @{ $args{'legs'} };
    $args{'override_day_trade_checks'} //= \0;
    $args{'override_dtbp_checks'}      //= \0;
    $args{'ref_id'}                    //= uuid();    # Random

    #my $post = {
    #    account => Finance::Robinhood::Utils::Client->instance->account->url,
    #    direction => 'debit', # credit or 'debit'
    #    legs => [
    #        {
    #        option => $s->url,
    #        position_effect => 'open', #  open or close
    #        ratio_quantity=> 1,
    #        side=> 'buy' # buy or sell
    #        }
    #    ],
    #    override_day_trade_checks => \0,
    #    override_dtbp_checks => \0,
    #    price => .05,
    #    quantity=> 1,
    #    ref_id => uuid(), # Random
    #    time_in_force => 'gfd',
    #    type => 'limit',
    #    #
    #    trigger => 'immediate'
    #};
    #ddx \%args;
    my ( $status, $data ) = $s->post( $Endpoints{'options/orders'}, \%args );
    $status == 201 ? Finance::Robinhood::Options::Order->new($data) : $data;
}

=head2 C<options_order( ... )>

    my $order = $rh->options_order('0adf9278-095d-ef93-eac37a8199fe');
    $order->cancel;

Gather a single order by id. This is returned as a new
C<Finance::Robinhood::Options::Order> object.

=cut

sub options_order {
    my ( $s, $id ) = @_;
    my ( $status, $data ) = $s->get( sprintf $Endpoints{'options/orders/{id}'}, $id );
    $status == 200 ? Finance::Robinhood::Options::Order->new($data) : $data;
}

=head2 C<options_orders( ... )>

    my $ok = $rh->options_orders();

Gather info about all options orders. This is returned as a
C<Finance::Robinhood::Utils::Paginated> object.

    my $inst = $rh->options_orders( before =>  '2018-10-01' );
    my $all = $inst->all;

    #

    my $orders = grep {$_->state eq ''} $rh->optoins_orders(since => '2018-04-15T14:47:07' )->all;

    # or

    use Time::Moment;
    my @recent = $rh->options_orders(
        since => Time::Moment->now->minus_weeks(1)->to_string()
    )->all;

Gather info about options orders before or after a certain date. This is returned as a
C<Finance::Robinhood::Utils::Paginated> object.

Expected arguments include:

=over

=item C<before> - MDY (optional)

=item C<since> - MDY (optional)

=back

=cut

sub options_orders {
    my ( $s, %args ) = @_;
    $args{'updated_at[gte]'} = delete $args{'since'}  if defined $args{'since'};
    $args{'updated_at[lte]'} = delete $args{'before'} if defined $args{'before'};
    Finance::Robinhood::Utils::Paginated->new(
        class => 'Finance::Robinhood::Options::Order',
        next  => Finance::Robinhood::Utils::Client::__url_and_args(
            $Endpoints{'options/orders'}, \%args
        )
    );
}

=head2 C<options_positions( ... )>

    my $ok = $rh->options_positions();

Gather info about all options orders. This is returned as a
C<Finance::Robinhood::Utils::Paginated> object.

Possible parameters are:

=over

=item C<chain_ids> - list of ids

=item C<type> - 'long' or 'short'

=back

=cut

sub options_positions {
    my ( $s, %args ) = @_;
    Finance::Robinhood::Utils::Paginated->new(
        class => 'Finance::Robinhood::Options::Position',
        next  => Finance::Robinhood::Utils::Client::__url_and_args(
            $Endpoints{'options/positions'}, \%args
        )
    );
}

=head2 C<options_position( ... )>

    my $labu = $rh->options_position('6a17083e-2867-4a20-9b78-a0a46b422279');

Gather data as a L<Finance::Robinhood::Options::Position> object.

=cut

sub options_position {
    my ( $s, $id ) = @_;
    warn $id;
    my ( $status, $data ) = $s->get( sprintf $Endpoints{'options/positions/{id}'}, $id );
    $status == 200 ? Finance::Robinhood::Options::Position->new($data) : $data;
}

=head2 C<options_events( ... )>

    my $ok = $rh->options_events();

Gather info about recent options events. This is returned as a
C<Finance::Robinhood::Utils::Paginated> object.

=cut

sub options_events {
    my ($s) = @_;
    Finance::Robinhood::Utils::Paginated->new(
        class => 'Finance::Robinhood::Options::Event',
        next  => $Endpoints{'options/events'}
    );
}

=head2 C<account( ... )>

    my $account = $rh->accounts();

Gather info about all brokerage accounts.

Please note that this will be a cached value. If you need updated information,
use C<accounts( )>.

=head2 C<accounts( ... )>

    my $account = $rh->accounts()->next;

Gather info about all brokerage accounts. This is returned as a
C<Finance::Robinhood::Utils::Paginated> object.

This is rather useless seeing as we're only allowed a single account per
signup.

=cut

sub accounts {
    my ( $s, %args ) = @_;
    Finance::Robinhood::Utils::Paginated->new(
        class => 'Finance::Robinhood::Account',
        next  => $Endpoints{'accounts'}
    );
}

=head2 C<ach_relationships( ... )>

    my $ok = $rh->ach_relationships();

Gather info about all attached bank accounts. This is returned as a
C<Finance::Robinhood::Utils::Paginated> object.

=cut

sub ach_relationships {
    my ( $s, %args ) = @_;
    Finance::Robinhood::Utils::Paginated->new(
        class => 'Finance::Robinhood::ACH',
        next  => $Endpoints{'ach/relationships'}
    );
}

=head2 C<create_ach_relationship( ... )>

    my $ok = $rh->create_ach_relationship(
        bank_routing_number => '026009593',
        bank_account_number => '009872784317963',
        bank_account_type => 'checking',
        bank_account_holder_name => 'John Smith
    );

Attach a bank accounts to your Robinhood account. This is returned as a
C<Finance::Robinhood::ACH> object if everything goes well.

All arguments are required. C<bank_account_type> is either C<'checking'> or
C<'savings'>.

=cut

sub create_ach_relationship {
    my ( $s, %args ) = @_;
    $args{account} = $s->accounts->next->url;
    my ( $status, $data ) = $s->post( sprintf $Endpoints{'ach/relationships'}, \%args );
    $status == 201 ? Finance::Robinhood::ACH->new($data) : $data;
}

=head2 C<ach_deposit_schedules( ... )>

    my $ok = $rh->ach_deposit_schedules();
    my $all = $ok->all;

Gather info about scheduled ACH deposits. This is returned as a
C<Finance::Robinhood::Utils::Paginated> object.

=cut

sub ach_deposit_schedules {
    my ( $s, %args ) = @_;
    Finance::Robinhood::Utils::Paginated->new(
        class => 'Finance::Robinhood::ACH::ScheduledDeposit',
        next  => $Endpoints{'ach/deposit_schedules'}
    );
}

=head2 C<dividends( )>

    my $ok = $rh->dividends( );

Gather info about expected dividends for positions you hold. This is returned
as a C<Finance::Robinhood::Utils::Paginated> object.

=cut

sub dividends {
    my ($s) = @_;
    Finance::Robinhood::Utils::Paginated->new(
        class => 'Finance::Robinhood::Dividend',
        next  => $Endpoints{'dividends'}
    );
}

=head2 C<dividend( )>

    my $ok = $rh->dividend( '3adf982a-cd20-98af-eaea-cea294475923' );

Gather info about a dividend payment by ID. This is returned as a
C<Finance::Robinhood::Dividend> object.

=cut

sub dividend {
    my ( $s, $id ) = @_;
    my ( $status, $data ) = $s->get( sprintf $Endpoints{'dividends/{id}'}, $id );
    $status == 200 ? Finance::Robinhood::Dividend->new($data) : $data;
}

=head2 C<search( ... )>

    my $results = $rh->search( 'finance' );

Searches for currency pairs, tags, and equity instruments. A list of each is
returned as values of a hash.

=cut

sub search {
    my ( $s, $query ) = @_;
    my ( $status, $data ) = $s->get( $Endpoints{'midlands/search'}, { query => $query } );
    if ( $status == 200 ) {
        $data->{'currency_pairs'} = [ map { Finance::Robinhood::Forex::CurrencyPair->new($_) }
                @{ $data->{'currency_pairs'} } ];
        $data->{'tags'}        = [ map { Finance::Robinhood::Tag->new($_) } @{ $data->{'tags'} } ];
        $data->{'instruments'} = [ map { Finance::Robinhood::Equity::Instrument->new($_) }
                @{ $data->{'instruments'} } ];
    }
    $data;
}

=head1 LEGAL

This is a simple wrapper around the API used in the official apps. The author
provides no investment, legal, or tax advice and is not responsible for any
damages incurred while using this software. Neither this software nor its
author are affiliated with Robinhood Financial LLC in any way.

For Robinhood's terms and disclosures, please see their website at
http://robinhood.com/

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
