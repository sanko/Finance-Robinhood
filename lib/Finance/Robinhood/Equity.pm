package Finance::Robinhood::Equity;    #  Instrument
our $VERSION = '0.92_003';

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Equity - Represents a Single Equity Instrument

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;
    my $instruments = $rh->equities();

    for my $instrument ($instruments->all) {
        CORE::say $instrument->symbol;
    }

=cut

#
use Moo;
use MooX::Enumeration;
use Types::Standard qw[ArrayRef Bool Dict Enum InstanceOf Maybe Num Str StrMatch];
use URI;
use Time::Moment;
use Data::Dump;
use experimental 'signatures';
use Finance::Robinhood::Types qw[UUID Timestamp URL];
#
use Finance::Robinhood::Equity::Prices;
use Finance::Robinhood::Equity::Quote;
#
sub _test__init {
    my $rh   = t::Utility::rh_instance(0);
    my $msft = $rh->equity('MSFT');
    isa_ok( $msft, __PACKAGE__ );
    t::Utility::stash( 'MSFT', $msft );    #  Store it for later
    t::Utility::rh_instance(1) // skip_all();
    $rh   = t::Utility::rh_instance(1);
    $msft = $rh->equity('MSFT');
    isa_ok( $msft, __PACKAGE__ );
    t::Utility::stash( 'MSFT_AUTH', $msft );
}
use overload '""' => sub ( $s, @ ) { $s->url }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('MSFT') // skip_all();
    is(
        +t::Utility::stash('MSFT'),
        'https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/',
    );
}
#
has robinhood =>
    ( is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood'], handles => ['_req'] );

=head1 METHODS

=head2 C<bloomberg_unique( )>

https://en.wikipedia.org/wiki/Financial_Instrument_Global_Identifier

=head2 C<country( )>

Country code of location of headquarters.

=head2 C<day_trade_ratio( )>



=head2 C<id( )>

Instrument id used by RH to refer to this particular instrument.

=head2 C<list_date( )>

Returns a the date the instrument began trading publically in the form of
C<YYYY-MM-DD>.

=head2 C<maintenance_ratio( )>

=head2 C<margin_initial_ratio( )>

=head2 C<min_tick_size( )>

If applicable, this returns the regulatory defined tick size. See
http://www.finra.org/industry/tick-size-pilot-program

=head2 C<name( )>

Full name of the instrument.

=head2 C<rhs_tradability( )>

Indicates whether the instrument can be traded specifically on Robinhood.
Returns C<tradable> or C<untradable>.

=head2 C<simple_name( )>

Shorter name for the instrument. Best suited for display.

=head2 C<state( )>

Indicates whether this instrument is C<active> or C<inactive>.

=head2 C<symbol( )>

Ticker symbol.

=head2 C<tradability( )>

Indicates whether or not this instrument can be traded in general. Returns
C<tradable> or C<untradable>.

=head2 C<tradable_chain_id( )>

Id for the related options chain as a UUID.

=head2 C<tradeable( )>

Returns a boolean value.

=head2 C<type( )>

Indicates what sort of instrument this is. May one one of these: C<adr>,
C<stock>, C<etf>, C<etp>, C<contra>, C<right>, C<escrow>, C<pfd>, C<reit>,
C<unit>, C<cef>, C<wrt>, C<mlp>, C<lp>, C<open_ended_fund>, C<tracking>,
C<rlt>, C<nyrs>, or C<pre_filing>.

=head2 C<default_collar_fraction( )>


=cut

has [qw[bloomberg_unique country name symbol]] => ( is => 'ro', isa => Str, required => 1 );
has [qw[simple_name]]                          => ( is => 'ro', isa => Maybe [Str], required => 1 );
has [qw[day_trade_ratio maintenance_ratio margin_initial_ratio]] =>
    ( is => 'ro', isa => Num, required => 1 );
has [qw[min_tick_size default_collar_fraction]] =>
    ( is => 'ro', isa => Maybe [Num], required => 1 );

# State
has state => (
    is       => 'ro',
    required => 1,
    isa      => Enum [qw[active inactive unlisted]],
    handles  => [qw[is_active is_inactive is_unlisted]]
);

# Equity type
has type => (
    is       => 'ro',
    required => 0,
    isa      => Enum [
        qw[adr stock etf etp contra right escrow pfd reit unit cef wrt mlp lp open_ended_fund tracking rlt nyrs pre_filing],
        ''
    ],
    handles => [
        qw[is_adr is_stock is_etf is_etp is_contra is_right is_escrow is_pfd is_reit is_unit is_cef is_wrt is_mlp is_lp is_open_ended_fund is_tracking is_rlt is_nyrs is_pre_filing]
    ]
);

# Tradability
has $_ => (
    is       => 'ro',
    required => 1,
    coerce   => sub ($tradability) { $tradability eq 'tradable' ? !!1 : !!0 },
    isa      => Bool
    )
    for qw[
    tradability rhs_tradability
];
has tradeable => ( is => 'ro', required => 1, coerce => sub ($bool) { !!$bool }, isa => Bool );
has list_date =>
    ( is => 'ro', required => 1, isa => Maybe [ StrMatch [qr[^\d\d\d\d-\d\d-\d\d$]] ] );

# UUID
has id => ( is => 'ro', required => 1, isa => UUID );

# Optional UUID
has tradable_chain_id => ( is => 'ro', required => 1, isa => Maybe [UUID] );

# URLs
has url => ( is => 'ro', required => 1, isa => URL, coerce => 1 );
has '_' . $_ => ( is => 'ro', required => 1, init_arg => $_, isa => URL, coerce => 1 ) for qw[
    fundamentals
    market
    quote
    splits
];

=head2 C<quote( )>

    my $quote = $instrument->quote( [...] );

Returns a Finance::Robinhood::Equity:Quote object with this instrument's quote
data.

You may modify the type of information returned with the following options:

=over

=item C<bounds> - C<trading>, C<extended>, or C<regular>

=item C<include_inactive> - A boolean value

=back

	$prices = $msft->prices(bounds => 'trading', include_inactive => 0);

=cut

# Methods
sub quote ( $s, %filters ) {
    $filters{include_inactive} = $filters{include_inactive} ? 'true' : 'false'
        if defined $filters{include_inactive};
    $filters{bounds} //= 'trading';
    $s->robinhood->_req( GET => $s->_quote, query => \%filters )
        ->as('Finance::Robinhood::Equity::Quote');
}

sub _test_quote {
    t::Utility::stash('MSFT_AUTH') // skip_all();
    isa_ok( t::Utility::stash('MSFT_AUTH')->quote(), 'Finance::Robinhood::Equity::Quote' );
}

=head2 C<prices( [...] )>

	my $prices = $instrument->prices;

Returns a Finance::Robinhood::Equity::Prices object with the instrument's price
data. You must be logged in for this to work.

You may modify the type of information returned with the following options:

=over

=item C<live> - Boolean value. If true, real time quote data is returned.

=item C<source> - You may specify C<consolidated> (which is the default) for data from the tape or C<nls> for the Nasdaq last sale price.

=back

	$prices = $instrument->prices(source => 'consolidated', live => 1);

This would return live quote data from the tape.
adr
=cut

sub prices ( $s, %filters ) {     $filters{delayed} = delete $filters{live} ?
'false' : 'true' if defined $filters{live};     $filters{source} //=
'consolidated';     $s->robinhood->_req(         GET   =>
'https://api.robinhood.com/marketdata/prices/' . $s->id . '/',         query =>
\%filters     )->as('Finance::Robinhood::Equity::Prices'); }

sub _test_prices {     t::Utility::stash('MSFT_AUTH') // skip_all();    
isa_ok(         t::Utility::stash('MSFT_AUTH')->prices(),        
'Finance::Robinhood::Equity::Prices'     ); }

=head2 C<splits( )>

    my @splits = $instrument->splits->all;

Returns an iterator with hash references. These hashes contain the following
keys:

=over

=item C<divisor>

=item C<execution_date> - In the form of YYYY-MM-DD

=item C<multiplier>

=back

=cut

has splits => (
    is => 'ro',

    #isa => Maybe [
    #    ArrayRef [
    #        Dict [
    #            divisor        => Num,
    #            execution_date => StrMatch [qr[^\d\d\d\d-\d\d-\d\d$]],
    #            instrument     => InstanceOf ['Finance::Robinhood::Equity'],
    #            multiplier     => Num,
    #            url            => URL
    #        ]
    #    ]
    #],
    isa      => InstanceOf ['Finance::Robinhood::Utilities::Iterator'],
    lazy     => 1,
    builder  => 1,
    init_arg => undef
);

sub _build_splits ( $s ) {
    Finance::Robinhood::Utilities::Iterator->new( robinhood => $s->robinhood, url => $s->_splits );
}

sub _test_splits {
    my $rh     = t::Utility::rh_instance(1) // skip_all();
    my @splits = $rh->equity('GUSH')->splits->all;
    @splits
        ? ref_ok( $splits[0], 'HASH' )
        : skip_all('Robinhood is not returning stock split data');
}

sub buy ( $s, $quantity, $account = $s->robinhood->equity_account ) {
    Finance::Robinhood::Equity::OrderBuilder->new(
        robinhood  => $s->robinhood,
        account    => $account,
        instrument => $s,
        side       => 'buy',
        quantity   => $quantity,
    );
}

sub sell ( $s, $quantity, $account = $s->robinhood->equity_account ) {
    Finance::Robinhood::Equity::OrderBuilder->new(
        robinhood  => $s->robinhood,
        account    => $account,
        instrument => $s,
        side       => 'sell',
        quantity   => $quantity,
    );
}
1;
