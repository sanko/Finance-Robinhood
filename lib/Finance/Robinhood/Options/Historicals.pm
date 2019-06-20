package Finance::Robinhood::Options::Historicals;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Options::Historicals - Represents an Options Instrument's
Historical Price Data

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
    isa_ok($option, 'Finance::Robinhood::Options::Instrument');
    t::Utility::stash('OPTION', $option);    #  Store it for later
    my $historicals = $option->historicals(interval => '5minute');
    isa_ok($historicals, __PACKAGE__);
    t::Utility::stash('HISTORICALS', $historicals);    #  Store it for later
}
##

=head1 METHODS

=cut

has _rh => undef => weak => 1;

=head2 C<bounds( )>


=head2 C<data_points( )>

Returns a list of Finance::Robinhood::Options::Historicals::DataPoint object.

=head2 C<interval( )>



=head2 C<open_price( )>


=head2 C<open_time( )>

Returns a Time::Moment object.

=head2 C<previous_close_price( )>


=head2 C<previous_close_time( )>

Returns a Time::Moment object.

=head2 C<span( )>


=cut

has ['bounds', 'interval', 'open_price', 'previous_close_price', 'span',];

sub data_points ($s) {
    require Finance::Robinhood::Options::Historicals::Datapoint;
    map {
        Finance::Robinhood::Options::Historicals::Datapoint->new(
                                                               _rh => $s->_rh,
                                                               %{$_})
    } @{$s->{data_points}};
}

sub _test_data_points {
    t::Utility::stash('HISTORICALS')
        // skip_all('No historicals object in stash');
    my ($datapoint) = t::Utility::stash('HISTORICALS')->data_points;
    isa_ok($datapoint, 'Finance::Robinhood::Options::Historicals::Datapoint');
}

sub open_time ($s) {
    Time::Moment->from_string($s->{open_time});
}

sub _test_open_time {
    t::Utility::stash('HISTORICALS')
        // skip_all('No historicals object in stash');
    isa_ok(t::Utility::stash('HISTORICALS')->open_time, 'Time::Moment');
}

=head2 C<previous_close_time( )>

Returns a Time::Moment object.

=cut

sub previous_close_time ($s) {
    Time::Moment->from_string($s->{previous_close_time});
}

sub _test_previous_close_time {
    t::Utility::stash('HISTORICALS')
        // skip_all('No historicals object in stash');
    isa_ok(t::Utility::stash('HISTORICALS')->previous_close_time,
           'Time::Moment');
}

=head2 C<instrument( )>

Returns the related Finance::Robinhood::Options::Instrument object.

=cut

sub instrument ($s) {
    $s->_rh->options_instrument_by_id($s->{id});
}

sub _test_instrument {
    t::Utility::stash('HISTORICALS')
        // skip_all('No historicals object in stash');
    isa_ok(t::Utility::stash('HISTORICALS')->instrument,
           'Finance::Robinhood::Options::Instrument');
}

=head2 C<quote( )>

Returns the related Finance::Robinhood::Options::Instrument::Quote object.

=cut

sub quote ($s) {
    $s->instrument->quote();
}

sub _test_quote {
    t::Utility::stash('HISTORICALS')
        // skip_all('No historicals object in stash');
    isa_ok(t::Utility::stash('HISTORICALS')->quote,
           'Finance::Robinhood::Options::Quote');
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
