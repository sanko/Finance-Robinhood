package Finance::Robinhood::Forex::AssetCurrency;
use Moo;
has [
    qw[
        code id increment name type
        ]
] => ( is => 'ro' );
1;
