package Finance::Robinhood::Equity::Account::Portfolio;
our $VERSION = '0.92_003';

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Equity::Account::Portfolio - Represents a Single Portfolio
attached to a Robinhood Account

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new( ... );
    my $portfolio = $rh->equity_portfolio;
    CORE::say $portfolio->equity;

=cut

sub _test__init {
    my $rh        = t::Utility::rh_instance(1);
    my $acct      = $rh->equity_accounts->current;
    my $portfolio = $acct->portfolio;
    isa_ok($portfolio, __PACKAGE__);
    t::Utility::stash('PORTFOLIO', $portfolio);    #  Store it for later
}
#
use Moo;
use MooX::Enumeration;
use Types::Standard qw[Bool Enum InstanceOf Maybe Num Str StrMatch];
use URI;
use Time::Moment;
use Data::Dump;
use experimental 'signatures';
use overload '""' => sub ($s, @) { $s->url }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('PORTFOLIO') // skip_all();
    like(+t::Utility::stash('PORTFOLIO'),
         qr'https://api.robinhood.com/portfolios/.+/');
}

=head1 METHODS

=cut

has robinhood =>
    (is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood']);

=head2 C<adjusted_equity_previous_close( )>

=head2 C<adjusted_portfolio_equity_previous_close( )>

=head2 C<equity( )>

=head2 C<equity_previous_close( )>

=head2 C<excess_maintenance( )>

=head2 C<excess_maintenance_with_uncleared_deposits( )>

=head2 C<excess_margin( )>

=head2 C<excess_margin_with_uncleared_deposits( )>

=head2 C<extended_hours_equity( )>

=head2 C<extended_hours_market_value( )>

=head2 C<last_core_equity( )>

=head2 C<last_core_market_value( )>

=head2 C<last_core_portfolio_equity( )>

=head2 C<market_value( )>

=head2 C<portfolio_equity_previous_close( )>

=head2 C<unwithdrawable_deposits( )>

=head2 C<unwithdrawable_grants( )>

=head2 C<withdrawable_amount( )>


=cut

has url => (is       => 'ro',
            isa      => InstanceOf ['URI'],
            coerce   => sub ($url) { URI->new($url) },
            required => 1
);
has [
    qw[adjusted_equity_previous_close adjusted_portfolio_equity_previous_close equity
        equity_previous_close excess_maintenance excess_maintenance_with_uncleared_deposits
        excess_margin excess_margin_with_uncleared_deposits
        last_core_equity last_core_market_value last_core_portfolio_equity
        market_value
        portfolio_equity_previous_close
        unwithdrawable_deposits unwithdrawable_grants
        withdrawable_amount]
] => (is => 'ro', isa => Num, required => 1);
has [
    qw[extended_hours_equity extended_hours_market_value extended_hours_portfolio_equity]
] => (is => 'ro', isa => Maybe [Num], required => 1);

=head2 C<start_date( )>

Returns a Time::Moment object.

=cut
has start_date => (
    is     => 'ro',
    isa    => InstanceOf ['Time::Moment'],
    coerce => sub ($date) {
        Time::Moment->from_string($date . 'T00:00:00.00000Z');
    }
);

sub _test_start_date {
    t::Utility::stash('PORTFOLIO')
        // skip_all('No portfolio object in stash');
    isa_ok(t::Utility::stash('PORTFOLIO')->start_date, 'Time::Moment');
}

=head2 C<account( )>

Returns the related Finance::Robinhood::Equity::Account object.

=cut
has '_account' => (is       => 'ro',
                   required => 1,
                   isa      => InstanceOf ['URI'],
                   coerce   => sub ($url) { URI->new($url) },
                   init_arg => 'account'
);
has account => (is      => 'ro',
                isa     => InstanceOf ['Finance::Robinhood::Equity::Account'],
                builder => 1,
                lazy    => 1,
                init_arg => undef
);

sub _build_account ($s) {
    $s->robinhood->_req(GET => $s->_account,
                        as  => 'Finance::Robinhood::Equity::Account');
}

sub _test_account {
    t::Utility::stash('POSITION') // skip_all('No position object in stash');
    isa_ok(t::Utility::stash('POSITION')->account,
           'Finance::Robinhood::Equity::Account');
}

=head1 LEGAL

This is a simple wrapper around the API used in the official apps. The author
provides no investment, legal, or tax advice and is not responsible for any
damages incurred while using this software. This software is not affiliated
with Robinhood Financial LLC in any way.

For Robinhood's terms and disclosures, please see their website at
https://robinhood.com/legal/

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module. Please refer to
the L<LEGAL> section.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut

1;
