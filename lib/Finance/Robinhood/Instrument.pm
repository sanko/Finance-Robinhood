package Finance::Robinhood::Instrument;
use 5.010;
use strict;
use warnings;
use Carp;
our $VERSION = "0.15";
use Moo;
use JSON::Tiny qw[decode_json];
use strictures 2;
use namespace::clean;
use Finance::Robinhood::Market;
use Finance::Robinhood::Instrument::Split;
use Finance::Robinhood::Instrument::Fundamentals;
#
has $_ => (
    is        => 'lazy',
    predicate => 1,
    builder   => sub {
        (caller(1))[3] =~ m[.+::(.+)$];
        shift->_get_raw->{$1};
    }
    )
    for (
        qw[bloomberg_unique day_trade_ratio min_tick_size margin_initial_ratio
        id maintenance_ratio name state symbol tradeable country]);
#
has $_ => (is     => 'ro',
           coerce => \&Finance::Robinhood::_2_datetime
) for (qw[list_date]);
has $_ => (is        => 'lazy',
           predicate => 1,
           builder   => 1
) for (qw[fundamentals url]);
has $_ => (is        => 'lazy',
           predicate => 1,
           init_arg  => undef,
           builder   => 1
) for (qw[quote market splits]);
has $_ => (is => 'lazy', reader => "_get_$_") for (qw[raw]);

sub _build_raw {
    my $s = shift;
    my $url;
    if ($s->has_url) {
        $url = $s->url;
    }
    elsif ($s->has_id) {
        $url = Finance::Robinhood::endpoint('instruments') . $s->id . '/';
    }
    else {
        return {}    # We done messed up!
    }
    my ($status, $result, $raw)
        = Finance::Robinhood::_send_request(undef, 'GET', $url);
    return $result;
}

sub _build_quote {
    return Finance::Robinhood::quote(shift->symbol())->{results}[0];
}

sub _build_historicals {
    return Finance::Robinhood::historicals(shift->symbol(), shift, shift);
}

sub _build_splits {

    # Upcoming stock splits
    my ($status, $result, $raw)
        = Finance::Robinhood::_send_request(undef, 'GET',
                                            shift->_get_raw->{'splits'});
    return [$result
                && $result->{results} ?
                map { Finance::Robinhood::Instrument::Split->new($_) }
                @{$result->{results}}
            : ()
    ];
}

sub _build_market {
    Finance::Robinhood::Market->new(url => shift->_get_raw->{'market'});
}

sub _build_fundamentals {
    Finance::Robinhood::Instrument::Fundamentals->new(
                                    url => shift->_get_raw->{'fundamentals'});
}
1;

=encoding utf-8

=head1 NAME

Finance::Robinhood::Instrument - Single Financial Instrument

=head1 SYNOPSIS

    use Finance::Robinhood::Instrument;

    my $apple = Finance::Robinhood::instrument('AAPL');
    my $msft  = Finance::Robinhood::Instrument->new(id => '50810c35-d215-4866-9758-0ada4ac79ffa');

=head1 DESCRIPTION

This class represents a single financial instrument. Objects are usually
created by Finance::Robinhood so please use
Finance::Robinhood->instrument(...) unless you know the instrument ID.

=head1 METHODS

This class has several getters and a few methods as follows...

=head2 C<quote( )>

Makes an API call and returns a Finance::Robinhood::Quote object with current
data on this security.

=head2 C<historicals( ... )>

    $instrument->historicals( 'week', 'year' );

You may retrieve historical quote data with this method which wraps the
function found in Finance::Robinhood. Please see the documentation for that
function for more info on what data is returned.

The first argument is an interval time and must be either C<5minute>,
C<10minute>, C<day>, or C<week>.

The second argument is a span of time indicating how far into the past you
would like to retrieve and may be one of the following: C<day>, C<week>,
C<year>, or C<5year>.

=head2 C<market( )>

This makes an API call for information this particular instrument is traded on.

=head2 C<tradeable( )>

Returns a boolean value indicating whether this security can be traded on
Robinhood.

=head2 C<symbol( )>

The ticker symbol for this particular security.

=head2 C<name( )>

The actual name of the security.

For example, AAPL would be 'Apple Inc. - Common Stock'.

=head2 C<country( )>

The home location of the security.

=head2 C<bloomberg_unique( )>

Returns the Bloomberg Global ID (BBGID) for this security.

See http://bsym.bloomberg.com/sym/

=head2 C<id( )>

The unique ID Robinhood uses to refer to this particular security.

=head2 C<maintenance_ratio( )>

Margin ratio.

=head2 C<day_trade_ratio( )>


=head2 C<min_tick_size( )>

See http://www.finra.org/industry/tick-size-pilot-program

=head2 C<margin_initial_ratio( )>

As governed by the Federal Reserve's Regulation T, when a trader buys on margin, key levels must be maintained throughout the life of the trade

=head2 C<splits( )>

Returns a list of current share splits for this security.

=head2 C<fundamentals( )>

Makes and API call and returns a hash containing the following data:

=over

=item C<average_volume>

=item C<description>

=item C<dividend_yield>

=item C<high>

=item C<high_52_weeks>

=item C<low>

=item C<low_52_weeks>

=item C<market_cap>

=item C<open>

=item C<pe_ratio>

=item C<volume>

=back

=head1 LEGAL

This is a simple wrapper around the API used in the official apps. The author
provides no investment, legal, or tax advice and is not responsible for any
damages incurred while using this software. Neither this software nor its
author are affiliated with Robinhood Financial LLC in any way.

For Robinhood's terms and disclosures, please see their website at http://robinhood.com/

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify
it under the terms found in the Artistic License 2.

Other copyrights, terms, and conditions may apply to data transmitted through
this module. Please refer to the L<LEGAL> section.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut
