package Finance::Robinhood::User::Employment;
use Moo;
use DateTime::Tiny;
#
has [
    qw[
        employer_address
        employer_city
        employer_name
        employer_state
        employer_zipcode
        employment_status
        occupation
        years_employed
        ]
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
    employer_address
    employer_city
    employer_name
    employer_state
    employer_zipcode
    employment_status
    occupation
    years_employed
    ]
) {
    after $field => sub {
        shift->_patch( { $field => pop } ) if scalar @_ >= 2;
        }
}

sub _patch {
    my ( $s, $val ) = @_;
    my ( $status, $data )
        = Finance::Robinhood::Utils::Client->instance->patch(
        $Finance::Robinhood::Endpoints{'user/employment'}, $val );
    $_[0]->_set_updated_at( $data->{updated_at} ) if $status == 200;
}
1;
