package Finance::Robinhood::Equity::Instrument;
use Moo;
use Time::Moment;

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
        tradeable maintenance_ratio id simple_name min_tick_size url]
] => ( is => 'ro' );
has 'list_date' => (
    is     => 'ro',
    coerce => sub {
        $_[0] ? Time::Moment->from_string( $_[0] . 'T00:00:00Z' ) : ();
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

=item C<interval> - C<5minute>, C<10minute>, C<hour>, C<day>, C<week>, or C<month>

=item C<span> - C<week>, C<year>, C<5year>, or C<10year>

=item C<bounds> - C<extended>, C<regular>, C<trading>

=back

C<interval> is required.

=cut

sub historicals {
    my ( $s,      %args ) = @_;
    my ( $status, $data ) = Finance::Robinhood::Utils::Client->instance->get(
        Finance::Robinhood::Utils::Client::__url_and_args(
            sprintf( $Finance::Robinhood::Endpoints{'marketdata/historicals/{symbol}'}, $s->id ),
            \%args
        )
    );
    $status == 200 ? Finance::Robinhood::Equity::Instrument::Historicals->new($data) : $data;
}

sub options_chains {
    my ( $s, %args ) = @_;
    $args{equity_instrument_ids} = [ $s->id ];
    Finance::Robinhood->options_chains(%args);
}

sub orders {
    my $s = @_;
    Finance::Robinhood->equity_orders( instrument => $s, @_ );
}

sub quote {
    my ( $s,      %args ) = @_;
    my ( $status, $data ) = Finance::Robinhood::Utils::Client->instance->get(
        Finance::Robinhood::Utils::Client::__url_and_args(
            sprintf( $Finance::Robinhood::Endpoints{'marketdata/quotes/{symbol}'}, $s->symbol ),
            \%args
        )
    );
    $status == 200 ? Finance::Robinhood::Equity::Quote->new($data) : $data;
}

sub fundamentals {
    my ($s) = @_;
    my ( $status, $data ) = Finance::Robinhood::Utils::Client->instance->get(
        Finance::Robinhood::Utils::Client::__url_and_args(
            sprintf( $Finance::Robinhood::Endpoints{'fundamentals/{symbol}'}, $s->symbol ),
        )
    );
    $status == 200 ? Finance::Robinhood::Equity::Fundamentals->new($data) : $data;
}

sub place_order {
    my ( $s, %args ) = @_;
    $args{instrument} = $s->url;
    $args{symbol}     = $s->symbol;
    $args{account} //= Finance::Robinhood::Utils::Client->instance->account();
    $args{account} = $args{account}->url if ref $args{account};
    $args{ref_id} //= Finance::Robinhood::Utils::v4_uuid();
    my ( $status, $data )
        = Finance::Robinhood::Utils::Client->instance->post(
        $Finance::Robinhood::Endpoints{'orders'}, \%args );
    $status == 201 ? Finance::Robinhood::Equity::Order->new($data) : $data;
}
1;
