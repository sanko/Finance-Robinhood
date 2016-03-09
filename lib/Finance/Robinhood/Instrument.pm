package Finance::Robinhood::Instrument;
use 5.008001;
use strict;
use warnings;
use Carp;
our $VERSION = "0.01";
use Data::Dump qw[ddx];
use Moo;
use JSON::Tiny qw[decode_json];
use strictures 2;
use namespace::clean;
#
has $_ => (is => 'ro', required => 1, writer => "_set_$_")
    for (qw[bloomberg_unique id list_date maintenance_ratio market name splits
         state symbol tradeable url]);

sub get_quote {
    return Finance::Robinhood->quote(shift->symbol());
}
1;
