package Finance::Robinhood::Forex::Holding;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls forex

=head1 NAME

Finance::Robinhood::Forex::Holding - Represents a Single Forex Currency Holding

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;

    # TODO

=cut

our $VERSION = '0.92_003';
use Mojo::Base-base, -signatures;
use Mojo::URL;
use Finance::Robinhood::Forex::Currency;
use Finance::Robinhood::Forex::Cost;
use Time::Moment;

sub _test__init {
    my $rh      = t::Utility::rh_instance(1);
    my $holding = $rh->forex_holdings->current;
    isa_ok($holding, __PACKAGE__);
    t::Utility::stash('HOLDING', $holding);    #  Store it for later
}
use overload '""' => sub ($s, @) { $s->{id} }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('HOLDING') // skip_all();
    like(+t::Utility::stash('HOLDING'),
         qr'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'i
    );
}
#
has _rh => undef => weak => 1;

=head1 METHODS
 

=head2 C<id( )>

Returns a UUID.

=head2 C<quantity( )>

Total asset size.

=head2 C<quantity_available( )>

Amount not being held for outstanding orders.

=head2 C<quantity_held_for_buy( )>

Amount being held for outstanding buy orders.

=head2 C<quantity_held_for_sell( )>

Amount being held for outstanding sell orders.

=cut

has ['id',                 'quantity',
     'quantity_available', 'quantity_held_for_buy',
     'quantity_held_for_sell'
];

=head2 C<currency( )>

Returns a Finance::Robinhood::Forex::Currency object.

=cut

sub currency ($s) {
    Finance::Robinhood::Forex::Currency->new(_rh => $s->_rh,
                                             %{$s->{currency}});
}

sub _test_currency {
    t::Utility::stash('HOLDING') // skip_all();
    isa_ok(t::Utility::stash('HOLDING')->currency,
           'Finance::Robinhood::Forex::Currency');
}

=head2 C<created_at( )>

Returns a Time::Moment object.

=cut

sub created_at ($s) {
    Time::Moment->from_string($s->{created_at});
}

sub _test_created_at {
    t::Utility::stash('HOLDING') // skip_all();
    isa_ok(t::Utility::stash('HOLDING')->created_at, 'Time::Moment');
}

=head2 C<updated_at( )>

Returns a Time::Moment object.

=cut

sub updated_at ($s) {
    Time::Moment->from_string($s->{updated_at});
}

sub _test_updated_at {
    t::Utility::stash('PAIR') // skip_all();
    isa_ok(t::Utility::stash('PAIR')->updated_at, 'Time::Moment');
}

=head2 C<account( )>

    my $acct = $holding->account();

Returns a Finance::Robinhood::Forex::Account object.

=cut

sub account ($s) {
    $s->_rh->forex_account_by_id($s->{account_id});
}

sub _test_account {
    t::Utility::stash('HOLDING') // skip_all();
    isa_ok(t::Utility::stash('HOLDING')->account(),
           'Finance::Robinhood::Forex::Account');
}

=head2 C<cost_bases( )>

Returns a list of Finance::Robinhood::Forex::Holding::Cost objects.

=cut

sub cost_bases ($s) {
    map { Finance::Robinhood::Forex::Cost->new(_rh => $s->_rh, %{$_}); }
        @{$s->{cost_bases}};
}

sub _test_cost_bases {
    t::Utility::stash('HOLDING') // skip_all();
    my ($cost_base) = t::Utility::stash('HOLDING')->cost_bases();
    $cost_base || skip_all('No currency holdings with defined cost bases.');
    isa_ok($cost_base, 'Finance::Robinhood::Forex::Cost');
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
