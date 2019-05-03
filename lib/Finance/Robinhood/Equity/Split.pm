package Finance::Robinhood::Equity::Split;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Equity::Split - Represents a Single Equity Instrument Split

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;
    my $msft = $rh->equity_instrument_by_symbol('JNUG');

    # TODO

=cut

our $VERSION = '0.92_002';
use Mojo::Base-base, -signatures;
use Mojo::URL;
use Time::Moment;
use Finance::Robinhood::Equity::Market::Hours;

sub _test__init {
    my $rh    = t::Utility::rh_instance(0);
    my $split = $rh->equity_instrument_by_symbol('JNUG')->splits->current;
    isa_ok($split, __PACKAGE__);
    t::Utility::stash('SPLIT', $split);    #  Store it for later
}
use overload '""' => sub ($s, @) { $s->{url} }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('SPLIT') // skip_all();
    like(+t::Utility::stash('SPLIT'),
         qr'^https://api.robinhood.com/instruments/66ec1551-e033-4f9a-a46f-2b73aa529977/splits/.+/$'
    );
}
#
has _rh => undef => weak => 1;

=head1 METHODS

=head2 C<divisor( )>



=head2 C<multiplier( )>


=cut

has ['divisor', 'multiplier'];

=head2 C<execution_date()>

Returns a Time::Moment object.

=cut

sub execution_date ($s) {
    Time::Moment->from_string($s->{execution_date} . 'T00:00:00Z');
}

sub _test_website {
    t::Utility::stash('SPLIT') // skip_all();
    isa_ok(t::Utility::stash('SPLIT')->execution_date, 'Time::Moment');
}

=head2 C<instrument( )>

    my $jnug = $split->instrument( );

Returns the related Finance::Robinhood::Equity::Instrument object.

=cut

sub instrument ( $s ) {
    my $res = $s->_rh->_get($s->{instrument});
    $res->is_success
        ? Finance::Robinhood::Equity::Instrument->new(_rh => $s->_rh,
                                                      %{$res->json})
        : Finance::Robinhood::Error->new(
             $res->is_server_error ? (details => $res->message) : $res->json);
}

sub _test_instrument {
    t::Utility::stash('SPLIT') // skip_all();
    my $inst = t::Utility::stash('SPLIT')->instrument();
    isa_ok($inst, 'Finance::Robinhood::Equity::Instrument');
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
