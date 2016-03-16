use strict;
use Test::More 0.98;
use lib '../lib/';
use_ok $_ for qw(
    Finance::Robinhood
);
subtest 'skippy' => sub {
    plan skip_all => 'Missing token!' if !defined $ENV{RHTOKEN};
    my $rh = Finance::Robinhood->new(token => $ENV{RHTOKEN});
    my $watchlists = $rh->watchlists();
    is ref $watchlists, 'HASH', '->watchlists()';
    my $name      = 'Test' . int rand(5000);
    my $watchlist = $rh->create_watchlist($name);
    isa_ok $watchlist, 'Finance::Robinhood::Watchlist',
        "newly created test watchlist named $name";
    {
        my ($found)
            = grep { $_->name() eq $name } @{$rh->watchlists()->{results}};
        isa_ok $found, 'Finance::Robinhood::Watchlist',
            "Persistant watchlist named $name is on Robinhood";
    }
    my @symbols
        = qw[AAPL TWTR TSLA NFLX FB MSFT DIS GPRO SBUX F BABA BAC FIT YHOO GE];
    my @instruments = $watchlist->bulk_add_symbols(@symbols);
    is $#instruments, $#symbols, 'added symbols match our bulk add';
    is_deeply \@instruments, $watchlist->instruments()->{results},
        'verify persistant state';
    ok $rh->delete_watchlist($watchlist), '->delete_watchlist( ... )';
    {
        my ($found)
            = grep { $_->name() eq $name } @{$rh->watchlists()->{results}};
        is $found, (), 'Deleted watchlist is no longer on Robinhood';
    }
};
done_testing;
