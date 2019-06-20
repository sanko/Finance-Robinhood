package Finance::Robinhood::Options::Event;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Options::Event - Represents a Single Options Event

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new->login('user', 'pass');

    # TODO

=head1 METHODS

=cut

our $VERSION = '0.92_003';
use Mojo::Base-base, -signatures;
use Mojo::URL;
use Time::Moment;
use Finance::Robinhood::Options::Event::CashComponent;
use Finance::Robinhood::Options::Event::EquityComponent;

sub _test__init {
    my $rh    = t::Utility::rh_instance(1);
    my $event = $rh->options_events->next;
    isa_ok($event, __PACKAGE__);
    t::Utility::stash('EVENT', $event);    #  Store it for later
}
use overload '""' => sub ($s, @) {
    'https://api.robinhood.com/options/events/' . $s->{id} . '/';
    },
    fallback => 1;

sub _test_stringify {
    t::Utility::stash('EVENT') // skip_all();
    like(+t::Utility::stash('EVENT'),
         qr'^https://api.robinhood.com/options/events/[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}/$'i
    );
}
has _rh => undef => weak => 1;

=head2 C<chain_id( )>

Returns a UUID.

=head2 C<direction( )>

Returns C<debit> or C<credit>.

=head2 C<id( )>

Returns a UUID.

=head2 C<quantity( )>


=head2 C<state( )>


=head2 C<total_cash_amount( )>


=head2 C<type( )>

The type of event. Might be one of the following: C<expiration>, C<assignment>,
C<exercise>, or C<voided>.

=head2 C<underlying_price( )>

Current price of the underlying equity.

=cut

has ['chain_id', 'direction',         'id',   'quantity',
     'state',    'total_cash_amount', 'type', 'underlying_price'
];

=head2 C<cash_component( )>

Returns a Finance::Robinhood::Options::Event::CashComponent objects if
applicable.

=cut

sub cash_component ($s) {
    $s->{cash_component}
        ? Finance::Robinhood::Options::Event::CashComponent->new(
                                                       _rh => $s->_rh,
                                                       %{$s->{cash_component}}
        )
        : ();
}

sub _test_cash_components {
    t::Utility::stash('EVENT') // skip_all('No event object in stash');
    my $cash_component = t::Utility::stash('EVENT')->cash_component;
    $cash_component // skip_all('Event has no cash component');
    isa_ok($cash_component,
           'Finance::Robinhood::Options::Event::CashComponent');
}

=head2 C<equity_components( )>

Returns a list of related Finance::Robinhood::Options::Event::EquityComponent
objects if applicable.

=cut

sub equity_components ($s) {
    map {
        Finance::Robinhood::Options::Event::EquityComponent->new(
                                                               _rh => $s->_rh,
                                                               %{$_})
    } @{$s->{equity_components}};
}

sub _test_equity_components {
    t::Utility::stash('EVENT') // skip_all('No event object in stash');
    my ($equity_component) = t::Utility::stash('EVENT')->equity_components;
    $equity_component // skip_all('Event does not contain equity components');
    isa_ok($equity_component,
           'Finance::Robinhood::Options::Event::EquityComponent');
}

=head2 C<chain( )>

Returns the related Finance::Robinhood::Options::Chain object.

=cut

sub chain ($s) {
    $s->_rh->options_chain_by_id($s->{chain_id});
}

sub _test_chain {
    t::Utility::stash('EVENT') // skip_all('No event object in stash');
    isa_ok(t::Utility::stash('EVENT')->chain,
           'Finance::Robinhood::Options::Chain');
}

=head2 C<instrument( )>

Returns the related Finance::Robinhood::Options::Instrument object.

=cut

sub instrument ($s) {
    require Finance::Robinhood::Options::Instrument;
    my $res = $s->_rh->_get($s->{option});
    return $res->is_success
        ? Finance::Robinhood::Options::Instrument->new(_rh => $s->_rh,
                                                       %{$res->json})
        : Finance::Robinhood::Error->new(
             $res->is_server_error ? (details => $res->message) : $res->json);
}

sub _test_instrument {
    t::Utility::stash('EVENT') // skip_all('No event object in stash');
    isa_ok(t::Utility::stash('EVENT')->instrument,
           'Finance::Robinhood::Options::Instrument');
}

=head2 C<position( )>

Returns the related Finance::Robinhood::Options::Position object.

=cut

sub position ($s) {
    my $res = $s->_rh->_get($s->{position});
    return $res->is_success
        ? Finance::Robinhood::Options::Position->new(_rh => $s->_rh,
                                                     %{$res->json})
        : Finance::Robinhood::Error->new(
             $res->is_server_error ? (details => $res->message) : $res->json);
}

sub _test_position {
    t::Utility::stash('EVENT') // skip_all('No event object in stash');
    isa_ok(t::Utility::stash('EVENT')->position,
           'Finance::Robinhood::Options::Position');
}

=head2 C<event_date( )>

Returns a list of Time::Moment objects.

=cut

sub event_date($s) {
    Time::Moment->from_string($s->{event_date} . 'T00:00:00Z');
}

sub _test_event_date {
    t::Utility::stash('EVENT') // skip_all();
    my $date = t::Utility::stash('EVENT')->event_date;
    isa_ok($date, 'Time::Moment');
}

=head2 C<account( )>

Returns the related Finance::Robinhood::Equity::Account object.

=cut

sub account ($s) {
    my $res = $s->_rh->_get($s->{account});
    return $res->is_success
        ? Finance::Robinhood::Equity::Account->new(_rh => $s->_rh,
                                                   %{$res->json})
        : Finance::Robinhood::Error->new(
             $res->is_server_error ? (details => $res->message) : $res->json);
}

sub _test_account {
    t::Utility::stash('EVENT') // skip_all('No event object in stash');
    isa_ok(t::Utility::stash('EVENT')->account,
           'Finance::Robinhood::Equity::Account');
}

=head2 C<created_at( )>

Returns a Time::Moment object.

=cut

sub created_at ($s) {
    Time::Moment->from_string($s->{created_at});
}

sub _test_created_at {
    t::Utility::stash('POSITION') // skip_all('No position object in stash');
    isa_ok(t::Utility::stash('POSITION')->created_at, 'Time::Moment');
}

=head2 C<updated_at( )>

Returns a Time::Moment object.

=cut

sub updated_at ($s) {
    Time::Moment->from_string($s->{updated_at});
}

sub _test_updated_at {
    t::Utility::stash('POSITION') // skip_all('No position object in stash');
    isa_ok(t::Utility::stash('POSITION')->updated_at, 'Time::Moment');
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
