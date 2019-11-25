package Finance::Robinhood::Equity::Fundamentals;
our $VERSION = '0.92_003';

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Equity::Fundamentals - Equity Instrument's Fundamental Data

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;
    my $instruments = $rh->instruments();

    for my $instrument ($instruments->all) {
        my $fundamentals = $instrument->fundamentals;
        CORE::say $instrument->symbol;
        CORE::say $fundamentals->description;
    }

=cut
use Moo;
use MooX::Enumeration;
use Types::Standard qw[Bool Enum InstanceOf Maybe Num Str StrMatch];
use URI;
use Time::Moment;
use Data::Dump;
use experimental 'signatures';
use Finance::Robinhood::Equity;

sub _test__init {
    my $rh   = t::Utility::rh_instance(1);
    my $tsla = $rh->equity('TSLA')->fundamentals();
    isa_ok($tsla, __PACKAGE__);
    t::Utility::stash('TSLA', $tsla);    #  Store it for later
}
#
has robinhood =>
    (is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood'],);

=head1 METHODS



=head2 C<average_volume( )>



=head2 C<average_volume_2_weeks( )>



=head2 C<ceo( )>

If applicable, the name of the chief executive(s) related to this instrument.

=head2 C<description( )>

Plain text description suited for display.

=head2 C<dividend_yield( )>

=head2 C<float( )>

=head2 C<headquarters_city( )>

If applicable, the city where the main headquarters are located.

=head2 C<headquarters_state( )>

If applicable, the US state where the main headquarters are located.

=head2 C<high( )>

Trading day high.

=head2 C<high_52_weeks( )>

52-week high.

=head2 C<industry( )>



=head2 C<low( )>

Trading day low.

=head2 C<low_52_weeks( )>

52-week low.

=head2 C<market_cap( )>



=head2 C<num_employees( )>

If applicable, the number of employees as reported by the company.

=head2 C<open( )>

=head2 C<pb_ratio( )>

=head2 C<pe_ratio( )>



=head2 C<sector( )>



=head2 C<shares_outstanding( )>

Number of shares outstanding according to the SEC.

=head2 C<volume( )>



=head2 C<year_founded( )>

The year the company was founded, if applicable.

=cut

has [
    qw[average_volume average_volume_2_weeks
        dividend_yield float high high_52_weeks
        low low_52_weeks
        market_cap
        num_employees
        open
        pb_ratio pe_ratio
        shares_outstanding volume year_founded]
] => (is => 'ro', isa => Maybe [Num], required => 1);
has [
    qw[ceo description
        headquarters_city headquarters_state
        industry sector]
] => (is => 'ro', isa => Str, required => 1);

=head2 C<instrument( )>

Loop back to the equity instrument.

=cut

has _instrument => (is       => 'ro',
                    isa      => InstanceOf ['URI'],
                    coerce   => sub ($url) { URI->new($url) },
                    required => 1,
                    init_arg => 'instrument'
);
has instrument => (is       => 'ro',
                   isa      => InstanceOf ['Finance::Robinhood::Equity'],
                   builder  => 1,
                   lazy     => 1,
                   init_arg => undef
);

sub _build_instrument($s) {
    $s->robinhood->_req(GET => $s->_instrument,
                        as  => 'Finance::Robinhood::Equity');
}

sub _test_instrument {
    t::Utility::stash('TSLA') // skip_all();
    isa_ok(t::Utility::stash('TSLA')->instrument,
           'Finance::Robinhood::Equity');
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
