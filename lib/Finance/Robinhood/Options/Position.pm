package Finance::Robinhood::Options::Position;
our $VERSION = '0.92_003';

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Options::Position - Represents a Single Options Position on
a Robinhood Account

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new->login('user', 'pass');

	for my $position ($rh->options_positions) {
		CORE::say $position->instrument->symbol;
	}

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
use Finance::Robinhood::Equity;

sub _test__init {
    my $rh       = t::Utility::rh_instance(1);
    my $position = $rh->options_positions->current;
    isa_ok($position, __PACKAGE__);
    t::Utility::stash('POSITION', $position);    #  Store it for later
}
use overload '""' => sub ($s, @) { $s->{url} }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('POSITION') // skip_all();
    like(+t::Utility::stash('POSITION'),
         qr'https://api.robinhood.com/options/positions/.+/');
}
##

=head1 METHODS

=cut

has robinhood =>
    (is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood']);

=head2 C<average_price( )>


=head2 C<chain_id( )>


=head2 C<chain_symbol( )>


=head2 C<intraday_average_open_price( )>

=head2 C<intraday_quantity( )>

=head2 C<pending_buy_quantity>


=head2 C<pending_expired_quantity( )>

=head2 C<pending_sell_quantity( )>

=head2 C<quantity( )>


=head2 C<trade_value_multiplier( )>


=head2 C<type( )>

C<long> or C<short>

=cut
has [
    qw[average_price intraday_average_open_price intraday_quantity pending_assignment_quantity
        pending_buy_quantity pending_exercise_quantity pending_expiration_quantity pending_expired_quantity
        pending_sell_quantity quantity trade_value_multiplier]
] => (is => 'ro', isa => Num, required => 1);
has [qw[id chain_id]] => (
    is => 'ro',
    isa =>
        StrMatch [
        qr[^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$]i
        ],
    required => 1
);
has chain_symbol => (is => 'ro', isa => Str, required => 1);
has type => (is       => 'ro',
             isa      => Enum [qw[long short]],
             handles  => [qw[is_long is_short]],
             required => 1
);

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
    required => 1
);

sub _test_created_at {
    t::Utility::stash('POSITION') // skip_all('No position object in stash');
    isa_ok(t::Utility::stash('POSITION')->created_at, 'Time::Moment');
}

sub _test_updated_at {
    t::Utility::stash('POSITION') // skip_all('No position object in stash');
    isa_ok(t::Utility::stash('POSITION')->updated_at, 'Time::Moment');
}

=head2 C<contract( )>

Returns the related Finance::Robinhood::Options::Contract object.

=cut

has option => (is       => 'ro',
               isa      => InstanceOf ['URI'],
               coerce   => sub ($url) { URI->new($url) },
               required => 1
);
has contract => (is   => 'ro',
                 isa  => InstanceOf ['Finance::Robinhood::Option::Contract'],
                 lazy => 1,
                 builder => 1
);

sub _build_contract ($s) {
    $s->robinhood->_req(GET => $s->option,
                        as  => 'Finance::Robinhood::Option::Contract');
}

sub _test_contract {
    t::Utility::stash('POSITION') // skip_all('No position object in stash');
    isa_ok(t::Utility::stash('POSITION')->contract,
           'Finance::Robinhood::Options::Contract');
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
    $s->robinhood->options(ids => $s->chain_id);
}

sub _test_chain {
    t::Utility::stash('POSITION') // skip_all('No position object in stash');
    isa_ok(t::Utility::stash('POSITION')->chain,
           'Finance::Robinhood::Options');
}

=head2 C<account( )>

Returns the related Finance::Robinhood::Equity::Account object.

=cut
has _account => (is       => 'ro',
                 isa      => InstanceOf ['URI'],
                 coerce   => sub ($url) { URI->new($url) },
                 required => 1,
                 init_arg => 'account'
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
    t::Utility::stash('POSITION') // skip_all('No position object in stash');
    isa_ok(t::Utility::stash('POSITION')->account,
           'Finance::Robinhood::Equity::Account');
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
