package Finance::Robinhood::User;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::User - Represents a Single Authorized User

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;
    
    my $user = $rh->user();
    CORE::say $user->first_name . ' ' . $user->last_name;

=cut

our $VERSION = '0.92_002';

sub _test__init {
    my $rh   = t::Utility::rh_instance(1);
    my $user = $rh->user;
    isa_ok($user, __PACKAGE__);
    t::Utility::stash('USER', $user);    #  Store it for later
}
use Mojo::Base-base, -signatures;
use Mojo::URL;
#
use Time::Moment;
use Finance::Robinhood::User::AdditionalInfo;
use Finance::Robinhood::User::BasicInfo;
use Finance::Robinhood::User::Employment;
use Finance::Robinhood::User::IDInfo;
use Finance::Robinhood::User::InternationalInfo;
use Finance::Robinhood::User::Profile;
#
has _rh => undef => weak => 1;

=head1 METHODS

=head2 C<email( )>

Email address attached to the account.

=head2 C<email_verified( )>

Returns true if the email has been verified.

=head2 C<id( )>

UUID used to represent this user.

=head2 C<first_name( )>

Legal first name of the account's owner.

=head2 C<last_name( )>

Legal last name of the account's owner.

=head2 C<username( )>

The username used to log in to the account.

=cut

has ['email', 'email_verified', 'first_name', 'last_name', 'id', 'username'];

=head2 C<additional_info( )>

    $user->additional_info();

Returns a Finance::Robinhood::User::AdditionalInfo object.

=cut

sub additional_info($s) {
    my $res = $s->_rh->_get($s->{additional_info});
    $_[0] = $res->is_success
        ? Finance::Robinhood::User::AdditionalInfo->new(_rh => $s->_rh,
                                                        %{$res->json})
        : Finance::Robinhood::Error->new(
             $res->is_server_error ? (details => $res->message) : $res->json);
}

sub _test_additional_info {
    t::Utility::stash('USER') // skip_all('No user object in stash');
    isa_ok(t::Utility::stash('USER')->additional_info,
           'Finance::Robinhood::User::AdditionalInfo');
}

=head2 C<basic_info( )>

    $user->basic_info();

Returns a Finance::Robinhood::User::BasicInfo object.

=cut

sub basic_info($s) {
    my $res = $s->_rh->_get($s->{basic_info});
    $_[0] = $res->is_success
        ? Finance::Robinhood::User::BasicInfo->new(_rh => $s->_rh,
                                                   %{$res->json})
        : Finance::Robinhood::Error->new(
             $res->is_server_error ? (details => $res->message) : $res->json);
}

sub _test_basic_info {
    t::Utility::stash('USER') // skip_all('No user object in stash');
    isa_ok(t::Utility::stash('USER')->basic_info,
           'Finance::Robinhood::User::BasicInfo');
}

=head2 C<created_at( )>

    $user->created_at();

Returns a Time::Moment object.

=cut

sub created_at ($s) {
    Time::Moment->from_string($s->{created_at});
}

sub _test_created_at {
    t::Utility::stash('USER') // skip_all();
    isa_ok(t::Utility::stash('USER')->created_at(), 'Time::Moment');
}

=head2 C<employment( )>

    $user->employment();

Returns a Finance::Robinhood::User::Employment object.

=cut

sub employment($s) {
    my $res = $s->_rh->_get($s->{employment});
    $_[0] = $res->is_success
        ? Finance::Robinhood::User::Employment->new(_rh => $s->_rh,
                                                    %{$res->json})
        : Finance::Robinhood::Error->new(
             $res->is_server_error ? (details => $res->message) : $res->json);
}

sub _test_employment {
    t::Utility::stash('USER') // skip_all('No user object in stash');
    isa_ok(t::Utility::stash('USER')->employment,
           'Finance::Robinhood::User::Employment');
}

=head2 C<id_info( )>

    $user->id_info();

Returns a Finance::Robinhood::User::IDInfo object.

=cut

sub id_info($s) {
    my $res = $s->_rh->_get($s->{id_info});
    $_[0]
        = $res->is_success
        ? Finance::Robinhood::User::IDInfo->new(_rh => $s->_rh, %{$res->json})
        : Finance::Robinhood::Error->new(
             $res->is_server_error ? (details => $res->message) : $res->json);
}

sub _test_id_info {
    t::Utility::stash('USER') // skip_all('No user object in stash');
    isa_ok(t::Utility::stash('USER')->id_info,
           'Finance::Robinhood::User::IDInfo');
}

=head2 C<international_info( )>

    $user->international_info();

Returns a Finance::Robinhood::User::InternationalInfo object if the user is a
non-US citizen.

=cut

sub international_info($s) {
    my $res = $s->_rh->_get($s->{international_info});
    $_[0] = $res->is_success
        ? Finance::Robinhood::User::InternationalInfo->new(_rh => $s->_rh,
                                                           %{$res->json})
        : Finance::Robinhood::Error->new(
             $res->is_server_error ? (details => $res->message) : $res->json);
}

sub _test_international_info {
    t::Utility::stash('USER') // skip_all('No user object in stash');
    todo(
        'As a US citizen, this will fail for me' => sub {
            isa_ok(t::Utility::stash('USER')->international_info,
                   'Finance::Robinhood::User::InternationalInfo');
        }
    );
}

=head2 C<profile( )>

    $user->profile();

Returns a Finance::Robinhood::User::Profile object.

=cut

sub profile($s) {
    my $res = $s->_rh->_get($s->{investment_profile});
    $_[0]
        = $res->is_success
        ? Finance::Robinhood::User::Profile->new(_rh => $s->_rh,
                                                 %{$res->json})
        : Finance::Robinhood::Error->new(
             $res->is_server_error ? (details => $res->message) : $res->json);
}

sub _test_profile {
    t::Utility::stash('USER') // skip_all('No user object in stash');
    todo(
        'As a US citizen, this will fail for me' => sub {
            isa_ok(t::Utility::stash('USER')->profile,
                   'Finance::Robinhood::User::Profile');
        }
    );
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
