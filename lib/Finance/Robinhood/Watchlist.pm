package Finance::Robinhood::Watchlist;
use 5.010;
use strict;
use warnings;
use Carp;
our $VERSION = "0.02_001";
use Moo;
use JSON::Tiny qw[decode_json];
use strictures 2;
use namespace::clean;
#
has $_ => (is => 'ro', required => 1, writer => "_set_$_") for (qw[name]);
has $_ => (
    is       => 'bare',
    required => 1,
    writer   => "_set_$_",
    reader   => "_get_$_",
    isa      => sub {
        die "$_[0] is not an Finance::Robinhood object!"
            unless ref $_[0] eq 'Finance::Robinhood';
    },
    weak_ref => 1
) for (qw[rh]);

sub instruments {
    my $self = shift;
    my $res  = $self->_get_rh()->_send_request('GET',
                    Finance::Robinhood::endpoint('watchlists') . $self->name);
    return $self->_get_rh()->_paginate(
        {results => [
             map {
                     my ($status, $ins, $raw)
                     = $self->_get_rh()
                     ->_send_request('GET', $_->{instrument});
                 $ins
             } @{delete $res->{results}}
         ],
         %$res
        },
        'Finance::Robinhood::Instrument'
    );
}

sub bulk_add_symbols {
    my ($self, @symbols) = @_;
    my $result =
        $self->_get_rh()->_send_request(
                  'POST',
                  sprintf(Finance::Robinhood::endpoint('watchlists/bulk_add'),
                          $self->name
                  ),
                  {symbols => join ',', @symbols}
        );
    return $result ?
        map {
            my ($status, $instrument, $raw)
            = $self->_get_rh()->_send_request('GET', $_->{instrument});
        Finance::Robinhood::Instrument->new($instrument)
        } @{$result}
        : ();
}

sub add_instrument {
    my ($self, $instrument) = @_;
    my $ret = $self->_get_rh()->_send_request('POST', Finance::Robinhood::endpoint('watchlists') . $self->name() . '/');
    return $ret;
}

sub delete_instrument {
    my ($self, $instrument) = @_;
    my ($status, $ret) =
        $self->_get_rh()->_send_request('DELETE',
              Finance::Robinhood::endpoint('watchlists') . $self->name() . '/' . $instrument->id() . '/');
    return $status == 204;
}

1;

=encoding utf-8

=head1 NAME

Finance::Robinhood::Watchlist - Persistant List of Financial Instruments

=head1 SYNOPSIS

    use Finance::Robinhood::Instrument;

    #...

    my $watchlist = $rh->create_watchlist( 'Tech' );

    $watchlist->add_instrument( $rh->instrument('APPL') );

=head1 DESCRIPTION

Robinhood allows persistant, categorized lists of financial instruments in
'watchlists'. Watchlists are tied to a user rather than a single
L<account|Finance::Robinhood::Account>.

If you intend to create your own wishlists, please use
C<<Finance::Robinhood->create_watchlist( ... )>>.

=head1 METHODS

Watchlists are rather simple in themselves but can be very powerful for
orgaization. Let's say you have a really short list of stocks you'd really
like to keep an eye on, you could add just those securities to a watchlist. Or
You could add a watchlist for securities in a certain field.

=head2 C<name( )>

Returns the name given to this watchlist. The official apps use a watchlist
named 'Default'.

=head2 C<instruments( )>

Returns a paginated list of Finance::Robinhood::Instrument objects being kept
track of in this watchlist.

=head2 C<delete_instrument( ... )>

    $watchlist->delete_instrument( $instrument );

Removes a financial instrument from the watchlist.

=head2 C<add_instrument( ... )>

    $watchlist->add_instrument( $instrument );

Adds a financial instrument to the watchlist. Attempts to add an instrument a
second time will fail.

=head2 C<bulk_add_symbols( ... )>

    $watchlist->bulk_add_symbols(qw[MSFT FB GOOGL]);

Add multiple instruments in a single API call and by their symbols with this.

...easier than gathering ::Instrument objects and calling
C<add_instrument( ... )> for each individual security, right?

=head1 LEGAL

This is a simple wrapper around the API used in the official apps. The author
provides no investment, legal, or tax advice and is not responsible for any
damages incured while using this software. Neither this software nor its
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
