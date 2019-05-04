package Finance::Robinhood::ACATS::Transfer;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::ACATS::Transfer - Represents a ACATS Transfer

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;
    my $transfers = $rh->acats_transfters();

    for my $transfer ($transferss->all) {
        CORE::say 'ACATS transfer from ' . $transfer->contra_brokerage_name;
    }

=cut

our $VERSION = '0.92_003';
use Mojo::Base-base, -signatures;
use Mojo::URL;
use Finance::Robinhood::ACATS::Transfer::Position;

sub _test__init {
    my $rh       = t::Utility::rh_instance(1);
    my $transfer = $rh->acats_transfers->current;
    skip_all('No ACATS transfers found') if !defined $transfer;
    isa_ok($transfer, __PACKAGE__);
    t::Utility::stash('TRANSFER', $transfer);    #  Store it for later
}
use overload '""' => sub ($s, @) { $s->{url} }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('TRANSFER') // skip_all();

    #is(
    #    +t::Utility::stash('TRANSFER'),
    #    'https://api.robinhood.com//',
    #);
}
#
has _rh => undef => weak => 1;

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

has ['cash_value',            'contra_account_number',
     'contra_brokerage_name', 'failure_reason',
     'fees_reimbursed',       'id',
     'replaced_by',           'state',
     'transfer_type'
];

=head2 C<cancel( )>

If the transfer can be cancelled, this method will do it.

=cut

sub cancel($s) {
    $s->{cancel} // return !1;
    my $res = $s->_rh->_post($s->{cancel});
    return $res->is_success
        ? !0
        : Finance::Robinhood::Error->new(
             $res->is_server_error ? (details => $res->message) : $res->json);
}

=head2 C<updated_at( )>

Returns a Time::Moment object.

=cut

sub updated_at ($s) {
    Time::Moment->from_string($s->{updated_at});
}

=head2 C<expected_landing_date( )>

Returns a Time::Moment object.

=cut

sub expected_landing_date ($s) {
    Time::Moment->from_string($s->{expected_landing_date} . 'T00:00:00Z');
}

=head2 C<positions( )>

    my $positions = $transfer->equity_positions();

Returns a list of Finance::Robinhood::ACATS::Transfer::Position objects with
this transfer's data.

=cut

sub positions ($s) {
    map {
        Finance::Robinhood::ACATS::Transfer::Position->new(_rh => $s->_rh,
                                                           %$_)
    } %{$s->{positions}};
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
