package Finance::Robinhood::Options::Event::CashComponent;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Options::Event::CashComponent - Represents a Single Options
Event's Cash Component

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new->login('user', 'pass');

    # TODO

=head1 METHODS

=cut

our $VERSION = '0.92_003';
use Mojo::Base-base, -signatures;
use Mojo::URL;

sub _test__init {
    my $rh        = t::Utility::rh_instance(1);
    my $component = $rh->options_events->next->cash_component;
    $component // skip_all('No cash component in event');
    isa_ok($component, __PACKAGE__);
    t::Utility::stash('COMPONENT', $component);          #  Store it for later
}
use overload '""' => sub ($s, @) { $s->{id}; }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('COMPONENT') // skip_all();
    like(+t::Utility::stash('COMPONENT'),
         qr'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}/$'i
    );
}
has _rh => undef => weak => 1;

=head2 C<id( )>

Returns a UUID.

=head3 C<direction( )>



=head2 C<cash_amount( )>


=cut

has ['id', 'direction', 'cash_amount'];

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
