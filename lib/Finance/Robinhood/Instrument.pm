package Finance::Robinhood::Instrument;
use 5.010;
use strict;
use warnings;
use Carp;
our $VERSION = "0.01";
use Moo;
use JSON::Tiny qw[decode_json];
use strictures 2;
use namespace::clean;
use Finance::Robinhood::Market;
use Finance::Robinhood::Instrument::Split;
#
has $_ => (is => 'ro', required => 1)
    for (qw[bloomberg_unique id list_date maintenance_ratio name state symbol
         tradeable url]);
has $_ => (is => 'bare', required => 1, reader => "_get_$_")
    for (qw[market splits]);

sub get_quote {
    return Finance::Robinhood->quote(shift->symbol());
}

sub buy {
    my ($self, $quantity, $order_type, $bid_price) = @_;

    # TODO: type and price are optional
}

sub sell {
    my ($self, $quantity, $order_type, $ask_price) = @_;

    # TODO: type and price are optional
}

sub splits {

    # Upcoming stock splits
    my $data = Finance::Robinhood::_send_request(undef, 'GET',
                                                 shift->_get_splits());
    return [$data
                && $data->{results} ?
                map { Finance::Robinhood::Instrument::Split->new($_) }
                @{$data->{results}}
            : ()
    ];
}

sub market {
    my $data = Finance::Robinhood::_send_request(undef, 'GET',
                                                 shift->_get_market());
    return $data ? Finance::Robinhood::Market->new($data) : ();
}
1;

=encoding utf-8

=head1 NAME

Finance::Robinhood - Trade stocks and ETFs with free brokerage Robinhood

=head1 SYNOPSIS

    use Finance::Robinhood::Instrument;

    my $MC = Finance::Robinhood::Instrument::search('APPL');

=head1 DESCRIPTION

This class represents a single financial instrument. Objects are usually
created by Finance::Robinhood. If you intend to create your own, please use
C<Finance::Robinhood->instrument(...)>.

=head1 METHODS

This class has several getters and a few methods as follows...

=head2 C<market( ... )>

This makes an API call for information this particular instrument is traded on.

=head2


=head1 LEGAL

This is a simple wrapper around the API used in the official apps. The author
provides no investment, legal, or tax advice and is not responsible for any
damages incured while using this software. Neither this software nor its
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
