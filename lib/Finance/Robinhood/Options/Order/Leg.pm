package Finance::Robinhood::Options::Order::Leg;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Options::Order::Leg - Represents a Single Leg of an Options
Order

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new->login('user', 'pass');
    my $orders = $rh->options_orders();

    # TODO

=head1 METHOD

=cut

our $VERSION = '0.92_003';

sub _test__init {
    my $rh     = t::Utility::rh_instance(1);
    my $orders = $rh->options_orders;
    my $order;
    do {
        $order = $orders->next;
    } while $order->state ne 'filled';
    $order // skip_all('Failed to fine executied options order');
    my ($leg) = $order->legs;
    isa_ok($leg, __PACKAGE__);
    t::Utility::stash('ORDER', $order);    #  Store it for later
    t::Utility::stash('LEG',   $leg);      #  Store it for later
}
use Mojo::Base-base, -signatures;
use Mojo::URL;
use overload '""' => sub ($s, @) { $s->{id} }, fallback => 1;
use Finance::Robinhood::Error;
use Finance::Robinhood::Options::Instrument;
use Finance::Robinhood::Options::Order::Execution;

sub _test_stringify {
    t::Utility::stash('LEG') // skip_all();
    like(+t::Utility::stash('LEG'), t::Utility::stash('LEG')->{id});
}
#
has _rh => undef => weak => 1;

=head2 C<id( )>

UUID used to identify this particular execution.

=head2 C<position_effect( )>


=head2 C<ratio_quantity( )>


=head2 C<side( )>

=cut
has ['id', 'position_effect', 'ratio_quantity', 'side'];

=head2 C<instrument( )>

Returns the related Finance::Robinhood::Options::Instrument object.

=cut

sub instrument ($s) {
    my $res = $s->_rh->_get($s->{option});
    return $res->is_success
        ? Finance::Robinhood::Options::Instrument->new(_rh => $s->_rh,
                                                       %{$res->json})
        : Finance::Robinhood::Error->new(
             $res->is_server_error ? (details => $res->message) : $res->json);
}

sub _test_instrument {
    t::Utility::stash('LEG') // skip_all('No leg object in stash');
    isa_ok(t::Utility::stash('LEG')->instrument,
           'Finance::Robinhood::Options::Instrument');
}

=head2 C<executions( )>

Returns a list of related Finance::Robinhood::Options::Order::Executions
objects.

=cut

sub executions ($s) {
    map {
        Finance::Robinhood::Options::Order::Execution->new(_rh => $s->_rh,
                                                           %{$_})
    } @{$s->{executions}};
}

sub _test_executions {
    t::Utility::stash('LEG') // skip_all('No leg object in stash');
    my ($execution) = t::Utility::stash('LEG')->executions;
    isa_ok($execution, 'Finance::Robinhood::Options::Order::Execution');
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
