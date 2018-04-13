package Finance::Robinhood::Options::Instrument;
use v5.10;
use Moo;
use DateTime::Tiny;
use Date::Tiny;
use Finance::Robinhood::Options::MarketData;
use Finance::Robinhood::Options::Instrument::Historicals;
has [qw[tradability strike_price chain_id state type chain_symbol id url]] => ( is => 'ro' );
has 'expiration_date' => (
    is     => 'ro',
    coerce => sub {
        Date::Tiny->from_string( $_[0] );
    }
);
has [ 'created_at', 'updated_at' ] => (
    is     => 'ro',
    coerce => sub {
        $_[0] =~ s'Z$'';

        # BUG: DateTime::Tiny cannot handle sub-second values.
        $_[0] =~ s'\..+$'';
        DateTime::Tiny->from_string( $_[0] );
    }
);
has 'min_ticks' => (
    is     => 'ro',
    coerce => sub {
        $_[0];    # { above_tick => "0.10", below_tick => 0.05, cutoff_price => "3.00" }
    }
);

sub market_data {
    my ($s) = shift;
    warn sprintf $Finance::Robinhood::Endpoints{'marketdata/options/{id}'}, $s->id;
    my ( $status, $data )
        = Finance::Robinhood::Utils::Client->instance->get(
        sprintf $Finance::Robinhood::Endpoints{'marketdata/options/{id}'}, $s->id );
    $status == 200 ? Finance::Robinhood::Options::MarketData->new($data) : $data;
}

=head2 C<historicals( ... )>

    my $ok = $options->historicals();

Gather info about all supported options chains. This is returned as a
C<Finance::Robinhood::Utils::Paginated> object.

    my $inst = $rh->options_chains( ids =>  ['0c0959c2-eb3a-4e3b-8310-04d7eda4b35c'] );
    my $all = $inst->all;

The following arguments are accepted:

=over

=item C<interval> - C<day>, C<week>, or C<month>

=item C<span> - C<year>, C<5year>, or C<10year>

=back

C<interval> is required.

=cut

sub historicals {
    my ( $s,      %args ) = @_;
    my ( $status, $data ) = Finance::Robinhood::Utils::Client->instance->get(
        join '?',
        sprintf( $Finance::Robinhood::Endpoints{'marketdata/options/historicals/{id}/'}, $s->id ), (
            join '&',
            map {
                $_ . '=' .
                    ( ref $args{$_} eq 'ARRAY' ? ( join ',', @{ $args{$_} } ) : $args{$_} )
            } keys %args
        )
    );
    $status == 200 ? Finance::Robinhood::Options::Instrument::Historicals->new($data) : $data;
}
1;
