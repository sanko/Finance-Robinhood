package Finance::Robinhood::Instrument::Fundamentals;
use 5.010;
use Carp;
our $VERSION = "0.16";
use Moo;
use strictures 2;
use namespace::clean;
require Finance::Robinhood;
#
has $_ => (required => 1, predicate => 1, is => 'ro', reader => "_get_$_", clearer => 1)
    for (qw[url]);


for my $method_name (qw[average_volume description dividend_yield high high_52_weeks low low_52_weeks market_cap open pe_ratio volume]) {
        no strict 'refs';

    *{__PACKAGE__ . '::' . $method_name} = sub {
        shift->_get_raw->{$method_name};
    };

}

sub instrument {
    my ($status, $result, $raw)
        = Finance::Robinhood::_send_request(undef, 'GET',
                                            shift->_get_raw->{'instrument'});
    return $result ?
        map { Finance::Robinhood::Instrument->new($_) } @{$result->{results}}
        : ();
}
has $_ => (is => 'lazy', reader => "_get_$_", clearer => 1) for (qw[raw]);

sub _build_raw {
    my $s = shift;
    my $url;
    if ($s->has_url) {
        $url = $s->_get_url;
    }

    #elsif ($s->has_id) {
    #    $url = Finance::Robinhood::endpoint('instruments') . $s->id . '/';
    #}
    else {
        return {}    # We done messed up!
    }
    my ($status, $result, $raw)
        = Finance::Robinhood::_send_request(undef, 'GET', $url);
    return $result;
}

sub refresh {
   $_[0]->clear_raw;
}
1;

=encoding utf-8

=head1 NAME

Finance::Robinhood::Instrument::Fundamentals - Fundamental Instrument Data

=head1 SYNOPSIS

    use Finance::Robinhood;

    # ... $rh creation, login, etc...
    $rh->instrument('IDK');
    printf 'Current volume: ' . $rh->instrument('IDK')->fundamentals->volume;

=head1 DESCRIPTION

This class contains data related to a security's fundamental data. Objects of
this type are not meant to be created directly from your code.

=head1 METHODS

This class has several getters and a few methods as follows...

=head2 C<average_volume( )>

=head2 C<description( )>

=head2 C<dividend_yield( )>

=head2 C<high( )>

=head2 C<high_52_weeks( )>

=head2 C<instrument( )>

Generates a new Finance::Robinhood::Instrument object related to this split.

=head2 C<low( )>

=head2 C<low_52_weeks( )>

=head2 C<market_cap( )>

=head2 C<open( )>

=head2 C<pe_ratio( )>

=head2 C<volume( )>

=head2 C<refresh( )>

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
