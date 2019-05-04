package Finance::Robinhood::User::InternationalInfo;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::User::InternationalInfo - Access Account Information
Related to a non-US Citizen User

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;
    
    my $user = $rh->user;
    my $info = $user->international_info;

    CORE::say 'User was born in : ' . $info->birthCountry;

=cut

our $VERSION = '0.92_003';

sub _test__init {
    my $rh   = t::Utility::rh_instance(1);
    my $user = $rh->user;
    isa_ok($user, 'Finance::Robinhood::User');
    t::Utility::stash('USER', $user);    #  Store it for later
    my $intl_info = $user->international_info();
    todo(                                # Might fail
        'International data only available to non-US citizens' => sub {
            isa_ok($ntl_info, __PACKAGE__);
            t::Utility::stash('USER_INTL_INFO', $intl_info) if $intl_info;
        }
    );
}
use Mojo::Base-base, -signatures;
use Mojo::URL;
#
use Time::Moment;
#
has _rh => undef => weak => 1;

=head1 METHODS

=head2 C<birthCountry( )>

User's nation of origin.

=head2 C<businessNature( )>

User's line of work and reason for being in the US on a Visa.

=head2 C<expectedWithdrawals( )>

How often is the user expecting to make withdraws from Robinhood back to their
account. This is required for taxation and withholding.

Proper values include C<frequent>, C<occasional>, and C<rare>.

=head2 C<foreignTaxId( )>

User's tax id in their home country.

=head2 C<howReferredToBroker( )>

How was the user referred to Robinhood.

=head2 C<initialDepositType( )>

This would typically be ACH but wire transfers are also possible.

=head2 C<primaryBanking( )>

User's primary bank in the US.

=head2 C<valueInitialDeposit( )>

How large was the user's initial deposit.

=head2 C<withdrawalsAllowed>

Returns a true value if the user is allowed to withdrawal funds via ACH.

=cut

has ['birthCountry',        'businessNature',
     'expectedWithdrawals', 'foreignTaxId',
     'howReferredToBroker', 'initialDepositType',
     'primaryBanking',      'valueInitialDeposit',
     'withdrawalsAllowed'
];

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
