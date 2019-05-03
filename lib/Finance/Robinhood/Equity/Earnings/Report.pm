package Finance::Robinhood::Equity::Earnings::Report;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Equity::Earnings::Report - Earnings Report Data

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;
    
    my $earnings = $rh->equity_earnings;

    for my $earnings ( $rh->equity_earnings('7d')->all ) {
        CORE::say 'Earnings for ' . $earnings->symbol . ' expected ' . $earnings->report->date;
    }    

=cut

our $VERSION = '0.92_002';

sub _test__init {
    my $rh     = t::Utility::rh_instance(1);
    my $report = $rh->equity_earnings(range => -7)->current->report;
    isa_ok($report, __PACKAGE__);
    t::Utility::stash('REPORT', $report);
}
use Mojo::Base-base, -signatures;
use Mojo::URL;
#
use Time::Moment;
#
has _rh => undef => weak => 1;

=head1 METHODS

=head2 C<date( )>

Returns a Time::Moment object.

=cut

sub date ($s) {
    Time::Moment->from_string($s->{date} . 'T00:00:00Z');
}

sub _test_datel {
    t::Utility::stash('REPORT') // skip_all();
    isa_ok(t::Utility::stash('REPORT')->date(), 'Time::Moment');
}

=head2 C<timing( )>

Returns when during the trading day the data and call are expected. Options
include C<am> and C<pm>.

=head2 C<verified( )>

This returns true when the earnings release has verified to take place as
expected.

=cut

has ['timing', 'verified'];

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
