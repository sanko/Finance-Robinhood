package Finance::Robinhood::Options::Instrument;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Options::Instrument - Represents a Single Options
Instrument

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;
    my $instruments = $rh->options_instruments();

    for my $instrument ($instruments->all) {
        CORE::say $instrument->chain_symbol;
    }

=cut

our $VERSION = '0.92_003';
use Mojo::Base-base, -signatures;
use Mojo::URL;
use Finance::Robinhood::Options::Quote;

sub _test__init {
    my $rh = t::Utility::rh_instance(1);
    my $instrument =
        $rh->options_instruments(
              chain_id =>
                  $rh->equity_instrument_by_symbol('MSFT')->tradable_chain_id,
              tradability => 'tradable'
    )->current;
    isa_ok($instrument, __PACKAGE__);
    t::Utility::stash('INSTRUMENT', $instrument);    #  Store it for later
}
use overload '""' => sub ($s, @) { $s->{url} }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('INSTRUMENT') // skip_all();
    is(+t::Utility::stash('INSTRUMENT'),
        'https://api.robinhood.com/options/instruments/' .
            t::Utility::stash('INSTRUMENT')->id . '/');
}
#
has _rh => undef => weak => 1;

=head1 METHODS

=head2 C<chain_id()>


=head2 C<chain_symbol()>


=head2 C<id( )>

UUID used to identify this instrument.

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

=cut

has ['chain_id',        'chain_symbol', 'id',           'min_ticks',
     'rhs_tradability', 'state',        'strike_price', 'tradability',
     'type',
];

=head2 C<expiration_date( )>

Returns a Time::Moment object.

=cut

sub expiration_date ($s) {
    Time::Moment->from_string($s->{expiration_date} . 'T00:00:00Z');
}

sub _test_expiration_date {
    t::Utility::stash('INSTRUMENT') // skip_all();
    isa_ok(t::Utility::stash('INSTRUMENT')->expiration_date, 'Time::Moment');
}

=head2 C<issue_date( )>

Returns a Time::Moment object.

=cut

sub issue_date ($s) {
    Time::Moment->from_string($s->{issue_date} . 'T00:00:00Z');
}

sub _test_issue_date {
    t::Utility::stash('INSTRUMENT') // skip_all();
    isa_ok(t::Utility::stash('INSTRUMENT')->issue_date, 'Time::Moment');
}

=head2 C<created_at( )>

Returns a Time::Moment object.

=cut

sub created_at ($s) {
    Time::Moment->from_string($s->{created_at});
}

sub _test_created_at {
    t::Utility::stash('INSTRUMENT') // skip_all();
    isa_ok(t::Utility::stash('INSTRUMENT')->created_at, 'Time::Moment');
}

=head2 C<updated_at( )>

Returns a Time::Moment object.

=cut

sub updated_at ($s) {
    Time::Moment->from_string($s->{updated_at});
}

sub _test_updated_at {
    t::Utility::stash('INSTRUMENT') // skip_all();
    isa_ok(t::Utility::stash('INSTRUMENT')->updated_at, 'Time::Moment');
}

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

sub historicals ($s, %filters) {
    my $res = $s->_rh->_get(
             Mojo::URL->new(
                 'https://api.robinhood.com/marketdata/options/historicals/' .
                     $s->id . '/'
             )->query(\%filters),
    );
    require Finance::Robinhood::Options::Historicals if $res->is_success;
    $res->is_success
        ? Finance::Robinhood::Options::Historicals->new(_rh => $s->_rh,
                                                        %{$res->json})
        : Finance::Robinhood::Error->new(
             $res->is_server_error ? (details => $res->message) : $res->json);
}

sub _test_historicals {
    t::Utility::stash('INSTRUMENT') // skip_all();
    isa_ok(t::Utility::stash('INSTRUMENT')->historicals(interval => 'hour'),
           'Finance::Robinhood::Options::Historicals');
}

=head2 C<quote( )>

    my $quote = $instrument->quote();

Builds a Finance::Robinhood::Options::Quote object with this instrument's quote
data.

You do not need to be logged in for this to work.

=cut

sub quote ($s) {
    my $res = $s->_rh->_get(
            'https://api.robinhood.com/marketdata/options/' . $s->{id} . '/');
    $res->is_success
        ? Finance::Robinhood::Options::Quote->new(_rh => $s->_rh,
                                                  %{$res->json})
        : Finance::Robinhood::Error->new(
             $res->is_server_error ? (details => $res->message) : $res->json);
}

sub _test_quote {
    t::Utility::stash('INSTRUMENT') // skip_all();
    isa_ok(t::Utility::stash('INSTRUMENT')->quote(),
           'Finance::Robinhood::Options::Quote');
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
