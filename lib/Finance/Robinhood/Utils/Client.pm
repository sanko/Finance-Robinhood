package Finance::Robinhood::Utils::Client;
use Moo;
use HTTP::Tiny;
use JSON::Tiny qw[decode_json encode_json];
use Try::Tiny;
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
    is      => 'ro',
    builder => sub {
        Finance::Robinhood::Utils::Paginated->new(
            class => 'Finance::Robinhood::Account',
            next  => $Finance::Robinhood::Endpoints{'accounts'}
        )->next;
    },
    lazy => 1
);

sub _http {
    my ( $s, $method, $url, $args, $headers ) = @_;
    $args    //= {};
    $headers //= {};
###
    #warn $url;
    #use Data::Dump;
    #ddx [caller(1)];
    #ddx [ $method, $url, $args, $headers ];
    %$headers = ( %{ $s->headers($headers) // () }, $headers ? %$headers : () );
    if ( $method ne 'GET' && $args->{content} ) {
        if ( $headers->{'Content-Type'} // '' eq 'application/x-www-form-urlencoded' ) {
            $args->{content} = __urlencode( $args->{content} );
        }
        else {
            $headers->{'Content-Type'} = 'application/json';
            $args->{content} = encode_json( $args->{content} );
        }
    }

    #use Data::Dump;
    #ddx [ $method, $url, { %$args, headers => ($headers) } ];
    my $response = $s->http->request( $method, $url, { %$args, headers => ($headers) } );
    if ( $response->{status} == 429 && $method eq 'GET' && !$headers->{'BOUNCER-FORCE'} ) {
        $headers->{'X-BOUNCER-FORCE'} = 'true';
        return shift->_http( $method, $url, $_[3], $headers );
    }

    #die "Failed!\n" unless $response->{success};
    #print "$response->{status} $response->{reason}\n";
    #while ( my ( $k, $v ) = each %{ $response->{headers} } ) {
    #    for ( ref $v eq 'ARRAY' ? @$v : $v ) {
    #        print "$k: $_\n";
    #    }
    #}
    #use Data::Dump;
    #ddx $response;
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

sub __url_and_args {
    my ( $url, $args ) = @_;
    join '?', grep {length} $url, join '&', map {
        __urlencode($_) . '=' . (
            ref $args->{$_} eq 'ARRAY' ? ( join ',', map { __urlencode($_) } @{ $args->{$_} } ) :
                __urlencode( $args->{$_} ) )
    } keys %$args;
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
    elsif ( ref $data eq 'SCALAR' ) {
        $data = $data ? 'true' : 'false';
    }
    $data =~ s/([^A-Za-z0-9\+-])/sprintf("%%%02X", ord($1))/seg;
    $data =~ s/ /+/g;
    return $data;
}

sub get {
    my ( $s, $url, $args, $headers ) = @_;
    $url = $url . ( $url =~ m[\?] ? '&' : '?' ) . __urlencode($args) if keys %$args;
    return $s->_http( 'GET', $url, (), $headers );
}

sub post {
    my ( $s, $url, $data, $headers ) = @_;
    return $s->_http( 'POST', $url, { content => $data }, $headers );
}

sub put {
    my ( $s, $url, $data, $headers ) = @_;
    return $s->_http( 'PUT', $url, { content => $data }, $headers );
}

sub options {
    my ( $s, $url, $data, $headers ) = @_;
    return $s->_http( 'OPTIONS', $url, { content => $data }, $headers );
}

sub patch {
    my ( $s, $url, $data, $headers ) = @_;
    return $s->_http( 'PATCH', $url, { content => $data }, $headers );
}

sub delete {
    my ( $s, $url, $headers ) = @_;
    return $s->_http( 'DELETE', $url, (), $headers );
}
1;
