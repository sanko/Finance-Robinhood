package Finance::Robinhood::Forex::QuoteCurrency;
use Moo;
has [
    qw[
        code id increment name type
        ]
] => ( is => 'ro' );
1;
