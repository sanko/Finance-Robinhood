package Finance::Robinhood::Options::Contract;
our $VERSION = '0.92_003';

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Options::Contract - Represents a Single Options Contract

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;
    my $instruments = $rh->options();

    for my $instrument ($instruments->all) {
        CORE::say $instrument->chain_symbol;
    }

=cut

use Moo;
use MooX::Enumeration;
use Types::Standard qw[ArrayRef Bool Dict Enum InstanceOf Maybe Num Str StrMatch];
use URI;
use Time::Moment;
use Data::Dump;
use experimental 'signatures';
#
#use Finance::Robinhood::Options::Historicals;
use Finance::Robinhood::Options::Quote;
#
sub _test__init {
    my $rh         = t::Utility::rh_instance(1);
    my $instrument = $rh->options(
        chain_id    => $rh->equity('MSFT')->tradable_chain_id,
        tradability => 'tradable'
    )->current;
    isa_ok( $instrument, __PACKAGE__ );
    t::Utility::stash( 'INSTRUMENT', $instrument );    #  Store it for later
}
use overload '""' => sub ( $s, @ ) { $s->{url} }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('INSTRUMENT') // skip_all();
    is(
        +t::Utility::stash('INSTRUMENT'),
        'https://api.robinhood.com/options/instruments/'
            . t::Utility::stash('INSTRUMENT')->id . '/'
    );
}
has robinhood => ( is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood'] );

=head1 METHODS

=head2 C<chain_id()>

UUID used internally for this options's chain.

=head2 C<chain_symbol()>

The ticker symbol of this particular option instrument.

=head2 C<created_at( )>

Returns a Time::Moment object.

=head2 C<expiration_date( )>

Returns the date of expiration in C<YYYY-MM-DD>.

=head2 C<id( )>

UUID used to identify this instrument.

=head2 C<issue_date( )>

Returns the date of issue in C<YYYY-MM-DD>.

=head2 C<min_ticks( )>

Returns a hash reference with the following keys:

=over

=item C<above_tick> - Minimum tick size when applicable.

=item C<below_tick> - Minimum tick size when applicable.

=item C<cutoff_price> - At this price or more, the C<above_tick> will apply. Below this price, the C<below_tick> is required.

=back

=head2 C<rhs_tradability( )>

Exposes whether or not this instrument can be traded on Robinhood. Either
C<tradable> or C<untradable>.

=head2 C<state( )>



=head2 C<strike_price( )>

The strike of this particular instrument.

=head2 C<tradability( )>

Indicates whether this instrument is being traded in general.

=head2 C<type( )>

Indicated whether this is a C<call> or C<put>.

=head2 C<updated_at( )>

Time::Moment object indicating when this particular instrument was last
modified.

=cut

has chain_id => (
    is  => 'ro',
    isa => StrMatch [qr[^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$]i],
    required => 1
);
has chain_symbol => ( is => 'ro', isa => Str, required => 1 );
has id           => (
    is  => 'ro',
    isa => StrMatch [qr[^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$]i],
    required => 1
);
has min_ticks => (
    is       => 'ro',
    isa      => Dict [ above_tick => Num, below_tick => Num, cutoff_price => Num ],
    required => 1
);
has [qw[expiration_date issue_date]] =>
    ( is => 'ro', isa => StrMatch [qr[^\d\d\d\d-\d\d-\d\d$]], required => 1 );
has [qw[created_at updated_at]] => (
    is     => 'ro',
    isa    => InstanceOf ['Time::Moment'],
    coerce => sub ($date) {
        Time::Moment->from_string($date);
    },
    required => 1
);
has [qw[rhs_tradability tradability]] => (
    is       => 'ro',
    isa      => Enum [qw[position_closing_only untradable tradable]],
    handles  => [qw[is_position_closing_only is_untradable is_tradable]],
    required => 1
);
has state => (
    is       => 'ro',
    isa      => Enum [qw[active expired inactive]],
    handles  => [qw[is_active is_expired is_inactive]],
    required => 1
);
has type => (
    is       => 'ro',
    isa      => Enum [qw[call put]],
    handles  => [qw[is_call is_put]],
    required => 1
);
has url => (
    is       => 'ro',
    isa      => InstanceOf ['URI'],
    coerce   => sub ($url) { URI->new($url) },
    required => 1
);

=head2 C<historicals( ... )>

    my $data = $instrument->historicals( interval => '15second' );

Returns a Finance::Robinhood::Options::Historicals object.

You may provide the following arguments:

=over

=item C<interval> Required and must be on eof the following:

=over

=item C<15second>

=item C<5minute>

=item C<10minute>

=item C<hour>

=item C<day>

=item C<week>

=item C<month>

=back

=item C<span> - Optional and must be one of the following:

=over

=item C<hour>

=item C<day>

=item C<week>

=item C<month>

=item C<year>

=item C<5year>

=item C<all>

=back

=item C<bounds> - Optional and must be one of the following:

=over

=item C<regular> - Default

=item C<extended>

=item C<24_7>

=back

=back

=cut

sub historicals ( $s, %filters ) {
    my $url
        = URI->new( 'https://api.robinhood.com/marketdata/options/historicals/' . $s->id . '/' );
    $url->query_form(%filters);
    $s->robinhood->_req(
        GET => $url,
        as  => 'Finance::Robinhood::Options::Historicals'
    );
}

sub _test_historicals {
    t::Utility::stash('INSTRUMENT') // skip_all();
    isa_ok(
        t::Utility::stash('INSTRUMENT')->historicals( interval => 'hour' ),
        'Finance::Robinhood::Options::Historicals'
    );
}

=head2 C<quote( )>

    my $quote = $instrument->quote();

Builds a Finance::Robinhood::Options::Quote object with this instrument's quote
data.

You do not need to be logged in for this to work.

=cut

sub quote ($s) {
    $s->robinhood->_req(
        GET => 'https://api.robinhood.com/marketdata/options/' . $s->id . '/',

        #as => 'Finance::Robinhood::Options::Quote'
    );
}

sub _test_quote {
    t::Utility::stash('INSTRUMENT') // skip_all();
    isa_ok(
        t::Utility::stash('INSTRUMENT')->quote(),
        'Finance::Robinhood::Options::Quote'
    );
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
