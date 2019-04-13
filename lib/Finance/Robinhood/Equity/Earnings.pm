package Finance::Robinhood::Equity::Earnings;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls st nd rd th

=head1 NAME

Finance::Robinhood::Equity::Earnings - Earnings Call and Report Data

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
    my $rh   = t::Utility::rh_instance(1);
    my $past = $rh->equity_earnings( range => -7 )->current;
    isa_ok( $past, __PACKAGE__ );
    t::Utility::stash( 'PAST', $past );
    my $future = $rh->equity_earnings( range => 7 )->current;
    isa_ok( $future, __PACKAGE__ );
    t::Utility::stash( 'FUTURE', $future );
}
use Mojo::Base-base, -signatures;
use Mojo::URL;
#
use Finance::Robinhood::Equity::Earnings::Call;
use Finance::Robinhood::Equity::Earnings::EPS;
use Finance::Robinhood::Equity::Earnings::Report;
use Finance::Robinhood::Equity::Instrument;
#
has _rh => undef => weak => 1;

=head1 METHODS

=head2 C<call( )>

Returns a Finance::Robinhood::Equity::Earnings::Call object if the call is
active or has been archived.

=cut

sub call ($s) {
    defined $s->{call}
        ? Finance::Robinhood::Equity::Earnings::Call->new( _rh => $s->_rh, %{ $s->{call} } )
        : ();
}

sub _test_call {
    t::Utility::stash('PAST') // skip_all();
    isa_ok( t::Utility::stash('PAST')->call(), 'Finance::Robinhood::Equity::Earnings::Call' );
}

=head2 C<eps( )>

Returns a Finance::Robinhood::Equity::Earnings::EPS object.

=cut

sub eps ($s) {
    defined $s->{eps}
        ? Finance::Robinhood::Equity::Earnings::EPS->new( _rh => $s->_rh, %{ $s->{eps} } )
        : ();
}

sub _test_eps {
    t::Utility::stash('PAST') // skip_all();
    isa_ok( t::Utility::stash('PAST')->eps(), 'Finance::Robinhood::Equity::Earnings::EPS' );
}

=head2 C<quarter( )>

C<1>st, C<2>nd, C<3>rd, or C<4>th.

=head2 C<report( )>

Returns a Fiance::Robinhood::Earnings::Report object.

=cut

sub report ($s) {
    defined $s->{report}
        ? Finance::Robinhood::Equity::Earnings::Report->new( _rh => $s->_rh, %{ $s->{report} } )
        : ();
}

sub _test_report {
    t::Utility::stash('PAST') // skip_all();
    isa_ok( t::Utility::stash('PAST')->report(), 'Finance::Robinhood::Equity::Earnings::Report' );
}

=head2 C<symbol( )>

The related ticker symbol.

=head2 C<year( )>

Four digit year.

=cut

has [ 'quarter', 'symbol', 'year' ];

=head2 C<instrument( )>

    my $instrument = $quote->instrument();

Loops back to a Finance::Robinhood::Equity::Instrument object.

=cut

sub instrument ($s) {
    my $res = $s->_rh->_get( $s->{instrument} );
    $res->is_success
        ? Finance::Robinhood::Equity::Instrument->new( _rh => $s->_rh, %{ $res->json } )
        : Finance::Robinhood::Error->new(
        $res->is_server_error ? ( details => $res->message ) : $res->json );
}

sub _test_instrument {
    t::Utility::stash('PAST') // skip_all();
    isa_ok( t::Utility::stash('PAST')->instrument(), 'Finance::Robinhood::Equity::Instrument' );
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
