package Finance::Robinhood::Instrument;
use 5.010;
use strict;
use warnings;
use Carp;
our $VERSION = "0.08";
use Moo;
use JSON::Tiny qw[decode_json];
use strictures 2;
use namespace::clean;
use Finance::Robinhood::Market;
use Finance::Robinhood::Instrument::Split;
#
has $_ => (is => 'ro', required => 1)
    for (
       qw[bloomberg_unique id maintenance_ratio name state symbol tradeable]);
has $_ => (is     => 'ro',
           coerce => \&Finance::Robinhood::_2_datetime
) for (qw[list_date]);
has $_ => (is => 'bare', required => 1, reader => "_get_$_")
    for (qw[market splits fundamentals url]);

sub quote {
    return Finance::Robinhood::quote(shift->symbol());
}

sub historicals {
    return Finance::Robinhood::historicals(shift->symbol(), shift, shift);
}

sub splits {

    # Upcoming stock splits
    my ($status, $result, $raw)
        = Finance::Robinhood::_send_request(undef, 'GET',
                                            shift->_get_splits());
    return [$result
                && $result->{results} ?
                map { Finance::Robinhood::Instrument::Split->new($_) }
                @{$result->{results}}
            : ()
    ];
}

sub market {
    my ($status, $result, $raw)
        = Finance::Robinhood::_send_request(undef, 'GET',
                                            shift->_get_market());
    return $result ? Finance::Robinhood::Market->new($result) : ();
}

sub fundamentals {
    my ($status, $result, $raw)
        = Finance::Robinhood::_send_request(undef, 'GET',
                                            shift->_get_fundamentals());
    return $status == 200 ? $result : ();
}
1;

=encoding utf-8

=head1 NAME

Finance::Robinhood::Instrument - Single Financial Instrument

=head1 SYNOPSIS

    use Finance::Robinhood::Instrument;

    my $MC = Finance::Robinhood::instrument('AAPL');

=head1 DESCRIPTION

This class represents a single financial instrument. Objects are usually
created by Finance::Robinhood so please use
C<<Finance::Robinhood->instrument(...)>>.

=head1 METHODS

This class has several getters and a few methods as follows...

=head2 C<quote( )>

Makes an API call and returns a Finance::Robinhood::Quote object with current
data on this security.

=head2 C<historicals( ... )>

    $instrument->historicals( 'week', 'year' );

You may retrieve historical quote data with this method which wraps the
function found in Finance::Robinhood. Please see the documentation for that
function for more info on what data is returned.

The first argument is an interval time and must be either C<5minute>,
C<10minute>, C<day>, or C<week>.

The second argument is a span of time indicating how far into the past you
would like to retrieve and may be one of the following: C<day>, C<week>,
C<year>, or C<5year>.

=head2 C<market( )>

This makes an API call for information this particular instrument is traded on.

=head2 C<tradeable( )>

Returns a boolean value indicating whether this security can be traded on
Robinhood.

=head2 C<symbol( )>

The ticker symbol for this particular security.

=head2 C<name( )>

The actual name of the security.

For example, AAPL would be 'Apple Inc. - Common Stock'.

=head2 C<bloomberg_unique( )>

Returns the Bloomberg Global ID (BBGID) for this security.

See http://bsym.bloomberg.com/sym/

=head2 C<id( )>

The unique ID Robinhood uses to refer to this particular security.

=head2 C<maintenance_ratio( )>

Margin ratio.

=head2 C<splits( )>

Returns a list of current share splits for this security.

=head2 C<fundamentals( )>

Makes and API call and returns a hash containing the following data:

=over

=item C<average_volume>

=item C<description>

=item C<dividend_yield>

=item C<high>

=item C<high_52_weeks>

=item C<low>

=item C<low_52_weeks>

=item C<market_cap>

=item C<open>

=item C<pe_ratio>

=item C<volume>

=back

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
