package Finance::Robinhood::Order;
use 5.010;
use Carp;
our $VERSION = "0.02";
use Moo;
use strictures 2;
use namespace::clean;
require Finance::Robinhood;
#
has $_ => (is => 'ro', required => 1)
    for (qw[average_price id cumulative_quantity fees price quantity
         reject_reason side state stop_price time_in_force trigger type url]);
has $_ => (is       => 'ro',
           required => 1,
           coerce   => \&Finance::Robinhood::_2_datetime
) for (qw[created_at last_transaction_at updated_at]);
has $_ => (is => 'bare', required => 1, accessor => "_get_$_")
    for (qw[cancel executions position]);
has $_ => (
    is       => 'bare',
    accessor => "_get_$_",
    weak_ref => 1,

    #lazy     => 1,
    #builder  => sub { shift->account()->_get_rh() }
) for (qw[rh]);
has $_ => (is => 'bare', required => 1, accessor => "_get_$_")
    for (qw[account instrument]);
around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;

    # If this is a new order, create it with the API first
    if (!defined {@args}->{url}) {
        my ($status, $data, $raw)
            = {@args}->{account}->_get_rh()->_send_request(
            'POST',
            Finance::Robinhood::endpoint('orders'),
            {account    => {@args}->{account}->url(),
             instrument => {@args}->{instrument}->url(),
             symbol     => {@args}->{instrument}->symbol(),
             (map {
                  {@args}
                  ->{$_} ? ($_ => {@args}->{$_}) : ()
              } qw[type price trigger time_in_force stop_price side quantity]
             )
            }
            );
        croak join '  ', @{$data->{non_field_errors}}
            if $data->{non_field_errors};
        croak $data->{detail} // join '  ',
            map { $_ . ': ' . join ' ', @{$data->{$_}} } keys %$data
            if $status == 400;
        $data->{rh} = {@args}->{account}->_get_rh();
        @args = $data;
    }
    return $class->$orig(@args);
};

sub account {
    my $self = shift;
    my $result
        = $self->_get_rh()->_send_request('GET', $self->_get_account());
    return $result ? Finance::Robinhood::Account->new($result) : ();
}

sub executions {
    my $self = shift;

    # TODO: Convert settlement_date and timestamp to DateTime objects
    [map {
         $_->{settlement_date}
             = Finance::Robinhood::_2_datetime($_->{settlement_date});
         $_->{timestamp} = Finance::Robinhood::_2_datetime($_->{timestamp})
     } @{$self->_get_executions()}
    ];
}

sub instrument {
    my $self = shift;
    my $result
        = $self->_get_rh()->_send_request('GET', $self->_get_instrument());
    return $result ? Finance::Robinhood::Instrument->new($result) : ();
}

sub position {
    my $self = shift;
    my $result
        = $self->_get_rh()->_send_request('GET', $self->_get_position());
    return $result
        ?
        Finance::Robinhood::Position->new(rh => $self->_get_rh(), %$result)
        : ();
}

sub cancel {
    my ($self) = @_;
    my $can_cancel = $self->_get_cancel();
    $can_cancel ?
        $self->_get_rh()->_send_request('POST', $can_cancel)
        : !1;
    return $_[0] = $self->_get_rh()->locate_order($self->id());
}
1;

=encoding utf-8

=head1 NAME

Finance::Robinhood::Order - Order to buy or sell a security

=head1 SYNOPSIS

    use Finance::Robinhood;

    my $rh    = Finance::Robinhood->new( token => ... );
    my $acct  = $rh->accounts()->[0];
    my $bill  = $rh->instrument('MSFT');
    my $order = Finance::Robinhood::Order->new(
        account       => $acct,
        instrument    => $bill,
        side          => 'buy',
        type          => 'market',
        trigger       => 'immediate',
        time_in_force => 'gfd',
        quantity      => 300
    );
    $order->cancel(); # Oh, wait!

=head1 DESCRIPTION

This class represents a single buy or sell order. These are returned by the
C<locate_order( ... )> and C<list_order( ... )> methods of Finance::Robinhood.

Of course, you may place new orders with the C<new( ... )> constructor of this
class.

=head1 METHODS

This class has several getters and a few methods as follows...

=head2 C<new( ... )>

The main event! Odds are, this is what you installed Finance::Robinhood to do:
buy and sell securities without commisions.

Please note that if the call to C<new( ... )> fails for any reason (not enough
buying power, etc.) this will C<confess( ... )> so it's probably a good idea
to wrap it in an eval or something.

There are some keys that are required for all orders and then there are some
that only apply for certain types of orders. Different C<type> and C<trigger>
combinations can make trading a lot less risky so please check out the
L<order cheat sheet|/"Order Cheat Sheet"> below for easy stop loss and stop
limit orders.

These are the required keys for all orders:

=over

=item C<account>

A Finance::Robinhood::Account object. You can get a list of these with the
C<accounts( )> method found in Finance::Robinhood.

=item C<instrument>

A Finance::Robinhood::Instrument. The easiest way to get these is to use the
C<instrument( )> method found in Finance::Robinhood.

=item C<type>

This is a string which may be one of the following:

=over

=item C<market>

=item C<limit>

=back

=item C<trigger>

Which may be one of the following:

=over

=item C<immediate>

The order is executed immediatly.

=item C<stop>

The order depends on a defined C<stop_price> and then automatically converts
into whatever C<type> you provided.

=item C<on_close>

The order executes as close to the end of the day as possible.

Please note that there are certain timing rules placed on Market On Close
(MOC) and Limit On Close (LOC) orders. All (MOC) orders must be submitted by
3:45pm on the NYSE and by 3:50pm EST on the Nasdaq. Neither exchange allows
for the modification or cancellation of MOC orders after those times.

=back

=item C<time_in_force>

Which may be one of the following:

=over

=item C<gfd>

Good For Day - The order is automatically cancelled at the end of the trading
day. This can lead to partial executions.

=item C<gtc>

Good 'Till Cancelled - The order will never cancel automatically. You must do
so manually.

=item C<fok>

Fill or Kill - When triggered, the entire order must execute in full
immediatly or the entire order is cancelled.

Note that FOK orders are no longer used on the NYSE.

=item C<ioc>

Immediate or Cancel - When triggered, the order must execute or the order is
cancelled. IOC orders allow for partial executions unlike FOK.

=item C<opg>

Opening - The order is executed at or as close to when the market opens.

Note that OPG orders are not used on Nasdaq.

=back

=item C<side>

This indicates whether you would like to...

=over

=item C<buy>

=item C<sell>

=back

=item C<quantity>

Is the number of shares this order covers. How many you would like to buy or
sell.

=back

In addition to the above, there are some situational values you may need to
pass. These include:

=over

=item C<price>

This is used in limit, stop limit, and stop loss orders where the order will
only execute when the going rate hits the given price.

=item C<stop_price>

This is used in stop limit and stop loss orders where the trigger is C<stop>
and the order is automatically converted when the price hits the given
C<stop_price>.

=back

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

=head2 C<cumulative_quantity( )>

Total number of shares which have executed so far.

=head2 C<reject_reason( )>

If the order was rejected (see  C<state( )>), the reason will be here.

=head2 C<side( )>

Indicates which side of the deal you were on: C<buy> or C<sell>.

=head2 C<state( )>

The current state of the order. For example, completly executed orders have a
C<filled> state. The current state may be any of the following: C<queued>,
C<unconfirmed>, C<confirmed>, C<partially_filled>, C<filled>, C<rejected>,
C<cancelled>, C<failed>.

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

May be one of the following: C<immediate>, C<on_close>, C<stop>

I<Note>: Support for C<opg> orders may indicate support for C<loo> and C<moo>
triggers but I have yet to test it.

=head2 C<type( )>

May be one of the following: C<market> or C<limit>.

=head2 C<created_at( )>

The timestamp when the order was placed.

=head2 C<last_transaction_at( )>

The timestamp of the most recent execution.

=head2 C<upated_at( )>

Timestamp of the last change made to this order.

=head1 Order Cheat Sheet

This is a little cheat sheet for creating certain types of orders:

=head2 Market Sell

A market sell gets you whatever the current ask price is at the exact moment
of execution.

    my $order = Finance::Robinhood::Order->new(
        type    => 'market',
        trigger => 'immediate',
        side    => 'sell',
        ...
    );

=head2 Limit Sell

Limit sells allow you specify the minimum amount you're willing to receive per
share.

    my $order = Finance::Robinhood::Order->new(
        type    => 'limit',
        trigger => 'immediate',
        price   => 200.45,
        side    => 'sell',
        ...
    );

=head2 Stop Loss Sell

When the bid price drops below the stop price, the order is converted to a
market order.

    my $order = Finance::Robinhood::Order->new(
        type       => 'market',
        trigger    => 'stop',
        stop_price => 200.45,
        side       => 'sell',
        ...
    );

=head2 Stop Limit Sell

When the bid price drops below the stop price, the order is converted to a
limit order at the given price. In the following example, when the price
reaches $200.45, the order is converted into a limit order at $199.5 a share.

    my $order = Finance::Robinhood::Order->new(
        type       => 'limit',
        trigger    => 'stop',
        stop_price => 200.45,
        price      => 199.5
        side       => 'sell',
        ...
    );

=head2 Market Buy

When triggered, this attempts to execute at the best current price. This may
be above both the current bid and ask price.

    my $order = Finance::Robinhood::Order->new(
        type       => 'market',
        trigger    => 'immediate',
        side       => 'buy',
        ...
    );

=head2 Limit Buy

You may set the maximum amount you're willing to pay per share with a limit
buy.

    my $order = Finance::Robinhood::Order->new(
        type       => 'limit',
        trigger    => 'immediate',
        price      => 2.65,
        side       => 'buy',
        ...
    );

=head2 Stop Loss Buy

This order type allows you to set a price at which your order converts to a
simple market order. In the following example, when the price rises above
$2.30/share, the order is converted to a market order and executed at the best
available price.

    my $order = Finance::Robinhood::Order->new(
        type       => 'market',
        trigger    => 'stop',
        stop_price => 2.30,
        side       => 'buy',
        ...
    );

=head2 Stop Limit Buy

This order type allows you to set a price that converts your order to a limit
order. In this example, when the price hits $6/share, the order turns into
a limit buy with a C<stop_price> of $6.15/share.

    my $order = Finance::Robinhood::Order->new(
        type       => 'limit',
        trigger    => 'stop',
        price      => 6.15,
        stop_price => 6,
        side       => 'buy',
        ...
    );

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
