package Finance::Robinhood::Options::Event;
our $VERSION = '0.92_003';

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Options::Event - Represents a Single Options Event

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new(...);

    my @events = $rh->options_events->all;

    # TODO

=head1 METHODS

=cut

use Moo;
use MooX::Enumeration;
use Types::Standard
    qw[ArrayRef Bool Dict Enum InstanceOf Maybe Num Str StrMatch];
use URI;
use Time::Moment;
use Data::Dump;
use experimental 'signatures';
#
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
has robinhood =>
    (is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood']);

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

=head2 C<event_date( )>

Returns the date as C<YYYY-MM-DD>.

=cut

has [qw[id chain_id]] => (
    is => 'ro',
    isa =>
        StrMatch [
        qr[^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$]i
        ],
    required => 1
);
has direction => (is       => 'ro',
                  isa      => Enum [qw[debit credit]],
                  handles  => [qw[is_debit is_credit]],
                  requried => 1
);
has event_date =>
    (is => 'ro', isa => StrMatch [qr[^\d\d\d\d-\d\d-\d\d$]], required => 1);
has [qw[quantity total_cash_amount underlying_price]] =>
    (is => 'ro', isa => Num, required => 1);
has type => (
           is      => 'ro',
           isa     => Enum [qw[assignment expiration exercise voided]],
           handles => [qw[is_assignment is_expiration is_exercise is_voided]],
           required => 1
);
has state => (is       => 'ro',
              isa      => Enum [qw[confirmed]],
              handles  => [qw[is_confirmed]],
              required => 1
);

=head2 C<cash_component( )>

Returns data about any cash component if applicable. A hash reference is
returned with the following keys:

=over

=item C<id> - UUID

=item C<direction>

=item C<cash_amount>

=back

=cut
has cash_component => (
    is  => 'ro',
    isa => Maybe [
        Dict [
            id =>
                StrMatch [
                qr[^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$]
                ],
            direction   => Enum [qw[buy sell]], # I don't know what goes here!
            cash_amount => Num
        ]
    ],
    required => 1
);

sub _test_cash_components {
    t::Utility::stash('EVENT') // skip_all('No event object in stash');
    my $cash_component = t::Utility::stash('EVENT')->cash_component;
    $cash_component // skip_all('Event has no cash component');

    # TODO: Might be a hash with certain keys...
}

=head2 C<equity_components( )>

Returns a list of related equity components if applicable.

Each element will be a hash with the following keys:

=over

=item C<id> - UUID

=item C<instrument>

=item C<price>

=item C<quantity>

=item C<side>

=item C<symbol>

=back

=cut
has equity_components => (
    is  => 'ro',
    isa => ArrayRef [
        Dict [
            id =>
                StrMatch [
                qr[^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$]
                ],
            instrument => Str,                   #InstanceOf['URI'],
            price      => Num,
            quantity   => Num,
            side       => Enum [qw[sell buy]],
            symbol     => Str
        ]
    ],
    coerce => sub ($list) {
        [map { %{$_}, instrument => URI->new(delete $_->{instrument}) }
         @$list]
    },
    required => 1
);

sub _test_equity_components {
    t::Utility::stash('EVENT') // skip_all('No event object in stash');
    my ($equity_component) = t::Utility::stash('EVENT')->equity_components;
    $equity_component // skip_all('Event does not contain equity components');

    # TODO: This might be a list of hashes
    #isa_ok($equity_component,
    #       'Finance::Robinhood::Options::Event::EquityComponent');
}

=head2 C<chain( )>

Returns the related Finance::Robinhood::Options::Chain object.

=cut

has chain => (is      => 'ro',
              isa     => InstanceOf ['Finance::Robinhood::Option'],
              lazy    => 1,
              builder => 1
);

sub _build_chain ($s) {
    $s->robinhood->options_chain_by_id($s->chain_id);
}

sub _test_chain {
    t::Utility::stash('POSITION') // skip_all('No position object in stash');
    isa_ok(t::Utility::stash('POSITION')->chain,
           'Finance::Robinhood::Options');
}

=head2 C<contract( )>

Returns the related Finance::Robinhood::Options::Contract object.

=cut

sub contract ($s) {
    $s->robinhood->_req(GET => $s->option,
                        as  => 'Finance::Robinhood::Options::Contract');
}

sub _test_contract {
    t::Utility::stash('EVENT') // skip_all('No event object in stash');
    isa_ok(t::Utility::stash('EVENT')->contract,
           'Finance::Robinhood::Options::Contract');
}

=head2 C<position( )>

Returns the related Finance::Robinhood::Options::Position object.

=cut

has _position => (is       => 'ro',
                  isa      => InstanceOf ['URI'],
                  coerce   => sub ($url) { URI->new($url) },
                  init_arg => 'position',
                  requried => 1
);
has position => (is  => 'ro',
                 isa => InstanceOf ['Finance::Robinhood::Options::Position'],
                 builder  => 1,
                 lazy     => 1,
                 init_arg => undef
);

sub _build_position ($s) {
    $s->robinhood->_req(GET => $s->_position,
                        as  => 'Finance::Robinhood::Options::Position');
}

sub _test_position {
    t::Utility::stash('EVENT') // skip_all('No event object in stash');
    isa_ok(t::Utility::stash('EVENT')->position,
           'Finance::Robinhood::Options::Position');
}

=head2 C<account( )>

Returns the related Finance::Robinhood::Equity::Account object.

=cut

has _account => (is       => 'ro',
                 isa      => InstanceOf ['URI'],
                 coerce   => sub ($url) { URI->new($url) },
                 init_arg => 'account',
                 requried => 1
);
has account => (is      => 'ro',
                isa     => InstanceOf ['Finance::Robinhood::Equity::Account'],
                builder => 1,
                lazy    => 1,
                init_arg => undef
);

sub _build_account ($s) {
    $s->robinhood->_req(GET => $s->_account,
                        as  => 'Finance::Robinhood::Equity::Account');
}

sub _test_account {
    t::Utility::stash('EVENT') // skip_all('No event object in stash');
    isa_ok(t::Utility::stash('EVENT')->account,
           'Finance::Robinhood::Equity::Account');
}

=head2 C<created_at( )>

Returns a Time::Moment object.

=head2 C<updated_at( )>

Returns a Time::Moment object.

=cut

has [qw[created_at updated_at]] => (
    is     => 'ro',
    isa    => InstanceOf ['Time::Moment'],
    coerce => sub ($time) {
        Time::Moment->from_string($time);
    },
    requried => 1
);

sub _test_created_at {
    t::Utility::stash('POSITION') // skip_all('No position object in stash');
    isa_ok(t::Utility::stash('POSITION')->created_at, 'Time::Moment');
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
