package Finance::Robinhood::User;
our $VERSION = '0.92_003';

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

sub _test__init {
    my $rh   = t::Utility::rh_instance(1);
    my $user = $rh->user;
    isa_ok( $user, __PACKAGE__ );
    t::Utility::stash( 'USER', $user );    #  Store it for later
}
#
use Moo;
use MooX::Enumeration;
use Types::Standard qw[Any Overload ArrayRef Bool Dict Enum InstanceOf Maybe Num Str StrMatch];
use URI;
use Time::Moment;
use Data::Dump;
use experimental 'signatures';
use Finance::Robinhood::Types qw[UUID Timestamp URL];
#
#use Finance::Robinhood::User::AdditionalInfo;
#use Finance::Robinhood::User::BasicInfo;
#use Finance::Robinhood::User::Employment;
#use Finance::Robinhood::User::IDInfo;
#use Finance::Robinhood::User::InternationalInfo;
#use Finance::Robinhood::User::Profile;
#
has robinhood => ( is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood'] );

=head1 METHODS



=head2 C<created_at( )>

    $user->created_at();

Returns a Time::Moment object.

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

=head2 C<origin( )>

Returns the user's nation of origin.

=head2 C<profile_name( )>

If defined, this returns a string.

=cut

has created_at => ( is => 'ro', isa => Timestamp, coerce => 1, required => 1 );
has email          => ( is => 'ro', isa => StrMatch [qr[^\w+\@\w+\.\w+$]], requried => 1 );
has email_verified => ( is => 'ro', isa => Bool, coerce => sub ($bool) { !!$bool }, required => 1 );
has [qw[first_name last_name username]] => ( is => 'ro', isa => Str,  required => 1 );
has id                                  => ( is => 'ro', isa => UUID, required => 1 );
has profile_name => ( is => 'ro', isa => Maybe [Str], required => 1 );

# The url from id_info no longer seems to be working
has '_' . $_ => ( is => 'ro', isa => URL, coerce => 1, required => 1, init_arg => $_ )
    for qw[id_info url];
has origin => ( is => 'ro', isa => Dict [ locality => Str ], required => 1 );

=begin :broken

=head2 C<id_info( )>

    $user->id_info();

Returns a hash reference.

 =cut

has id_info => ( is => 'ro', isa => Maybe[Dict[

]], lazy=> 1, coerce => 1, init_arg => undef, predicate => 1 ); sub
_build_id_info($s) {    $s->robinhood->_req( GET => $s->_id_info ); }

sub _test_id_info {     t::Utility::stash('USER') // skip_all('No user object
in stash');     ref_ok( t::Utility::stash('USER')->id_info, 'HASH' ); }

=end :broken

=head2 C<additional_info( )>

    $user->additional_info();

Returns an object with the following methods:

=over

=item C<agreed_to_rhs( )> - Boolean value

=item C<agreed_to_rhs_margin( )> - Boolean value

=item C<control_person( )> - Boolean

=item C<control_person_security_symbol( )> - Ticker symbol

=item C<object_to_disclosure( )> - Boolean

=item C<security_affiliated_address( )>

=item C<security_affiliated_address_subject( )>

=item C<security_affiliated_employee( )> - True value if the user works for a public company

=item C<security_affiliated_firm_name( )> - Name of the public firm

=item C<security_affiliated_firm_relationship( )>

=item C<security_affiliated_person_name( )>

=item C<security_affiliated_requires_duplicates( )>

=item C<stock_loan_consent_status( )>

=over

=item C<consented>

=item C<needs_response>

=item C<did_not_consent>

=back

=item C<sweep_consent( )> - Boolean value

=item C<updated_at( )> - Time::Moment object

=back

=cut
{
    package    # Hide it!
        Finance::Robinhood::User::AdditionalInfo;
    use Moo;
    use MooX::Enumeration;
    use Types::Standard qw[Any Overload ArrayRef Bool Dict Enum InstanceOf Maybe Num Str StrMatch];
    use URI;
    use Time::Moment;
    use Data::Dump;
    use experimental 'signatures';
    use Finance::Robinhood::Types qw[UUID Timestamp URL];
    #
    has robinhood => ( is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood'] );
    #
    has [
        qw[agreed_to_rhs agreed_to_rhs_margin control_person object_to_disclosure
            security_affiliated_employee security_affiliated_requires_duplicates
            sweep_consent
            ]
    ] => ( is => 'ro', isa => Maybe [Bool], coerce => 1, required => 1 );
    has [
        qw[control_person_security_symbol security_affiliated_address
            security_affiliated_address_subject
            security_affiliated_firm_name
            security_affiliated_firm_relationship security_affiliated_person_name
            ]
    ] => ( is => 'ro', isa => Maybe [Str], required => 1 );
    has stock_loan_consent_status =>
        ( is => 'ro', isa => Enum [qw[consented needs_response did_not_consent]] );
    has updated_at => ( is => 'ro', isa => Timestamp, coerce => 1, required => 1 );

    # malformed! Robinhood forgets the https:// on this URL
    has _user => ( is => 'ro', isa => URL, coerce => 1, required => 1, init_arg => 'user' );
    has user  => (
        is       => 'ro',
        isa      => InstanceOf ['Finance::Robinhood::User'],
        builder  => 1,
        lazy     => 1,
        init_arg => undef
    );

    sub _build_user($s) {
        $s->robinhood->_req( GET => 'https://api.robinhood.com/user/' )
            ->as('Finance::Robinhood::User');
    }
};
has additional_info => (
    is       => 'ro',
    isa      => InstanceOf ['Finance::Robinhood::User::AdditionalInfo'],
    builder  => 1,
    lazy     => 1,
    init_arg => undef
);

sub _build_additional_info($s) {
    $s->robinhood->_req( GET => 'https://api.robinhood.com/user/additional_info/' )
        ->as('Finance::Robinhood::User::AdditionalInfo');
}

sub _test_additional_info {
    t::Utility::stash('USER') // skip_all('No user object in stash');
    isa_ok( t::Utility::stash('USER')->additional_info,
        'Finance::Robinhood::User::AdditionalInfo' );
    isa_ok( t::Utility::stash('USER')->additional_info->updated_at, 'Time::Moment' );
}

=head2 C<basic_info( )>

    $user->basic_info();

Returns an object with the follwoing methods:

=over

=item C<address( )>

=item C<citizenship( )>

=item C<city( )>

=item C<country_of_residence( )>

=item C<date_of_birth> Date as YYYY-MM-DD

=item C<marital_status( )> - C<single>, C<married>, C<divorced>, or C<widowed>

=item C<number_dependents( )>

=item C<phone_number( )>

=item C<signup_as_rhs( )> - Boolean

=item C<state( )>

=item C<tax_id_ssn( )> - Last 4 digits of the user's SSN or Tax Id

=item C<updated_at( )> - Time::Moment ojbect

=item C<zipcode( )>

=back

=cut

{
    package    # Hide it!
        Finance::Robinhood::User::BasicInfo;
    use Moo;
    use MooX::Enumeration;
    use Types::Standard qw[Any Overload ArrayRef Bool Dict Enum InstanceOf Maybe Num Str StrMatch];
    use URI;
    use Time::Moment;
    use Data::Dump;
    use experimental 'signatures';
    use Finance::Robinhood::Types qw[UUID Timestamp URL];
    #
    has robinhood => ( is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood'] );
    #
    has [qw[address citizenship city country_of_residence state]] =>
        ( is => 'ro', isa => Str, required => 1 );
    has [qw[number_dependents phone_number tax_id_ssn zipcode]] =>
        ( is => 'ro', isa => Num, required => 1 );
    has date_of_birth => ( is => 'ro', isa => StrMatch [qr[^\d\d\d\d-\d\d-\d\d$]], required => 1 );
    has marital_status =>
        ( is => 'ro', isa => Enum [ qw[single married divorced widowed], '' ], required => 1 );
    has signup_as_rhs => ( is => 'ro', isa => Bool,      coerce => 1, required => 1 );
    has updated_at    => ( is => 'ro', isa => Timestamp, coerce => 1, required => 1 );

    # malformed! Robinhood forgets the https:// on this URL
    has _user => ( is => 'ro', isa => URL, coerce => 1, required => 1, init_arg => 'user' );
    has user  => (
        is       => 'ro',
        isa      => InstanceOf ['Finance::Robinhood::User'],
        builder  => 1,
        lazy     => 1,
        init_arg => undef
    );

    sub _build_user($s) {
        $s->robinhood->_req( GET => 'https://api.robinhood.com/user/' )
            ->as('Finance::Robinhood::User');
    }
};
has basic_info => (
    is       => 'ro',
    isa      => InstanceOf ['Finance::Robinhood::User::BasicInfo'],
    builder  => 1,
    lazy     => 1,
    coerce   => 1,
    init_arg => undef
);

sub _build_basic_info($s) {
    $s->robinhood->_req( GET => 'https://api.robinhood.com/user/basic_info/' )
        ->as('Finance::Robinhood::User::BasicInfo');
}

sub _test_basic_info {
    t::Utility::stash('USER') // skip_all('No user object in stash');
    isa_ok( t::Utility::stash('USER')->basic_info, 'Finance::Robinhood::User::BasicInfo' );
    isa_ok( t::Utility::stash('USER')->basic_info->updated_at, 'Time::Moment' );
}

=head2 C<employment( )>

    $user->employment();

Returns an object with the following methods:

=over

=item C<employer_address( )>

=item C<employer_city( )>

=item C<employer_name( )>

=item C<employer_state( )>

=item C<employer_zipcode( )>

=item C<employment_status( )>

=item C<occupation( )>

=item C<updated_at( )>

=item C<years_employed( )>

=back

=cut

{
    package    # Hide it!
        Finance::Robinhood::User::Employment;
    use Moo;
    use MooX::Enumeration;
    use Types::Standard qw[Any Overload ArrayRef Bool Dict Enum InstanceOf Maybe Num Str StrMatch];
    use URI;
    use Time::Moment;
    use Data::Dump;
    use experimental 'signatures';
    use Finance::Robinhood::Types qw[UUID Timestamp URL];
    #
    has robinhood => ( is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood'] );
    #
    has [qw[employer_address employer_city employer_name employer_state occupation]] =>
        ( is => 'ro', isa => Maybe [Str], required => 1 );

    # Empty string if undefined
    has employer_zipcode  => ( is => 'ro', isa => Maybe [ Num | Str ], required => 1 );
    has employment_status => (
        is       => 'ro',
        isa      => Maybe [ Enum [ qw[employed unemployed student retired not_asked], '' ] ],
        required => 1
    );
    has updated_at     => ( is => 'ro', isa => Timestamp,   coerce   => 1, required => 1 );
    has years_employed => ( is => 'ro', isa => Maybe [Num], required => 1 );

    # malformed! Robinhood forgets the https:// on this URL
    has _user => ( is => 'ro', isa => URL, coerce => 1, required => 1, init_arg => 'user' );
    has user  => (
        is       => 'ro',
        isa      => InstanceOf ['Finance::Robinhood::User'],
        builder  => 1,
        lazy     => 1,
        init_arg => undef
    );

    sub _build_user($s) {
        $s->robinhood->_req( GET => 'https://api.robinhood.com/user/' )
            ->as('Finance::Robinhood::User');
    }
};
has employment => (
    is       => 'ro',
    isa      => InstanceOf ['Finance::Robinhood::User::Employment'],
    builder  => 1,
    lazy     => 1,
    coerce   => 1,
    init_arg => undef
);

sub _build_employment($s) {
    $s->robinhood->_req( GET => 'https://api.robinhood.com/user/employment/' )
        ->as('Finance::Robinhood::User::Employment');
}

sub _test_employment {
    t::Utility::stash('USER') // skip_all('No user object in stash');
    isa_ok( t::Utility::stash('USER')->employment, 'Finance::Robinhood::User::Employment' );
    isa_ok( t::Utility::stash('USER')->employment->updated_at, 'Time::Moment' );
}

=head2 C<has_international_info( )>

Returns a boolean value. True if C<international_info( )> would return data.

=head2 C<international_info( )>

    $user->international_info();

If the user is a non-US citizen, this method returns an object with the
following methods:

=over

=item C<birthCountry( )> - User's nation of origin.

=item C<businessNature( )> - User's line of work and reason for being in the US on a Visa.

=item C<expectedWithdrawals( )>

How often is the user expecting to make withdraws from Robinhood back to their
account. This is required for taxation and withholding.

Proper values include C<frequent>, C<occasional>, and C<rare>.

=item C<foreignTaxId( )> - User's tax id in their home country

=item C<howReferredToBroker( )> - How was the user referred to Robinhood.

=item C<initialDepositType( )> - This would typically be ACH but wire transfers are also possible

=item C<primaryBanking( )> - User's primary bank in the US

=item C<valueInitialDeposit( )> - How large was the user's initial deposit

=item C<withdrawalsAllowed( )> -  Returns a true value if the user is allowed to withdrawal funds via ACH

=back

=cut

{
    package    # Hide it!
        Finance::Robinhood::User::InternationalInfo;
    use Moo;
    use MooX::Enumeration;
    use Types::Standard qw[Any Overload ArrayRef Bool Dict Enum InstanceOf Maybe Num Str StrMatch];
    use URI;
    use Time::Moment;
    use Data::Dump;
    use experimental 'signatures';
    use Finance::Robinhood::Types qw[UUID Timestamp URL];
    #
    has robinhood => ( is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood'] );
    #
    has [qw[birthCountry businessNature howReferredToBroker initialDepositType primaryBanking ]] =>
        ( is => 'ro', isa => Str, required => 1 );
    has expectedWithdrawals =>
        ( is => 'ro', isa => Enum [qw[rare occasional frequent]], required => 1 );
    has [qw[foreignTaxId valueInitialDeposit]] => ( is => 'ro', isa => Num, required => 1 );
    has withdrawalsAllowed => ( is => 'ro', isa => Bool, coerce => 1, required => 1 );

    # malformed! Robinhood forgets the https:// on this URL
    has _user => ( is => 'ro', isa => URL, coerce => 1, required => 1, init_arg => 'user' );
    has user  => (
        is       => 'ro',
        isa      => InstanceOf ['Finance::Robinhood::User'],
        builder  => 1,
        lazy     => 1,
        init_arg => undef
    );

    sub _build_user($s) {
        $s->robinhood->_req( GET => 'https://api.robinhood.com/user/' )
            ->as('Finance::Robinhood::User');
    }
};
has international_info => (
    is        => 'ro',
    isa       => Maybe [ InstanceOf ['Finance::Robinhood::User::InternationalInfo'] ],
    builder   => 1,
    lazy      => 1,
    coerce    => 1,
    init_arg  => undef,
    predicate => 1
);

sub _build_international_info($s) {
    my $res = $s->robinhood->_req( GET => 'https://api.robinhood.com/user/international_info/' );
    $res && $res->success ? $res->as('Finance::Robinhod::User::InternationalInfo') : ();
}

sub _test_international_info {
    t::Utility::stash('USER') // skip_all('No user object in stash');
    todo(
        'As a US citizen, this will fail for me' => sub {
            ref_ok( t::Utility::stash('USER')->international_info, 'HASH' );
        }
    );
}

=head2 C<investment_profile( )>

    $user->investment_profile( );

Returns an object with the following methods:

=over

=item C<annual_income( )>

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

=item C<interested_in_options( )>

Returns a boolean value.

=item C<investment_experience( )>

One of the following options:

=over

=item C<good_investment_exp>

=item C<extensive_investment_exp>

=item C<limited_investment_exp>

=item C<no_investment_exp>

=back

=item C<investment_experience_collected( )>

Returns a boolean value.

=item C<investment_objective( )>

One of the following:

=over

=item C<growth_invest_obj>

=item C<income_invest_obj>

=item C<other_invest_obj>

=item C<cap_preserve_invest_obj>

=item C<speculation_invest_obj>

=back

=item C<liquid_net_worth( )>

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

=item C<liquidity_needs( )>

One of the following:

=over

=item C<not_important_liq_need>

=item C<somewhat_important_liq_need>

=item C<very_important_liq_need>

=back

=item C<option_trading_experience( )>

One of the following:

=over

=item C<no_option_exp>

=item C<one_to_two_years_option_exp>

=item C<three_years_plus_option_exp>

=back

=item C<professional_trader( )>

Returns a boolean value. True if the user is a paid professional.

=item C<risk_tolerance( )>

One of the following:

=over

=item C<high_risk_tolerance>

=item C<med_risk_tolerance>

=item C<low_risk_tolerance>

=back

=item C<source_of_funds( )>

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

=item C<suitability_verified( )>

Returns a boolean value.


=item C<tax_bracket( )>

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

=item C<time_horizon( )>

One of the following:

=over

=item C<long_time_horizon>

=item C<med_time_horizon>

=item C<short_time_horizon>

=back

=item C<total_net_worth( )>

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

=item C<understand_option_spreads( )>

Returns a boolean value.

=item C<updated_at( )>

Returns a Time::Moment object.

=back

=cut

{
    package    # Hide it!
        Finance::Robinhood::User::InvestmentProfile;
    use Moo;
    use MooX::Enumeration;
    use Types::Standard qw[Any Overload ArrayRef Bool Dict Enum InstanceOf Maybe Num Str StrMatch];
    use URI;
    use Time::Moment;
    use Data::Dump;
    use experimental 'signatures';
    use Finance::Robinhood::Types qw[UUID Timestamp URL];
    #
    has robinhood => ( is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood'] );
    #
    has annual_income => (
        is  => 'ro',
        isa => Enum [
            qw[0_24999 25000_39999 40000_49999 50000_74999 75000_99999 100000_199999 200000_299999 300000_499999 500000_1199999 1200000_inf]
        ],
        required => 1
    );
    has interested_in_options => ( is => 'ro', isa => Maybe [Bool], required => 1 );
    has investment_experience => (
        is  => 'ro',
        isa => Enum [
            qw[extensive_investment_exp good_investment_exp limited_investment_exp no_investment_exp]
        ],
        required => 1
    );
    has investment_experience_collected => ( is => 'ro', isa => Bool, coerce => 1, required => 1 );
    has investment_objective            => (
        is  => 'ro',
        isa => Enum [
            qw[cap_preserve_invest_obj income_invest_obj growth_invest_obj speculation_invest_obj other_invest_obj]
        ],
        required => 1
    );
    has liquid_net_worth => (
        is  => 'ro',
        isa => Enum [
            qw[0_24999 25000_39999 40000_49999 50000_99999 100000_199999 200000_249999 250000_499999 500000_999999 1000000_4999999 5000000_inf 1000000_inf]
        ],
        required => 1
    );
    has liquidity_needs => (
        is => 'ro',
        isa =>
            Enum [qw[not_important_liq_need somewhat_important_liq_need very_important_liq_need]],
        required => 1
    );
    has option_trading_experience => (
        is  => 'ro',
        isa => Enum [qw[no_option_exp one_to_two_years_option_exp three_years_plus_option_exp]],
        required => 1
    );
    has professional_trader => ( is => 'ro', isa => Bool, coerce => 1, required => 1 );
    has risk_tolerance      => (
        is       => 'ro',
        isa      => Enum [qw[low_risk_tolerance med_risk_tolerance high_risk_tolerance]],
        required => 1
    );
    has source_of_funds => (
        is  => 'ro',
        isa => Enum [
            qw[savings_personal_income pension_retirement insurance_payout inheritance gift sale_business_or_property other]
        ],
        required => 1
    );
    has suitability_verified => ( is => 'ro', isa => Bool, coerce => 1, required => 1 );
    has tax_bracket          => (
        is       => 'ro',
        isa      => Enum [qw[10_pct 20_pct 25_pct 28_pct 33_pct 35_pct 39_6_pct]],
        required => 1
    );
    has time_horizon => (
        is       => 'ro',
        isa      => Enum [qw[short_time_horizon med_time_horizon long_time_horizon]],
        required => 1
    );
    has total_net_worth => (
        is  => 'ro',
        isa => Enum [
            qw[0_24999 25000_49999 50000_64999 65000_99999 100000_149999 150000_199999 200000_249999 250000_499999 500000_999999 1000000_4999999 5000000_inf 1000000_inf]
        ],
        required => 1
    );
    has understand_option_spreads =>
        ( is => 'ro', isa => Maybe [Bool], coerce => 1, required => 1 );
    has updated_at => ( is => 'ro', isa => Timestamp, coerce => 1, required => 1 );

    # malformed! Robinhood forgets the https:// on this URL
    has _user => ( is => 'ro', isa => URL, coerce => 1, required => 1, init_arg => 'user' );
    has user  => (
        is       => 'ro',
        isa      => InstanceOf ['Finance::Robinhood::User'],
        builder  => 1,
        lazy     => 1,
        init_arg => undef
    );

    sub _build_user($s) {
        $s->robinhood->_req( GET => 'https://api.robinhood.com/user/' )
            ->as('Finance::Robinhood::User');
    }
};
has investment_profile => (
    is       => 'ro',
    isa      => InstanceOf ['Finance::Robinhood::User::InvestmentProfile'],
    builder  => 1,
    lazy     => 1,
    coerce   => 1,
    init_arg => undef
);

sub _build_investment_profile($s) {
    $s->robinhood->_req( GET => 'https://api.robinhood.com/user/investment_profile/' )
        ->as('Finance::Robinhood::User::InvestmentProfile');
}

sub _test_investment_profile {
    t::Utility::stash('USER') // skip_all('No user object in stash');
    isa_ok(
        t::Utility::stash('USER')->investment_profile,
        'Finance::Robinhood::User::InvestmentProfile'
    );
    isa_ok( t::Utility::stash('USER')->investment_profile->updated_at, 'Time::Moment' );
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
