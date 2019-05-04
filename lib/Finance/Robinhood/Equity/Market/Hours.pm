package Finance::Robinhood::Equity::Market::Hours;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Equity::Market::Hours - Represents an Equity Market's
Operating Hours

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;
    my $nyse = $rh->equity_market_by_mic('XNAS');

    CORE::say 'The Nasdaq is ' . ($nyse->hours->is_open ? '' : 'not ' ) . 'open today';

=cut

our $VERSION = '0.92_003';
use Mojo::Base-base, -signatures;
use Mojo::URL;
use Time::Moment;

sub _test__init {
    my $rh   = t::Utility::rh_instance(0);
    my $open = $rh->equity_market_by_mic('XNAS')
        ->hours(Time::Moment->from_epoch(1552613507))
        ;    # NASDAQ - March 15th, 2019
    isa_ok($open, __PACKAGE__);
    t::Utility::stash('HOURS_OPEN', $open);    #  Store it for later
    my $closed = $rh->equity_market_by_mic('XNAS')
        ->hours(Time::Moment->from_epoch(1552699907))
        ;                                      # NASDAQ - March 16th, 2019
    isa_ok($closed, __PACKAGE__);
    t::Utility::stash('HOURS_CLOSED', $closed);    #  Store it for later
}
use overload '""' => sub ($s, @) { $s->{date} }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('HOURS_OPEN') // skip_all();
    is(+t::Utility::stash('HOURS_OPEN'), '2019-03-15');
    t::Utility::stash('HOURS_CLOSED') // skip_all();
    is(+t::Utility::stash('HOURS_CLOSED'), '2019-03-16');
}
#
has _rh => undef => weak => 1;

=head1 METHODS

=head2 C<is_open( )>

Returns a true value if opens for trading on this date.

=cut

has ['is_open'];

=head2 C<opens_at( )>

    $hours->opens_at;

If the market opens today, this returns a Time::Moment object.

=cut

sub opens_at ($s) {
    $s->{closes_at} ? Time::Moment->from_string($s->{opens_at}) : ();
}

sub _test_opens_at {
    t::Utility::stash('HOURS_OPEN') // skip_all();
    is(t::Utility::stash('HOURS_OPEN')->opens_at->to_string,
        '2019-03-15T13:30:00Z');
    t::Utility::stash('HOURS_CLOSED') // skip_all();
    is(t::Utility::stash('HOURS_CLOSED')->opens_at, ());
}

=head2 C<closes_at( )>

    $hours->closes_at;

If the market was open, this returns a Time::Moment object.

=cut

sub closes_at ($s) {
    $s->{closes_at} ? Time::Moment->from_string($s->{closes_at}) : ();
}

sub _test_closes_at {
    t::Utility::stash('HOURS_OPEN') // skip_all();
    is(t::Utility::stash('HOURS_OPEN')->closes_at->to_string,
        '2019-03-15T20:00:00Z');
    t::Utility::stash('HOURS_CLOSED') // skip_all();
    is(t::Utility::stash('HOURS_CLOSED')->closes_at, ());
}

=head2 C<extended_opens_at( )>

    $hours->extended_opens_at;

If the market was open and had an extended hours trading session, this returns
a Time::Moment object.

=cut

sub extended_opens_at ($s) {
    $s->{extended_opens_at}
        ? Time::Moment->from_string($s->{extended_opens_at})
        : ();
}

sub _test_extended_opens_at {
    t::Utility::stash('HOURS_OPEN') // skip_all();
    is(t::Utility::stash('HOURS_OPEN')->extended_opens_at->to_string,
        '2019-03-15T13:00:00Z');
    t::Utility::stash('HOURS_CLOSED') // skip_all();
    is(t::Utility::stash('HOURS_CLOSED')->extended_opens_at, ());
}

=head2 C<extended_closes_at( )>

    $hours->extended_closes_at;

If the market was open and had an extended hours trading session, this returns
a Time::Moment object.

=cut

sub extended_closes_at ($s) {
    $s->{extended_closes_at}
        ? Time::Moment->from_string($s->{extended_closes_at})
        : ();
}

sub _test_extended_closes_at {
    t::Utility::stash('HOURS_OPEN') // skip_all();
    is(t::Utility::stash('HOURS_OPEN')->extended_closes_at->to_string,
        '2019-03-15T22:00:00Z');
    t::Utility::stash('HOURS_CLOSED') // skip_all();
    is(t::Utility::stash('HOURS_CLOSED')->extended_closes_at, ());
}

=head2 C<date( )>

    $hours->date;

Returns a Time::Moment object.

=cut

sub date ($s) {
    Time::Moment->from_string($s->{date} . 'T00:00:00Z');
}

sub _test_date {
    t::Utility::stash('HOURS_OPEN') // skip_all();
    is(t::Utility::stash('HOURS_OPEN')->date->to_string,
        '2019-03-15T00:00:00Z');
    t::Utility::stash('HOURS_CLOSED') // skip_all();
    is(t::Utility::stash('HOURS_CLOSED')->date->to_string,
        '2019-03-16T00:00:00Z');
}

=head2 C<next_open_hours( )>

This returns a Finance::Robinhood::Equity::Market::Hours object for the next
day the market is open.

=cut

sub next_open_hours( $s ) {
    my $res = $s->_rh->_get($s->{next_open_hours});
    $res->is_success
        ? Finance::Robinhood::Equity::Market::Hours->new(_rh => $s->_rh,
                                                         %{$res->json})
        : Finance::Robinhood::Error->new(
             $res->is_server_error ? (details => $res->message) : $res->json);
}

sub _test_next_open_hours {
    t::Utility::stash('HOURS_OPEN') // skip_all();
    is(t::Utility::stash('HOURS_OPEN')->next_open_hours->date->to_string,
        '2019-03-18T00:00:00Z');
    t::Utility::stash('HOURS_CLOSED') // skip_all();
    is(t::Utility::stash('HOURS_CLOSED')->next_open_hours->date->to_string,
        '2019-03-18T00:00:00Z');
}

=head2 C<previous_open_hours( )>

This returns a Finance::Robinhood::Equity::Market::Hours object for the
previous day the market was open.

=cut

sub previous_open_hours( $s ) {
    my $res = $s->_rh->_get($s->{previous_open_hours});
    $res->is_success
        ? Finance::Robinhood::Equity::Market::Hours->new(_rh => $s->_rh,
                                                         %{$res->json})
        : Finance::Robinhood::Error->new(
             $res->is_server_error ? (details => $res->message) : $res->json);
}

sub _test_previous_open_hours {
    t::Utility::stash('HOURS_OPEN') // skip_all();
    is(t::Utility::stash('HOURS_OPEN')->previous_open_hours->date->to_string,
        '2019-03-14T00:00:00Z');
    t::Utility::stash('HOURS_CLOSED') // skip_all();
    is( t::Utility::stash('HOURS_CLOSED')
            ->previous_open_hours->date->to_string,
        '2019-03-15T00:00:00Z'
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
