package Finance::Robinhood::Utils::Client;
use Moo;
use HTTP::Tiny;
use JSON::Tiny qw[decode_json encode_json];
with 'MooX::Singleton';
use Finance::Robinhood::Utils::Credentials;
use Finance::Robinhood::Utils::Error;
#
has 'http' => (
    is      => 'ro',
    builder => sub {
        HTTP::Tiny->new(
            agent => 'Finance::Robinhood/' . $Finance::Robinhood::VERSION,
            default_headers =>
                { 'X-Robinhood-API-Version' => '1.197.0', 'X-Midlands-API-Version' => '1.48.1' }
        );
    },
    lazy => 1
);
has 'credentials' => (
    is      => 'rw',
    builder => sub { Finance::Robinhood::Utils::Credentials->instance },
    handles => [qw(headers)],
    lazy    => 1
);
has 'account' => (
    is      => 'rw',
    builder => sub {
        my $acct = Finance::Robinhood::Utils::Paginated->new(
            class => 'Finance::Robinhood::Account',
            next  => $Finance::Robinhood::Endpoints{'accounts'}
        )->next;
    },
    lazy => 1
);

sub _http {
    my ( $s, $method, $url, $args, $headers ) = @_;
###
    #warn $url;
    use Data::Dump;

    #ddx [caller(1)];
    ddx [ $method, $url, $args, $headers ];
    %$headers = ( %{ $s->headers // () }, $headers ? %$headers : () );

    #@$headers{keys %$args} = values %$args;
    delete $headers->{'Authorization'} if $args->{'skip_authorization'};
    if ( $method ne 'GET' && $args->{content} ) {
        if (0) {
            $headers->{'Content-Type'} = 'application/x-www-form-urlencoded';
            $args->{content} = __urlencode( $args->{content} );
        }
        else {
            $headers->{'Content-Type'} = 'application/json';
            $args->{content} = encode_json( $args->{content} );
        }
    }

    #ddx [ $method, $url, { %$args, headers => ($headers) }];
    my $response = $s->http->request( $method, $url, { %$args, headers => ($headers) } );
    if ( $response->{status} == 429 && $method eq 'GET' && !$headers->{'BOUNCER-FORCE'} ) {
        $headers->{'X-BOUNCER-FORCE'} = 'true';
        return shift->_http(@_);
    }

    #die "Failed!\n" unless $response->{success};
    #print "$response->{status} $response->{reason}\n";
    #while ( my ( $k, $v ) = each %{ $response->{headers} } ) {
    #    for ( ref $v eq 'ARRAY' ? @$v : $v ) {
    #        print "$k: $_\n";
    #    }
    #}
    #ddx$response;
    my $content = length $response->{content} ? decode_json( $response->{content} ) : ();

    #warn $response->{content} if length $response->{content};
    #use Path::Tiny;
    # creating Path::Tiny objects
    #my $dir  = path("/tmp");
    #my $name = $url;
    #$name =~ s[[^a-z\d]+][_]g;
    #warn $name;
    #my $bar = $dir->child( $method . '_' . $name . '.txt' );
    #$bar->spew( $response->{content} );
    $content
        = Finance::Robinhood::Utils::Error->new( status => $response->{status}, data => $content )
        if $response->{status} > 201;

    #ddx [$response->{status}, $content];
    wantarray ? ( $response->{status}, $content ) : $content;
}

sub __urlencode {
    my $data = shift;
    if ( ref $data eq 'HASH' ) {
        return join '&', sort { $a cmp $b } map {
            __urlencode($_) . '=' . join ',',
                map { join ',', __urlencode($_) }
                @{ ref $data->{$_} eq 'ARRAY' ? $data->{$_} : [ $data->{$_} ] }
        } keys %$data;
    }
    $data =~ s/([^A-Za-z0-9\+-])/sprintf("%%%02X", ord($1))/seg;
    $data =~ s/ /+/g;
    return $data;
}

sub get {
    my ( $s, $url, $args ) = @_;
    $url = $url . ( $url =~ m[\?] ? '&' : '?' ) . __urlencode($args) if keys %$args;
    return $s->_http( 'GET', $url );
}

sub post {
    my ( $s, $url, $data ) = @_;
    return $s->_http( 'POST', $url, { content => $data } );
}

sub put {
    my ( $s, $url, $data ) = @_;
    return $s->_http( 'PUT', $url, { content => $data } );
}

sub options {
    my ( $s, $url, $data ) = @_;
    return $s->_http( 'OPTIONS', $url, { content => $data } );
}

sub patch {
    my ( $s, $url, $data ) = @_;
    return $s->_http( 'PATCH', $url, { content => $data } );
}

sub delete {
    my ( $s, $url ) = @_;
    return $s->_http( 'DELETE', $url );
}
1;
