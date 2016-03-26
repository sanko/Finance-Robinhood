package Finance::Robinhood::Order;
use 5.010;
use Carp;
our $VERSION = "0.01";
use Moo;
use strictures 2;
use namespace::clean;
require Finance::Robinhood;
#
has $_ => (is => 'ro', required => 1)
    for (qw[average_price id cumulative_quantity fees price quantity
         reject_reason side state stop_price time_in_force trigger type url]);
has $_ => (
    is       => 'ro',
    required => 1,
    coerce   => \&Finance::Robinhood::_2datetime
) for (qw[created_at last_transaction_at updated_at]);
has $_ => (is => 'bare', required => 1, accessor => "_get_$_")
    for (qw[account cancel executions instrument position]);
has $_ => (is => 'bare', required => 1, accessor => "_get_$_", weak_ref => 1)
    for (qw[rh]);

sub account {
    my $self = shift;
    my $result = $self->_get_rh()->_send_request('GET', $self->_get_account());
    return $result ? Finance::Robinhood::Account->new($result) : ();
}

sub executions {
    my $self = shift;
    # TODO: Convert settlement_date and timestamp to DateTime objects
    [map { $_->{settlement_date} = Finance::Robinhood::_2datetime($_->{settlement_date});
          $_->{timestamp}       = Finance::Robinhood::_2datetime($_->{timestamp}) } @{$self->_get_executions()}];
}
sub instrument { my $self = shift;
    my $result = $self->_get_rh()->_send_request('GET', $self->_get_instrument());
    return $result ? Finance::Robinhood::Instrument->new($result) : ();
}
sub position   {
    my $self = shift;
    my $result = $self->_get_rh()->_send_request('GET', $self->_get_position());
    return $result ? Finance::Robinhood::Position->new(rh=>$self->_get_rh(), %$result) : ();
}
sub cancel {
    my $self = shift;
    my $can_cancel = $self->_get_cancel();
    return $can_cancel ? $self->_get_rh()->_send_request('GET', $can_cancel) : !1;
}
1;

=encoding utf-8

=head1 NAME

Finance::Robinhood::Order - Securities trade order

=head1 SYNOPSIS

    use Finance::Robinhood;

    my $rh = Finance::Robinhood->new( token => ... );
    my $bill = $rh->instrument('MSFT');
    my $order = $MC->place_buy_order({type => 'market', quantity => 3000, instrument => $bill});
    $order->cancel(); # Oh, wait!

=head1 DESCRIPTION

This class represents a single buy or sell order. Objects are usually
created by Finance::Robinhood with either the C<place_buy_order( ... )>. or
C<place_sell_order( )> methods.

=head1 METHODS

This class has several getters and a few methods as follows...

=head2 C<account( )>

    my $acct = $order->account();

Returns the Finance::Robinhood::Account object related to this order.

=head2 C<executions( )>

Returns order executions as a list of hashes which contain the following keys:

    price              The exact price per share
    quantity           The number of shares transfered in this execution
    settlement_date    Date on which the funds of this transaction will settle
    timestamp          When this execution took place

=head2 C<cancel( )>

    $order->cancel( ); # Nm! I want to keep these!

I<If> the order can be cancelled (has not be executed in completion, etc.),
you may cancel it with this.

=head2 C<position( )>

Returns a Finance::Robinhood::Position object related to this order's security.

=head2 C<average_price( )>

Average price paid for all shares executed in this order.

=head2 C<id( )>

    my $id = $order->id();
    # ...later...
    my $order = $rh->order( $id );

The order ID for this particular order. Use this for locating the order again.

=head2 C<fees( )>

Total amount of fees related to this order.

=head2 C<price( )>

Total current value of the order.

=head2 C<quantity( )>

Total number of shares ordered or put up for sale.

=head2 C<cumulative_quantity>

Total number of shares which have executed so far.

=head2 C<reject_reason( )>

If the order was rejected (see  C<state( )>), the reason will be here.

=head2 C<side( )>

Indicates which side of the deal you were on: C<buy> or C<sell>.

=head2 C<state( )>

The current state of the order. For example, completly executed orders have a
C<filled> state. The current state may be any of the following:

    queued
    unconfirmed
    confirmed
    partially_filled
    filled
    rejected
    cancelled
    failed

=head2 C<stop_price( )>

Stop limit and stop loss orders will have a defined stop price.

=head2 C<time_in_force( )>

This may be one of the following:

    gfd     Good For Day
    gtc     Good Til Cancelled
    fok     Fill or Kill
    ioc     Immediate or Cancel
    opg

=head2 C<trigger( )>

May be one of the following:

    immediate
    on_close
    stop

I<Note>: Support for C<opg> orders may indicate support for C<loo> and C<moo>
triggers but I have yet to test it.

=head2 C<type( )>

May be one of the following:

    market
    limit
    stop_limit
    stop_loss

=head2 C<created_at( )>

The timestamp when the order was placed.

=head2 C<last_transaction_at( )>

The timestamp of the most recent execution.

=head2 C<upated_at( )>

Timestamp of the last change made to this order.

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
