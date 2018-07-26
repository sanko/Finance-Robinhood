package Finance::Robinhood::Options::Instrument;
use v5.10;
use Moo;
use Time::Moment;
use Finance::Robinhood::Options::MarketData;
use Finance::Robinhood::Options::Instrument::Historicals;
has [qw[tradability rhs_tradability strike_price chain_id state type chain_symbol id url]] => ( is => 'ro' );
has [ 'expiration_date', 'issue_date' ] => (
    is     => 'ro',
    coerce => sub {
        Time::Moment->from_string( $_[0] . 'T00:00:00Z' );
    }
);
has [ 'created_at', 'updated_at' ] => (
    is     => 'ro',
    coerce => sub {
        Time::Moment->from_string( $_[0] );
    }
);
has 'min_ticks' => (
    is     => 'ro',
    coerce => sub {
        Finance::Robinhood::Options::Chain::Ticks->new( $_[0] );
    }
);

sub market_data {
    my ($s) = shift;
    my ( $status, $data )
        = Finance::Robinhood::Utils::Client->instance->get(
        sprintf $Finance::Robinhood::Endpoints{'marketdata/options/{id}'}, $s->id );
    $status == 200 ? Finance::Robinhood::Options::MarketData->new($data) : $data;
}

=head2 C<historicals( ... )>

    my $ok = $option->historicals( interval => 'week' );

Gather historical quote data for all supported options instrument. This is
returned as a C<Finance::Robinhood::Options::Instrument::Historicals> object.

    my @instruments = $rh->options_instruments(tradability => 'tradable', type => 'call')->next_page;
    my $inst = $instruments[0]->historicals(interval => 'day');

The following arguments are accepted:

=over

=item C<interval> - C<hour>, C<day>, C<week>, or C<month>

=item C<span> - C<week>, C<year>, C<5year>, or C<10year>

=back

C<interval> is required.

=cut

sub historicals {
    my ( $s,      %args ) = @_;
    my ( $status, $data ) = Finance::Robinhood::Utils::Client->instance->get(
        join '?',
        grep {length} sprintf(
            $Finance::Robinhood::Endpoints{'marketdata/options/historicals/{id}'}, $s->id
        ), (
            join '&',
            map {
                $_ . '=' .
                    ( ref $args{$_} eq 'ARRAY' ? ( join ',', @{ $args{$_} } ) : $args{$_} )
            } keys %args
        )
    );
    $status == 200 ? Finance::Robinhood::Options::Instrument::Historicals->new($data) : $data;
}

sub equity_instrument {
    Finance::Robinhood->equity_instruments( symbol => shift->chain_symbol )->next;
}

sub chains {
    Finance::Robinhood->options_chains( ids => [ shift->chain_id ] );
}
1;
