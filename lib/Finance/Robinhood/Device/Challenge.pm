package Finance::Robinhood::Device::Challenge;
our $VERSION = '0.92_003';

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Device::Challenge - Device Authentication

=head1 SYNOPSIS

    $challenge->respond( 284750 );
    $challenge || die; # false value is retured when the challenge response has not been validated

=head1 DESCRIPTION

As a security measure, Robinhood has implemented user-involved client
validation. When met with a challenge, the user must respond with a six digit
string of numbers sent to them via SMS or email within a certain length of
time. Failing to respond or failing to respond with the correct numbers
blacklists the device from accessing the user's account.

Challenge objects evaluate to untrue values if the response was invalid or if
the challenge has not been responded to yet. Obviously, they evaluate to true
values if the challenge was met successfully.

=head1 METHODS

=cut

use strictures 2;
use namespace::clean;
use Moo;
use MooX::Enumeration;
use Data::Dump;
use HTTP::Tiny;
use JSON::Tiny;
use Types::Standard qw[ArrayRef Bool Dict Enum InstanceOf Maybe Num Str StrMatch];
use Finance::Robinhood::Types qw[URL UUID Timestamp];
use URI;
use experimental 'signatures';
#
use overload 'bool' => sub ( $s, @ ) { $s->is_validated },
    fallback        => 1;
#
has robinhood => ( is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood'] );

=head2 C<id( )>

UUID of the challenge request.

=head2 C<user( )>

UUID of the currently or attempting to log in.

=head2 C<type( )>

Current primary means of sending validation key.

=head2 C<alternate_type( )>

Alternate means of sending validation key.

=head2 C<remaining_retries( )>

The number of times the system will attempt to deliver the validation key.

=head2 C<remaining_attempts( )>

The number of times the user has to verify before the device ID is blocked.

=head2 C<status( )>

    return 'OK' if $challenge->status eq 'validated';

Returns whether the challenge has been C<issued>, C<validated>, etc.

=cut

has [qw[id user]] => ( is => 'ro', isa => UUID, required => 1 );
has type =>
    ( is => 'ro', isa => Enum [qw[email sms]], handles => [qw[is_email is_sms]], required => 1 );
has alternate_type => ( is => 'ro', isa => Enum [qw[email sms]], required => 1 );
has [qw[remaining_retries remaining_attempts]] => ( is => 'ro', isa => Num, required => 1 );
has status => ( is => 'ro', isa => Enum [qw[issued validated]], handles => [qw[is_validated]] );

=head2 C<expires_at( )>

    $challenge->expires_at;

Returns a Time::Moment object. This value should be 5 minutes in the future
which is how long you have to C<respond( ... )> to the challenge.

=cut

has expires_at => ( is => 'ro', isa => Timestamp, coerce => 1, required => 1 );

=head2 C<email( )>

    $challenge->email;

Request that the system sends the authorization key via email to the address on
file.

=cut

sub email ($s) {
    my $res = $s->robinhood->_req(
        POST => sprintf( 'https://api.robinhood.com/challenge/%s/replace/', $s->id ),
        form => { challenge_type => 'email' }
    );
    $_[0] = $res->is_success
        ? Finance::Robinhood::Device::Challenge->new(
        robinhood => $s->robinhood,
        %{ $res->json->{challenge} }
        )
        : $res;
}

=head2 C<sms( )>

    $challenge->sms;

Request that the system sends the authorization key via SMS to the phone number
on file.

=cut

sub sms ($s) {
    my $res = $s->robinhood->_req(
        POST => sprintf( 'https://api.robinhood.com/challenge/%s/replace/', $s->id ),
        form => { challenge_type => 'sms' }
    );
    $_[0] = $res->is_success
        ? Finance::Robinhood::Device::Challenge->new(
        robinhood => $s->robinhood,
        %{ $res->json->{challenge} }
        )
        : $res;
}

=head2 C<respond( ... )>

    $challenge->respond( 003298 );

Respond to the challenge with the string sent to you via SMS or email.

=cut

sub respond ( $s, $response ) {
    my $res = $s->robinhood->_req(
        POST => sprintf( 'https://api.robinhood.com/challenge/%s/respond/', $s->id ),
        json => { response => $response }
    );
    $_[0]
        = Finance::Robinhood::Device::Challenge->new( robinhood => $s->robinhood, %{ $res->json } );
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
