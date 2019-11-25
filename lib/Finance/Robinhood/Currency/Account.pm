package Finance::Robinhood::Currency::Account;
our $VERSION = '0.92_003';

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Currency::Account - Represents a Single Cryptocurrency
Account

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new( ... );
    my $acct = $rh->currency_account();

=cut

sub _test__init {
    my $rh   = t::Utility::rh_instance(1);
    my $acct = $rh->currency_account;
    isa_ok($acct, __PACKAGE__);
    t::Utility::stash('ACCOUNT', $acct);    #  Store it for later
}
#
use Moo;
use MooX::Enumeration;
use Types::Standard
    qw[Any Overload ArrayRef Bool Dict Enum InstanceOf Maybe Num Str StrMatch];
use URI;
use Time::Moment;
use Data::Dump;
use experimental 'signatures';
use Finance::Robinhood::Types qw[UUID Timestamp];
use overload '""' => sub ($s, @) { $s->id }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('ACCOUNT') // skip_all();
    like(+t::Utility::stash('ACCOUNT'),
         qr'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'i
    );
}
has robinhood =>
    (is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood']);

=head1 METHODS

=head2 C<created_at( )>

Returns a Time::Moment object.

=head2 C<id( )>

Returns a UUID.

=head2 C<status( )>


=head2 C<status_reason_code( )>


=head2 C<update_at( )>

Returns a Time::Moment object.

=head2 C<user_id( )>

Returns a UUID.

=cut

has [qw[created_at updated_at]] =>
    (is => 'ro', isa => Timestamp, coerce => 1, required => 1,);
has [qw[id user_id]] => (is => 'ro', isa => UUID, required => 1);
has status => (is => 'ro', isa => Enum [qw[active]], required => 1);
has status_reason_code => (is => 'ro', isa => Str, required => 1);

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
