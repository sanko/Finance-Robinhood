package Finance::Robinhood::Equity::PriceBook;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Equity::PriceBook - Represents an Equity Instrument's Level
II Price Data

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new->login('user', 'pass');

    # TODO

=cut

our $VERSION = '0.92_003';
use Mojo::Base-base, -signatures;
use Mojo::URL;

sub _test__init {
    my $rh   = t::Utility::rh_instance(1);
    my $msft = $rh->equity_instrument_by_symbol('MSFT');
    isa_ok($msft, __PACKAGE__);
    t::Utility::stash('MSFT', $msft);    #  Store it for later
    my $l2 = $msft->pricebook;
    isa_ok($l2, __PACKAGE__);
    t::Utility::stash('L2', $l2);        #  Store it for later
}
##

=head1 METHODS

=cut

has _rh => undef => weak => 1;

=head2 C<midpoint( )>


=head2 C<asks( )>

Returns a list of Finance::Robinhood::Equity::PriceBook::DataPoint objects.

=head2 C<bids( )>

Returns a list of Finance::Robinhood::Equity::PriceBook::DataPoint objects.

=cut

has ['midpoint'];

sub asks ($s) {
    require Finance::Robinhood::Equity::PriceBook::Datapoint;
    map {
        Finance::Robinhood::Equity::PriceBook::Datapoint->new(_rh => $s->_rh,
                                                              %{$_})
    } @{$s->{ask}};
}

sub _test_asks {
    t::Utility::stash('L2') // skip_all('No Level II data object in stash');
    my ($datapoint) = t::Utility::stash('L2')->asks;
    isa_ok($datapoint, 'Finance::Robinhood::Equity::PriceBook::Datapoint');
}

sub bids ($s) {
    require Finance::Robinhood::Equity::PriceBook::Datapoint;
    map {
        Finance::Robinhood::Equity::PriceBook::Datapoint->new(_rh => $s->_rh,
                                                              %{$_})
    } @{$s->{bids}};
}

sub _test_bids {
    t::Utility::stash('L2') // skip_all('No Level II data object in stash');
    my ($datapoint) = t::Utility::stash('L2')->bids;
    isa_ok($datapoint, 'Finance::Robinhood::Equity::PriceBook::Datapoint');
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
