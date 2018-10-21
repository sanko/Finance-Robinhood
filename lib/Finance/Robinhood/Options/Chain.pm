package Finance::Robinhood::Options::Chain;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Options::Chain - Represents a Single Options Chain

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new->login('user', 'pass');
    my $account = $rh->accounts->current();

    # TODO

=cut

use Mojo::Base-base, -signatures;
use Mojo::URL;
use overload '""' => sub { 'https://api.robinhood.com/options/chains/' . shift->id . '/' };
#
has _rh => undef => weak => 1;
has [ 'can_open_position', 'cash_component', 'id', 'symbol', 'trade_value_multiplier' ];
sub expiration_dates($s) { $s->{expiration_dates} }

sub underlying_instruments($s) {
    [ map { Finance::Robinhood::Options::Chain::Underlying->new( _rh => $s->_rh, %$_ ) }
            @{ $s->{underlying_instruments} } ]
}
sub min_ticks($s) { $s->{min_ticks} }

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
