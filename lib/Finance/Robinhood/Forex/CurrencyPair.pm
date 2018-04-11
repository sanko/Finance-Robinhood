package Finance::Robinhood::Forex::CurrencyPair;
use Moo;
has [
    qw[
        display_only id max_order_size min_order_price_increment
        min_order_size name symbol tradability
        ]
] => ( is => 'ro' );
has 'asset_currency' => (
    is     => 'ro',
    coerce => sub {
        Finance::Robinhood::Forex::AssetCurrency->new( $_[0] );
    }
);
has 'quote_currency' => (
    is     => 'ro',
    coerce => sub {
        Finance::Robinhood::Forex::QuoteCurrency->new( $_[0] );
    }
);
1;
