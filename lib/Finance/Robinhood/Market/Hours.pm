package Finance::Robinhood::Market::Hours;
use 5.010;
use Carp;
our $VERSION = "0.15";
use Moo;
use strictures 2;
use namespace::clean;
require Finance::Robinhood;
#
has $_ => (is => 'ro', required => 1) for (qw[is_open]);
has $_ => (is       => 'ro',
           required => 1,
           coerce   => \&Finance::Robinhood::_2_datetime
) for (qw[closes_at extended_closes_at date opens_at extended_opens_at]);
has $_ => (is => 'bare', required => 1, reader => "_get_$_")
    for (qw[next_open_hours previous_open_hours]);

sub next_open_hours {
    my $data = Finance::Robinhood::_send_request(undef,
                                        'GET', shift->_get_next_open_hours());
    return $data ? Finance::Robinhood::Market::Hours->new($data) : ();
}

sub previous_open_hours {
    my $data = Finance::Robinhood::_send_request(undef,
                                    'GET', shift->_get_previous_open_hours());
    return $data ? Finance::Robinhood::Market::Hours->new($data) : ();
}
1;

=encoding utf-8

=head1 NAME

Finance::Robinhood::Market::Hours - Trading Hours for a Particular Exchange

=head1 SYNOPSIS

    use Finance::Robinhood::Market::Hours;

    my $NASDAQ = Finance::Robinhood::Market->new('XNAS');
    warn 'Market opens at ' .  $NASDAQ->todays_hours()->opens_at();

=head1 DESCRIPTION

This class contains data related to a market's open and close times. Objects
of this type are not meant to be created directly from your code.

=head1 METHODS

This class has several getters and a few methods as follows...

=head2 C<is_open( )>

Boolean which may represents whether or not the market is currently open. Note
that this value is cached and may not be accurate.

=head2 C<date( )>

The particular date this object represents. This is returned in the form of a
Time::Piece or DateTime object.

=head2 C<opens_at( )>

The time the market opens for trading for this particular date. This is
returned in the form of a Time::Piece or DateTime object.

=head2 C<closes_at( )>

The time the market closes on this particular date. This is returned in the
form of a Time::Piece or DateTime object.

=head2 C<extended_opens_at( )>

The time the market opens for trading for this particular date for pre-open
trading. This is returned in the form of a Time::Piece object.

=head2 C<extended_closes_at( )>

The time the market closes on this particular date for after hours trading.
This is returned in the form of a Time::Piece or DateTime object.

=head2 C<next_open_hours( )>

Generates a Finance::Robinhood::Market::Hours object related to the nearest
future date the market will be open.

=head2 C<previous_open_hours( )>

Generates a Finance::Robinhood::Market::Hours object related to the most
recent date the market was open.

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
