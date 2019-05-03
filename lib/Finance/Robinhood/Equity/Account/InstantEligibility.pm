package Finance::Robinhood::Equity::Account::InstantEligibility;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Equity::Account - Robinhood Account's Instant or Gold
Margin Account Eligibility

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new->login('user', 'pass');
    my $account = $rh->equity_accounts->current();

    CORE::say 'Instant? ' . $account->instant_eligibility->state;

=cut

sub _test__init {
    my $rh                  = t::Utility::rh_instance(1);
    my $acct                = $rh->equity_accounts->current;
    my $instant_eligibility = $acct->instant_eligibility;
    isa_ok($instant_eligibility, __PACKAGE__);
    t::Utility::stash('INSTANT', $instant_eligibility);  #  Store it for later
}
our $VERSION = '0.92_002';
use Mojo::Base-base, -signatures;
use Mojo::URL;
use overload '""' => sub ($s, @) { $s->{state} }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('INSTANT') // skip_all();
    is(+t::Utility::stash('INSTANT'), 'ok');
}

=head1 METHODS

=cut

has _rh => undef => weak => 1;

=head2 C<reason( )>


=head2 C<reversal( )>

=head2 C<state( )>

=cut

has ['state', 'reversal', 'reason'];

=head2 C<reinstatement_date( )>

Returns a Time::Moment object if applicable.

=cut

sub reinstatement_date ($s) {
    Time::Moment->from_string($s->{reinstatement_date} . 'T00:00:00Z');
}

sub _test_reinstatement_date {
    t::Utility::stash('INSTANT')
        // skip_all('No instant eligibility object in stash');
    skip_all('Instant state is okay... No reinstatement_date set')
        if t::Utility::stash('INSTANT')->state eq 'ok';
    isa_ok(t::Utility::stash('INSTANT')->reinstatement_date, 'Time::Moment');
}

=head2 C<updated_at( )>

Returns a Time::Moment object if applicable.

=cut

sub updated_at ($s) {
    Time::Moment->from_string($s->{updated_at});
}

sub _test_updated_at {
    t::Utility::stash('INSTANT')
        // skip_all('No instant eligibility object in stash');
    skip_all('Instant state is okay... No updated_at set')
        if t::Utility::stash('INSTANT')->state eq 'ok';
    isa_ok(t::Utility::stash('INSTANT')->updated_at, 'Time::Moment');
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
