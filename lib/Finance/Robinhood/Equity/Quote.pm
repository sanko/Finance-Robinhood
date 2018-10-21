package Finance::Robinhood::Equity::Quote;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Equity::Quote - Represents Quote Data for a Single Equity
Instrument

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;
    my $instruments = $rh->instruments();

    for my $instrument ($instruments->all) {
        CORE::say $instrument->quote->last_trade_price;
    }

=cut

sub _test__init {
    plan( tests => 1 );
    use_ok('Finance::Robinhood');
}
use Mojo::Base-base, -signatures;
use Mojo::URL;
#
use Time::Moment;
#
has _rh => undef => weak => 1;

=head1 METHODS



=head2 C<adjusted_previous_close( )>



=head2 C<ask_price( )>

Delayed ask price.

=head2 C<ask_size( )>

Delayed ask size.

=head2 C<bid_price( )>

Delayed bid price.

=head2 C<bid_size( )>

Delayed bid size.

=head2 C<has_traded( )>

Boolean value... no idea what this means yet.

=head2 C<last_extended_hours_trade_price( )>

Last pre- or after-hours trading price.

=head2 C<last_trade_price( )>

=head2 C<last_trade_price_source( )>

Which venue provided the last trade price.

=head2 C<previous_close( )>

The price at the most recent close.

=head2 C<symbol( )>

The ticker symbol of the instrument related to this quote data. See
C<instrument( )> to be given the instrument object itself.

=head2 C<trading_halted( )>

Returns a boolean value; true if trading is halted.

=cut

has [
    'adjusted_previous_close',         'ask_price',
    'ask_size',                        'bid_price',
    'bid_size',                        'has_traded',
    'last_extended_hours_trade_price', 'last_trade_price',
    'last_trade_price_source',         'previous_close',
    'symbol',                          'trading_halted'
];

=head2 C<previous_close_date( )>

    $quote->previous_close_date();

Returns a Time::Moment object.

=cut

sub previous_close_date ($s) {
    Time::Moment->from_string( $s->{previous_close_date} . 'T16:30:00-05:00' );
}

sub _test_previous_close_date {
    plan( tests => 2 );
    my $rh         = new_ok('Finance::Robinhood');
    my $instrument = $rh->search('MSFT')->{instruments}[0];
    isa_ok(
        $instrument->quote()->previous_close_date(),
        'Time::Moment', '...->previous_close_date() works',
    );
    done_testing();
}

=head2 C<updated_at( )>

    $quote->updated_at();

Returns a Time::Moment object.

=cut

sub updated_at ($s) {
    Time::Moment->from_string( $s->{updated_at} );
}

sub _test_updated_at {
    plan( tests => 2 );
    my $rh         = new_ok('Finance::Robinhood');
    my $instrument = $rh->search('MSFT')->{instruments}[0];
    isa_ok( $instrument->quote()->updated_at(), 'Time::Moment', '...->updated_at() works', );
    done_testing();
}

=head2 C<instrument( )>

    my $instrument = $quote->instrument();

Loops back to a Finance::Robinhood::Equity::Instrument object.

=cut

sub instrument ($s) {
    my $res = $s->_rh->_get( $s->{instrument} );
    $res->is_success ?
        Finance::Robinhood::Equity::Instrument->new( _rh => $s->_rh, %{ $res->json } ) :
        Finance::Robinhood::Error->new( $res->json );
}

sub _test_instrument {
    plan( tests => 2 );
    my $rh         = new_ok('Finance::Robinhood');
    my $instrument = $rh->search('MSFT')->{instruments}[0];
    isa_ok(
        $instrument->quote()->instrument(),
        'Finance::Robinhood::Equity::Instrument',
        '...->instrument() works',
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
