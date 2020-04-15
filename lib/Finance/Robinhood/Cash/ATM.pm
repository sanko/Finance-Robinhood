package Finance::Robinhood::Cash::ATM;
our $VERSION = '0.92_003';

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Cash::ATM - Represents an In-Network ATM

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new( ... );
    my $atms = $rh->atms(40.785091, -73.968285);

	CORE::say 'Nearby ATMS:';
    for my $atm ($atms->all) {
        CORE::say join ' ', ' -' . $atm->name, $atm->address, $atm->city;
    }

=cut

use Moo;
use MooX::Enumeration;
use Types::Standard qw[ArrayRef Bool Dict Enum InstanceOf Maybe Num Str StrMatch];
use URI;
use Time::Moment;
use Data::Dump;
use experimental 'signatures';
use Finance::Robinhood::Types qw[:all];
#
sub _test__init {
    my $rh  = t::Utility::rh_instance(1);
    my $ATM = $rh->atm_by_id('2fb3fac0-96ef-4154-830f-21d4b8affbca');
    skip_all('ATM near Central Park is missing? Hmm...') if !defined $ATM;
    isa_ok( $ATM, __PACKAGE__ );
    t::Utility::stash( 'ATM', $ATM );    #  Store it for later
}
use overload '""' => sub ( $s, @ ) { $s->terminal_id }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('ATM') // skip_all();
    is( +t::Utility::stash('ATM'), 'AXD34305', );
}
#
has robinhood => ( is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood'] );

=head1 METHODS

=head2 C<address( )>

The street address.

=head2 C<city( )>

The local city.

=head2 C<country( )>

Nation of location.

=head2 C<deposit_enabled( )>

Returns a boolean value. True if the ATM accepts deposits.

=head2 C<id( )>

Returns a UUID used internally to identify this ATM.

=head2 C<location( )>

Returns a hash reference with the following keys:

=over

=item C<latitude> - Latitude in decimal degrees

=item C<longitude> - Longitude in decimal degrees

=back

Use these values to locate the ATM on a map.

=head2 C<name( )>

Common name of the ATM location. This is usually like a business name.

=head2 C<postal_code()>

Returns the zip code.

=head2 C<state( )>

Returns the US state.

=head2 C<terminal_id( )>

Retusns the terminal id used by banks to identify this ATM.

=head2 C<withdrawal_enabled( )>

Returns a boolean value. True if the ATM is currently able to give out cash.

=cut

has [qw[address city country name state terminal_id]] => ( is => 'ro', isa => Str, required => 1 );
has [qw[deposit_enabled withdrawal_enabled]] =>
    ( is => 'ro', isa => Bool, coerce => 1, required => 1 );
has id       => ( is => 'ro', isa => UUID, required => 1 );
has location => (
    is       => 'ro',
    isa      => Dict [ latitude => Num, longitude => Num ],
    required => 1
);
has postal_code => ( is => 'ro', isa => Num | Str, required => 1 );

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
