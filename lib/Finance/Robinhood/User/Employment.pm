package Finance::Robinhood::User::Employment;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::User::Employment - Access Basic Data About the Current User

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;
    
    my $user = $rh->user;
    my $info = $user->employment;

    CORE::say 'User is ' . $info->employment_status;

=cut

our $VERSION = '0.92_002';

sub _test__init {
    my $rh   = t::Utility::rh_instance(1);
    my $user = $rh->user;
    isa_ok($user, 'Finance::Robinhood::User');
    t::Utility::stash('USER', $user);    #  Store it for later
    my $basic_info = $user->employment();
    isa_ok($basic_info, __PACKAGE__);
    t::Utility::stash('USER_EMPLOYMENT_INFO', $basic_info);
}
use Mojo::Base-base, -signatures;
use Mojo::URL;
#
use Time::Moment;
#
has _rh => undef => weak => 1;

=head1 METHODS

=head2 C<employer_address( )>

Mailing address box number or street and number.

=head2 C<employer_city( )>

Mailing address city or town.

=head2 C<employer_name( )>

Name of current employer.

=head2 C<employer_state( )>

State code.

=head2 C<employer_zipcode( )>

Mailing address zip code.

=head2 C<employment_status( )>

C<employed>, C<unemployed>, C<retired>, or C<student>.

=head2 C<occupation( )>

Free form occupation.

=head2 C<years_employed( )>

Number of years. This value is static and must be updated by the user.

=cut

has ['employer_address', 'employer_city',
     'employer_name',    'employer_state',
     'employer_zipcode', 'employment_status',
     'occupation',       'years_employed'
];

=head2 C<updated_at( )>

    $user->updated_at();

Returns a Time::Moment object.

=cut

sub updated_at ($s) {
    Time::Moment->from_string($s->{updated_at});
}

sub _test_updated_at {
    t::Utility::stash('USER_EMPLOYMENT_INFO') // skip_all();
    isa_ok(t::Utility::stash('USER_EMPLOYMENT_INFO')->updated_at(),
           'Time::Moment');
}

=head2 C<user( )>

    $order->user();

Reloads the data for this order from the API server.

Use this if you think the status or some other info might have changed.

=cut

sub user($s) {
    my $res = $s->_rh->_get($s->{user});
    $_[0]
        = $res->is_success
        ? Finance::Robinhood::User->new(_rh => $s->_rh, %{$res->json})
        : Finance::Robinhood::Error->new(
             $res->is_server_error ? (details => $res->message) : $res->json);
}

sub _test_user {
    t::Utility::stash('USER_EMPLOYMENT_INFO')
        // skip_all('No additional user data object in stash');
    isa_ok(t::Utility::stash('USER_EMPLOYMENT_INFO')->user(),
           'Finance::Robinhood::User');
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
