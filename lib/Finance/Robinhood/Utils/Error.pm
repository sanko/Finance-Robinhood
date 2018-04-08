package Finance::Robinhood::Utils::Error;
use Moo;
use overload 'bool' => sub {0};
has [qw[data status]] => ( is => 'ro' );
1;
