package Finance::Robinhood::Cash::Card;
our $VERSION = '0.92_003';

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Cash::Card - Represents an Cash Management Debit Card

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;
    my $card = $rh->debit_cards->current;

    $card->disable; # Goodbye, card!

=cut

use Moo;
use MooX::Enumeration;
use Types::Standard qw[ArrayRef Bool Dict Enum InstanceOf Maybe Num Str StrMatch];
use JSON::Tiny qw[encode_json];
use URI;
use Time::Moment;
use Data::Dump;
use experimental 'signatures';
use lib '../../../../lib';
use Finance::Robinhood::Types qw[:all];
use Finance::Robinhood::Utilities::Iterator;
#
sub _test__init {
    my $rh   = t::Utility::rh_instance(1);
    my $card = $rh->debit_cards->current;
    skip_all('No cash management debit cards found') if !defined $card;
    isa_ok( $card, __PACKAGE__ );
    t::Utility::stash( 'CARD', $card );    #  Store it for later
}
use overload '""' => sub ( $s, @ ) { $s->id }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('CARD') // skip_all();
    like( +t::Utility::stash('CARD'),
        qr'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'i );
}
#
has robinhood => ( is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood'] );

=head1 METHODS


=head2 C<account_id( )>

Returns a UUID.

=head2 C<card_color( )>

Returns either C<green> or C<white>, C<black>, or C<usa>.

=head2 C<is_green( )>

Returns a boolean value. True if C<card_color( )> is C<green>.

=head2 C<is_white( )>

Returns a boolean value. True if C<card_color( )> is C<white>.

=head2 C<is_black( )>

Returns a boolean value. True if C<card_color( )> is C<black>.

=head2 C<is_usa( )>

Returns a boolean value. True if C<card_color( )> is C<usa>.

=head2 C<card_type( )>

Returns C<debit>, C<credit> or C<unknown>.

=head2 C<is_debit( )>

Returns a boolean value. True if C<card_type( )> is C<debit>.

=head2 C<is_credit( )>

Returns a boolean value. True if C<card_type( )> is C<credit>.

=head2 C<disabled( )>

Returns a boolean value.

=head2 C<estimated_delivery_date( )>

Returns a Time::Moment object.

=head2 C<id( )>

Returns a UUID.

=head2 C<last_four_digits( )>

Last four digits of the card number.

=head2 C<pin_set( )>

Returns a boolean value. True if the pin is set.

=head2 C<shipping_update_request( )>

Returns a UUID.

=head2 C<state( )>

Returns C<new>, C<requested>, C<shipped>, C<active>, C<disabled>, C<lost>,
C<stolen>, or C<unknown>.

=head2 C<is_new( )>

Returns a boolean value. True if C<state( )> is C<>.

=head2 C<is_new( )>

Returns a boolean value. True if C<state( )> is C<new>.

=head2 C<is_requested( )>

Returns a boolean value. True if C<state( )> is C<requested>.

=head2 C<is_shipped( )>

Returns a boolean value. True if C<state( )> is C<shipped>.

=head2 C<is_active( )>

Returns a boolean value. True if C<state( )> is C<active>.

=head2 C<is_disabled( )>

Returns a boolean value. True if C<state( )> is C<disabled>.

=head2 C<is_lost( )>

Returns a boolean value. True if C<state( )> is C<lost>.

=head2 C<is_stolen( )>

Returns a boolean value. True if C<state( )> is C<stolen>.

=cut

has account_id => ( is => 'ro', isa => UUID, requried => 1 );
has card_color => (
    is       => 'ro',
    isa      => Enum [qw[green white black usa]],
    handles  => [qw[is_green is_white is_black is_usa]],
    required => 1
);
has card_type => (
    is       => 'ro',
    isa      => Enum [qw[debit credit]],
    handles  => [qw[is_debit is_credit]],
    required => 1
);
has disabled                => ( is => 'ro', isa => Bool,      coerce => 1, required => 1 );
has estimated_delivery_date => ( is => 'ro', isa => Timestamp, coerce => 1, required => 1 );
has id                      => ( is => 'ro', isa => UUID, required => 1 );
has last_four_digits        => ( is => 'ro', isa => Num,  required => 1 );
has pin_set                 => ( is => 'ro', isa => Bool, coerce   => 1, required => 1 );
has shipping_update_request => ( is => 'ro', isa => UUID, required => 1 );
has state => (
    is      => 'ro',
    isa     => Enum [qw[new requested shipped active disabled lost stolen unknown]],
    handles => [
        qw[
            is_new is_requested is_shipped is_active is_disabled is_lost is_stolen
            ]
    ]
);

=head2 C<disable( )>

Disables the card and returns a boolean value. True if successful.

=cut

sub disable($s) {
    $s->robinhood->_req(
        POST => sprintf 'https://minerva.robinhood.com/cards/%s/disable/',
        $s->id
    )->is_success;
}

=head2 C<enable( )>

Enables the card and returns a boolean value. True if successful.

=cut

sub enable($s) {
    $s->robinhood->_req( POST => sprintf 'https://minerva.robinhood.com/cards/%s/enable/', $s->id )
        ->is_success;
}

=head2 C<pending_transactions( ... )>

Returns an iterator filled with Finance::Robinhood::Cash::PendingTransaction
objects.

You must pass a Finance:Robinhood::Cash::Merchant object.

=cut

sub pending_transactions ( $s, $aggregate_merchant_id ) {    # TODO: Properly document merchant UUID
    Finance::Robinhood::Utilities::Iterator->new(
        robinhood => $s->robinhood,
        url => 'https://minerva.robinhood.com/cards/pending_transactions/?aggregate_merchant_id=' .
            $aggregate_merchant_id,

        #as => 'Finance::Robinhood::Cash::PendingTransaction'
    );
}

=head2 C<activate( $month, $year )>

Activates a new debit card.

The month should be two digits (MM) and the year should four digits (YYYY).

=cut

sub activate ( $s, $month, $year ) {
    $s->robinhood->_req(
        POST => 'https://minerva.robinhood.com/cards/' . $s->id . '/activate/',
        json => { expiry_month => $month, expiry_year => $year }
    );
}

=head2 C<change_pin( $pin )>

Initiate the process to change the card's four digit pin.

=cut

sub change_pin ( $s, $pin ) {
    my $request = $s->robinhood->_req(
        GET => 'https://minerva.robinhood.com/cards/' . $s->id . '/change_pin/' );
    if ($request) {
        my $data = $request->as(
            Dict [
                pin_change_key => Str,
                action_url     => URL,
                submitter_id   => StrMatch [qr[^\d\d\d-\d\d\d\d$]]
            ]
        );
        my $change = $s->robinhood->_req(
            POST =>    # Redirects back to Minerva
                $request->json->{action_url},
            query => { pin_change_key => $data->{pin_change_key} },
            form  => {
                pin            => $pin,
                pin_reentry    => $pin,
                pin_change_key => $data->{pin_change_key},
                submitter_id   => $data->{submitter_id}
            }
        );
        if ( $change->status == 302 ) {

            # Ping changed! Let RH know, they'll send us some value...
            my $x = $s->robinhood->_req( GET => $change->headers->{location} );

            # Tell them were done...
            return $s->robinhood->_req(
                POST => 'https://minerva.robinhood.com/cards/' . $s->id . '/commit_pin_change/',
                json => { response_code => $x->json->{r} }
            );
        }
    }
}

=begin todo

    @com.robinhood.android.featuregate.UseLocalityFeatureGate(localityFeatureGate = com.robinhood.android.featuregate.LocalityFeatureGates.CASH_MANAGEMENT)
    @retrofit2.http.GET("cards/pending_transactions/")
    io.reactivex.Single<com.robinhood.models.PaginatedResult<com.robinhood.models.api.minerva.ApiPendingCardTransaction>> getPendingCardTransactions(@retrofit2.http.Query("aggregate_merchant_id") java.util.UUID uuid);

    @com.robinhood.android.featuregate.UseLocalityFeatureGate(localityFeatureGate = com.robinhood.android.featuregate.LocalityFeatureGates.CASH_MANAGEMENT)
    @retrofit2.http.GET("cards/declined_transactions/{id}/")
    io.reactivex.Single<com.robinhood.models.api.minerva.ApiDeclinedCardTransaction> getDeclinedCardTransaction(@retrofit2.http.Path("id") java.util.UUID uuid);

    @com.robinhood.android.featuregate.UseLocalityFeatureGate(localityFeatureGate = com.robinhood.android.featuregate.LocalityFeatureGates.CASH_MANAGEMENT)
    @retrofit2.http.GET("cards/disputes/{id}/")
    io.reactivex.Single<com.robinhood.models.api.minerva.ApiDispute> getDispute(@retrofit2.http.Path("id") java.util.UUID uuid);

    @com.robinhood.android.featuregate.UseLocalityFeatureGate(localityFeatureGate = com.robinhood.android.featuregate.LocalityFeatureGates.CASH_MANAGEMENT)
    @retrofit2.http.GET("cards/pending_transactions/{id}/")
    io.reactivex.Single<com.robinhood.models.api.minerva.ApiPendingCardTransaction> getPendingCardTransaction(@retrofit2.http.Path("id") java.util.UUID uuid);

    @com.robinhood.android.featuregate.UseLocalityFeatureGate(localityFeatureGate = com.robinhood.android.featuregate.LocalityFeatureGates.CASH_MANAGEMENT)
    @retrofit2.http.GET("cards/settled_transactions/{id}/")
    io.reactivex.Single<com.robinhood.models.api.minerva.ApiSettledCardTransaction> getSettledCardTransaction(@retrofit2.http.Path("id") java.util.UUID uuid);

    @com.robinhood.android.featuregate.UseLocalityFeatureGate(localityFeatureGate = com.robinhood.android.featuregate.LocalityFeatureGates.CASH_MANAGEMENT)
    @retrofit2.http.GET("cards/settled_transactions/")
    io.reactivex.Single<com.robinhood.models.PaginatedResult<com.robinhood.models.api.minerva.ApiSettledCardTransaction>> getSettledCardTransactions(@retrofit2.http.Query("aggregate_merchant_id") java.util.UUID uuid);

    @com.robinhood.android.featuregate.UseLocalityFeatureGate(localityFeatureGate = com.robinhood.android.featuregate.LocalityFeatureGates.CASH_MANAGEMENT)
    @retrofit2.http.GET("cards/top_spent/{id}/?include_all=true")
    io.reactivex.Single<com.robinhood.models.api.minerva.ApiTopSpent> getTopSpent(@retrofit2.http.Path("id") java.util.UUID uuid);

    @retrofit2.http.POST("cards/declined_transactions/{id}/mark_fraudulent/")
    @com.robinhood.android.featuregate.UseLocalityFeatureGate(localityFeatureGate = com.robinhood.android.featuregate.LocalityFeatureGates.CASH_MANAGEMENT)
    io.reactivex.Completable markCardTransactionFraudulent(@retrofit2.http.Path("id") java.util.UUID uuid);

    @retrofit2.http.POST("cards/declined_transactions/{id}/mark_not_fraudulent/")
    @com.robinhood.android.featuregate.UseLocalityFeatureGate(localityFeatureGate = com.robinhood.android.featuregate.LocalityFeatureGates.CASH_MANAGEMENT)
    io.reactivex.Completable markCardTransactionNotFraudulent(@retrofit2.http.Path("id") java.util.UUID uuid);

    @com.robinhood.android.featuregate.UseLocalityFeatureGate(localityFeatureGate = com.robinhood.android.featuregate.LocalityFeatureGates.CASH_MANAGEMENT)
    @retrofit2.http.GET("cards/top_spent/")
    io.reactivex.Single<com.robinhood.models.PaginatedResult<com.robinhood.models.api.minerva.ApiTopSpent>> getTopSpent();



=end todo
=cut

sub top_spent ( $s, $all = 0 ) {     $s->robinhood->_req(         GET =>
'https://minerva.robinhood.com/cards/top_spent/' . $s->id . '/',         $all ?
( query => { include_all => 'true' } ) : ()     ); }

=head2 C<get_image_url( [$config] )>

Returns a URI object containing a link to of a PNG (with transparency) that can
be layed over a template card.

C<$config> is optional. It's a hash ref with the following keys:

=over

=item C<version> - Galileo API version (default is C<2>)

=item C<w> - Width of the card in millimeters (default is C<54>)

=item C<h> - Height of the card in millimeters (default is C<195>)

=item C<bg_color> - RBGA as a hash (default is C<<{ r => 0, g => 0, b => 0, a => 127 }>>)

=item C<txt> - Hash reference with values that can modify how the info on the card is displayed

=over

=item C<file> - The font used. (default is C<RHPFDinMono>)

Options for this include:

=over

=item C<toolkit-entypo>

=item C<RHPFDinMono>

=item C<OpenSans-Semibold>

=item C<OpenSans-SemiboldItalic>

=item C<OpenSans-Regular>

=item C<OpenSans-Light>

=item C<OpenSans-LightItalic>

=item C<OpenSans-Italic>

=item C<OpenSans-ExtraBold>

=item C<OpenSans-ExtraBoldItalic>

=item C<OpenSans-Bold>

=item C<OpenSans-BoldItalic>

=item C<OcrA>

=item C<kredit>

=item C<kredit_shine>

=item C<kredit_front>

=item C<kredit_back>

=item C<glyphicons-halflings-regular>

=back

=item C<color> - RBGA as a hash (default is C<<{ r => 255, g => 255, b => 255, a => 0 }>>)

=item C<fields> - Hash reference with the following keys:

=over

=item C<card> - Controls how the actual card number is displayed. Hash ref with the following keys:

=over

=item C<sep> - The character used to join the four card number quads (default is C<\n>)

=item C<pt> - Font size (default is C<18>)

=item C<x> - Position for the left side of the first digit.

=item C<y> - Position for the top of the first digit.

=back

=item C<cvv> - Controls how the B<C>ard B<V>erification B<V>alue is displayed. Hash ref with the following keys:

=over

=item C<pt> - Font size (default is C<11>)

=item C<x> - Position for the left side of the first digit.

=item C<y> - Position for the top of the first digit.

=back

=item C<exp>  - Controls how the expiration date is displayed. Hash ref with the following keys:

=over

=item C<pt> - Font size (default is C<11>)

=item C<x> - Position for the left side of the first digit.

=item C<y> - Position for the top of the first digit.

=back

=back

=back

=back

=head2 C<get_image( [$config] )>

Returns the raw data of a PNG (with transparency) that can be layed over a
template card.

See C<get_image_url( [$config] )> for C<$config> options.

=cut

sub get_image_url (
    $s,
    $config = {
        version  => 2,
        w        => 54,
        h        => 195,
        bg_color => { r => 0, g => 0, b => 0, a => 127 },
        txt      => {
            file   => 'RHPFDinMono',
            color  => { r => 255, g => 255, b => 255, a => 0 },
            fields => {
                card => { sep => "\n", pt => 18, x => 2, y => 18 },
                exp  => { pt  => 11,   x  => 13, y => 150 },
                cvv  => { pt  => 11,   x  => 28, y => 193 }
            }
        }
    }
) {
    my $url = $s->robinhood->_req(
        GET => sprintf 'https://minerva.robinhood.com/cards/%s/get_card_image/',
        $s->id
    )->as( Dict [ location => URL ] )->{location};
    my $image = encode_json($config);
    $image = encode_base64($image);
    $url->query_form( $url->query_form, image => $image );
    $url;
}

sub get_image($s) {
    $s->robinhood->_req( GET => $s->get_image_url )->content;
}

# Based on code taken from MIME::Base64::Perl
# Copyright 1995-1999, 2001-2004 Gisle Aas.
sub encode_base64 {
    my $res = pack( 'u', $_[0] );

    # Remove first character of each line, remove newlines
    $res =~ s/^.//mg;
    $res =~ s/\n//g;
    $res =~ tr|` -_|AA-Za-z0-9+/|;
    return $res;
}

=head2 C<report_damaged( [...] )>

	$card->report_damaged;

Reports the debit card as damaged and arranges for a new one to be mailed.

	$card->report_damaged(
		address1 => '1999 Main Street',
		city => 'New New York',
		province => 'New York',
		postal_code => 10019,
		country_of_residence => 'US'
	);


To send your replacement card to another address, you may define the following
parameters:

=over

=item C<address1> (required)

=item C<address2> (optional)

=item C<city> (required)

=item C<province> (required)

=item C<country_of_residence> (required)

=item C<postal_code> (required)

=back

=cut

sub report_damaged ( $s, $shipping = $s->robinhood->user->basic_info ) {
    $shipping = {
        address1             => $shipping->address,
        city                 => $shipping->city,
        country_of_residence => $shipping->country_of_residence,
        postal_code          => $shipping->zipcode,
        provence             => $shipping->state
        }
        if ref $shipping eq 'Finance::Robinhood::User::BasicInfo';
    $s->robinhood->_req(
        POST => 'https://minerva.robinhood.com/cards/' . $s->id . '/report_damaged/',
        form => $shipping
    );
}

=head2 C<report_lost( [...] )>

	$card->report_lost;

Reports the debit card as lost and arranges for a new one to be mailed.

	$card->report_lost(
		address1 => '1999 Main Street',
		city => 'New New York',
		province => 'New York',
		postal_code => 10019,
		country_of_residence => 'US'
	);


To send your replacement card to another address, you may define the following
parameters:

=over

=item C<address1> (required)

=item C<address2> (optional)

=item C<city> (required)

=item C<province> (required)

=item C<country_of_residence> (required)

=item C<postal_code> (required)

=back

=cut

sub report_lost ( $s, $shipping = $s->robinhood->user->basic_info ) {
    $shipping = {
        address1             => $shipping->address,
        city                 => $shipping->city,
        country_of_residence => $shipping->country_of_residence,
        postal_code          => $shipping->zipcode,
        provence             => $shipping->state
        }
        if ref $shipping eq 'Finance::Robinhood::User::BasicInfo';
    $s->robinhood->_req(
        POST => 'https://minerva.robinhood.com/cards/' . $s->id . '/report_lost/',
        form => $shipping
    );
}

=head2 C<report_stolen( [...] )>

	$card->report_stolen;

Reports the debit card as stolen and arranges for a new one to be mailed.

	$card->report_stolen(
		address1 => '1999 Main Street',
		city => 'New New York',
		province => 'New York',
		postal_code => 10019,
		country_of_residence => 'US'
	);


To send your replacement card to another address, you may define the following
parameters:

=over

=item C<address1> (required)

=item C<address2> (optional)

=item C<city> (required)

=item C<province> (required)

=item C<country_of_residence> (required)

=item C<postal_code> (required)

=back

=cut

sub report_stolen ( $s, $shipping = $s->robinhood->user->basic_info ) {
    $shipping = {
        address1             => $shipping->address,
        city                 => $shipping->city,
        country_of_residence => $shipping->country_of_residence,
        postal_code          => $shipping->zipcode,
        provence             => $shipping->state
        }
        if ref $shipping eq 'Finance::Robinhood::User::BasicInfo';
    $s->robinhood->_req(
        POST => 'https://minerva.robinhood.com/cards/' . $s->id . '/report_stolen/',
        form => $shipping
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
