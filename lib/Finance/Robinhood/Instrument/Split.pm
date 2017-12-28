package Finance::Robinhood::Instrument::Split;
use 5.010;
use Carp;
our $VERSION = "0.21";
use Moo;
use strictures 2;
use namespace::clean;
require Finance::Robinhood;
#
has $_ => (is => 'ro', required => 1) for (qw[divisor multiplier url]);
has $_ => (is       => 'ro',
           required => 1,
           coerce   => \&Finance::Robinhood::_2_datetime
) for (qw[execution_date]);
has $_ => (is => 'bare', required => 1, reader => "_get_$_")
    for (qw[instrument]);

sub instrument {
    my ($status, $result, $raw)
        = Finance::Robinhood::_send_request(undef, 'GET',
                                            shift->_get_instrument());
    return $result ?
        map { Finance::Robinhood::Instrument->new($_) } @{$result->{results}}
        : ();
}
1;

=encoding utf-8

=head1 NAME

Finance::Robinhood::Instrument::Split - Share split

=head1 SYNOPSIS

    use Finance::Robinhood::Instrument::Split;

    # ... $rh creation, login, etc...
    $rh->instrument('IDK');
    for my $split ($rh->split()) {
        print 'Split scheduled on ' . $split->execution_date();
    }

=head1 DESCRIPTION

This class contains data related to a single stock split. Objects of this type
are not meant to be created directly from your code.

=head1 METHODS

This class has several getters and a few methods as follows...

=head2 C<divisor( )>

=head2 C<execution_date( )>

Time::Piece or DateTime object representing the date the split will take place.

=head2 C<instrument( )>

Generates a new Finance::Robinhood::Instrument object related to this split.

=head2 C<multiplier( )>

=head1 LEGAL

This is a simple wrapper around the API used in the official apps. The author
provides no investment, legal, or tax advice and is not responsible for any
damages incurred while using this software. Neither this software nor its
author are affiliated with Robinhood Financial LLC in any way.

For Robinhood's terms and disclosures, please see their website at http://robinhood.com/

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify
it under the terms found in the Artistic License 2.

Other copyrights, terms, and conditions may apply to data transmitted through
this module. Please refer to the L<LEGAL> section.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut
