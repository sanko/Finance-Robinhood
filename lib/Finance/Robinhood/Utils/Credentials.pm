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
    $status == 200 ? !!$s->oauth( $token, _birth => time ) && $s->clear_old_skool() : 0;
}

sub headers {
    my $s = shift;
    if ( $s->has_oauth ) {

        #use Data::Dump;
        # TODO: If expired, use refresh token to get new access token
        #ddx $s->oauth;
        return { Authorization => 'Bearer ' . $s->oauth->{access_token} };
    }
    elsif ( $s->has_old_skool ) {
        return { Authorization => 'Token ' . $s->old_skool };
    }
    {};
}
1;
