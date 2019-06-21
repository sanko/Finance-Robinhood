package Finance::Robinhood::Options::Order;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Options::Order - Represents a Single Options Order

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new->login('user', 'pass');
    my $orders = $rh->options_orders();

    for my $order ($orders->all) {
        $order->cancel if $order->can_cancel;
    }

=head1 METHODS

=cut

our $VERSION = '0.92_003';
use Mojo::Base-base, -signatures;
use Mojo::URL;
use lib '../../../';
use Finance::Robinhood::Error;
use Finance::Robinhood::Options::Order::Leg;

sub _test__init {
    my $rh    = t::Utility::rh_instance(1);
    my $order = $rh->options_orders->current;
    isa_ok($order, __PACKAGE__);
    t::Utility::stash('ORDER', $order);    #  Store it for later
}
use overload '""' => sub ($s, @) {
    'https://api.robinhood.com/options/orders/' . $s->{id} . '/';
    },
    fallback => 1;

sub _test_stringify {
    t::Utility::stash('ORDER') // skip_all();
    like(+t::Utility::stash('ORDER'),
         qr'https://api.robinhood.com/options/orders/.+/');
}
#
has _rh => undef => weak => 1;

=head2 C<canceled_quantity( )>

=head2 C<chain_id( )>

=head2 C<chain_symbol( )>

=head2 C<closing_strategy( )>


=head2 C<direction( )>

=head2 C<opening_strategy( )>

=head2 C<pending_quantity( )>

=head2 C<premium( )>

=head2 C<processed_premium( )>

=head2 C<processed_quantity( )>

=head2 C<ref_id( )>

=head2 C<response_category( )>

=head2 C<state( )>

=head2 C<time_in_force( )>

Returns the Time-in-Force value. C<gfd> (good for day) or C<gtc> (good 'til
cancelled).

=head2 C<trigger( )>

Returns the trigger. C<stop> or C<immediate>.

=head2 C<type( )>

Returns the order type. C<limit> or C<market>.

=cut

has ['canceled_quantity', 'chain_id',
     'chain_symbol',      'closing_strategy',
     'direction',         'id',
     'opening_strategy',  'pending_quantity',
     'premium',           'price',
     'processed_premium', 'processed_quantity',
     'quantity',          'ref_id',
     'response_category', 'state',
     'time_in_force',     'trigger',
     'type',
];

=head2 C<can_cancel( )>

Returns true if the order can be cancelled.

=cut

sub can_cancel ($s) { defined $s->{cancel_url} ? !0 : !1 }

sub _test_can_cancel {
    my $rh     = t::Utility::rh_instance(1);
    my $orders = $rh->options_orders;
    my ($filled, $cancelled);
    while ($orders->has_next) {
        my $order = $orders->next;

        #$filled   = $order if $order->state eq 'queued';
        $cancelled = $order if $order->state eq 'cancelled';
        last if $filled && $cancelled;
    }
SKIP: {
        skip('I need to create a new options order here', 1);
        $filled // skip('Cannot find a filled options order', 1);
        my $execution = $filled->legs->[0]->executions->[0];
        isa_ok($execution,
               'Finance::Robinhood::Options::Order::Leg::Execution');
    }
SKIP: {
        $cancelled // skip('Cannot find a cancelled options order', 1);
        is($cancelled->can_cancel, !1, 'cancelled order cannot be cancelled');
    }
    todo(
        "Place an order and test if it can be cancelled then cancel it, reload, and retest it"
            => sub { pass('ugh') });
}

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

=head2 C<chain( )>

Returns the related Finance::Robinhood::Options::Chain object.

=cut

sub chain ($s) {
    $s->_rh->options_chain_by_id($s->{chain_id});
}

sub _test_chain {
    t::Utility::stash('POSITION') // skip_all('No position object in stash');
    isa_ok(t::Utility::stash('POSITION')->chain,
           'Finance::Robinhood::Options::Chain');
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

=head2 C<legs( )>

Returns a list of related Finance::Robinhood::Options::Order::Leg objects, if
applicable.

=cut

sub legs ($s) {
    map {
        Finance::Robinhood::Options::Order::Leg->new(_rh => $s->_rh, %{$_})
    } @{$s->{legs}};
}

sub _test_legs {
    my $rh     = t::Utility::rh_instance(1);
    my $orders = $rh->options_orders;
    my ($leg)  = $orders->current->legs;
    isa_ok($leg, 'Finance::Robinhood::Options::Order::Leg');
}

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
    my $res = $s->_rh->_get(+$s); # Stringify
    $_[0] = $res->is_success
        ? Finance::Robinhood::Options::Order->new(_rh => $s->_rh,
                                                  %{$res->json})
        : Finance::Robinhood::Error->new(
             $res->is_server_error ? (details => $res->message) : $res->json);
}

sub _test_reload {
    t::Utility::stash('ORDER') // skip_all('No order object in stash');
    t::Utility::stash('ORDER')->reload;
    isa_ok(t::Utility::stash('ORDER'), 'Finance::Robinhood::Options::Order');
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
