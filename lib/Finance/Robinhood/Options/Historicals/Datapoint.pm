package Finance::Robinhood::Options::Historicals::Datapoint;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Options::Historicals::Datapoint - Represents a Single
Interval of Time in a Options Instrument's Historical Price Data

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new->login('user', 'pass');

    # TODO

=cut

our $VERSION = '0.92_003';
use Mojo::Base-base, -signatures;
use Mojo::URL;

sub _test__init {
    my $rh = t::Utility::rh_instance(1);
    my $option = $rh->options_instrument_by_id(
                                      '78ff8b76-4886-40bd-bfc8-b563b17c99c0');
    t::Utility::stash('OPTION', $option);    #  Store it for later
    my $historicals = $option->historicals(interval => '5minute');
    my ($datapoint) = $historicals->data_points;
    isa_ok($datapoint, __PACKAGE__);
    t::Utility::stash('DATAPOINT', $datapoint);    #  Store it for later
}
##

=head1 METHODS

=cut

has _rh => undef => weak => 1;

=head2 C<begins_at( )>

Returns a Time::Moment object.

=head2 C<close_price( )>



=head2 C<high_price( )>


=head2 C<interpolated( )>


=head2 C<low_price( )>

Returns a Time::Moment object.

=head2 C<open_price( )>


=head2 C<session( )>

Returns a Time::Moment object.

=head2 C<volume( )>

=cut

has ['close_price', 'high_price', 'interpolated', 'low_price',
     'open_price',  'session',    'volume'
];

sub begins_at ($s) {
    Time::Moment->from_string($s->{begins_at});
}

sub _test_begins_at {
    t::Utility::stash('DATAPOINT')
        // skip_all('No historical datapoint object in stash');
    isa_ok(t::Utility::stash('DATAPOINT')->begins_at, 'Time::Moment');
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
