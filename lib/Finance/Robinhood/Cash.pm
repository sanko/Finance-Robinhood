package Finance::Robinhood::Cash;
our $VERSION = '0.92_003';

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Cash - Represents an Cash Management Account

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;
    my $accounts = $rh->cash_accounts();

    # TODO

=cut

use Moo;
use MooX::Enumeration;
use Types::Standard
    qw[ArrayRef Bool Dict Enum InstanceOf Maybe Num Str StrMatch];
use URI;
use Time::Moment;
use Data::Dump;
use experimental 'signatures';
use Finance::Robinhood::Types qw[:all];
#
sub _test__init {
    my $rh      = t::Utility::rh_instance(1);
    my $account = $rh->cash_accounts->current;
    skip_all('No cash management accounts found') if !defined $account;
    isa_ok($account, __PACKAGE__);
    t::Utility::stash('ACCOUNT', $account);    #  Store it for later
}
use overload '""' => sub ($s, @) { $s->id }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('ACCOUNT') // skip_all();
    like(+t::Utility::stash('ACCOUNT'),
         qr'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'i
    );
}
#
has robinhood =>
    (is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood']);

=head1 METHODS


=head2 C<account_number( )>

Your actual bank account number.

=head2 C<account_type( )>

Returns either C<brokerage> or C<unknown>.

=head2 C<is_brokerage( )>

Returns a boolean value. True if C<account_type( )> is C<brokerage>.

=head2 C<created_at( )>

Returns a Time::Moment object.

=head2 C<default_card_id( )>

Returns a UUID.

=head2 C<enrollment_state( )>

Returns C<upgrade_requested>, C<upgraded>, C<downgrade_requested>,
C<downgraded>, or C<unknown>.

=head2 C<is_upgrade_requested( )>

Returns a boolean value. True if C<enrollment_state( )> is C<update_requested>.

=head2 C<is_upgraded( )>

Returns a boolean value. True if C<enrollment_state( )> is C<upgraded>.

=head2 C<is_downgrade_requested( )>

Returns a boolean value. True if C<enrollment_state( )> is
C<downgrade_requested>.

=head2 C<is_downgraded( )>

Returns a boolean value. True if C<enrollment_state( )> is C<downgraded>.

=head2 C<is_active( )>

Returns a boolean value. True if C<enrollment_state( )> is C<upgraded> or
C<downgrade_requested>.

=head2 C<location_protection_enabled( )>

Returns a boolean value.

=head2 C<id( )>

Returns a UUID.

=cut

has account_number => (is => 'ro', isa => Num, requried => 1);
has account_type => (is       => 'ro',
                     isa      => Enum [qw[brokerage unknown]],
                     handles  => [qw[is_brokerage]],
                     required => 1
);
has created_at => (is => 'ro', isa => Timestamp, coerce => 1, required => 1);
has [qw[default_card_id id]] => (is => 'ro', isa => UUID, required => 1);
has enrollment_state => (
    is  => 'ro',
    isa => Enum [
         qw[upgrade_requested upgraded downgrade_requested downgraded unknown]
    ],
    handles => [
        qw[is_upgrade_requested is_upgraded is_downgrade_requested is_downgraded]
    ]
);
has is_active => (
    is      => 'ro',
    isa     => Bool,
    builder => sub ($s) {
        $s->is_upgraded || $s->is_downgrade_requested;
    }
);
has location_protection_enabled =>
    (is => 'ro', isa => Bool, coerce => 1, required => 1);

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
