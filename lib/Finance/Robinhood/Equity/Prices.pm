package Finance::Robinhood::Equity::Prices;
our $VERSION = '0.92_003';

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Equity::Prices - Gather Real-Time Quote Data

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $prices = Finance::Robinhood->new( ... )->equity('MSFT')->prices( delayed => 0 );

    CORE::say 'Current price is $' . $prices->price;

=cut

use Moo;
use Data::Dump;
use HTTP::Tiny;
use JSON::Tiny;
use Types::Standard qw[Enum InstanceOf Num StrMatch Str];
use URI;
use experimental 'signatures';
#
use Finance::Robinhood::Types qw[:all];

sub _test__init {
    my $rh     = t::Utility::rh_instance(1);
    my $prices = $rh->equity('MSFT')->prices( delayed => 0 );
    isa_ok( $prices, __PACKAGE__ );
    t::Utility::stash( 'PRICES', $prices );    #  Store it for later
}
use overload '""' => sub ( $s, @ ) { $s->price }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('PRICES') // skip_all();
    like( +t::Utility::stash('PRICES'), qr[^\d+\.\d+$] );
}
#
has robinhood => ( is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood'] );

=head1 METHODS

=head2 C<ask_mic( )>

ISO 10383 ID of the provided ask data.

=head2 C<ask_price( )>

Returns the best ask price.

=head2 C<ask_size( )>

Returns the number of shares available at the best ask price.

=head2 C<bid_micv>

ISO 10383 ID of the provided bid data.

=head2 C<bid_price( )>

Returns the best bid price.

=head2 C<bid_size( )>

Returns the number of shares wanted at the best bid price.

=head2 C<equity( )>

Returns the related Finance::Robinhood::Equity object.

=head2 C<mic( )>

ISO 10383 ID of the provided price data.

=head2 C<price( )>

Returns the price of most recent execution.

=head2 C<size( )>

Returns the size of most recent execution.

=head2 C<updated_at( )>

Returns a Time::Moment object.

=cut

has [qw[ask_mic bid_mic mic]]       => ( is => 'ro', isa => Str, required => 1 );
has [qw[ask_price bid_price price]] => ( is => 'ro', isa => Num, required => 1 );
has [qw[ask_size bid_size size]]    => ( is => 'ro', isa => Num, required => 1 );
has updated_at    => ( is => 'ro', isa => Timestamp, coerce   => 1, required => 1 );
has instrument_id => ( is => 'ro', isa => UUID,      required => 1 );
has equity => (
    is      => 'ro',
    isa     => InstanceOf ['Finance::Robinhood::Equity'],
    lazy    => 1,
    builder => sub ($s) {
        $s->robinhood->equity_by_id( $s->instrument_id );
    }
);

sub _test_equity {
    t::Utility::stash('PRICES') // skip_all();
    my $equity = t::Utility::stash('PRICES')->equity;
    isa_ok( $equity, 'Finance::Robinhood::Equity' );
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
