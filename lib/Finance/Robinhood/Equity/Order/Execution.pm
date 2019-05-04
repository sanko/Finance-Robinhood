package Finance::Robinhood::Equity::Order::Execution;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Equity::Order::Execution - Represents a Single Execution of
an Equity Order

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new->login('user', 'pass');
    my $orders = $rh->equity_orders();

    for my $order ($orders->all) {
        grep{ CORE::say( $_->settlement_date) } @{$order->executions} and if $order->state eq 'filled';
    }

=head1 METHOD

=cut

our $VERSION = '0.92_003';

sub _test__init {
    my $rh     = t::Utility::rh_instance(1);
    my $orders = $rh->equity_orders;
    my $order;
    do {
        $order = $orders->next;
    } while $order->state ne 'filled';
    $order // skip_all('Failed to fine executied equity order');
    my ($execution) = $order->executions;
    isa_ok($execution, __PACKAGE__);
    t::Utility::stash('ORDER',     $order);        #  Store it for later
    t::Utility::stash('EXECUTION', $execution);    #  Store it for later
}
use Mojo::Base-base, -signatures;
use Mojo::URL;
use overload '""' => sub ($s, @) { $s->{url} }, fallback => 1;
use Finance::Robinhood::Equity::Account;
use Finance::Robinhood::Error;
use Finance::Robinhood::Equity::Position;

sub _test_stringify {
    t::Utility::stash('ORDER') // skip_all();
    like(+t::Utility::stash('ORDER'),
         qr'https://api.robinhood.com/orders/.+/');
}
#
has _rh => undef => weak => 1;
has ['id', 'price', 'quantity'];

=head2 C<id( )>

UUID used to identify this particular execution.

=head2 C<price( )>

The price for this particular execution.

=head2 C<quantity( )>

Number of shares for this particular execution.

=head2 C<timestamp( )>

Returns a Time::Moment object.

=cut

sub timestamp ($s) {
    Time::Moment->from_string($s->{timestamp});
}

sub _test_timestamp {
    t::Utility::stash('EXECUTION')
        // skip_all('No order execution object in stash');
    isa_ok(t::Utility::stash('EXECUTION')->timestamp, 'Time::Moment');
}

=head2 C<settlement_date( )>

Returns a Time::Moment object.

=cut

sub settlement_date($s) {
    Time::Moment->from_string($s->{settlement_date} . 'T00:00:00Z');
}

sub _test_settlement_date {
    t::Utility::stash('EXECUTION')
        // skip_all('No order execution object in stash');
    isa_ok(t::Utility::stash('EXECUTION')->settlement_date, 'Time::Moment');
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
