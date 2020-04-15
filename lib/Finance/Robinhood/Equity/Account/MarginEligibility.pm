package Finance::Robinhood::Equity::Account::MarginEligibility;
our $VERSION = '0.92_003';
#
use Moo;
use MooX::Enumeration;
use Types::Standard qw[Bool Enum InstanceOf Maybe Num Str StrMatch];
use URI;
use Time::Moment;
use Data::Dump;
use experimental 'signatures';
#
has additional_deposit_needed => ( is => 'ro', required => 1, isa => Num );

# Major Oak is RH's internal support rep dashboard
has compliance_user_major_oak_email => (
    is       => 'ro',
    required => 1,
    isa      => Maybe [ StrMatch [qr[^\w+\@\w+\.\w+$]] ]
);
has created_at => (
    is       => 'ro',
    required => 1,
    isa      => InstanceOf ['Time::Moment'],
    coerce   => sub ($date) { Time::Moment->from_string($date) }
);
has created_by => ( is => 'ro', required => 1, isa => Maybe [Str] );
has reason     => ( is => 'ro', required => 1, isa => Maybe [Str] );
has reinstatement_date => (
    is       => 'ro',
    required => 1,
    isa      => Maybe [ InstanceOf ['Time::Moment'] ],
    coerce   => sub ($date) {
        defined $date ? Time::Moment->from_string($date) : ();
    }
);
has reversal => (
    is       => 'ro',
    required => 1,
    isa      => Maybe [ InstanceOf ['URI'] ],
    coerce   => sub ($uri) { defined $uri ? URI->new($uri) : () }
);
has state => (
    is       => 'ro',
    required => 1,
    isa      => Enum [qw[ok in_review pending_deposit suspended revoked]],
    handles  => [qw[is_ok is_in_review is_pending_deposit is_suspended is_revoked]]
);
has updated_at => (
    is       => 'ro',
    required => 1,
    isa      => Maybe [ InstanceOf ['Time::Moment'] ],
    coerce   => sub ($date) {
        defined $date ? Time::Moment->from_string($date) : ();
    }
);
#
1;
