package Finance::Robinhood::User::InvestmentProfile;
use Moo;
use DateTime::Tiny;
#
has [
    qw[
        annual_income
        investment_experience
        risk_tolerance
        total_net_worth
        liquidity_needs
        investment_objective
        source_of_funds
        tax_bracket
        time_horizon
        liquid_net_worth
        ]
] => ( is => 'rw' );
has [
    qw[
        suitability_verified
        ]    # boolean
] => ( is => 'rw' );
has [
    qw[
        user
        ]
] => ( is => 'ro' );
has 'updated_at' => (
    is     => 'rwp',
    coerce => sub {
        $_[0] =~ s'Z$'';

        # BUG: DateTime::Tiny cannot handle sub-second values.
        $_[0] =~ s'\..+$'';
        DateTime::Tiny->from_string( $_[0] );
    }
);
for my $field (
    qw[
    annual_income
    investment_experience
    risk_tolerance
    total_net_worth
    liquidity_needs
    investment_objective
    source_of_funds
    tax_bracket
    time_horizon
    liquid_net_worth
    suitability_verified
    ]
) {
    after $field => sub {
        shift->_patch( { $field => pop } ) if scalar @_ >= 2;
        }
}
after suitability_verified => sub {
    shift->_patch(
        {suitability_verified => !!pop ? \1 : \0 });
};

sub _patch {
    my ($s, $val) = @_;
    my ($status, $data) = Finance::Robinhood::Utils::Client->instance->patch(
    $Finance::Robinhood::Endpoints{'user/investment_profile'} ,
    $val
    );
    $_[0]->_set_updated_at( $data->{updated_at} ) if $status == 200;
    }
     1;
