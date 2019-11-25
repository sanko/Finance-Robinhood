package Finance::Robinhood::Currency::Portfolio;
our $VERSION = '0.92_003';

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Currency::Portfolio - Represents a Forex Account Portfolio

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new( ... );

    # TODO

=cut

sub _test__init {
    my $rh        = t::Utility::rh_instance(1);
    my $portfoios = $rh->currency_portfolios;
    isa_ok($portfoios->current, __PACKAGE__);
    t::Utility::stash('PORTFOLIO', $portfoios->current); #  Store it for later
}
use Moo;
use MooX::Enumeration;
use Types::Standard
    qw[ArrayRef Bool Dict Enum InstanceOf Maybe Num Str StrMatch];
use experimental 'signatures';
#
use Finance::Robinhood::Types qw[UUID Timestamp];
#
use overload '""' => sub ($s, @) { $s->id }, fallback => 1;
#
sub _test_stringify {
    t::Utility::stash('PORTFOLIO') // skip_all();
    like(+t::Utility::stash('PORTFOLIO'),
         qr[^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$]i);
}
#

=head1 METHODS

=cut
has robinhood =>
    (is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood']);
#

=head2 C<account_id( )>

Returns a UUID.

=head2 C<equity( )>


=head2 C<extended_hours_equity( )>


=head2 C<extended_hours_market_value( )>


=head2 C<id( )>


=head2 C<market_value( )>


=head2 C<previous_close( )>


=head2 C<updated_at( )>

Returns a Time::Moment object.

=cut

has account_id => (is => 'ro', isa => UUID, required => 1);
has equity     => (is => 'ro', isa => Num,  required => 1);
has extended_hours_equity => (is => 'ro', isa => Maybe [Num], required => 1);
has extended_hours_market_value =>
    (is => 'ro', isa => Maybe [Num], required => 1);
has id             => (is => 'ro', isa => UUID, required => 1);
has market_value   => (is => 'ro', isa => Num,  required => 1);
has previous_close => (is => 'ro', isa => Num,  required => 1);
has updated_at => (is => 'ro', isa => Timestamp, coerce => 1, required => 1);

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
