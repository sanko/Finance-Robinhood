package Finance::Robinhood::Equity::Account::Portfolio;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Equity::Account::Portfolio - Represents a Single Portfolio
attached to a Robinhood Account

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new->login('user', 'pass');
    my $portfolios = $rh->equity_portfolios->current();

    for my $portfolio ($portfolios->all) {
        CORE::say $portfolio->equity;
    }

=cut

our $VERSION = '0.92_002';

sub _test__init {
    my $rh        = t::Utility::rh_instance(1);
    my $acct      = $rh->equity_accounts->current;
    my $portfolio = $acct->portfolio;
    isa_ok($portfolio, __PACKAGE__);
    t::Utility::stash('PORTFOLIO', $portfolio);    #  Store it for later
}
use Mojo::Base-base, -signatures;
use Mojo::URL;
use overload '""' => sub ($s, @) { $s->{url} }, fallback => 1;
use Finance::Robinhood::Equity::Instrument;

sub _test_stringify {
    t::Utility::stash('PORTFOLIO') // skip_all();
    like(+t::Utility::stash('PORTFOLIO'),
         qr'https://api.robinhood.com/portfolios/.+/');
}

=head1 METHODS

=cut

has _rh => undef => weak => 1;

=head2 C<adjusted_equity_previous_close( )>

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

=head2 C<market_value( )>

=head2 C<unwithdrawable_deposits( )>

=head2 C<unwithdrawable_grants( )>

=head2 C<withdrawable_amount( )>


=cut

has ['adjusted_equity_previous_close',             'equity',
     'equity_previous_close',                      'excess_maintenance',
     'excess_maintenance_with_uncleared_deposits', 'excess_margin',
     'excess_margin_with_uncleared_deposits',      'extended_hours_equity',
     'extended_hours_market_value',                'last_core_equity',
     'last_core_market_value',                     'market_value',
     'unwithdrawable_deposits',                    'unwithdrawable_grants',
     'withdrawable_amount'
];

=head2 C<start_date( )>

Returns a Time::Moment object.

=cut

sub start_date ($s) {
    Time::Moment->from_string($s->{start_date} . 'T00:00:00Z');
}

sub _test_start_date {
    t::Utility::stash('PORTFOLIO')
        // skip_all('No portfolio object in stash');
    isa_ok(t::Utility::stash('PORTFOLIO')->start_date, 'Time::Moment');
}

=head2 C<account( )>

Returns the related Finance::Robinhood::Equity::Account object.

=cut

sub account ($s) {
    my $res = $s->_rh->_get($s->{account});
    return $res->is_success
        ? Finance::Robinhood::Equity::Account->new(_rh => $s->_rh,
                                                   %{$res->json})
        : Finance::Robinhood::Error->new(
             $res->is_server_error ? (details => $res->message) : $res->json);
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
