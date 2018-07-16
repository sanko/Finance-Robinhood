package Finance::Robinhood::Account::InstantEligibility;
use Moo;
use Time::Moment;
has [
    qw[reason reinstatement_date reversal state
        ]
] => ( is => 'ro' );
has 'created_at' => (
    is     => 'ro',
    coerce => sub {
        $_[0] // return;
        Time::Moment->from_string( $_[0] );
    }
);
1;
