package Finance::Robinhood::Equity::Position;
use Moo;
use DateTime::Tiny;
#

has [
    qw[shares_held_for_buys shares_held_for_sells
       shares_held_for_stock_grants
       shares_held_for_options_events shares_held_for_options_collateral
       shares_pending_from_options_events
       quantity intraday_quantity
       average_buy_price intraday_average_buy_price
       pending_average_buy_price url]
] => ( is => 'ro' );
has ['created_at', 'updated_at'] => (
    is     => 'ro',
    coerce => sub {
      $_[0] =~ s'Z$'';

      # BUG: DateTime::Tiny cannot handle sub-second values.
      $_[0] =~ s'\..+$'';
      DateTime::Tiny->from_string( $_[0] );
    }
);

has '_account_url' => (
    is       => 'ro',
    init_arg => 'account',
    coerce   => sub {
        ref $_[0] ? $_[0]->url : $_[0];
    }
);
has 'account' => (
    is       => 'ro',
    lazy     => 1,
    init_arg => undef,
    builder  => sub {
        my ( $status, $data )
            = Finance::Robinhood::Utils::Client->instance->get( shift->_account_url );
        $status == 200 ? Finance::Robinhood::Account->new($data) : ();
    }
);




      has '_instrument_url' => (
          is       => 'ro',
          init_arg => 'instrument',
          coerce   => sub {
              ref $_[0] ? $_[0]->url : $_[0];
          }
      );
      has 'instrument' => (
          is       => 'ro',
          lazy     => 1,
          init_arg => undef,
          builder  => sub {
              my ( $status, $data )
                  = Finance::Robinhood::Utils::Client->instance->get( shift->_instrument_url );
              $status == 200 ? Finance::Robinhood::Equity::Instrument->new($data) : ();
          }
      );
1;
