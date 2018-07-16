package Finance::Robinhood::User::AdditionalInfo;
use Moo;
use Time::Moment;
#
has [
    qw[
        control_person
        control_person_security_symbol
        object_to_disclosure
        security_affiliated_addres
        security_affiliated_firm_name
        security_affiliated_firm_relationship
        security_affiliated_person_name
        stock_loan_consent_status
        ]
] => ( is => 'rw' );
has [
    qw[
        security_affiliated_employee sweep_consent
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
        Time::Moment->from_string( $_[0] );
    }
);
for my $field (
    qw[
    control_person
    control_person_security_symbol
    object_to_disclosure
    security_affiliated_addres
    security_affiliated_firm_name
    security_affiliated_firm_relationship
    security_affiliated_person_name
    stock_loan_consent_status
    ]
) {
    after $field => sub {
        shift->_patch( { $field => pop } ) if scalar @_ >= 2;
        }
}
after security_affiliated_employee => sub {
    my ( $s, $bool ) = @_;
    $s->_patch( { security_affiliated_employee => $bool ? \1 : \0 } );
};
after sweep_consent => sub {
    my ( $s, $bool ) = @_;
    $s->_patch( { sweep_consent => $bool ? \1 : \0 } );
};

sub _patch {
    my ( $s, $val ) = @_;
    my ( $status, $data )
        = Finance::Robinhood::Utils::Client->instance->patch(
        $Finance::Robinhood::Endpoints{'user/additional_info'}, $val );
    $_[0]->_set_updated_at( $data->{updated_at} ) if $status == 200;
}
1;
