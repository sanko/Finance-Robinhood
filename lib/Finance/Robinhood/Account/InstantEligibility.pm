package Finance::Robinhood::Account::InstantEligibility;
use Moo;
use DateTime::Tiny;
has [
    qw[reason reinstatement_date reversal state
        ]
] => ( is => 'ro' );
has 'created_at' => (
    is     => 'ro',
    coerce => sub {
        $_[0] // return;
        $_[0] =~ s'Z$'';

        # BUG: DateTime::Tiny cannot handle sub-second values.
        $_[0] =~ s'\..+$'';
        DateTime::Tiny->from_string( $_[0] );
    }
);
1;
