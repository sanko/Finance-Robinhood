package Finance::Robinhood::Options::Chain::Ticks;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Options::Chain::Ticks - Represents Pricing Ticks for an
Options Chain

=head1 SYNOPSIS

    use Text::Wrap qw[wrap];
    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;

    # TODO

=head1 METHODS

=cut

our $VERSION = '0.92_002';
use Mojo::Base-base, -signatures;
use Mojo::URL;

sub _test__init {
    my $rh    = t::Utility::rh_instance(0);
    my $ticks = $rh->options_chains->current->min_ticks;
    isa_ok($ticks, __PACKAGE__);
    t::Utility::stash('TICKS', $ticks);    #  Store it for later
}
use overload '""' => sub ($s, @) { $s->{below_tick} }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('TICKS') // skip_all();
    like(+t::Utility::stash('TICKS'), qr[^\d+\.\d+$],);
}
#
has _rh => undef => weak => 1;

=head2 C<above_tick( )>

Value to 'round up' to.

=head2 C<below_tick( )>

Value to 'round down' to.

=head2 C<cutoff_price( )>

Below this, use the C<above_tick( )> and C<below_tick( )> values. Otherwise,
ignore them.

=cut

has ['above_tick', 'below_tick', 'cutoff_price'];

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
