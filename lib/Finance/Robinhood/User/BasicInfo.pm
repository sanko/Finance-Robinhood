package Finance::Robinhood::User::BasicInfo;
use Moo;
use DateTime::Tiny;
#
has [
    qw[address citizenship city country_of_residence date_of_birth
        marital_status number_dependents phone_number state tax_id_ssn user zipcode]
] => ( is => 'ro' );
1;
has ['updated_at'] => (
    is     => 'ro',
    coerce => sub {
        $_[0] =~ s'Z$'';

        # BUG: DateTime::Tiny cannot handle sub-second values.
        $_[0] =~ s'\..+$'';
        DateTime::Tiny->from_string( $_[0] );
    }
);
1;
