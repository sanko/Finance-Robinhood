package Finance::Robinhood::Forex::Halt;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Forex::Halt - Represents a Single Forex/Crypto Trade Halt

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;

    # TODO

=cut

our $VERSION = '0.92_002';
use Mojo::Base-base, -signatures;
use Mojo::URL;
use Time::Moment;

sub _test__init {
    my $rh   = t::Utility::rh_instance(1);
    my $halt = $rh->forex_halts->current;
    isa_ok($halt, __PACKAGE__);
    t::Utility::stash('HALT', $halt);    #  Store it for later
}
use overload '""' => sub ($s, @) { $s->{id} }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('HALT') // skip_all();
    like(+t::Utility::stash('HALT'),
         qr'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'i
    );
}
#
has _rh => undef => weak => 1;

=head1 METHODS

=head2 C<active( )>

Returns a boolean value which indicates whether or not this halt is currently
active.

=head2 C<pair_id( )>


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

has ['active', 'pair_id', 'id', 'reason', 'reason_code', 'state'];

sub start_at ($s) {
    Time::Moment->from_string($s->{start_at});
}

sub _test_start_at {
    t::Utility::stash('HALT') // skip_all();
    isa_ok(t::Utility::stash('HALT')->start_at, 'Time::Moment');
}

sub end_at ($s) {
    $s->{end_at} // return ();
    Time::Moment->from_string($s->{end_at});
}

sub _test_end_at {
    t::Utility::stash('HALT') // skip_all();
    isa_ok(t::Utility::stash('HALT')->end_at, 'Time::Moment');
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
