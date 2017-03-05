package Finance::Robinhood::Position;
use 5.010;
use Carp;
our $VERSION = "0.17";
use Moo;
use strictures 2;
use namespace::clean;
require Finance::Robinhood;
#
has $_ => (is => 'ro', required => 1)
    for (qw[average_buy_price intraday_quantity quantity
         shares_held_for_buys shares_held_for_sells url]);
has $_ => (is       => 'ro',
           required => 1,
           coerce   => \&Finance::Robinhood::_2_datetime
) for (qw[created_at updated_at]);
has $_ => (is => 'bare', required => 1, accessor => "_get_$_")
    for (qw[account instrument]);
has $_ => (is => 'bare', required => 1, accessor => "_get_$_", weak_ref => 1)
    for (qw[rh]);

sub account {
    my $self = shift;
    my $result
        = $self->_get_rh()->_send_request('GET', $self->_get_account());
    return $result ? Finance::Robinhood::Account->new($result) : ();
}

sub instrument {
    my $self = shift;
    my $result
        = $self->_get_rh()->_send_request('GET', $self->_get_instrument());
    return $result ? Finance::Robinhood::Instrument->new($result) : ();
}
1;

=encoding utf-8

=head1 NAME

Finance::Robinhood::Position - Where my money at?

=head1 SYNOPSIS

    use Finance::Robinhood;

    my $rh = Finance::Robinhood->new( token => ... );
    $rh->positions(); # List of these objects, actually

=head1 DESCRIPTION

This class represents a single security you have or do own. These objects are
not to be created directly.

=head1 METHODS

This class has several getters and a few methods as follows...

=head2 C<account( )>

Returns the Finance::Robinhood::Account object related to this order.

=head2 C<average_buy_price( )>

How much you spent on average for shares of this security.

=head2 C<created_at( )>

Timestamp of your first buy of this this security.

=head2 C<instrument( )>

Builds a Finance::Robinhood::Instrument object related to this security.

=head2 C<average_price( )>

Average price paid for all shares executed in this order.

=head2 C<intraday_quantity( )>

Total number of shares traded on the current day.

=head2 C<quantity( )>

Current number of shares of this security owned by you.

=head2 C<shares_held_for_buys( )>

Number of shares in buy orders which have not fully executed.

=head2 C<shares_held_for_sells( )>

Number of shares held in sell orders which have not fully executed.

=head2 C<upated_at( )>

Timestamp of the last change made to this order.

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
