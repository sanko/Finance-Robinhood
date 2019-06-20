package Finance::Robinhood::Forex::Pair;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls forex

=head1 NAME

Finance::Robinhood::Forex::Pair - Represents a Single Forex Currency Pair
Watchlist

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;

    # TODO

=cut

our $VERSION = '0.92_003';
use Mojo::Base-base, -signatures;
use Mojo::URL;
use Finance::Robinhood::Forex::Currency;
use Finance::Robinhood::Forex::OrderBuilder;
use Finance::Robinhood::Forex::Quote;

sub _test__init {
    my $rh = t::Utility::rh_instance(1);
    my $pair
        = $rh->currency_pair_by_id('3d961844-d360-45fc-989b-f6fca761d511')
        ;    # BTC-USD
    isa_ok($pair, __PACKAGE__);
    t::Utility::stash('PAIR', $pair);    #  Store it for later
}
use overload '""' => sub ($s, @) { $s->{id} }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('PAIR') // skip_all();
    like(+t::Utility::stash('PAIR'),
         qr'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'i
    );
}
#
has _rh => undef => weak => 1;

=head1 METHODS


=head2 C<id( )>

Returns a UUID.

=head2 C<display_only( )>

Returns a boolean. If this is true, you can only add the pair to a forex
watchlist to monitor the price for now.

=head2 C<max_order_size( )>

Largest amount of this asset you may trade in a single order.

=head2 C<min_order_price_increment( )>

Smallest price of the quote currency you may place an order for.

=head2 C<min_order_quantity_increment( )>

Smallest increment of the asset you may place an order for.

=head2 C<min_order_size( )>

Smallest amount of the asset you may place an order for.

=head2 C<name( )>

Returns a string suited for display. And example would be 'Bitcoin to US
Dollar'.

=head2 C<symbol( )>

String used for display. Example of this might be 'BTC-USD'.

=head2 C<tradability( )>

Either C<tradable> or C<untradable>.

=cut

has ['id',                           'display_only',
     'max_order_size',               'min_order_price_increment',
     'min_order_quantity_increment', 'min_order_size',
     'name',                         'symbol',
     'tradability'
];

=head2 C<asset_currency( )>

Returns a Finance::Robinhood::Forex::Currency object.

=cut

sub asset_currency ($s) {
    Finance::Robinhood::Forex::Currency->new(_rh => $s,
                                             %{$s->{asset_currency}});
}

sub _test_asset_currency {
    t::Utility::stash('PAIR') // skip_all();
    isa_ok(t::Utility::stash('PAIR')->asset_currency,
           'Finance::Robinhood::Forex::Currency');
}

=head2 C<quote_currency( )>

Returns a Finance::Robinhood::Forex::Currency object.

=cut

sub quote_currency ($s) {
    Finance::Robinhood::Forex::Currency->new(_rh => $s,
                                             %{$s->{quote_currency}});
}

sub _test_quote_currency {
    t::Utility::stash('PAIR') // skip_all();
    isa_ok(t::Utility::stash('PAIR')->quote_currency,
           'Finance::Robinhood::Forex::Currency');
}

=head2 C<quote( )>

    my $quote = $pair->quote();

Builds a Finance::Robinhood::Forex::Quote object with this currency pair's
quote data.

You do not need to be logged in for this to work.

=cut

sub quote ($s) {
    my $res
        = $s->_rh->_get('https://api.robinhood.com/marketdata/forex/quotes/' .
                        $s->{id} . '/');
    $res->is_success
        ? Finance::Robinhood::Forex::Quote->new(_rh => $s->_rh, %{$res->json})
        : Finance::Robinhood::Error->new(
             $res->is_server_error ? (details => $res->message) : $res->json);
}

sub _test_quote {
    t::Utility::stash('PAIR') // skip_all();
    isa_ok(t::Utility::stash('PAIR')->quote(),
           'Finance::Robinhood::Forex::Quote');
}

=head2 C<historicals( ... )>

    my $data = $pair->historicals( interval => '15second' );

Returns a Finance::Robinhood::Forex::Historicals object.

You may provide the following arguments:

=over

=item C<interval> Required and must be on eof the following:

=over

=item C<15second>

=item C<5minute>

=item C<10minute>

=item C<hour>

=item C<day>

=item C<week>

=item C<month>

=back

=item C<span> - Optional and must be one of the following:

=over

=item C<hour>

=item C<day>

=item C<week>

=item C<month>

=item C<year>

=item C<5year>

=item C<all>

=back

=item C<bounds> - Optional and must be one of the following:

=over

=item C<regular> - Default

=item C<extended>

=item C<24_7>

=back

=back

=cut

sub historicals ($s, %filters) {
    my $res = $s->_rh->_get(
               Mojo::URL->new(
                   'https://api.robinhood.com/marketdata/forex/historicals/' .
                       $s->id . '/'
               )->query(\%filters),
    );
    require Finance::Robinhood::Forex::Historicals if $res->is_success;
    $res->is_success
        ? Finance::Robinhood::Forex::Historicals->new(_rh => $s->_rh,
                                                      %{$res->json})
        : Finance::Robinhood::Error->new(
             $res->is_server_error ? (details => $res->message) : $res->json);
}

sub _test_historicals {
    t::Utility::stash('PAIR') // skip_all();
    isa_ok(t::Utility::stash('PAIR')->historicals(interval => 'hour'),
           'Finance::Robinhood::Forex::Historicals');
}

=head2 C<buy( ... )>

    my $order = $pair->buy(34);

Returns a Finance::Robinhood::Forex::OrderBuilder object.

Without any additional method calls, this will create an order that looks like
this:

    {
       account          => "XXXXXXXXX",
       currency_pair_id => "3d961844-d360-45fc-989b-f6fca761d511",
       price            => "111.700000", # Automatically grabs bid price quote on submission
       quantity         => 4, # Actually the amount of crypto you requested
       side             => "buy",
       time_in_force    => "ioc",
       type             => "market"
     }

=cut

sub buy ($s, $quantity, $account = $s->_rh->forex_accounts->next) {
    Finance::Robinhood::Forex::OrderBuilder->new(_rh      => $s->_rh,
                                                 _pair    => $s,
                                                 _account => $account,
                                                 quantity => $quantity
    )->buy;
}

sub _test_buy {
    my $rh = t::Utility::rh_instance(1);
    my $btc_usd
        = $rh->currency_pair_by_id('3d961844-d360-45fc-989b-f6fca761d511');
    #
    my $market = $btc_usd->buy(4);
    is( {$market->_dump(1)},
        {account          => '--private--',
         currency_pair_id => '3d961844-d360-45fc-989b-f6fca761d511',
         quantity         => 4,
         side             => 'buy',
         type             => 'market',
         time_in_force    => 'gtc',
         ref_id           => '00000000-0000-0000-0000-000000000000',
         price            => '5.00'
        }
    );

    #->stop(43)->limit(55);#->submit;
    #ddx \{$order->_dump};
    todo("Write actual tests!" => sub { pass('ugh') });

    #my $news = t::Utility::stash('MSFT')->news;
    #isa_ok( $news,          'Finance::Robinhood::Utilities::Iterator' );
    #isa_ok( $news->current, 'Finance::Robinhood::News' );
}

=head2 C<sell( ... )>

    my $order = $btc->sell(34);

Returns a Finance::Robinhood::Forex::OrderBuilder object.

Without any additional method calls, this will create an order that looks like
this:

    {
       account       => "XXXXXXXXXX",
       pair_id    => "3d961844-d360-45fc-989b-f6fca761d511",
       price         => "111.700000", # Automatically grabs ask price quote on submission
       quantity      => 4, # Actually the amount of currency you requested
       side          => "sell",
       time_in_force => "ioc",
       type          => "market"
     }

=cut

sub sell ($s, $quantity, $account = $s->_rh->forex_accounts->next) {
    Finance::Robinhood::Forex::OrderBuilder->new(_rh      => $s->_rh,
                                                 _pair    => $s,
                                                 _account => $account,
                                                 quantity => $quantity
    )->sell;
}

sub _test_sell {
    my $rh = t::Utility::rh_instance(1);
    my $btc_usd
        = $rh->currency_pair_by_id('3d961844-d360-45fc-989b-f6fca761d511');
    #
    my $market = $btc_usd->sell(4);
    is( {$market->_dump(1)},
        {account          => '--private--',
         currency_pair_id => '3d961844-d360-45fc-989b-f6fca761d511',
         quantity         => 4,
         side             => 'sell',
         type             => 'market',
         time_in_force    => 'gtc',
         ref_id           => '00000000-0000-0000-0000-000000000000',
         price            => '5.00'
        }
    );

    #->stop(43)->limit(55);#->submit;
    #ddx \{$order->_dump};
    todo("Write actual tests!" => sub { pass('ugh') });

    #my $news = t::Utility::stash('MSFT')->news;
    #isa_ok( $news,          'Finance::Robinhood::Utilities::Iterator' );
    #isa_ok( $news->current, 'Finance::Robinhood::News' );
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
