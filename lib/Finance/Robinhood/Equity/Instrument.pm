package Finance::Robinhood::Equity::Instrument;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Equity::Instrument - Represents a Single Equity Instrument

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;
    my $instruments = $rh->instruments();

    for my $instrument ($instruments->all) {
        CORE::say $instrument->symbol;
    }

=cut

our $VERSION = '0.92_003';
use Mojo::Base-base, -signatures;
use Mojo::URL;
use Finance::Robinhood::Equity::Fundamentals;
use Finance::Robinhood::Equity::Quote;
use Finance::Robinhood::Equity::OrderBuilder;
use Finance::Robinhood::Equity::Market;
use Finance::Robinhood::Equity::Ratings;
use Finance::Robinhood::Equity::Tag;
use Time::Moment;

sub _test__init {
    my $rh   = t::Utility::rh_instance(0);
    my $msft = $rh->equity_instrument_by_symbol('MSFT');
    isa_ok($msft, __PACKAGE__);
    t::Utility::stash('MSFT', $msft);    #  Store it for later
    t::Utility::rh_instance(1) // skip_all();
    $rh   = t::Utility::rh_instance(1);
    $msft = $rh->equity_instrument_by_symbol('MSFT');
    isa_ok($msft, __PACKAGE__);
    t::Utility::stash('MSFT_AUTH', $msft);
}
use overload '""' => sub ($s, @) { $s->{url} }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('MSFT') // skip_all();
    is( +t::Utility::stash('MSFT'),
        'https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/',
    );
}
#
has _rh => undef => weak => 1;

=head1 METHODS

=head2 C<bloomberg_unique( )>

https://en.wikipedia.org/wiki/Financial_Instrument_Global_Identifier

=head2 C<country( )>

Country code of location of headquarters.

=head2 C<day_trade_ratio( )>



=head2 C<id( )>

Instrument id used by RH to refer to this particular instrument.

=head2 C<list_date( )>

Returns a Time::Moment object containing the date the instrument began trading
publically.

=cut

sub list_date ($s) {
    Time::Moment->from_string($s->{list_date} . 'T00:00:00.000Z');
}

sub _test_list_date {
    t::Utility::stash('MSFT') // skip_all();
    isa_ok(t::Utility::stash('MSFT')->list_date(), 'Time::Moment');
}

=head2 C<maintenance_ratio( )>

=head2 C<margin_initial_ratio( )>

=head2 C<min_tick_size( )>

If applicable, this returns the regulatory defined tick size. See
http://www.finra.org/industry/tick-size-pilot-program

=head2 C<name( )>

Full name of the instrument.

=head2 C<rhs_tradability( )>

Indicates whether the instrument can be traded specifically on Robinhood.
Returns C<tradable> or C<untradable>.

=head2 C<simple_name( )>

Shorter name for the instrument. Best suited for display.

=head2 C<state( )>

Indicates whether this instrument is C<active> or C<inactive>.

=head2 C<symbol( )>

Ticker symbol.

=head2 C<tradability( )>

Indicates whether or not this instrument can be traded in general. Returns
C<tradable> or C<untradable>.

=head2 C<tradable_chain_id( )>

Id for the related options chain as a UUID.

=head2 C<tradeable( )>

Returns a boolean value.

=head2 C<type( )>

Indicates what sort of instrument this is. May one one of these: C<stock>,
C<adr>, C<cef>, C<reit>, or C<etp>.

=cut

has ['bloomberg_unique',  'country',
     'day_trade_ratio',   'id',
     'maintenance_ratio', 'margin_initial_ratio',
     'min_tick_size',     'name',
     'rhs_tradability',   'simple_name',
     'state',             'symbol',
     'tradability',       'tradable_chain_id',
     'tradeable',         'type',
     'url'
];

=head2 C<quote( )>

    my $quote = $instrument->quote();

Builds a Finance::Robinhood::Equity::Quote object with this instrument's quote
data.

You do not need to be logged in for this to work.

=cut

sub quote ($s) {
    my $res = $s->_rh->_get($s->{quote});
    $res->is_success
        ? Finance::Robinhood::Equity::Quote->new(_rh => $s->_rh,
                                                 %{$res->json})
        : Finance::Robinhood::Error->new(
             $res->is_server_error ? (details => $res->message) : $res->json);
}

sub _test_quote {
    t::Utility::stash('MSFT_AUTH') // skip_all();
    isa_ok(t::Utility::stash('MSFT_AUTH')->quote(),
           'Finance::Robinhood::Equity::Quote');
}

=head2 C<prices( [...] )>

	my $prices = $instrument->prices;

Builds a Finance::Robinhood::Equity::Prices object with the instrument's price
data. You must be logged in for this to work.

You may modify the type of information returned with the following options:

=over

=item C<delayed> - Boolean value. If false, real time quote data is returned.

=item C<source> - You may specify C<consolidated> (which is the default) for data from the tape or C<nls> for the Nasdaq last sale price.

=back

	$prices = $instrument->prices(source => 'consolidated', dealyed => 0);

This would return live quote data from the tape.

=cut

sub prices ($s, %filters) {
    $filters{delayed} = !!$filters{delayed} ? 'true' : 'false'
        if defined $filters{delayed};
    $filters{source} //= 'consolidated';
    my $res = $s->_rh->_get(
           Mojo::URL->new(
               'https://api.robinhood.com/marketdata/prices/' . $s->{id} . '/'
           )->query(\%filters)
    );
    require Finance::Robinhood::Equity::Prices;
    $res->is_success
        ? Finance::Robinhood::Equity::Prices->new(_rh => $s->_rh,
                                                  %{$res->json})
        : Finance::Robinhood::Error->new(
             $res->is_server_error ? (details => $res->message) : $res->json);
}

sub _test_prices {
    t::Utility::stash('MSFT_AUTH') // skip_all();
    isa_ok(t::Utility::stash('MSFT_AUTH')->prices(),
           'Finance::Robinhood::Equity::Prices');
}

=head2 C<splits( )>

    my @splits = $instrument->splits->all;

Returns an iterator with Finance::Robinhood::Equity::Split objects.

=cut

sub splits ( $s ) {
    Finance::Robinhood::Utilities::Iterator->new(
                                 _rh        => $s->_rh,
                                 _next_page => Mojo::URL->new($s->{splits}),
                                 _class => 'Finance::Robinhood::Equity::Split'
    );
}

sub _test_splits {
    my $rh     = t::Utility::rh_instance(0);
    my $splits = $rh->equity_instrument_by_symbol('JNUG')->splits;
    isa_ok($splits,       'Finance::Robinhood::Utilities::Iterator');
    isa_ok($splits->next, 'Finance::Robinhood::Equity::Split');
}

=head2 C<market( )>

    my $market = $instrument->market();

Builds a Finance::Robinhood::Equity::Market object with this instrument's quote
data.

You do not need to be logged in for this to work.

=cut

sub market ($s) {
    my $res = $s->_rh->_get($s->{market});
    $res->is_success
        ? Finance::Robinhood::Equity::Market->new(_rh => $s->_rh,
                                                  %{$res->json})
        : Finance::Robinhood::Error->new(
             $res->is_server_error ? (details => $res->message) : $res->json);
}

sub _test_market {
    my $rh   = t::Utility::rh_instance(0);
    my $msft = $rh->equity_instrument_by_symbol('MSFT');
    $msft // skip_all();
    isa_ok($msft->market(), 'Finance::Robinhood::Equity::Market');
}

=head2 C<fundamentals( )>

    my $fundamentals = $instrument->fundamentals();

Builds a Finance::Robinhood::Equity::Fundamentals object with this instrument's
data.

You do not need to be logged in for this to work.

=cut

sub fundamentals ($s) {
    my $res = $s->_rh->_get($s->{fundamentals});
    $res->is_success
        ? Finance::Robinhood::Equity::Fundamentals->new(_rh => $s->_rh,
                                                        %{$res->json})
        : Finance::Robinhood::Error->new(
             $res->is_server_error ? (details => $res->message) : $res->json);
}

sub _test_fundamentals {
    t::Utility::stash('MSFT_AUTH') // skip_all();
    isa_ok(t::Utility::stash('MSFT_AUTH')->fundamentals(),
           'Finance::Robinhood::Equity::Fundamentals');
}

=head2 C<ratings( )>

    my $fundamentals = $instrument->ratings();

Builds a Finance::Robinhood::Equity::Ratings object with this instrument's
data.

=cut

sub ratings ($s) {
    my $res = $s->_rh->_get(
                    'https://midlands.robinhood.com/ratings/' . $s->id . '/');
    $res->is_success
        ? Finance::Robinhood::Equity::Ratings->new(_rh => $s->_rh,
                                                   %{$res->json})
        : Finance::Robinhood::Error->new(
             $res->is_server_error ? (details => $res->message) : $res->json);
}

sub _test_ratings {
    t::Utility::stash('MSFT_AUTH') // skip_all();
    isa_ok(t::Utility::stash('MSFT_AUTH')->ratings(),
           'Finance::Robinhood::Equity::Ratings');
}

=head2 C<options_chains( )>

    $instrument = $rh->equity_instrument_by_symbol('MSFT');
    my $chains = $instrument->options_chains;

Returns an iterator containing chain elements.

=cut

sub options_chains ($s) {
    $s->_rh->options_chains($s);
}

sub _test_options_chains {
    my $chains = t::Utility::stash('MSFT')->options_chains;
    isa_ok($chains,          'Finance::Robinhood::Utilities::Iterator');
    isa_ok($chains->current, 'Finance::Robinhood::Options::Chain');
}

=head2 C<news( )>

    my $news = $instrument->news;

Returns an iterator containing Finance::Robinhood::News elements.

=cut

sub news ($s) { $s->_rh->news($s->symbol) }

sub _test_news {
    my $news = t::Utility::stash('MSFT')->news;
    isa_ok($news,          'Finance::Robinhood::Utilities::Iterator');
    isa_ok($news->current, 'Finance::Robinhood::News');
}

=head2 C<tags( )>

    my $tags = $instrument->tags( );

Locates an instrument's tags and returns a list of
Finance::Robinhood::Equity::Tag objects.

=cut

sub tags ( $s ) {
    my $res = $s->_rh->_get(
            'https://midlands.robinhood.com/tags/instrument/' . $s->id . '/');
    return $res->is_success
        ?
        map { Finance::Robinhood::Equity::Tag->new(_rh => $s, %{$_}) }
        @{$res->json->{tags}}
        : Finance::Robinhood::Error->new(
             $res->is_server_error ? (details => $res->message) : $res->json);
}

sub _test_tags {
    my @tags = t::Utility::stash('MSFT')->tags;
    ok(@tags);
    isa_ok($tags[0], 'Finance::Robinhood::Equity::Tag');
}

=head2 C<historicals( ... )>

    my $data = $instrument->historicals( interval => '15second' );

Returns a Finance::Robinhood::Equity::Historicals object.

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
                         'https://api.robinhood.com/marketdata/historicals/' .
                             $s->id . '/'
                     )->query(\%filters),
    );
    require Finance::Robinhood::Equity::Historicals if $res->is_success;
    $res->is_success
        ? Finance::Robinhood::Equity::Historicals->new(_rh => $s->_rh,
                                                       %{$res->json})
        : Finance::Robinhood::Error->new(
             $res->is_server_error ? (details => $res->message) : $res->json);
}

sub _test_historicals {
    t::Utility::stash('MSFT_AUTH') // skip_all();
    isa_ok(t::Utility::stash('MSFT_AUTH')->historicals(interval => 'hour'),
           'Finance::Robinhood::Equity::Historicals');
}

=head2 C<pricebook( ... )>

    my $data = $instrument->pricebook( );

Returns a Finance::Robinhood::Equity::Pricebook object filled with Level II
quote data.

This will fail if the account is not a current Gold subscriber.

=cut

sub pricebook ($s) {
    my $res = $s->_rh->_get(
             Mojo::URL->new(
                 'https://api.robinhood.com/marketdata/pricebook/snapshots/' .
                     $s->id . '/'
             ),
    );
    require Finance::Robinhood::Equity::PriceBook if $res->is_success;
    $res->is_success
        ? Finance::Robinhood::Equity::PriceBook->new(_rh => $s->_rh,
                                                     %{$res->json})
        : Finance::Robinhood::Error->new(
             $res->is_server_error ? (details => $res->message) : $res->json);
}

sub _test_pricebook {
    t::Utility::stash('MSFT_AUTH') // skip_all();

    # TODO: I need to check Gold status
    isa_ok(t::Utility::stash('MSFT_AUTH')->pricebook(),
           'Finance::Robinhood::Equity::Historicals');
}

=head2 C<buy( ... )>

    my $order = $instrument->buy(34);

Returns a Finance::Robinhood::Equity::OrderBuilder object.

Without any additional method calls, this will create an order that looks like
this:

    {
       account       => "https://api.robinhood.com/accounts/XXXXXXXXXX/",
       instrument    => "https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/",
       price         => "111.700000", # Automatically grabs last trade price quote on submission
       quantity      => 4, # Actually the number of shares you requested
       side          => "buy",
       symbol        => "MSFT",
       time_in_force => "gfd",
       trigger       => "immediate",
       type          => "market"
     }

=cut

sub buy ($s, $quantity, $account = $s->_rh->equity_accounts->next) {
    Finance::Robinhood::Equity::OrderBuilder->new(_rh         => $s->_rh,
                                                  _instrument => $s,
                                                  _account    => $account,
                                                  quantity    => $quantity
    )->buy;
}

sub _test_buy {
    t::Utility::stash('MSFT_AUTH') // skip_all();
    #
    my $market = t::Utility::stash('MSFT_AUTH')->buy(4);
    is( {$market->_dump(1)},
        {account => '--private--',
         instrument =>
             'https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/',
         quantity      => 4,
         side          => 'buy',
         trigger       => 'immediate',
         type          => 'market',
         time_in_force => 'gfd',
         ref_id        => '00000000-0000-0000-0000-000000000000',
         symbol        => 'MSFT',
         price         => '5.00'
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

    my $order = $instrument->sell(34);

Returns a Finance::Robinhood::Equity::OrderBuilder object.

Without any additional method calls, this will create an order that looks like
this:

    {
       account       => "https://api.robinhood.com/accounts/XXXXXXXXXX/",
       instrument    => "https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/",
       price         => "111.700000", # Automatically grabs last trade price quote on submission
       quantity      => 4, # Actually the number of shares you requested
       side          => "sell",
       symbol        => "MSFT",
       time_in_force => "gfd",
       trigger       => "immediate",
       type          => "market"
     }

=cut

sub sell ($s, $quantity, $account = $s->_rh->equity_accounts->next) {
    Finance::Robinhood::Equity::OrderBuilder->new(_rh         => $s->_rh,
                                                  _instrument => $s,
                                                  _account    => $account,
                                                  quantity    => $quantity
    )->sell;
}

sub _test_sell {
    t::Utility::stash('MSFT_AUTH') // skip_all();
    #
    my $market = t::Utility::stash('MSFT_AUTH')->sell(4);
    is( {$market->_dump(1)},
        {account => '--private--',
         instrument =>
             'https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/',
         quantity      => 4,
         side          => 'sell',
         trigger       => 'immediate',
         type          => 'market',
         time_in_force => 'gfd',
         ref_id        => '00000000-0000-0000-0000-000000000000',
         symbol        => 'MSFT',
         price         => '5.00'
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
