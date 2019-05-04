package Finance::Robinhood::Forex::Portfolio;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Forex::Portfolio - Represents a Single Forex Portfolio

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;

    # TODO

=cut

our $VERSION = '0.92_003';
use Mojo::Base-base, -signatures;
use Mojo::URL;

sub _test__init {
    my $rh  = t::Utility::rh_instance(1);
    my $act = $rh->forex_portfolios->current;
    isa_ok($act, __PACKAGE__);
    t::Utility::stash('PORTFOLIO', $act);    #  Store it for later
}
use overload '""' => sub ($s, @) { $s->{id} }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('PORTFOLIO') // skip_all();
    like(+t::Utility::stash('PORTFOLIO'),
         qr'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'i
    );
}
#
has _rh => undef => weak => 1;

=head1 METHODS
 
=head2 C<account_id( )>

Returns a UUID.

=head2 C<equity( )>

Returs a dollar amount.

=head2 C<extended_hours_equity( )>

Returns a dollar amount if applicable.

=head2 C<extended_hours_market_value( )>

Returns a dollar amount if applicable.

=head2 C<id( )>

Returns a UUID.

=head2 C<market_value( )>

Returns a dollar amount.

=head2 C<previous_close( )>

Returns a dollar amount.

=cut

has ['account_id',            'equity',
     'extended_hours_equity', 'extended_hours_market_value',
     'id',                    'market_value',
     'previous_close'
];

=head2 C<updated_at( )>

Returns a Time::Moment object.

=cut

sub updated_at ($s) {
    Time::Moment->from_string($s->{updated_at});
}

sub _test_updated_at {
    t::Utility::stash('PORTFOLIO') // skip_all();
    isa_ok(t::Utility::stash('PORTFOLIO')->updated_at, 'Time::Moment');
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
