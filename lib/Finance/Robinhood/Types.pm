package Finance::Robinhood::Types;
our $VERSION = '0.92_003';
#
use Type::Library -base, -declare => qw[Timestamp URL UUID UUID PathTiny];
use Type::Utils -all;
use Types::Standard -types;
#
use Time::Moment;
use URI;
use Data::Dump;
#
class_type Timestamp => { class => 'Time::Moment' };
coerce
    Timestamp => from Int,
    via { Time::Moment->from_epoch($_) }, from Str,
    via { Time::Moment->from_string($_) };
#
declare UUID =>
    as StrMatch [qr[^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$]i];

# Some of my early ref_id UUIDs weren't v4 and RH accepted them anyway...
declare UUIDBroken =>
    as StrMatch [qr[^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$]i];
#
class_type URL => { class => 'URI' };
coerce URL     => from Str, via { URI->new($_) };
#
coerce
    UUID => from StrMatch [qr[https://]],
    via {
    m[([0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12})]i;
    $1
    };
coerce
    UUID => from StrMatch [qr[robinhood://]],
    via {
    m[([0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12})]i;
    $1
    };
1;
