package Finance::Robinhood::Equity::Fundamentals;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Equity::Fundamentals - Equity Instrument's Fundamental Data

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;
    my $instruments = $rh->instruments();

    for my $instrument ($instruments->all) {
        my $fundamentals = $instrument->fundamentals;
        CORE::say $instrument->symbol;
        CORE::say $fundamentals->description;
    }

=cut

our $VERSION = '0.92_002';
use Mojo::Base-base, -signatures;
use Finance::Robinhood::Equity::Instrument;

sub _test__init {
    my $rh   = t::Utility::rh_instance(1);
    my $tsla = $rh->equity_instrument_by_symbol('TSLA')->fundamentals();
    isa_ok( $tsla, __PACKAGE__ );
    t::Utility::stash( 'TSLA', $tsla );    #  Store it for later
}
#
has _rh => undef => weak => 1;

=head1 METHODS



=head2 C<average_volume( )>



=head2 C<average_volume_2_weeks( )>



=head2 C<ceo( )>

If applicable, the name of the chief executive(s) related to this instrument.

=head2 C<description( )>

Plain text description suited for display.

=head2 C<dividend_yield( )>



=head2 C<headquarters_city( )>

If applicable, the city where the main headquarters are located.

=head2 C<headquarters_state( )>

If applicable, the US state where the main headquarters are located.

=head2 C<high( )>

Trading day high.

=head2 C<high_52_weeks( )>

52-week high.

=head2 C<industry( )>



=head2 C<low( )>

Trading day low.

=head2 C<low_52_weeks( )>

52-week low.

=head2 C<market_cap( )>



=head2 C<num_employees( )>

If applicable, the number of employees as reported by the company.

=head2 C<open( )>



=head2 C<pe_ratio( )>



=head2 C<sector( )>



=head2 C<shares_outstanding( )>

Number of shares outstanding according to the SEC.

=head2 C<volume( )>



=head2 C<year_founded( )>

The year the company was founded, if applicable.

=cut

has [
    'average_volume',     'average_volume_2_weeks',
    'ceo',                'description',
    'dividend_yield',     'headquarters_city',
    'headquarters_state', 'high',
    'high_52_weeks',      'industry',
    'low',                'low_52_weeks',
    'market_cap',         'num_employees',
    'open',               'pe_ratio',
    'sector',             'shares_outstanding',
    'volume',             'year_founded',
];

=head2 C<instrument( )>

Loop back to the equity instrument.

=cut

sub instrument($s) {
    my $res = $s->_rh->_get( $s->{instrument} );
    $res->is_success
        ? Finance::Robinhood::Equity::Instrument->new( _rh => $s->_rh, %{ $res->json } )
        : Finance::Robinhood::Error->new(
        $res->is_server_error ? ( details => $res->message ) : $res->json );
}

sub _test_instrument {
    t::Utility::stash('TSLA') // skip_all();
    isa_ok( t::Utility::stash('TSLA')->instrument, 'Finance::Robinhood::Equity::Instrument' );
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
