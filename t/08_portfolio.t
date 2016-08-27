use strict;
use Test::More 0.98;
use lib '../lib/';
use_ok $_ for qw(
    Finance::Robinhood
);
subtest 'skippy' => sub {
    plan skip_all => 'Missing token!' if !defined $ENV{RHTOKEN};
    my $rh = Finance::Robinhood->new(token => $ENV{RHTOKEN});
    #
    my $portfolios = $rh->portfolios()->{results};
    isa_ok $portfolios , 'ARRAY', 'At least one portfolio returned';
    my $portfolio = $portfolios->[0];
    isa_ok $portfolio, 'Finance::Robinhood::Portfolio',
        'first item in portfolio list';
    #
    can_ok $portfolio, $_ for qw[account adjusted_equity_previous_close equity
        equity_previous_close excess_maintenance
        excess_maintenance_with_uncleared_deposits excess_margin
        excess_margin_with_uncleared_deposits extended_hours_equity
        extended_hours_market_value last_core_equity last_core_market_value
        market_value start_date unwithdrawable_deposits url withdrawable_amount
        id refresh];
    isa_ok $portfolio->account, 'Finance::Robinhood::Account', '->account()';
    isa_ok $portfolio->start_date, 'DateTime', '->start_date()';
    ok $portfolio->refresh, '->refresh';
    isa_ok $portfolio, 'Finance::Robinhood::Portfolio', 'still a portfolio';
    #
    ok
        exists $portfolio->historicals('10minute', 'week')
        ->{equity_historicals}, q[->historicals('10minute', 'week')];
    ok exists $portfolio->historicals('week', '5year')->{equity_historicals},
        q[->historicals('week', '5year')];
};
done_testing;
