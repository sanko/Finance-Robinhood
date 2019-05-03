package Finance::Robinhood::ACATS::Transfer::Position;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::ACATS::Transfer::Position - Represents a Single Position in
an ACATS Transfer

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;
    
    ...
    CORE::say $_->instrument->symbol for @{$transfer->equity_positions};

=cut

our $VERSION = '0.92_002';
use Mojo::Base-base, -signatures;
use Mojo::URL;
use Time::Moment;

sub _test__init {
    my $rh       = t::Utility::rh_instance(1);
    my $transfer = $rh->acats_transfers->current;
    skip_all('No ACATS transfers found') if !defined $transfer;
    isa_ok($transfer->equity_positions->[0], __PACKAGE__);
    t::Utility::stash('POSITION', $transfer->equity_positions->[0])
        ;    #  Store it for later
}
#
has _rh => undef => weak => 1;

=head1 METHODS

 
=head2 C<price( )>

Average price for this position.

=head2 C<quantity( )>

Number of shares in this position

=cut

has ['price', 'quantity'];

=head2 C<instrument( )>

    my $instrument = $position->instrument();

Loops back to a Finance::Robinhood::Equity::Instrument object.

=cut

sub instrument ($s) {
    my $res = $s->_rh->_get($s->{instrument});
    $res->is_success
        ? Finance::Robinhood::Equity::Instrument->new(_rh => $s->_rh,
                                                      %{$res->json})
        : Finance::Robinhood::Error->new(
             $res->is_server_error ? (details => $res->message) : $res->json);
}

sub _test_instrument {
    t::Utility::stash('POSITION') // skip_all();
    isa_ok(t::Utility::stash('POSITION')->instrument,
           'Finance::Robinhood::Equity::Instrument');
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
