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

sub _test__init {
    plan( tests => 1 );
    use_ok('Finance::Robinhood');
}
use Mojo::Base-base, -signatures;
use Mojo::URL;
use overload '""' => sub ( $s, @ ) { $s->{url} }, fallback => 1;

sub _test_stringify {
    plan( tests => 2 );
    my $rh         = new_ok('Finance::Robinhood');
    my $instrument = $rh->search('MSFT')->{instruments}[0];
    is(
        $instrument,
        'https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/',
        'stringify to url',
    );
    done_testing();
}
#
has _rh => undef => weak => 1;

=head1 METHODS



=head2 C<id( )>



=head2 C<state( )>



=head2 C<symbol( )>



=head2 C<tradability( )>



=head2 C<type( )>



=cut

has [
    'bloomberg_unique',  'country',           'day_trade_ratio',      'id',
    'list_date',         'maintenance_ratio', 'margin_initial_ratio', 'market',
    'min_tick_size',     'name',              'rhs_tradability',      'simple_name',
    'splits',            'state',             'symbol',               'tradability',
    'tradable_chain_id', 'tradeable',         'type'
];

=head2 C<quote( )>

    my $quote = $instrument->quote();

Builds a Finance::Robinhood::Equity::Order object with this instrument's quote
data.

You do not need to be logged in for this to work.

=cut

sub quote ($s) {
    my $res = $s->_rh->_get( $s->{quote} );
    $res->is_success ? Finance::Robinhood::Equity::Quote->new( _rh => $s->_rh, %{ $res->json } ) :
        Finance::Robinhood::Error->new( $res->json );
}

sub _test_quote {
    plan( tests => 2 );
    my $rh         = new_ok('Finance::Robinhood');
    my $instrument = $rh->search('MSFT')->{instruments}[0];
    isa_ok( $instrument->quote(), 'Finance::Robinhood::Equity::Quote', '...->quote() works', );
    done_testing();
}

=head2 C<fundamentals( )>

    my $fundamentals = $instrument->fundamentals();

Builds a Finance::Robinhood::Equity::Fundamentals object with this instrument's
data.

You do not need to be logged in for this to work.

=cut

sub fundamentals ($s) {
    my $res = $s->_rh->_get( $s->{fundamentals} );
    $res->is_success ?
        Finance::Robinhood::Equity::Fundamentals->new( _rh => $s->_rh, %{ $res->json } ) :
        Finance::Robinhood::Error->new( $res->json );
}

sub _test_fundamentals {
    plan( tests => 2 );
    my $rh         = new_ok('Finance::Robinhood');
    my $instrument = $rh->search('MSFT')->{instruments}[0];
    isa_ok(
        $instrument->fundamentals(),
        'Finance::Robinhood::Equity::Fundamentals',
        '...->fundamentals() works',
    );
    done_testing();
}

=head2 C<options_chains( )>

	my $instrument = $rh->search('MSFT')->{instruments}[0];
    my $chains = $instrument->options_chains;

Returns an iterator containing chain elements.

=cut

sub options_chains ($s) {
    warn $s->tradable_chain_id;
    $s->_rh->options_chains($s);
}

sub _test_options_chains {
    plan( tests => 4 );
    my $rh = new_ok('Finance::Robinhood');
    my $msft
        = isa_ok( $rh->search('MSFT')->{instruments}[0], 'Finance::Robinhood::Equity::Instrument' );
    my $chains = $rh->options_chains($msft);
    isa_ok( $chains, 'Finance::Robinhood::Utility::Iterator', '...options_chains call works' );
    isa_ok( $chains->next, 'Finance::Robinhood::Options::Chain' );
}

=head2 C<news( )>

    my $news = $instrument->news;

Returns an iterator containing Finance::Robinhood::News elements.

=cut

sub news ($s) { $s->_rh->news( $s->symbol ) }

sub _test_news {
    plan( tests => 3 );
    my $rh   = new_ok('Finance::Robinhood');
    my $msft = $rh->instrument_by_symbol('MSFT');
    my $news = $msft->news;
    isa_ok( $news, 'Finance::Robinhood::Utility::Iterator', '...news call works' );
    isa_ok( $news->next, 'Finance::Robinhood::News' );
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
