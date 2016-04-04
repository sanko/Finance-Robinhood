package Finance::Robinhood::Market;
use 5.010;
use Carp;
our $VERSION = "0.05";
use Moo;
use strictures 2;
use namespace::clean;
use Finance::Robinhood::Market::Hours;
#
has $_ => (is => 'ro', required => 1)
    for (
        qw[acronym city country mic name operating_mic timezone url website]);
has $_ => (is => 'bare', required => 1, accessor => "_get_$_")
    for (qw[todays_hours]);

sub todays_hours {
    my $data = Finance::Robinhood::_send_request(undef, 'GET',
                                                 shift->_get_todays_hours());
    return $data ? Finance::Robinhood::Market::Hours->new($data) : ();
}
1;

=encoding utf-8

=head1 NAME

Finance::Robinhood::Market - Basic Market Information

=head1 SYNOPSIS

    use Finance::Robinhood::Market;

    my $MC = Finance::Robinhood::instrument('APPL');
    my $market = $MC->market();
    print $market->acronym() . ' is based in ' . $market->city();

=head1 DESCRIPTION

This class represents a single financial market. Objects are usually
created by Finance::Robinhood. If you're looking for information about the
market where a particular security is traded, use
C<<<Finance::Robinhood::instrument($symbol)->market()>>>.

=head1 METHODS

This class has several getters and a few methods as follows...

=head2 C<acronym( )>

The common acronym used for this particular market or exchange.

=head2 C<city( )>

The city this particular market is based in.

=head2 C<country( )>

The country this particular market is based in.

=head2 C<mic( )>

Market Identifier Code (MIC) used to identify this exchange or market.

See ISO 10383.

=head2 C<name( )>

The common name of the market.

=head2 C<operating_mic( )>

Identifies the entity operating the exchange.

=head2 C<timezone( )>

The time zone this market operates in.

=head2 C<website( )>

Returns the URL for this market's website.

=head2 C<todays_hours( )>

Generates a Finace::Robinhood::Market::Hours object for the current day's
operating hours for this particular market.

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
