package Finance::Robinhood::Forex::Order;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Forex::Order - Represents a Single Forex Order

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;

    # TODO

=cut

our $VERSION = '0.92_002';
use Mojo::Base-base, -signatures;
use Mojo::URL;
use Finance::Robinhood::Forex::Account;
use Finance::Robinhood::Forex::Order::Execution;

sub _test__init {
    my $rh    = t::Utility::rh_instance(1);
    my $order = $rh->forex_orders->current;
    isa_ok($order, __PACKAGE__);
    t::Utility::stash('ORDER', $order);    #  Store it for later
}
use overload '""' => sub ($s, @) { $s->{id} }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('ORDER') // skip_all();
    like(+t::Utility::stash('ORDER'),
         qr'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'i
    );
}
#
has _rh => undef => weak => 1;

=head1 METHODS

=head2 C<cumulative_quantity( )>

Returns the amount of currency bought or sold.

=head2 C<pair_id( )>

Returns a UUIS.

=head2 C<id( )>

Returns a UUID.

=head2 C<price( )>

Returns a dollar amount.

=head2 C<quantity( )>

Returns the amount of currency in the order.

=head2 C<ref_id( )>

Returns a UUID.

=head2 C<side>

Returns C<buy> or C<sell>.

=head2 C<state( )>

Returns C<canceled>, C<rejected>, C<filled>, C<queued>, or C<unconfirmed>.

=head2 C<time_in_force( )>

=cut

has ['cumulative_quantity', 'pair_id', 'id',   'price',
     'quantity',            'ref_id',  'side', 'state',
     'time_in_force',       'type'
];

=head2 C<can_cancel( )>

Returns true if the order can be cancelled.

=cut

sub can_cancel ($s) { defined $s->{cancel_url} ? !0 : !1 }

sub _test_can_cancel {
    my $rh     = t::Utility::rh_instance(1);
    my $orders = $rh->forex_orders;
    my ($filled, $cancelled);
    while ($orders->has_next) {
        my $order = $orders->next;

        #$filled   = $order if $order->state eq 'queued';
        $cancelled = $order if $order->state eq 'canceled';
        last if $filled && $cancelled;
    }
SKIP: {
        skip('I need to create a new forex order here', 1);
        $filled // skip('Cannot find a filled forex order', 1);
        my $execution = $filled->executions->[0];
        isa_ok($execution, 'Finance::Robinhood::Forex::Order::Execution');
    }
SKIP: {
        $cancelled // skip('Cannot find a cancelled forex order', 1);
        is($cancelled->can_cancel, !1, 'cancelled order cannot be cancelled');
    }
    todo(
        "Place an order and test if if can be cancelled then cancel it, reload, and retest it"
            => sub { pass('ugh') });
}

=head2 C<created_at( )>

Returns a Time::Moment object.

=cut

sub created_at ($s) {
    Time::Moment->from_string($s->{created_at});
}

sub _test_created_at {
    t::Utility::stash('ORDER') // skip_all();
    isa_ok(t::Utility::stash('ORDER')->created_at, 'Time::Moment');
}

=head2 C<last_transaction_at( )>

Returns a Time::Moment object.

=cut

sub last_transaction_at ($s) {
    Time::Moment->from_string($s->{last_transaction_at});
}

sub _test_last_transaction_at {
    t::Utility::stash('ORDER') // skip_all();
    isa_ok(t::Utility::stash('ORDER')->last_transaction_at, 'Time::Moment');
}

=head2 C<updated_at( )>

Returns a Time::Moment object.

=cut

sub updated_at ($s) {
    Time::Moment->from_string($s->{updated_at});
}

sub _test_updated_at {
    t::Utility::stash('ORDER') // skip_all();
    isa_ok(t::Utility::stash('ORDER')->updated_at, 'Time::Moment');
}

=head2 C<account( )>

Returns the related Finance::Robinhood::Forex::Account object.

=cut

sub account ($s) {
    my $res = $s->_rh->_get(
           'https://nummus.robinhood.com/accounts/' . $s->{account_id} . '/');
    $res->is_success
        ? Finance::Robinhood::Forex::Account->new(_rh => $s->_rh,
                                                  %{$res->json})
        : Finance::Robinhood::Error->new(
             $res->is_server_error ? (details => $res->message) : $res->json);
}

sub _test_account {
    t::Utility::stash('ORDER') // skip_all('No order object in stash');
    isa_ok(t::Utility::stash('ORDER')->account,
           'Finance::Robinhood::Forex::Account');
}

=head2 C<pair( )>

Returns the related Finance::Robinhood::Forex::Pair object.

=cut

sub pair ($s) {
    $s->_rh->forex_pair_by_id($s->{currency_pair_id});
}

sub _test_pair {
    t::Utility::stash('ORDER') // skip_all('No order object in stash');
    isa_ok(t::Utility::stash('ORDER')->pair,
           'Finance::Robinhood::Forex::Pair');
}

=head2 C<executions( )>

Returns a list of related Finance::Robinhood::Forex::Order::Execution objects
if applicable.

=cut

sub executions ($s) {
    map {
        Finance::Robinhood::Forex::Order::Execution->new(_rh => $s->_rh,
                                                         %{$_})
    } @{$s->{executions}};
}

sub _test_executions {
    my $rh     = t::Utility::rh_instance(1);
    my $orders = $rh->forex_orders;
    my ($filled, $rejected);
    while ($orders->has_next) {
        my $order = $orders->next;
        $filled   = $order if $order->state eq 'filled';
        $rejected = $order if $order->state eq 'rejected';
        last if $filled && $rejected;
    }
SKIP: {
        $filled // skip('Cannot find a filled forex order', 1);
        my ($execution) = $filled->executions;
        isa_ok($execution, 'Finance::Robinhood::Forex::Order::Execution');
    }
SKIP: {
        $rejected // skip('Cannot find a rejected forex order', 1);
        is($rejected->executions, [], 'rejected order has no executions');
    }
}

=head2 C<cancel( )>

    $order->cancel();

If the order can be cancelled, this method will do it.

Be aware that the order is still active for about a second after this is called
so I'm adding a 'smart' delay here.

=cut

sub cancel ($s) {
    CORE::state $delay = .15;
    $s->can_cancel // return !1;
    my $res;
    for my $tries (1 .. 10) {
        $res = $s->_rh->_post($s->{cancel_url});
        $s->reload if $res->is_success;
        return $s  if !$s->can_cancel;
        require Time::HiRes;
        Time::HiRes::sleep($delay + ($tries * .15));
    }
    Finance::Robinhood::Error->new(
             $res->is_server_error ? (details => $res->message) : $res->json);
}

=head2 C<reload( )>

    $order->reload();

Reloads the data for this order from the API server.

Use this if you think the status or some other info might have changed.

=cut

sub reload($s) {
    my $res = $s->_rh->_get(
                     'https://nummus.robinhood.com/orders/' . $s->{id} . '/');
    $_[0]
        = $res->is_success
        ? Finance::Robinhood::Forex::Order->new(_rh => $s->_rh, %{$res->json})
        : Finance::Robinhood::Error->new(
             $res->is_server_error ? (details => $res->message) : $res->json);
}

sub _test_reload {
    t::Utility::stash('ORDER') // skip_all('No order object in stash');
    t::Utility::stash('ORDER')->reload;
    isa_ok(t::Utility::stash('ORDER'), 'Finance::Robinhood::Forex::Order');
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
