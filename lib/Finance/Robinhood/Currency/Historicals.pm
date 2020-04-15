package Finance::Robinhood::Currency::Historicals;
our $VERSION = '0.92_003';

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Currency::Historicals - Represents a Forex Currency's
Historical Price Data

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new( ... );

    # TODO

=cut

use Data::Dump;
use strictures 2;
use namespace::clean;
use HTTP::Tiny;
use JSON::Tiny;
use Moo;
use MooX::ChainedAttributes;
use Types::Standard qw[ArrayRef Bool Dict Enum InstanceOf Maybe Num Str StrMatch];
use experimental 'signatures';
use Finance::Robinhood::Types qw[Timestamp];

sub _test__init {
    my $rh          = t::Utility::rh_instance(1);
    my $historicals = $rh->currency_pair_by_id('3d961844-d360-45fc-989b-f6fca761d511')    # BTC-USD
        ->historicals( interval => '5minute' );
    isa_ok( $historicals, __PACKAGE__ );
    t::Utility::stash( 'HISTORICALS', $historicals );    #  Store it for later
}
##

=head1 METHODS

=cut

has robinhood => ( is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood'] );

=head2 C<bounds( )>


=head2 C<data_points( )>

Returns a list of hash references. These hash references hold the following
keys:

=over

=item C<begins_at> - Time::Moment object

=item C<close_price>

=item C<high_price>

=item C<interpolated> - Boolean value

=item C<low_price>

=item C<open_price>

=item C<session>

=item C<volume>

=back

=head2 C<interval( )>



=head2 C<open_price( )>


=head2 C<open_time( )>

Returns a Time::Moment object.

=head2 C<previous_close_price( )>


=head2 C<previous_close_time( )>

Returns a Time::Moment object.

=head2 C<span( )>


=head2 C<symbol( )>

=cut

has bounds => (
    is       => 'ro',
    isa      => Enum [qw[24_7 regular trading extended]],
    required => 1
);
has interval => (
    is       => 'ro',
    isa      => Enum [qw[15second week hour day 10minute 5minute 30minute]],
    required => 1
);
has open_price           => ( is => 'ro', isa => Maybe [Num], required => 1 );
has previous_close_price => ( is => 'ro', isa => Maybe [Num], required => 1 );
has span                 => (
    is       => 'ro',
    isa      => Enum [qw[hour day week month year 5year all]],
    required => 1
);
has symbol      => ( is => 'ro', isa => Str, required => 1 );
has data_points => (
    is  => 'ro',
    isa => ArrayRef [
        Dict [
            begins_at    => Timestamp,
            close_price  => Num,
            high_price   => Num,
            interpolated => Bool,
            low_price    => Num,
            open_price   => Num,
            session      => Enum [qw[reg]],
            volume       => Maybe [Num]
        ]
    ],
    coerce   => 1,
    required => 1
);

sub _test_data_points {
    t::Utility::stash('HISTORICALS') // skip_all('No historicals object in stash');
    my ($datapoint) = t::Utility::stash('HISTORICALS')->data_points;
    ref_ok( $datapoint, 'HASH' );
}
has open_time => ( is => 'ro', isa => Maybe [Timestamp], coerce => 1, required => 1 );

sub _test_open_time {
    t::Utility::stash('HISTORICALS') // skip_all('No historicals object in stash');
    isa_ok( t::Utility::stash('HISTORICALS')->open_time, 'Time::Moment' );
}

=head2 C<previous_close_time( )>

Returns a Time::Moment object.

=cut

has previous_close_time => ( is => 'ro', isa => Maybe [Timestamp], coerce => 1, required => 1 );

sub _test_previous_close_time {
    t::Utility::stash('HISTORICALS') // skip_all('No historicals object in stash');
    isa_ok(
        t::Utility::stash('HISTORICALS')->previous_close_time,
        'Time::Moment'
    );
}

=head2 C<pair( )>

Returns the related Finance::Robinhood::Currency::Pair object.

=cut

sub pair ($s) {
    $s->robinhood->currency_pair_by_id( $s->id );
}

sub _test_instrument {
    t::Utility::stash('HISTORICALS') // skip_all('No historicals object in stash');
    isa_ok(
        t::Utility::stash('HISTORICALS')->pair,
        'Finance::Robinhood::Currency::Pair'
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
