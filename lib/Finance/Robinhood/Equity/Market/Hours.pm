package Finance::Robinhood::Equity::Market::Hours;
our $VERSION = '0.92_003';

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

use Moo;
use MooX::Enumeration;
use Types::Standard qw[Bool Enum InstanceOf Maybe Num Str StrMatch];
use URI;
use Time::Moment;
use Data::Dump;
use experimental 'signatures';
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
has robinhood =>
    (is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood'],);

=head1 METHODS

=head2 C<is_open( )>

Returns a true value if opens for trading on this date.

=cut

has is_open => (is       => 'ro',
                isa      => Bool,
                coerce   => sub($bool) { !!$bool },
                required => 1
);

=head2 C<opens_at( )>

    $hours->opens_at;

If the market opens today, this returns a Time::Moment object.


=head2 C<closes_at( )>

    $hours->closes_at;

If the market was open, this returns a Time::Moment object.


=head2 C<extended_opens_at( )>

    $hours->extended_opens_at;

If the market was open and had an extended hours trading session, this returns
a Time::Moment object.


=head2 C<extended_closes_at( )>

    $hours->extended_closes_at;

If the market was open and had an extended hours trading session, this returns
a Time::Moment object.

=cut

has [qw[opens_at closes_at extended_opens_at extended_closes_at]] => (
        is  => 'ro',
        isa => Maybe [InstanceOf ['Time::Moment']],
        coerce =>
            sub ($time) { $time // return; Time::Moment->from_string($time) },
        required => 1
);

sub _test_opens_at {
    t::Utility::stash('HOURS_OPEN') // skip_all();
    is(t::Utility::stash('HOURS_OPEN')->opens_at->to_string,
        '2019-03-15T13:30:00Z');
    t::Utility::stash('HOURS_CLOSED') // skip_all();
    is(t::Utility::stash('HOURS_CLOSED')->opens_at, ());
}

sub _test_closes_at {
    t::Utility::stash('HOURS_OPEN') // skip_all();
    is(t::Utility::stash('HOURS_OPEN')->closes_at->to_string,
        '2019-03-15T20:00:00Z');
    t::Utility::stash('HOURS_CLOSED') // skip_all();
    is(t::Utility::stash('HOURS_CLOSED')->closes_at, ());
}

sub _test_extended_opens_at {
    t::Utility::stash('HOURS_OPEN') // skip_all();
    is(t::Utility::stash('HOURS_OPEN')->extended_opens_at->to_string,
        '2019-03-15T13:00:00Z');
    t::Utility::stash('HOURS_CLOSED') // skip_all();
    is(t::Utility::stash('HOURS_CLOSED')->extended_opens_at, ());
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

has date => (
    is     => 'ro',
    isa    => InstanceOf ['Time::Moment'],
    coerce => sub ($date) {
        Time::Moment->from_string($date . 'T00:00:00Z');
    },
    required => 1
);

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

=head2 C<previous_open_hours( )>

This returns a Finance::Robinhood::Equity::Market::Hours object for the
previous day the market was open.

=cut

has '_'
    .
    $_ => (is       => 'ro',
           isa      => Maybe [InstanceOf ['URI']],
           coerce   => sub($url) { $url ? URI->new($url) : () },
           init_arg => $_
    ) for qw[next_open_hours previous_open_hours];
has [qw[next_open_hours previous_open_hours]] => (
              is  => 'ro',
              isa => InstanceOf ['Finance::Robinhood::Equity::Market::Hours'],
              builder  => 1,
              lazy     => 1,
              init_arg => undef
);

sub _build_next_open_hours($s) {
    $s->robinhood->_req(GET => $s->_next_open_hours,
                        as  => 'Finance::Robinhood::Equity::Market::Hours');
}

sub _build_previous_open_hours($s) {
    $s->robinhood->_req(GET => $s->_previous_open_hours,
                        as  => 'Finance::Robinhood::Equity::Market::Hours');
}

sub _test_next_open_hours {
    t::Utility::stash('HOURS_OPEN') // skip_all();
    is(t::Utility::stash('HOURS_OPEN')->next_open_hours->date->to_string,
        '2019-03-18T00:00:00Z');
    t::Utility::stash('HOURS_CLOSED') // skip_all();
    is(t::Utility::stash('HOURS_CLOSED')->next_open_hours->date->to_string,
        '2019-03-18T00:00:00Z');
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
