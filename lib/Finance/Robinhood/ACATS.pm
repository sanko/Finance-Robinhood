package Finance::Robinhood::ACATS;
our $VERSION = '0.92_003';

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::ACATS - Represents an ACATS Transfer

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;
    my $transfers = $rh->acats_transfters();

    for my $transfer ($transferss->all) {
        CORE::say 'ACATS transfer from ' . $transfer->contra_brokerage_name;
    }

=cut

use Moo;
use MooX::Enumeration;
use Types::Standard
    qw[ArrayRef Bool Dict Enum InstanceOf Maybe Num Str StrMatch];
use URI;
use Time::Moment;
use Data::Dump;
use experimental 'signatures';
use Finance::Robinhood::Types qw[:all];
#
sub _test__init {
    my $rh       = t::Utility::rh_instance(1);
    my $transfer = $rh->acats_transfers->current;
    skip_all('No ACATS transfers found') if !defined $transfer;
    isa_ok($transfer, __PACKAGE__);
    t::Utility::stash('TRANSFER', $transfer);    #  Store it for later
}
use overload '""' => sub ($s, @) { $s->_url }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('TRANSFER') // skip_all();

    #is(
    #    +t::Utility::stash('TRANSFER'),
    #    'https://api.robinhood.com//',
    #);
}
#
has robinhood =>
    (is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood']);
has '_' .
    $_ => (is => 'ro', required => 1, isa => URL, coerce => 1, init_arg => $_)
    for qw[url];

=head1 METHODS



=head2 C<id( )>



=head2 C<cash_value( )>



=head2 C<contra_account_number( )>



=head2 C<contra_brokerage_name( )>



=head2 C<failure_reason( )>


=head2 C<fees_reimbursed( )>



=head2 C<transfer_type( )>



=head2 C<replaced_by( )>




=head2 C<state( )>



=cut
has [qw[cash_value fees_reimbursed]] =>
    (is => 'ro', isa => Num, requried => 1);
has [
    qw[contra_account_number contra_brokerage_name
        failure_reason replaced_by transfer_type state
        ]
] => (is => 'ro', isa => Str, required => 1);
has id => (is => 'ro', isa => UUID, required => 1);

=head2 C<can_cancel( )>

Returns a boolean value.

=head2 C<cancel( )>

If the transfer can be cancelled, this method will do it.

=cut
has _cancel => (is        => 'ro',
                isa       => URL,
                coerce    => 1,
                init_arg  => 'cancel',
                required  => 1,
                predicate => 'can_cancel'
);

sub cancel($s) {
    return if !$s->can_cancel;
    $s->robinhood->_req(POST => $s->_cancel);
}

=head2 C<updated_at( )>

Returns a Time::Moment object.

=cut

has updated_at => (is => 'ro', isa => Timestamp, coerce => 1, required => 1);

=head2 C<expected_landing_date( )>

Returns a date as YYYY-MM-DD.

=cut

has expected_landing_date =>
    (is => 'ro', isa => StrMatch [qr[^\d\d\d\d-\d\d-\d\d$]], required => 1);

=head2 C<positions( )>

    my $positions = $transfer->equity_positions();

Returns a list of hash references with the transfer's data. These references
each contain:

=over

=item C<instrument> - UUID

=item C<price>

=item C<quantity>

=back

=cut

has positions => (
      is => 'ro',
      isa =>
          ArrayRef [Dict [instrument => UUID, price => Num, quantity => Num]],
      required => 1
);

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
