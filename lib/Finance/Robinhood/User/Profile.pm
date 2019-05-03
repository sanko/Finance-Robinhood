package Finance::Robinhood::User::Profile;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::User::Profile - Represents the User's Investment Profile
User

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;
    
    my $user = $rh->user;
    my $info = $user->profile;

    CORE::say 'User is' . ($info->interested_in_options?'':' not') . ' interested in options';

=cut

our $VERSION = '0.92_002';

sub _test__init {
    my $rh   = t::Utility::rh_instance(1);
    my $user = $rh->user;
    isa_ok($user, 'Finance::Robinhood::User');
    t::Utility::stash('USER', $user);    #  Store it for later
    my $profile = $user->profile();
    isa_ok($profile, __PACKAGE__);
    t::Utility::stash('USER_INV_INFO', $profile);
}
use Mojo::Base-base, -signatures;
use Mojo::URL;
#
use Time::Moment;
#
has _rh => undef => weak => 1;

=head1 METHODS

=head2 C<annual_income( )>

One of the following categories:

=over

=item C<0_24999>

=item C<25000_39999>

=item C<40000_49999>

=item C<50000_74999>

=item C<75000_99999>

=item C<100000_199999>

=item C<200000_299999>

=item C<300000_499999>

=item C<500000_1199999>

=item C<1200000_inf>

=back      

=head2 C<interested_in_options( )>

Returns a boolean value.

=head2 C<investment_experience( )>

One of the following options:

=over

=item C<good_investment_exp>

=item C<extensive_investment_exp>

=item C<limited_investment_exp>

=back

=head2 C<investment_experience_collected( )>

Returns a boolean value.

=head2 C<investment_objective( )>

One of the following:

=over

=item C<growth_invest_obj>
      
=item C<income_invest_obj>
      
=item C<other_invest_obj>
      
=item C<cap_preserve_invest_obj>

=item C<speculation_invest_obj>

=back

=head2 C<liquid_net_worth( )>

One of the following:

=over

=item C<0_24999>

=item C<25000_39999>

=item C<40000_49999>

=item C<50000_99999>

=item C<100000_199999>

=item C<200000_249999>

=item C<250000_499999>

=item C<500000_999999>

=item C<1000000_4999999>

=item C<5000000_inf>

=item C<1000000_inf>

=back

=head2 C<liquidity_needs( )>

One of the following:

=over

=item C<not_important_liq_need>

=item C<somewhat_important_liq_need>

=item C<very_important_liq_need>

=back

=head2 C<option_trading_experience( )>

One of the following:

=over

=item C<no_option_exp>

=item C<one_to_two_years_option_exp>

=item C<three_years_plus_option_exp>

=back      

=head2 C<professional_trader( )>

Returns a boolean value. True if the user is a paid professional.

=head2 C<risk_tolerance( )>

One of the following:

=over

=item C<high_risk_toleranceL>

=item C<med_risk_tolerance>

=item C<low_risk_tolerance>

=back 

=head2 C<source_of_funds( )>

One of the following:

=over

=item C<gift>

=item C<inheritance>

=item C<insurance_payout>

=item C<savings_personal_income>

=item C<sale_business_or_property>

=item C<pension_retirement>

=item C<other>

=back

=head2 C<suitability_verified( )>

Returns a boolean value.

=head2 C<tax_bracket( )>

One of the following:

=over

=item C<10_pct>

=item C<20_pct>

=item C<25_pct>

=item C<28_pct>

=item C<33_pct>
      
=item C<35_pct>
      
=item C<39_6_pct>

=back

=head2 C<time_horizon( )>

One of the following:

=over

=item C<long_time_horizon>

=item C<med_time_horizon>
      
=item C<short_time_horizon>

=back

=head2 C<total_net_worth( )>

One of the following:

=over

=item C<0_24999>

=item C<25000_49999>

=item C<50000_64999>

=item C<65000_99999>
      
=item C<1000000_4999999>
      
=item C<100000_149999>
      
=item C<150000_199999>
      
=item C<200000_249999>
      
=item C<250000_499999>
      
=item C<500000_999999>
      
=item C<1000000_inf>

=item C<5000000_inf>

=back

=head2 C<understand_option_spreads( )>

Returns a boolean value.

=cut

has ['annual_income',                   'interested_in_options',
     'investment_experience_collected', 'investment_experience_collected',
     'investment_objective',            'liquid_net_worth',
     'liquidity_needs',                 'option_trading_experience',
     'professional_trader',             'risk_tolerance',
     'source_of_funds',                 'suitability_verified',
     'tax_bracket',                     'time_horizon',
     'total_net_worth',                 'understand_option_spreads'
];

=head2 C<updated_at( )>

    $user->updated_at();

Returns a Time::Moment object.

=cut

sub updated_at ($s) {
    Time::Moment->from_string($s->{updated_at});
}

sub _test_updated_at {
    t::Utility::stash('USER_INV_INFO') // skip_all();
    isa_ok(t::Utility::stash('USER_INV_INFO')->updated_at(), 'Time::Moment');
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
    t::Utility::stash('USER_INV_INFO')
        // skip_all('No user id data object in stash');
    isa_ok(t::Utility::stash('USER_INV_INFO')->user(),
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
