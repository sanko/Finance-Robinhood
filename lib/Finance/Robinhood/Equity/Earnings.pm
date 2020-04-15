package Finance::Robinhood::Equity::Earnings;
our $VERSION = '0.92_003';

=encoding utf-8

=for stopwords watchlist watchlists untradable urls btw

=head1 NAME

Finance::Robinhood::Equity::Earnings - Represents Speculative or Actual Equity
Earnings Holding

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;
    # TODO

=head1 METHODS

=cut

use Moo;
use Data::Dump;
use HTTP::Tiny;
use JSON::Tiny;
use Time::Moment;
use Types::Standard qw[ArrayRef Bool Dict Enum InstanceOf Maybe Num Str StrMatch];
use URI;
use experimental 'signatures';
#
use Finance::Robinhood::Types qw[URL UUID UUIDBroken Timestamp];
#
sub _test__init {
    my $rh       = t::Utility::rh_instance(1);
    my $earnings = $rh->equity_earnings( instrument => $rh->equity('MSFT') )->current;
    isa_ok( $earnings, __PACKAGE__ );
    t::Utility::stash( 'EARNINGS', $earnings );    #  Store it for later
}
use overload '""' => sub ( $s, @ ) {
    join '', $s->symbol, $s->year, $s->quarter;
    },
    fallback => 1;

sub _test_stringify {
    t::Utility::stash('EARNINGS') // skip_all();
    like( +t::Utility::stash('EARNINGS'), qr'^\w+\d{4}\d$'i );
}
#
has robinhood => (
    is        => 'ro',
    predicate => 1,
    isa       => InstanceOf ['Finance::Robinhood'],
    required  => 1
);

=head2 C<call( )>

If defined, this returns and object with the following methods:

=over

=item C<broadcast_url( )>

If defined, this returns a URI object to listen to the call live.

=item C<datetime( )>

Returns a Time::Moment object.

=item C<replay_url( )>

If defined, this returns a URI object to listen to a replay of the call.

=back

=cut

{
    package    # Hide it!
        Finance::Robinhood::Equity::Earnings::Call;
    use Moo;
    use MooX::Enumeration;
    use Types::Standard qw[ArrayRef Bool Dict Enum InstanceOf Maybe Num Str StrMatch];
    use experimental 'signatures';
    #
    use Finance::Robinhood::Types qw[URL UUID Timestamp];
    has broadcast_url => ( is => 'ro', isa => Maybe [URL], coerce => 1, required => 1 );
    has datetime      => ( is => 'ro', isa => Timestamp, coerce => 1, required => 1 );
    has replay_url    => ( is => 'ro', isa => Maybe [URL], coerce => 1, required => 1 );
}
has call => (
    is     => 'ro',
    isa    => Maybe [ InstanceOf ['Finance::Robinhood::Equity::Earnings::Call'] ],
    coerce => sub ($data) {
        defined $data
            ? Finance::Robinhood::Equity::Earnings::Call->new(%$data)
            : ();
    }
);

=head2 C<eps( )>

If defined, this returns and object with the following methods:

=over

=item C<actual( )>

If defined, the actual earnings per share.

=item C<estimate( )>

If defined, the expected earnings per share.

=back

=cut

{
    package    # Hide it!
        Finance::Robinhood::Equity::Earnings::EPS;
    use Moo;
    use MooX::Enumeration;
    use Types::Standard qw[ArrayRef Bool Dict Enum InstanceOf Maybe Num Str StrMatch];
    use experimental 'signatures';
    #
    use Finance::Robinhood::Types qw[URL UUID Timestamp];
    has [qw[actual estimate]] => ( is => 'ro', isa => Maybe [Num], predicate => 1, required => 1 );
}
has eps => (
    is     => 'ro',
    isa    => Maybe [ InstanceOf ['Finance::Robinhood::Equity::Earnings::EPS'] ],
    coerce => sub ($data) {
        defined $data
            ? Finance::Robinhood::Equity::Earnings::EPS->new(%$data)
            : ();
    }
);

=head2 C<equity( )>

Returns the related Finance::Robinhood::Equity object.

=cut

has _equity => (
    is       => 'ro',
    isa      => UUID,
    coerce   => 1,
    required => 1,
    init_arg => 'instrument'
);
has equity => (
    is      => 'ro',
    isa     => InstanceOf ['Finance::Robinhood::Equity'],
    lazy    => 1,
    builder => 1
);

sub _build_equity($s) {
    my ($blah) = $s->robinhood->equities_by_id( $s->_equity );
    $blah;
}

=head2 C<quarter( )>

Returns C<1>, C<2>, C<3>, or C<4>.

=cut

has quarter => ( is => 'ro', isa => Enum [qw[1 2 3 4]], required => 1 );

=head2 C<report( )>

If defined, this returns and object with the following methods:

=over

=item C<date( )>

The date as YYYY-MM-DD.

=item C<timing( )>

Either C<am> or C<pm>.

=item C<verified( )>

Returns a boolean value.

=back

=cut

{
    package    # Hide it!
        Finance::Robinhood::Equity::Earnings::Report;
    use Moo;
    use MooX::Enumeration;
    use Types::Standard qw[ArrayRef Bool Dict Enum InstanceOf Maybe Num Str StrMatch];
    use experimental 'signatures';
    #
    use Finance::Robinhood::Types qw[URL UUID Timestamp];
    has date => (
        is       => 'ro',
        isa      => StrMatch [qr[^\d\d\d\d-\d\d-\d\d$]],
        required => 1
    );
    has timing   => ( is => 'ro', isa => Maybe [ Enum [qw[am pm]] ], required => 1 );
    has verified => ( is => 'ro', isa => Bool, coerce => 1, required => 1 );
}
has report => (
    is     => 'ro',
    isa    => Maybe [ InstanceOf ['Finance::Robinhood::Equity::Earnings::Report'] ],
    coerce => sub ($data) {
        defined $data
            ? Finance::Robinhood::Equity::Earnings::Report->new(%$data)
            : ();
    },
    required => 1
);

=head2 C<symbol( )>

Returns the ticker symbol of the related equity instrument.

=cut

has symbol => ( is => 'ro', isa => Str, required => 1 );

=head2 C<year( )>

Returns the year.

=cut

has year => ( is => 'ro', isa => Num, required => 1 );

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
