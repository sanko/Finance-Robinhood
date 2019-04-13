package Finance::Robinhood::Forex::Activation;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Forex::Activation - Represents a Single Forex Account
Application

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;

    # TODO

=cut

our $VERSION = '0.92_002';
use Mojo::Base-base, -signatures;
use Mojo::URL;

sub _test__init {
    my $rh  = t::Utility::rh_instance(1);
    my $act = $rh->forex_activations->current;
    isa_ok( $act, __PACKAGE__ );
    t::Utility::stash( 'ACTIVATION', $act );    #  Store it for later
}
use overload '""' => sub ( $s, @ ) { $s->{id} }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('ACTIVATION') // skip_all();
    like(
        +t::Utility::stash('ACTIVATION'),
        qr'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'i
    );
}
#
has _rh => undef => weak => 1;

=head1 METHODS
 
=head2 C<created_at( )>

Returns a Time::Moment object.

=head2 C<email( )>

The email address used to apply for a forex account.

=head2 C<external_rejection_code( )>

Reason why the account may have been (or should be) rejected. Will return one
of the following, if applicable:

=over

=item C<equities_account_deactivated>

=item C<ineligible_jurisdiction>

=item C<ineligible_jurisdiction2>

=item C<ineligible_jurisdiction3>

=item C<user_information_mismatch>

=item C<no_equities_account>

=item C<other>

=item C<unsuitable>

=back

=head2 C<external_rejection_reason( )>

If given, this is a string with a specific reason why the application to
activate an account was rejected.

=head2 C<external_status_code( )>

Same options as C<external_rejection_code( )>.

=head2 C<first_name( )>

The first name of the account holder.

=head2 C<id( )>

UUID of the activation attempt.

=head2 C<last_name( )>

The last name of the account holder.

=head2 C<speculative( )>

Boolean value.

=head2 C<state( )>

One of the following:

=over

=item C<approved>

=item C<rejected>

=item C<in_review>

=back

=head2 C<type( )>

The type of account being applied for. May be one of the following:

=over

=item C<new_account>

=item C<reactivation>

=back

=head2 C<user_id( )>

Returns a UUID.

=cut

has [
    'email', 'external_rejection_code', 'external_rejection_reason', 'external_status_code',
    'first_name', 'id', 'last_name', 'speculative', 'state', 'type', 'user_id'
];

=head2 C<created_at( )>

Returns a Time::Moment object.

=cut

sub created_at ($s) {
    Time::Moment->from_string( $s->{created_at} );
}

sub _test_created_at {
    t::Utility::stash('ACTIVATION') // skip_all();
    isa_ok( t::Utility::stash('ACTIVATION')->created_at, 'Time::Moment' );
}

=head2 C<updated_at( )>

Returns a Time::Moment object.

=cut

sub updated_at ($s) {
    Time::Moment->from_string( $s->{updated_at} );
}

sub _test_updated_at {
    t::Utility::stash('ACTIVATION') // skip_all();
    isa_ok( t::Utility::stash('ACTIVATION')->updated_at, 'Time::Moment' );
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
