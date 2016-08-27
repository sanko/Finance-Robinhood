use strict;
use Test::More 0.98;
use lib '../lib/';
use_ok $_ for qw(
    Finance::Robinhood
);
subtest 'skippy' => sub {
    plan skip_all => 'Missing token!' if !defined $ENV{RHTOKEN};
    my $rh = Finance::Robinhood->new(token => $ENV{RHTOKEN});
    #
    my $accounts = $rh->accounts()->{results};
    isa_ok $accounts , 'ARRAY', 'At least one account returned';
    my $account = $accounts->[0];
    isa_ok $account, 'Finance::Robinhood::Account',
        'First item in account list';
    #
    my $orders = $rh->list_orders();

    #use Data::Dump; ddx $orders;
    isa_ok $orders->{results}[0], 'Finance::Robinhood::Order',
        '$RH->list_orders->{results}[0]';

    #my $order = $orders->{results}[0];
    diag 'Locate filled order to test executions...';
    for my $order (@{$orders->{results}}) {
        next if $order->state ne 'filled';
        is_deeply [sort keys %{$order->executions->[0]}],
            [qw[price quantity settlement_date timestamp]],
            'executions have price, quantity and timestamps';
        last;

        #warn $#{$order->executions};
    }
    #
    ok $orders->{results}[0]->refresh(), '->refresh()';
    #
    isa_ok $orders->{results}[0], 'Finance::Robinhood::Order';

    #$order->executions
};
done_testing;
