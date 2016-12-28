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
    my $instrument = $rh->instrument('EGLE');    # Penny stock!
    isa_ok $instrument, 'Finance::Robinhood::Instrument',
        'EGLE symbol search result';
    can_ok $instrument, 'quote';
    my $quote = $instrument->quote();
    isa_ok $quote, 'Finance::Robinhood::Quote',
        'Quote result for EGLE';
    subtest 'Have enough buying power' => sub {
        plan skip_all => 'Not enough buying power'
            if $account->buying_power() < $quote->bid_price();
        subtest 'Order 1 share and cancel that order' => sub {
            plan skip_all => 'EGLE is not tradeable!?!'
                if !$instrument->tradeable();
            diag q"Okay, let's buy something!'";

            # TODO: Make sure we have enough cash on hand to make this order
            my $price = $quote->bid_price() / 2;
            $price = sprintf(($price > 1 ? '%.2f' : '%.4f'), $price);
            my $order =
                Finance::Robinhood::Order->new(
                                        account    => $account,
                                        instrument => $instrument,
                                        type       => 'limit',
                                        stop_price => sprintf('%.4f', $price),
                                        trigger    => 'stop',
                                        time_in_force => 'opg',
                                        side          => 'buy',
                                        quantity      => 1,
                                        price => sprintf('%.4f', $price)
                );
            isa_ok $order, 'Finance::Robinhood::Order', 'Limit buy order';
            ok $order->cancel(), 'Cancel that order quick';
            sleep 1;    # Their API server is slow these days
            like $order->state(), qr[(confirmed|queued|cancelled)],
                'Verify that the order has been canceled';
        };
    };
};
done_testing;
