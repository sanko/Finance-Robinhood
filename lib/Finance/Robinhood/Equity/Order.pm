package Finance::Robinhood::Equity::Order;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Equity::Order - Represents a Single Equity Order

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new->login('user', 'pass');
    my $orders = $rh->equity_orders();

    for my $order ($orders->all) {
        $order->cancel if $order->can_cancel;
    }

=head1 METHOD

=cut

our $VERSION = '0.92_003';
use Mojo::Base-base, -signatures;
use Mojo::URL;
use Finance::Robinhood::Equity::Account;
use Finance::Robinhood::Error;
use Finance::Robinhood::Equity::Position;
use Finance::Robinhood::Equity::Order::Execution;

sub _test__init {
    my $rh    = t::Utility::rh_instance(1);
    my $order = $rh->equity_orders->current;
    isa_ok($order, __PACKAGE__);
    t::Utility::stash('ORDER', $order);    #  Store it for later
}
use overload '""' => sub ($s, @) { $s->{url} }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('ORDER') // skip_all();
    like(+t::Utility::stash('ORDER'),
         qr'https://api.robinhood.com/orders/.+/');
}
#
has _rh => undef => weak => 1;
has ['average_price',        'cumulative_quantity',
     'extended_hours',       'fees',
     'id',                   'override_day_trade_checks',
     'override_dtbp_checks', 'price',
     'quantity',             'ref_id',
     'reject_reason',        'response_category',
     'side',                 'state',
     'stop_price',           'time_in_force',
     'trigger',              'type',
     'url'
];

=head2 C<can_cancel( )>

Returns true if the order can be cancelled.

=cut

sub can_cancel ($s) { defined $s->{cancel} ? !0 : !1 }

sub _test_can_cancel {
    my $rh     = t::Utility::rh_instance(1);
    my $orders = $rh->equity_orders;
    my ($filled, $cancelled);
    while ($orders->has_next) {
        my $order = $orders->next;

        #$filled   = $order if $order->state eq 'queued';
        $cancelled = $order if $order->state eq 'cancelled';
        last if $filled && $cancelled;
    }
SKIP: {
        skip('I need to create a new equity order here', 1);
        $filled // skip('Cannot find a filled equity order', 1);
        my $execution = $filled->executions->[0];
        isa_ok($execution, 'Finance::Robinhood::Equity::Order::Execution');
    }
SKIP: {
        $cancelled // skip('Cannot find a cancelled equity order', 1);
        is($cancelled->can_cancel, !1, 'cancelled order cannot be cancelled');
    }
    todo(
        "Place an order and test if it can be cancelled then cancel it, reload, and retest it"
            => sub { pass('ugh') });
}

=head2 C<account( )>

Returns the related Finance::Robinhood::Equity::Account object.

=cut

sub account ($s) {
    my $res = $s->_rh->_get($s->{account});
    $res->is_success
        ? Finance::Robinhood::Equity::Account->new(_rh => $s->_rh,
                                                   %{$res->json})
        : Finance::Robinhood::Error->new(
             $res->is_server_error ? (details => $res->message) : $res->json);
}

sub _test_account {
    t::Utility::stash('ORDER') // skip_all('No order object in stash');
    isa_ok(t::Utility::stash('ORDER')->account,
           'Finance::Robinhood::Equity::Account');
}

=head2 C<position( )>

Returns the related Finance::Robinhood::Equity::Position object.

=cut

sub position ($s) {
    my $res = $s->_rh->_get($s->{position});
    $res->is_success
        ? Finance::Robinhood::Equity::Position->new(_rh => $s->_rh,
                                                    %{$res->json})
        : Finance::Robinhood::Error->new(
             $res->is_server_error ? (details => $res->message) : $res->json);
}

sub _test_position {
    t::Utility::stash('ORDER') // skip_all('No order object in stash');
    isa_ok(t::Utility::stash('ORDER')->position,
           'Finance::Robinhood::Equity::Position');
}

=head2 C<average_price( )>

Average price per share for all executions so far.

=head2 C<cancel( )>

    $order->cancel();

If the order can be cancelled, this method will do it.

Be aware that the order is still active for about a second after this is called
so add a 'smart' delay here and then call C<reload( )> to update the object
correctly.

=cut

sub cancel ($s) {
    $s->can_cancel // return $s;
    my $res = $s->_rh->_post($s->{cancel});
    $s->reload && return $s if $res->is_success;
    Finance::Robinhood::Error->new(
             $res->is_server_error ? (details => $res->message) : $res->json);
}

=head2 C<created_at( )>

Returns a Time::Moment object.

=cut

sub created_at ($s) {
    Time::Moment->from_string($s->{created_at});
}

sub _test_created_at {
    t::Utility::stash('ORDER') // skip_all('No order object in stash');
    isa_ok(t::Utility::stash('ORDER')->created_at, 'Time::Moment');
}

=head2 C<cumulative_quantity( )>

Number of shares that have been bought or sold with this order's execution(s)
so far.

=head2 C<executions( )>

Returns a list of related Finance::Robinhood::Equity::Order::Execution objects
if applicable.

=cut

sub executions ($s) {
    map {
        Finance::Robinhood::Equity::Order::Execution->new(_rh => $s->_rh,
                                                          %{$_})
    } @{$s->{executions}};
}

sub _test_executions {
    my $rh     = t::Utility::rh_instance(1);
    my $orders = $rh->equity_orders;
    my ($filled, $rejected);
    while ($orders->has_next) {
        my $order = $orders->next;
        $filled   = $order if $order->state eq 'filled';
        $rejected = $order if $order->state eq 'rejected';
        last if $filled && $rejected;
    }
SKIP: {
        $filled // skip('Cannot find a filled equity order', 1);
        my ($execution) = $filled->executions;
        isa_ok($execution, 'Finance::Robinhood::Equity::Order::Execution');
    }
SKIP: {
        $rejected // skip('Cannot find a rejected equity order', 1);
        is([$rejected->executions], [], 'rejected order has no executions');
    }
}

=head2 C<extended_hours( )>

Returns a true value if this order is set to execute during extended hours and
pre-market.

=head2 C<fees( )>

Fees charged by Robinhood. Always C<0.00>.

=head2 C<id( )>

UUID used to identify this specific order.

=head2 C<instrument( )>

Returns the related Finance::Robinhood::Equity::Instrument object.

=cut

sub instrument($s) {
    my $res = $s->_rh->_get($s->{instrument});
    $res->is_success
        ? Finance::Robinhood::Equity::Instrument->new(_rh => $s->_rh,
                                                      %{$res->json})
        : Finance::Robinhood::Error->new(
             $res->is_server_error ? (details => $res->message) : $res->json);
}

sub _test_instrument {
    t::Utility::stash('ORDER') // skip_all('No order object in stash');
    isa_ok(t::Utility::stash('ORDER')->instrument,
           'Finance::Robinhood::Equity::Instrument');
}

=head2 C<last_transaction_at( )>

Returns a Time::Moment object if applicable.

=cut

sub last_transaction_at($s) {
    defined $s->{last_transaction_at}
        ? Time::Moment->from_string($s->{last_transaction_at})
        : ();
}

sub _test_last_transaction_at {
    t::Utility::stash('ORDER') // skip_all('No order in stash');
    my $last_transaction_at = t::Utility::stash('ORDER')->last_transaction_at;
    skip_all('No transactions... goodbye') if !defined $last_transaction_at;
    isa_ok($last_transaction_at, 'Time::Moment');
}

=head2 C<override_day_trade_checks( )>

A boolean value indicating whether this order bypassed PDT checks.

=head2 C<override_dtbp_checks( )>

A boolean value indicating whether this order bypassed day trade buying power
checks.

Risky Regulation T violation warning!

=head2 C<price( )>

The price used as an exact limit (for limit and stop-limit orders) or as the
price to collar from (for market and stop-loss orders).

=head2 C<quantity( )>

Returns the total number of shares in this order.

=head2 C<ref_id( )>

Client generated UUID is returned.

=head2 C<reject_reason( )>

If the order was rejected, this will be filled with the reason.

=head2 C<response_category( )>

Returns the response category if applicable.

=head2 C<side( )>

Indicates if this is an order to C<buy> or C<sell>.

=head2 C<state( )>

One of the following:

=over

=item C<queued>

=item C<new>

=item C<unconformed>

=item C<confirmed>

=item C<partially_filled>

=item C<filled>

=item C<rejected>

=item C<canceled>

=item C<failed>

=item C<voided>

=back

=head2 C<stop_price( )>

Returns a float if the trigger type is C<stop>, otherwise, C<undef>.

=head2 C<time_in_force( )>

Returns the Time-in-Force value. C<gfd> (good for day) or C<gtc> (good 'til
cancelled).

=head2 C<trigger( )>

Returns the trigger. C<stop> or C<immediate>.

=head2 C<type( )>

Returns the order type. C<limit> or C<market>.

=head2 C<updated_at( )>

Returns a Time::Moment object.

=cut

sub updated_at($s) {
    Time::Moment->from_string($s->{updated_at});
}

sub _test_updated_at {
    t::Utility::stash('ORDER') // skip_all('No order object in stash');
    isa_ok(t::Utility::stash('ORDER')->updated_at, 'Time::Moment');
}

=head2 C<reload( )>

    $order->reload();

Reloads the data for this order from the API server.

Use this if you think the status or some other info might have changed.

=cut

sub reload($s) {
    my $res = $s->_rh->_get($s->{url});
    $_[0]
        = $res->is_success
        ? Finance::Robinhood::Equity::Order->new(_rh => $s->_rh,
                                                 %{$res->json})
        : Finance::Robinhood::Error->new(
             $res->is_server_error ? (details => $res->message) : $res->json);
}

sub _test_reload {
    t::Utility::stash('ORDER') // skip_all('No order object in stash');
    t::Utility::stash('ORDER')->reload;
    isa_ok(t::Utility::stash('ORDER'), 'Finance::Robinhood::Equity::Order');
}

=head1 LEGAL

This is a simple wrapper around the API used in the official apps. The author
provides no investment, legal, or tax advice and is not responsible for any
damages incurred while using this software. This software is not affiliated
with Robinhood Financial LLC in any way.

For Robinhood's terms and disclosures, please see their website at
https://robinhood.com/legal/

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module. Please refer to
the L<LEGAL> section.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut

1;
