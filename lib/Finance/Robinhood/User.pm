package Finance::Robinhood::User;
use Moo;
with 'MooX::Singleton';
use DateTime::Tiny;
#
has [
    qw[email email_verified first_name id last_name username url
        ]
] => ( is => 'ro' );

# TODO: Inflate these urls
has [
    qw[additional_info basic_info employment id_info international_info
        investment_profile
        ]
] => ( is => 'ro' );
has ['created_at'] => (
    is     => 'ro',
    coerce => sub {
        $_[0] =~ s'Z$'';

        # BUG: DateTime::Tiny cannot handle sub-second values.
        $_[0] =~ s'\..+$'';
        DateTime::Tiny->from_string( $_[0] );
    }
);
1;
