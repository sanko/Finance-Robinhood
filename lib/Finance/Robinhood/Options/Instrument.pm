package Finance::Robinhood::Options::Instrument;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Options::Instrument - Represents a Single Options
Instrument

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;
    my $instruments = $rh->options_instruments();

    for my $instrument ($instruments->all) {
        CORE::say $instrument->chain_symbol;
    }

=cut

use Mojo::Base-base, -signatures;
use Mojo::URL;
use overload '""' => sub ($s) { $s->{url} };
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
    'chain_id', 'chain_symbol', 'created_at',  'expiration_date',
    'id',       'issue_date',   'min_ticks',   'rhs_tradability',
    'state',    'strike_price', 'tradability', 'type',
    'updated_att'
];

=head2 C<fundamentals( )>

    my $fundamentals = $instrument->fundamentals();

Builds a Finance::Robinhood::Equity::Fundamentals object with this instrument's
data.

You do not need to be logged in for this to work.

=cut

sub fundamentals($s) {
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
