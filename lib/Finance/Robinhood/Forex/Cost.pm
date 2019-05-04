package Finance::Robinhood::Forex::Cost;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls forex

=head1 NAME

Finance::Robinhood::Forex::Cost - Represents a Forex Positio's Cost Basis

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;

    # TODO

=cut

our $VERSION = '0.92_003';
use Mojo::Base-base, -signatures;
use Mojo::URL;
use Finance::Robinhood::Forex::Currency;

sub _test__init {
    my $rh = t::Utility::rh_instance(1);
    my ($cost) = $rh->forex_holdings->current->cost_bases;
    $cost // skip_all('No cost basis found');
    isa_ok($cost, __PACKAGE__);
    t::Utility::stash('COST_BASIS', $cost);    #  Store it for later
}
use overload '""' => sub ($s, @) { $s->{id} }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('COST_BASIS') // skip_all();
    like(+t::Utility::stash('COST_BASIS'),
         qr'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'i
    );
}
#
has _rh => undef => weak => 1;

=head1 METHODS



=head2 C<direct_quantity( )>



=head2 C<direct_cost_basis( )>



=head2 C<intraday_cost_basis( )>



=head2 C<intraday_quantity( )>



=head2 C<marked_quantity( )>



=head2 C<marked_quantity( )>

=cut

has ['direct_quantity',     'direct_cost_basis',
     'intraday_cost_basis', 'intraday_quantity',
     'marked_quantity',     'marked_cost_basis'
];

=head2 C<currency( )>

Returns a Finance::Robinhood::Forex::Currency object.

=cut

sub currency ($s) {
    $s->_rh->forex_currency_by_id($s->{currency_id});
}

sub _test_currency {
    t::Utility::stash('COST_BASIS') // skip_all();
    isa_ok(t::Utility::stash('COST_BASIS')->currency,
           'Finance::Robinhood::Forex::Currency');
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
