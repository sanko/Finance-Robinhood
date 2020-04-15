package Finance::Robinhood::Equity::Position;
our $VERSION = '0.92_003';

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Equity::Position - Represents a Single Equity Position on a
Robinhood Account

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new( ... );

	for my $position ($rh->equity_positions) {
		CORE::say $position->instrument->symbol;
	}

=cut

sub _test__init {
    my $rh       = t::Utility::rh_instance(1);
    my $acct     = $rh->equity_account;
    my $position = $acct->positions->current;
    isa_ok( $position, __PACKAGE__ );
    t::Utility::stash( 'POSITION', $position );    #  Store it for later
}
#
use Moo;
use MooX::Enumeration;
use Types::Standard qw[InstanceOf Num Str];
use URI;
use Time::Moment;
use Data::Dump;
use experimental 'signatures';
use Finance::Robinhood::Types qw[UUID Timestamp URL];
#
use overload '""' => sub ( $s, @ ) { $s->_url }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('POSITION') // skip_all();
    like(
        +t::Utility::stash('POSITION'),
        qr'https://api.robinhood.com/accounts/.+/positions/.+/',
    );
}

=head1 METHODS

=cut

has robinhood => (
    is       => 'ro',
    required => 1,
    isa      => InstanceOf ['Finance::Robinhood'],
    handles  => ['_req']
);

=head2 C<average_buy_price( )>


=head2 C<intraday_average_buy_price( )>


=head2 C<intraday_quantity( )>


=head2 C<pending_average_buy_price( )>


=head2 C<quantity( )>


=head2 C<shares_held_for_buys( )>


=head2 C<shares_held_for_options_collateral( )>

Shares held for collateral for a sold call, etc.

=head2 C<shares_held_for_options_events( )>


=head2 C<shares_held_for_sells( )>

Shares that are marked to be sold in outstanding orders.

=head2 C<shares_held_for_stock_grants( )>

Shares that were a reward (referral, etc.) and must be held for a period before
they can be sold.

=head2 C<shares_pending_from_options_events( )>


=cut

has '_' . $_ => ( is => 'ro', required => 1, isa => URL, coerce => 1, init_arg => $_ )
    for qw[account instrument url];

=head2 C<account( )>

Returns the related Finance::Robinhood::Equity::Account object.

=cut

sub account ($s) {
    $s->robinhood->_req(
        GET => $s->_account,
        as  => 'Finance::Robinhood::Equity::Account'
    );
}

sub _test_account {
    t::Utility::stash('POSITION') // skip_all('No position object in stash');
    isa_ok(
        t::Utility::stash('POSITION')->account,
        'Finance::Robinhood::Equity::Account'
    );
}

=head2 C<instrument( )>

Returns the related Finance::Robinhood::Equity object.

=cut

sub instrument ($s) {
    $s->robinhood->_req(
        GET => $s->_instrument,
        as  => 'Finance::Robinhood::Equity'
    );
}

sub _test_instrument {
    t::Utility::stash('POSITION') // skip_all('No position object in stash');
    isa_ok(
        t::Utility::stash('POSITION')->instrument,
        'Finance::Robinhood::Equity'
    );
}
has account_number => ( is => 'ro', required => 1, isa => Str );
has [
    qw[average_buy_price intraday_average_buy_price intraday_quantity pending_average_buy_price
        quantity shares_held_for_buys shares_held_for_options_collateral shares_held_for_options_events
        shares_held_for_sells shares_held_for_stock_grants shares_pending_from_options_events]
] => ( is => 'ro', required => 1, isa => Num );

=head2 C<created_at( )>

Returns a Time::Moment object.

=head2 C<updated_at( )>

Returns a Time::Moment object.

=cut

has [qw[created_at updated_at]] => ( is => 'ro', required => 1, isa => Timestamp, coerce => 1 );
1;
