package Finance::Robinhood::Equity::Earnings::Call;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Equity::Earnings::Call - Earnings Call Data

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
    my $rh       = t::Utility::rh_instance(1);
    my $earnings = $rh->equity_earnings( range => -7 );
    my $call;
    while ( $earnings->next ) {
        next if !$earnings->current->call;
        $call = $earnings->current->call;
        last;
    }
    isa_ok( $call, __PACKAGE__ );
    t::Utility::stash( 'CALL', $call );
}
use Mojo::Base-base, -signatures;
use Mojo::URL;
#
use Time::Moment;
#
has _rh => undef => weak => 1;

=head1 METHODS

=head2 C<broadcast_url( )>

When available, this returns a Mojo::URL object. This URL will allow you to
join a call in progress.

=cut

sub broadcast_url ($s) {
    $s->{broadcast_url} ? Mojo::URL->new( $s->{broadcast_url} ) : ();
}

sub _test_broadcast_url {
    t::Utility::stash('CALL') // skip_all();
    todo(
        'Nearly impossible to catch a call in progress in a unscheduled test' => sub {
            isa_ok( t::Utility::stash('CALL')->broadcast_url(), 'Mojo::URL' );
        }
    );
}

=head2 C<datetime( )>

Returns a Time::Moment object.

=cut

sub datetime ($s) {
    Time::Moment->from_string( $s->{datetime} );
}

sub _test_datetime {
    t::Utility::stash('CALL') // skip_all();
    isa_ok( t::Utility::stash('CALL')->datetime(), 'Time::Moment' );
}

=head2 C<replay_url( )>

When available, this returns a Mojo::URL object. This URL will allow you to
replay an archived call.

=cut

sub replay_url ($s) {
    $s->{replay_url} ? Mojo::URL->new( $s->{replay_url} ) : ();
}

sub _test_replay_url {
    t::Utility::stash('CALL') // skip_all();
    isa_ok( t::Utility::stash('CALL')->replay_url(), 'Mojo::URL' );
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
