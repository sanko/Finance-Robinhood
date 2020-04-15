package Finance::Robinhood::Options;
our $VERSION = '0.92_003';

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Options - Represents a Single Options Chain

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new->login('user', 'pass');

    # TODO

=head1 METHODS

=cut

use Moo;
use MooX::Enumeration;
use Types::Standard qw[ArrayRef Bool Dict Enum InstanceOf Maybe Num Str StrMatch];
use URI;
use Time::Moment;
use Data::Dump;
use experimental 'signatures';
#
use Finance::Robinhood::Equity;

sub _test__init {
    my $rh     = t::Utility::rh_instance(0);
    my $chains = $rh->options_chains;
    my $chain;
    while ( $chains->has_next ) {
        my @dates = $chains->next->expiration_dates;
        if (@dates) {
            $chain = $chains->current;
            last;
        }
    }
    isa_ok( $chain, __PACKAGE__ );
    t::Utility::stash( 'CHAIN', $chain );    #  Store it for later
}
use overload '""' => sub ( $s, @ ) {
    'https://api.robinhood.com/options/chains/' . $s->{id} . '/';
    },
    fallback => 1;

sub _test_stringify {
    t::Utility::stash('CHAIN') // skip_all();
    like(
        +t::Utility::stash('CHAIN'),
        qr'^https://api.robinhood.com/options/chains/[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}/$'i
    );
}
has robinhood => ( is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood'] );

=head2 C<can_open_position( )>

Returns a boolean value. True if you may open a new position.

=head2 C<cash_compenent( )>

If defined, a dollar amount

=head2 C<has_cash_component( )>.

Returns a boolean value. True if there's a cash component. Otherwise, false.

=head2 C<expiration_dates( )>

Returns a list of C<YYYY-MM-DD> dates.

=head2 C<id( )>

Returns a UUID.

=head2 C<min_ticks( )>

Returns a hash reference with the following keys:

=over

=item C<above_tick> - Minimum tick size when applicable.

=item C<below_tick> - Minimum tick size when applicable.

=item C<cutoff_price> - At this price or more, the C<above_tick> will apply. Below this price, the C<below_tick> is required.

=back

=head2 C<symbol( )>

Chain's ticker symbol.

=head2 C<trade_value_multiplier( )>



=cut

has can_open_position => (
    is       => 'ro',
    isa      => Bool,
    coerce   => sub ($bool) { !!$bool },
    required => 1
);
has cash_component   => ( is => 'ro', isa => Maybe [Num], predicate => 1, required => 1 );
has expiration_dates => (
    is       => 'ro',
    isa      => ArrayRef [ StrMatch [qr[^\d\d\d\d-\d\d-\d\d$]] ],
    required => 1
);
has id => (
    is  => 'ro',
    isa => StrMatch [qr[^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$]i],
    required => 1
);
has min_ticks => (
    is       => 'ro',
    isa      => Dict [ above_tick => Num, below_tick => Num, cutoff_price => Num ],
    required => 1
);
has symbol                 => ( is => 'ro', isa => Str, required => 1 );
has trade_value_multiplier => ( is => 'ro', isa => Num, required => 1 );
has _underlying_instruments => (
    is  => 'ro',
    isa => ArrayRef [
        Dict [
            id => StrMatch [
                qr[^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$]i],
            instrument => Str,
            quantity   => Num
        ]
    ],
    required => 1,
    init_arg => 'underlying_instruments'
);

=head2 C<underlying_equities( )>

Returns the underlying equities as a list of hash references. These hases
contain the following keys:

=over

=item C<id> - UUID

=item C<equity> - Finance::Robinhood::Equity object

=item C<quantity> - Number of shares

=back

=cut

has underlying_equities => (
    is  => 'ro',
    isa => ArrayRef [
        Dict [
            id => StrMatch [
                qr[^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$]i],
            equity   => InstanceOf ['Finance::Robinhood::Equity'],
            quantity => Num
        ]
    ],
    lazy     => 1,
    builder  => 1,
    init_arg => undef
);

sub _build_underlying_equities($s) {
    [
        map {
            {
                id     => $_->{id},
                equity => $s->robinhood->_req(
                    GET => $_->{instrument},
                    as  => 'Finance::Robinhood::Equity'
                ),
                quantity => $_->{quantity}
            }
        } @{ $s->_underlying_instruments }
    ];
}

sub _test_underlying_equities {
    t::Utility::stash('CHAIN') // skip_all();
    my ($underlying) = t::Utility::stash('CHAIN')->underlying_equities;
    isa_ok( $underlying->{equity}, 'Finance::Robinhood::Equity' );
}

=head2 C<contracts( [...] )>

    my $instruments = $chain->contracts( );

Returns an iterator filled with Finance::Robinhood::Options::Contract objects.

The following options are all optional:

=over

=item * C<type> - If given, must be C<put> or C<call>

=item * C<expiration_dates> - If given, this is a list of expiration dates in the form of C<YYYY-MM-DD> or Time::Moment objects.

	my $instruments = $chain->contracts(expiration_dates => [$chain->expiration_dates]);

It would be a good idea to pass the values from C<expiration_dates( )>.

=item * C<tradability> - May be either C<tradable> or C<untradable>

=back

=cut

sub contracts ( $s, %filter ) {
    $filter{expiration_dates} = join ',',
        map { ref $_ eq 'Time::Moment' ? $_->strftime('%Y-%m-%d') : $_; }
        @{ $filter{expiration_dates} }
        if $filter{expiration_dates};
    my $url = URI->new('https://api.robinhood.com/options/instruments/');
    $url->query_form( chain_id => $s->id, %filter );
    Finance::Robinhood::Utilities::Iterator->new(
        robinhood => $s->robinhood,
        url       => $url,
        as        => 'Finance::Robinhood::Options::Contract'
    );
}

sub _test_instruments {
    t::Utility::stash('CHAIN') // skip_all();
    my $instrument = t::Utility::stash('CHAIN')->instruments;
    isa_ok( $instrument,          'Finance::Robinhood::Utilities::Iterator' );
    isa_ok( $instrument->current, 'Finance::Robinhood::Options::Contract' );
}
has url => ( is => 'ro', isa => InstanceOf ['URI'], builder => 1,, lazy => 1 );

sub _build_url ($s) {
    URI->new( sprintf 'https://api.robinhood.com/options/chains/%s/', $s->id );
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
