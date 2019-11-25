package Finance::Robinhood::Currency::Pair;
our $VERSION = '0.92_003';

=encoding utf-8

=for stopwords watchlist watchlists untradable urls forex

=head1 NAME

Finance::Robinhood::Cryptocurrency::Pair - Represents a Single Currency Pair
Watchlist

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;

    # TODO

=cut

use Moo;
use Data::Dump;
use HTTP::Tiny;
use JSON::Tiny;
use Types::Standard qw[Any Bool Dict Enum InstanceOf Num Str StrMatch];
use URI;
use experimental 'signatures';
#
use Finance::Robinhood::Currency;
use Finance::Robinhood::Currency::Quote;
use Finance::Robinhood::Currency::OrderBuilder;
use Finance::Robinhood::Currency::Historicals;
#
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
has robinhood =>
    (is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood']);

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

has [
    qw[max_order_size min_order_price_increment min_order_quantity_increment min_order_size]
] => (is => 'ro', isa => Num, required => 1);
has id => (
    is  => 'ro',
    isa => StrMatch [
        qr'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'i
    ],
    required => 1
);
has display_only => (is       => 'ro',
                     isa      => Bool,
                     required => 1,
                     coerce   => sub ($bool) { !!$bool }
);
has [qw[name symbol]] => (is => 'ro', isa => Str, required => 1);
has tradability => (is       => 'ro',
                    isa      => Enum [qw[tradable untradable]],
                    handles  => [qw[is_tradable is_untradable]],
                    required => 1
);

=head2 C<asset_currency( )>

Returns a Finance::Robinhood::Currency object.

=head2 C<quote_currency( )>

Returns a Finance::Robinhood::Currency object.

=cut

has '_' . $_ => (is => 'ro', isa => Any, required => 1, init_arg => $_)
    for qw[asset_currency quote_currency];
has asset_currency => (is      => 'ro',
                       isa     => InstanceOf ['Finance::Robinhood::Currency'],
                       lazy    => 1,
                       builder => 1,
                       init_arg => undef
);

sub _build_asset_currency ($s) {
    Finance::Robinhood::Currency->new(robinhood => $s->robinhood,
                                      %{$s->_asset_currency});
}

sub _test_asset_currency {
    t::Utility::stash('PAIR') // skip_all();
    isa_ok(t::Utility::stash('PAIR')->asset_currency,
           'Finance::Robinhood::Currency');
}
has quote_currency => (is      => 'ro',
                       isa     => InstanceOf ['Finance::Robinhood::Currency'],
                       lazy    => 1,
                       builder => 1,
                       init_arg => undef
);

sub _build_quote_currency ($s) {
    Finance::Robinhood::Currency->new(robinhood => $s->robinhood,
                                      %{$s->_quote_currency});
}

sub _test_quote_currency {
    t::Utility::stash('PAIR') // skip_all();
    isa_ok(t::Utility::stash('PAIR')->quote_currency,
           'Finance::Robinhood::Currency');
}

=head2 C<quote( )>

    my $quote = $pair->quote();

Builds a Finance::Robinhood::Currency::Quote object with this currency pair's
quote data.

You do not need to be logged in for this to work.

=cut

sub quote ($s) {
    $s->robinhood->_req(
               GET => 'https://api.robinhood.com/marketdata/forex/quotes/' .
                   $s->{id} . '/')->as('Finance::Robinhood::Currency::Quote');
}

sub _test_quote {
    t::Utility::stash('PAIR') // skip_all();
    isa_ok(t::Utility::stash('PAIR')->quote(),
           'Finance::Robinhood::Currency::Quote');
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
    $s->robinhood->_req(
            GET => 'https://api.robinhood.com/marketdata/forex/historicals/' .
                $s->id . '/',
            query => \%filters
    )->as('Finance::Robinhood::Currency::Historicals');
}

sub _test_historicals {
    t::Utility::stash('PAIR') // skip_all();
    isa_ok(t::Utility::stash('PAIR')->historicals(interval => 'hour'),
           'Finance::Robinhood::Currency::Historicals');
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

sub buy ($s, $quantity, $account = $s->robinhood->currency_account) {
    Finance::Robinhood::Currency::OrderBuilder->new(
                                                   robinhood => $s->robinhood,
                                                   pair      => $s,
                                                   account   => $account,
                                                   quantity  => $quantity,
                                                   side      => 'buy'
    );
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
         quantity         => '4.00000000',
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

sub sell ($s, $quantity, $account = $s->robinhood->currency_account) {
    Finance::Robinhood::Currency::OrderBuilder->new(
                                                   robinhood => $s->robinhood,
                                                   pair      => $s,
                                                   account   => $account,
                                                   quantity  => $quantity,
                                                   side      => 'sell'
    );
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
         quantity         => '4.00000000',
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
