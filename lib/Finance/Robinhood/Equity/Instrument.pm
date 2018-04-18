package Finance::Robinhood::Equity::Instrument;
use Moo;
use Date::Tiny;

# TODO:
#  "splits": "https://api.robinhood.com/instruments/ad5fc8ab-c9e1-41ba-ab38-37253577bcba/splits/",
#      "url": "https://api.robinhood.com/instruments/ad5fc8ab-c9e1-41ba-ab38-37253577bcba/",
#      "quote": "https://api.robinhood.com/quotes/KNG/",
#      "fundamentals": "https://api.robinhood.com/fundamentals/KNG/",
#      "market": "https://api.robinhood.com/markets/BATS/",
#
has [
    qw[type margin_initial_ratio tradability bloomberg_unique
        name symbol state country day_trade_ratio
        tradeable maintenance_ratio id simple_name min_tick_size]
] => ( is => 'ro' );
has 'list_date' => (
    is     => 'ro',
    coerce => sub {
        $_[0] ? Date::Tiny->from_string( $_[0] ) : ();
    }
);

=head2 C<historicals( ... )>

    my $ok = $option->historicals( interval => 'week' );

Gather historical quote data for all supported options instrument. This is
returned as a C<Finance::Robinhood::Equity::Instrument::Historicals> object.

    my @instruments = $rh->equity_instruments(tradability => 'tradable')->next_page;
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
        sprintf( $Finance::Robinhood::Endpoints{'marketdata/historicals/{symbol}'}, $s->id ), (
            join '&',
            map {
                $_ . '=' .
                    ( ref $args{$_} eq 'ARRAY' ? ( join ',', @{ $args{$_} } ) : $args{$_} )
            } keys %args
        )
    );
    $status == 200 ? Finance::Robinhood::Equity::Instrument::Historicals->new($data) : $data;
}
1;
