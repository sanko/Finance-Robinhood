package Finance::Robinhood::Equity::Quote;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Equity::Quote - Represents Quote Data for a Single Equity
Instrument

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;

    # TODO

=cut

our $VERSION = '0.92_003';
use Moo;
use Data::Dump;
use HTTP::Tiny;
use JSON::Tiny;
use Types::Standard qw[Bool Enum InstanceOf Maybe Num StrMatch Str];
use URI;
use experimental 'signatures';
#
use Finance::Robinhood::Equity;
use Finance::Robinhood::Types qw[:all];
#
sub _test__init {
    my $rh    = t::Utility::rh_instance(1);
    my $quote = $rh->equity('MSFT')->quote();
    isa_ok( $quote, __PACKAGE__ );
    t::Utility::stash( 'QUOTE', $quote );    #  Store it for later
}
#
has robinhood => ( is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood'] );

=head1 METHODS

=head2 C<adjusted_previous_close( )>

Price at the end of Robinhood's trading period.

=head2 C<ask_price( )>

Delayed ask price.

=head2 C<ask_size( )>

How many shares are available at the current (delayed) ask price.

=head2 C<bid_price( )>

Delayed bid price.

=head2 C<bid_size( )>

How many shares are available at the current (delayed) bid price.

=head2 C<has_traded( )>

Returns a boolean value. True if this instrument has been traaded by the user.

=head2 C<last_extended_hours_trade_price( )>

Last pre- or after-hours trading price, if defined.

=head2 C<last_trade_price( )>

Price of the most recent live trade.

=head2 C<last_trade_price_source( )>

Which venue provided the last trade price.

=head2 C<previous_close( )>

Price of last trade before the close of trading.

=head2 C<previous_close_date( )>

Returns the date in YYYY-MM-DD format.

=head2 C<symbol( )>

The ticker symbol of the instrument related to this quote data. See C<equity(
)> to be given the object itself.

=head2 C<trading_halted( )>

Returns a boolean value. True if trading of this instrument is currently
halted.

=head2 C<updated_at( )>

Returns a Time::Moment object.

=cut

has [
    qw[adjusted_previous_close ask_price ask_size bid_price bid_size last_trade_price previous_close]
] => ( is => 'ro', isa => Num, required => 1 );
has last_extended_hours_trade_price => ( is => 'ro', isa => Maybe [Num], required => 1 );
has [qw[has_traded trading_halted]] => ( is => 'ro', isa => Bool, coerce => 1, required => 1 );
has last_trade_price_source => ( is => 'ro', isa => Enum [qw[consolidated nls]], required => 1 );
has previous_close_date =>
    ( is => 'ro', isa => StrMatch [qr[^\d\d\d\d-\d\d-\d\d$]], required => 1 );
has symbol => ( is => 'ro', isa => Str, required => 1 );

=head2 C<equity( )>

    my $instrument = $quote->equity();

Loops back to a Finance::Robinhood::Equity object.

=cut

has instrument => ( is => 'ro', isa => URL, coerce => 1, required => 1 );
has equity     => (
    is   => 'ro',
    isa  => InstanceOf ['Finance::Robinhood::Equity'],
    lazy => 1,
    builder =>
        sub ($s) { $s->robinhood->_req( GET => $s->instrument )->as('Finance::Robinhood::Equity') },
    init_arg => undef
);

sub _test_equity {
    t::Utility::stash('QUOTE') // skip_all();
    isa_ok( t::Utility::stash('QUOTE')->equity(), 'Finance::Robinhood::Equity' );
}

=head2 C<updated_at( )>

Returns a Time::Moment object.

=cut

has updated_at => ( is => 'ro', isa => Timestamp, coerce => 1, required => 1 );

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
