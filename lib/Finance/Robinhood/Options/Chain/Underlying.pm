package Finance::Robinhood::Options::Chain::Underlying;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Options::Chain::Underlying - Represents a Single Options
Chain's Underlying Equity Instrument

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new->login('user', 'pass');
    my $account = $rh->accounts->current();

    # TODO

=cut

our $VERSION = '0.92_002';
use Mojo::Base-base, -signatures;
use Mojo::URL;

sub _test__init {
    my $rh = t::Utility::rh_instance(1);

    #my $instrument = $rh->options_instruments(
    #    chain_id    => $rh->search('MSFT')->equity_instruments->[0]->tradable_chain_id,
    #    tradability => 'tradable'
    #)->current;
    #isa_ok( $instrument, __PACKAGE__ );
    #t::Utility::stash( 'INSTRUMENT', $instrument );    #  Store it for later
    todo( "Write actual tests!" => sub { pass('ugh') } );
}
use overload '""' => sub ( $s, @ ) { $s->{instrument} }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('UNDERLYING') // skip_all();
    like(
        +t::Utility::stash('UNDERLYING'),
        qr'^https://api.robinhood.com/instruments/[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}/$'i
    );
}
#
has _rh => undef => weak => 1;
has [ 'id', 'quantity' ];

sub instrument($s) {
    Finance::Robinhood::Equity::Instrument->new(
        _rh => $s->_rh,
        %{ $s->_rh->_get( $s->{instrument} )->json }
    );
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
