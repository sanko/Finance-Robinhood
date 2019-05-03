package Finance::Robinhood::Error::Challenge;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Error::Challenge - Device Authentication

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
values if the challenge was met sucessfully.

=head1 METHODS

=cut

our $VERSION = '0.92_002';
use Mojo::Base-base, -signatures;
use Mojo::URL;
use Time::Moment;
use overload 'bool' => sub ($s, @) { $s->status eq 'validated' ? 1 : 0 },
    fallback => 1;
#
has _rh => undef => weak => 1;

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

has ['id',                'user',
     'type',              'alternate_type',
     'remaining_retries', 'remaining_attempts',
     'status'
];

=head2 C<expires_at( )>

    $challenge->expires_at;

Returns a Time::Moment object. This value should be 5 minutes in the future
which is how long you have to C<respond( ... )> to the challenge.

=cut

sub expires_at($s) {
    Time::Moment->from_string($s->{expires_at});
}

=head2 C<email( )>

    $challenge->email;

Request that the system sends the authorization key via email to the address on
file.

=cut

sub email ($s) {
    my $res
        = $s->_rh->_post(
           sprintf('https://api.robinhood.com/challenge/%s/replace/', $s->id),
           challenge_type => 'email');
    $_[0] = $res->is_success
        ? Finance::Robinhood::Error::Challenge->new(_rh => $s->_rh,
                                                    %{$res->json->{challenge}}
        )
        : Finance::Robinhood::Error->new(
             $res->is_server_error ? (details => $res->message) : $res->json);
}

=head2 C<sms( )>

    $challenge->sms;

Request that the system sends the authorization key via SMS to the phone number
on file.

=cut

sub sms ($s) {
    my $res
        = $s->_rh->_post(
           sprintf('https://api.robinhood.com/challenge/%s/replace/', $s->id),
           challenge_type => 'sms');
    $_[0] = $res->is_success
        ? Finance::Robinhood::Error::Challenge->new(_rh => $s->_rh,
                                                    %{$res->json->{challenge}}
        )
        : Finance::Robinhood::Error->new(
             $res->is_server_error ? (details => $res->message) : $res->json);
}

=head2 C<respond( ... )>

    $challenge->respond( 003298 );

Respond to the challenge with the string sent to you via SMS or email.

=cut

sub respond ($s, $response) {
    my $res
        = $s->_rh->_post(
           sprintf('https://api.robinhood.com/challenge/%s/respond/', $s->id),
           response => $response);
    $_[0] = $res->is_success
        ? Finance::Robinhood::Error::Challenge->new(_rh => $s->_rh,
                                                    %{$res->json})
        : Finance::Robinhood::Error->new(
             $res->is_server_error ? (details => $res->message) : $res->json);
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
