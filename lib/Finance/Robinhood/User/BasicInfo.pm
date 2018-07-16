package Finance::Robinhood::User::BasicInfo;
use Moo;
use Time::Moment;
#
has [
    qw[address citizenship city country_of_residence date_of_birth
        marital_status number_dependents phone_number state tax_id_ssn user zipcode]
] => ( is => 'ro' );
1;
has ['updated_at'] => (
    is     => 'ro',
    coerce => sub {
        Time::Moment->from_string( $_[0] );
    }
);
1;
