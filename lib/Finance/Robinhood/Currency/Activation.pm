package Finance::Robinhood::Currency::Activation;
our $VERSION = '0.92_003';

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Currency::Activation - Represents a Forex Account
Activation

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new( ... );

    # TODO

=cut

sub _test__init {
    my $rh         = t::Utility::rh_instance(1);
    my $activation = $rh->currency_activations->current;
    isa_ok( $activation, __PACKAGE__ );
    t::Utility::stash( 'ACTIVATION', $activation );    #  Store it for later
}
use Moo;
use MooX::Enumeration;
use Types::Standard qw[ArrayRef Bool Dict Enum InstanceOf Maybe Num Str StrMatch];
use experimental 'signatures';
#
use Finance::Robinhood::Types qw[URL UUID Timestamp];
#
use overload '""' => sub ( $s, @ ) { $s->id }, fallback => 1;
#
sub _test_stringify {
    t::Utility::stash('ACTIVATION') // skip_all();
    like(
        +t::Utility::stash('ACTIVATION'),
        qr[^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$]i
    );
}
#

=head1 METHODS

=cut

has robinhood => ( is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood'] );

=head2 C<created_at( )>

Returns a Time::Moment object.

=head2 C<updated_at( )>

Returns a Time::Moment object.

=cut

has [qw[created_at updated_at]] => ( is => 'ro', isa => Timestamp, coerce => 1, required => 1 );

=head2 C<email( )>

Returns the address used to activate.

=cut

has email => ( is => 'ro', isa => StrMatch [qr[^\w+\@\w+\.\w+$]], required => 1 );

=head2 C<external_rejection_code( )>

Returns one of the following:

=over

=item C<equities_account_deactivated>

=item C<ineligible_jurisdiction1>

=item C<ineligible_jurisdiction2>

=item C<ineligible_jurisdiction3>

=item C<user_information_mismatch>

=item C<no_equities_account>

=item C<other>

=item C<unsuitable>

=back

=cut

has external_rejection_code => (
    is  => 'ro',
    isa => Maybe [
        Enum [
            qw[
                equities_account_deactivated
                ineligible_jurisdiction1
                ineligible_jurisdiction2
                ineligible_jurisdiction3
                user_information_mismatch
                no_equities_account
                other
                unsuitable
                ]
        ]
    ],
    required => 1,
    handles  => [
        qw[
            is_equities_account_deactivated
            is_ineligible_jurisdiction1
            is_ineligible_jurisdiction2
            is_ineligible_jurisdiction3
            is_user_information_mismatch
            is_no_equities_account
            is_unsuitable
            ]
    ]
);

=head2 C<external_rejection_reason( )>

If defined, this returns a string.

=cut

has external_rejection_reason => ( is => 'ro', isa => Maybe [Str], required => 1 );

=head2 C<external_status_code( )>


=cut

has external_status_code => (
    is  => 'ro',
    isa => Enum [
        qw[equities_account_deactivated
            ineligible_jurisdiction1
            ineligible_jurisdiction2
            ineligible_jurisdiction3
            user_information_mismatch
            no_equities_account
            other
            unsuitable]
    ],
    required => 1
);

=head2 C<first_name( )>

Legal first name.

=cut

has first_name => ( is => 'ro', isa => Str, required => 1 );

=head2 C<id( )>

Returns a UUID.

=cut

has id => ( is => 'ro', isa => UUID, required => 1 );

=head2 C<last_name( )>

Legal last name.

=cut

has last_name => ( is => 'ro', isa => Str, required => 1 );

=head2 C<speculative( )>

Returns true if the resultant account will be for speculative trading only.

=cut

has speculative => ( is => 'ro', isa => Bool, coerce => 1, required => 1 );

=head2 C<state( )>

Returns C<approved>, C<rejected>, or C<in_review>.

=head2 C<is_approved( )>

Returns a boolean value. True if C<state( )> is C<approved>.

=head2 C<is_rejected( )>

Returns a boolean value. True if C<state( )> is C<rejected>.

=head2 C<is_in_review( )>

Returns a boolean value. True if C<state( )> is C<in_review>.

=cut

has state => (
    is       => 'ro',
    isa      => Enum [qw[approved rejected in_review]],
    required => 1,
    handles  => [qw[is_approved is_rejected is_in_review]]
);

=head2 C<type( )>

Returns C<new_account> or C<reactivating>.

=head2 C<is_new_account( )>

Returns a boolean value. True if C<type( )> is C<new_account>.

=head2 C<is_reactivated( )>

Returns a boolean value. True if C<type( )> is C<is_reactivated>.

=cut

has type => (
    is       => 'ro',
    isa      => Enum [qw[new_account reactivation]],
    required => 1,
    handles  => [qw[is_new_account is_reactivation]]
);

=head2 C<user_id( )>

Returns a UUID.

=cut

has user_id => ( is => 'ro', isa => UUID, required => 1 );

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
