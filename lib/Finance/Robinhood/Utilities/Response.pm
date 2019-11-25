package    # hide it
    Finance::Robinhood::Utilities::Response;
our $VERSION = '0.92_003';

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Utilities::Response - HTTP Responses

=head1 SYNOPSIS

    use Finance::Robinhood;

    my $rh = Finance::Robinhood->new(username => 'timbob35', password => 'hunter3' ); # Wrong, I hope
    $rh || die $rh; # false value is returned; stringify it as a fatal error

=head1 DESCRIPTION

When this distribution has trouble with anything, this is returned.

Error objects evaluate to untrue values.

Error objects stringify to the contents of C<detail( )> or 'Unknown error.'

=head1 METHODS

=cut

use Moo;
use MooX::Enumeration;
use Types::Standard qw[Any ArrayRef Bool Dict Enum InstanceOf Maybe Num Str StrMatch];
use URI;
use Time::Moment;
use Data::Dump;
use experimental 'signatures';
use overload 'bool' => sub ( $s, @ ) { $s->success },
    '""'            => sub ( $s, @ ) {
    $s->message // 'Unknown error.';
    },
    fallback => 1;
#
use Moo;
use Types::Standard qw[InstanceOf Maybe ArrayRef HashRef Bool Num Str Ref];
use JSON::Tiny;
use Finance::Robinhood::Types qw[URL UUID Timestamp];
use URI;
use experimental 'signatures';
#

=head2 C<success( )>

Returns a boolean indicating whether the operation returned a 2XX status code.

=head2 C<url( )>

URL that provided the response. This is the URL of the request unless there
were redirections, in which case it is the last URL queried in a redirection
chain.

=head2 C<status( )>

Returns the HTTP status code of the response.

=head2 C<reason( )>

Returns the response phrase returned by the server.

=head2 C<success( )>

Boolean indicating whether the operation returned a 2XX  status code.

On an exception during the execution of the request, the "status" field will
contain 599, and the "content" field will contain the text of the exception.

=head2 C<headers( )>

A hashref of header fields. All header field names will be normalized to be
lower case. If a header is repeated, the value will be an arrayref; it will
otherwise be a scalar string containing the value.

=head2 C<protocol( )>

If this field exists, it is the protocol of the response such as HTTP/1.0 or
HTTP/1.1.

=head2 C<redirects( )>

If this field exists, it is an arrayref of response hash references from
redirects in the same order that redirections occurred. If it does not exist,
then no redirections occurred.

=head2 C<has_redirects( )>

Returns a true value if there are redirects in the response.

=cut

has robinhood            => ( is => 'ro', isa => InstanceOf ['Finance::Robinhood'] );
has protocol             => ( is => 'ro', isa => Str );
has redirects            => ( is => 'ro', isa => ArrayRef [HashRef], predicate => 'has_redirects' );
has headers              => ( is => 'ro', isa => HashRef [ ArrayRef [Str] | Str ] );
has status               => ( is => 'ro', isa => Num );
has [qw[content reason]] => ( is => 'ro', isa => Str );
has url                  => ( is => 'ro', isa => URL, coerce => 1 );
has success              => ( is => 'ro', isa => Bool, coerce => 1 );

=head2 C<json( )>

If the response has a JSON content type, this parses that content and returns
it neatly.

=head2 C<is_json( )>

Attempts to parse the content and returns true if successfull.

=cut

has json => (    # Smartly wrap JSON responses :D
    is        => 'ro',
    isa       => Maybe [Ref],
    init_arg  => undef,
    lazy      => 1,
    predicate => 'is_json',
    builder   => sub ($s) {
        ( $s->headers->{'content-type'} // '' ) =~ m[application/json] ?
            JSON::Tiny::decode_json( $s->content ) :
            ();
    }
);

=head2 C<as( ... )>

	$response->as(Dict[name => Str, type => Num]);

	$response->as('Finance::Robinhood::Equity');

Blesses or coerces the json content in the response.

=cut

sub as ( $s, @class ) {
    my $json = $s->json;
    use Data::Dump;
    ddx $json;
    if ( @class > 1 ) {
        my %class = @class;
        for my $key ( keys %class ) {
            $json->{$key} = [
                map {
                    warn;
                    ref $class{$key} &&
                        $class{$key}->isa('Type::Tiny') ? $class{$key}->coerce($_) :
                        $class{$key}->new( robinhood => $s->robinhood, %$_ );
                } @{ $json->{$key} }
            ];
        }
        return $json;
    }
    my $class = shift @class;
    warn $class;
    $class // return $json;
    if ( defined $json->{results} ) {
        $json->{results} = [
            map {
                use Data::Dump;

                #ddx \%$_;
                ref $class &&
                    $class->isa('Type::Tiny') ? $class->coerce($_) :
                    $class->new( robinhood => $s->robinhood, %$_ );
            } grep {defined} @{ delete $json->{results} }
        ];
        return $json;
    }
    warn ref $class;

    #use Data::Dump;
    #ddx $s->json;
    ref $class &&
        $class->isa('Type::Tiny') ? $class->coerce($json) :
        $class->new( %$json, robinhood => $s->robinhood );
}

=head2 C<message( )>

    warn $error->message;

Returns a string. If this is a failed API call, the message returned by the
service is here.

=cut

has message => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    builder => sub ($s) {
        !$s->success ? $s->reason : $s->json ? $s->json->{detail} : $s->reason;
    }
);

sub _test_message {
    require Finance::Robinhood;
    my $rh = Finance::Robinhood->new(
        username => substr( crypt( $< / $), rand $$ ), 0, 5 + rand(6) ),
        password => substr( crypt( $< / $), rand $$ ), 0, 5 + rand(6) )
    );    # Wrong, I hope
    #
    isa_ok( $rh, __PACKAGE__ );
    is( $rh->message, 'Bad Request', 'bad log in is an error' );
    #
    my $fourhundred = Finance::Robinhood->new->_req( GET => 'https://postman-echo.com/status/400' );
    isa_ok( $fourhundred, __PACKAGE__ );
    is( $fourhundred->message, 'Bad Request', 'error page is an error' );
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
