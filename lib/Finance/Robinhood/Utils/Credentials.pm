package Finance::Robinhood::Utils::Credentials;
use Moo;
with 'MooX::Singleton';
has 'old_skool' => ( is => 'rw', clearer => 1, predicate => 1 );
has 'oauth'     => ( is => 'rw', clearer => 1, predicate => 1 );

sub migrate {
    my $s = shift;
    return 1 if $s->has_oauth;
    return 0 if !$s->has_old_skool;
    my ( $status, $token )
        = Finance::Robinhood::Utils::Client->instance->post(
        $Finance::Robinhood::Endpoints{'oauth2/migrate_token'} );
    $token->{_birth} = time;
    $status == 200 ? !!$s->oauth($token) && $s->clear_old_skool() : 0;
}

sub headers {
    my ( $s, $headers ) = @_;
    if ( $headers->{'X-Skip-Authorization'} ) {
        delete $headers->{'X-Skip-Authorization'};
    }
    elsif ( $s->has_oauth ) {
        if ( $s->oauth->{_birth} + $s->oauth->{expires_in} <= time ) {
            if ( $s->oauth->{client_id} ) {
                my ( $ok, $token ) = Finance::Robinhood::Utils::Client->instance->post(
                    $Finance::Robinhood::Endpoints{'oauth2/token'},
                    {   refresh_token => $s->oauth->{refresh_token},
                        grant_type    => 'refresh_token',
                        scope         => $s->oauth->{scope},
                        client_id     => $s->oauth->{client_id},
                    },
                    {   'Content-Type'         => 'application/x-www-form-urlencoded',
                        'X-Skip-Authorization' => 1
                    }
                );
                $token->{_birth} = time;
                $s->oauth($token) if $ok == 200;
            }
            else {
                ...    # TODO: store the token, login old skool, then migrate?
            }
        }
        $headers->{Authorization} = 'Bearer ' . $s->oauth->{access_token};
    }
    elsif ( $s->has_old_skool ) {
        $headers->{Authorization} = 'Token ' . $s->old_skool;
    }
    $headers;
}
1;
