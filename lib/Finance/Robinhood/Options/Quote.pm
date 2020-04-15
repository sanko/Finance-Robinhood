package Finance::Robinhood::Options::Quote;
our $VERSION = '0.92_003';

=encoding utf-8

=for stopwords watchlist watchlists untradable urls vega

=head1 NAME

Finance::Robinhood::Options::Quote - Represents Quote Data for a Single Options
Instrument

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;
    my $instruments = $rh->options();

    for my $instrument ($instruments->take(3)) {
        CORE::say $instrument->quote->last_trade_price;
    }

=cut

use Moo;
use MooX::Enumeration;
use Types::Standard qw[ArrayRef Bool Dict Enum InstanceOf Maybe Num Str StrMatch];
use URI;
use Time::Moment;
use Data::Dump;
use experimental 'signatures';
#
use Finance::Robinhood::Options;

sub _test__init {
    my $rh    = t::Utility::rh_instance(1);
    my $quote = $rh->options_instrument_by_id('78ff8b76-4886-40bd-bfc8-b563b17c99c0')->quote();
    isa_ok( $quote, __PACKAGE__ );
    t::Utility::stash( 'QUOTE', $quote );    #  Store it for later
}
#
has robinhood => ( is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood'] );

=head1 METHODS


=head2 adjusted_mark_price( )


=head2 ask_price( )


=head2 ask_size( )


=head2 bid_price( )


=head2 bid_size( )


=head2 break_even_price( )


=head2 chance_of_profit_long( )


=head2 chance_of_profit_short( )


=head2 delta( )


=head2 gamma( )


=head2 high_fill_rate_buy_price( )


=head2 high_fill_rate_sell_price( )


=head2 high_price( )


=head2 last_trade_price( )


=head2 last_trade_size( )


=head2 low_fill_rate_buy_price( )


=head2 low_fill_rate_sell_price( )


=head2 low_price( )


=head2 open_interest( )


=head2 previous_close_price( )

The price at the most recent close.

=head2 rho( )


=head2 theta( )


=head2 vega( )


=head2 volume( )


=cut

has [
    'adjusted_mark_price',      'ask_price',
    'ask_size',                 'bid_price',
    'bid_size',                 'break_even_price',
    'chance_of_profit_long',    'chance_of_profit_short',
    'delta',                    'gamma',
    'high_fill_rate_buy_price', 'high_fill_rate_sell_price',
    'high_price',               'last_trade_price',
    'last_trade_size',          'low_fill_rate_buy_price',
    'low_fill_rate_sell_price', 'low_price',
    'open_interest',            'previous_close_price',
    'rho',                      'theta',
    'vega',                     'volume',
] => ( is => 'ro', isa => Str, required => 1 );

=head2 C<previous_close_date( )>

    $quote->previous_close_date();

Returns a Time::Moment object.

=cut

sub previous_close_date ($s) {
    Time::Moment->from_string( $s->{previous_close_date} . 'T16:30:00-05:00' );
}

sub _test_previous_close_date {
    t::Utility::stash('QUOTE') // skip_all();
    isa_ok( t::Utility::stash('QUOTE')->previous_close_date(), 'Time::Moment' );
}

=head2 C<instrument( )>

    my $instrument = $quote->instrument();

Loops back to a Finance::Robinhood::Options::Instrument object.

=cut

sub instrument ($s) {
    my $res = $s->_rh->_get( $s->{instrument} );
    $res->is_success
        ? Finance::Robinhood::Options::Instrument->new(
        _rh => $s->_rh,
        %{ $res->json }
        )
        : Finance::Robinhood::Error->new(
        $res->is_server_error ? ( details => $res->message ) : $res->json );
}

sub _test_instrument {
    t::Utility::stash('QUOTE') // skip_all();
    isa_ok(
        t::Utility::stash('QUOTE')->instrument(),
        'Finance::Robinhood::Options::Instrument'
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
