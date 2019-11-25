package Finance::Robinhood::Currency::Halt;
our $VERSION = '0.92_003';

=encoding utf-8

=for stopwords watchlist watchlists untradable urls forex

=head1 NAME

Finance::Robinhood::Forex::Halt - Represents a Single Forex/Crypto Trade Halt

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;

    # TODO

=cut

use Moo;
use Data::Dump;
use HTTP::Tiny;
use JSON::Tiny;
use Types::Standard qw[Any Bool Dict Enum InstanceOf Num Str Maybe];
use URI;
use experimental 'signatures';
#
use Finance::Robinhood::Currency;
use Finance::Robinhood::Types qw[Timestamp UUID];
#
sub _test__init {
    my $rh = t::Utility::rh_instance(1);
    my $halt
        = $rh->currency_halt_by_id('cb4bf195-6949-41a5-bb0a-f97cfcb5f908');
    isa_ok($halt, __PACKAGE__);
    t::Utility::stash('HALT', $halt);    #  Store it for later
}
use overload '""' => sub ($s, @) { $s->id }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('HALT') // skip_all();
    like(+t::Utility::stash('HALT'),
         qr'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'i
    );
}
#
has robinhood =>
    (is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood']);

=head1 METHODS

=head2 C<active( )>

Returns a boolean value which indicates whether or not this halt is currently
active.

=head2 C<pair_id( )>

Returns the currency pair ID if it exitsts.

=head2 C<currency_pair( )>

If the currency pair is defined, this will return the related
Finance::Robinhod::Currency::Pair object.

=head2 C<end_at( )>

Returns a Time::Moment object if defined.

=head2 C<id( )>

Returns a UUID.

=head2 C<reason( )>

If defined, this returns a text string suited for display.

=head2 C<reason_code( )>

One of the following: C<outage>, C<scheduled_maintenance>, or C<other>.

=head2 C<start_at( )>

Returns a Time::Moment object.

=head2 C<state( )>

One of the following: C<queued>, C<full>, C<sell_only>, and C<buy_only>.

=cut

has active => (is => 'ro', isa => Bool, required => 1, coerce => 1);
has pair_id => (is        => 'ro',
                isa       => Maybe [UUID],
                requried  => 1,
                init_arg  => 'currency_pair_id',
                predicate => 1
);
has [qw[end_at start_at]] => (is        => 'ro',
                              isa       => Maybe [Timestamp],
                              required  => 1,
                              coerce    => 1,
                              predicate => 1
);
has id => (is => 'ro', isa => UUID, requried => 1);
has reason => (is => 'ro', isa => Maybe [Str], required => 1);
has reason_code => (is       => 'ro',
                    isa      => Enum [qw[outage scheduled_maintenance other]],
                    required => 1
);
has state => (is       => 'ro',
              isa      => Enum [qw[queued full sell_only buy_only]],
              required => 1
);
has currency_pair => (
             is  => 'ro',
             isa => Maybe [InstanceOf ['Finance::Robinhood::Currency::Pair']],
             builder  => 1,
             lazy     => 1,
             init_arg => undef
);

sub _build_currency_pair ($s) {
    $s->has_pair_id ? $s->robinhood->currency_pair_by_id($s->pair_id) : ();
}

sub _test_start_at {
    t::Utility::stash('HALT') // skip_all();
    t::Utility::stash('HALT')->start_at // skip_all();
    isa_ok(t::Utility::stash('HALT')->start_at, 'Time::Moment');
}

sub _test_end_at {
    t::Utility::stash('HALT') // skip_all();
    t::Utility::stash('HALT')->end_at // skip_all();
    isa_ok(t::Utility::stash('HALT')->end_at, 'Time::Moment');
}

sub _test_currency_pair {
    t::Utility::stash('HALT') // skip_all();
    use Data::Dump;
    ddx t::Utility::stash('HALT');

    #id          => "cb4bf195-6949-41a5-bb0a-f97cfcb5f908",
    #       pair_id     => "086a8f9f-6c39-43fa-ac9f-57952f4a1ba6",
    isa_ok(t::Utility::stash('HALT')->currency_pair,
           'Finance::Robinhood::Currency::Pair');
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
