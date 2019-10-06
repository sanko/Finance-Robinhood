package Finance::Robinhood::Options::OrderBuilder::Leg;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Options::Instrument - Represents a Single Options
Instrument

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;
    my $instruments = $rh->options_instruments();

    for my $instrument ($instruments->all) {
        CORE::say $instrument->chain_symbol;
    }

=cut

our $VERSION = '0.92_003';
use Mojo::Base-base, -signatures;
use Mojo::UserAgent;
use Mojo::URL;
use overload '""' => sub ($s, @) { $s->{url} }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('INSTRUMENT') // skip_all();
    is(+t::Utility::stash('INSTRUMENT'),
        'https://api.robinhood.com/options/instruments/' .
            t::Utility::stash('INSTRUMENT')->id . '/');
}
#
has _rh => undef;

#=head2 C<ratio_quantity( )>
#
#=cut
#has $_ =>(is => 'ro')  for ['id', 'position_effect', 'ratio_quantity', 'side'];
# Private; required for builder
has ['_option'];

# position_effect

=head2 C<open( )>

    $order->open( );

Use this to change the order for buy to open or sell to open legs.

=head2 C<close( )>

    $order->close( );

Use this to change the order for buy to close or sell to close legs.

=cut

sub open($s) {
    $s->with_roles(
              'Finance::Robinhood::Options::OrderBuilder::Leg::Role::ToOpen');
}
{

    package Finance::Robinhood::Options::OrderBuilder::Leg::Role::ToOpen;
    use Mojo::Base-role, -signatures;
    use strictures 2;
    use namespace::clean;
    use URI;
    use v5.30;
    use Data::Dump;
    no warnings qw[experimental::signatures];
    use feature 'signatures';
    around _dump => sub ($orig, $s, $test = 0) {
        my %data = $orig->($s, $test);
        (%data, position_effect => 'open');
    };
}

sub _test_open {
    t::Utility::stash('MSFT') // skip_all('No cached equity instrument');
    my $order = t::Utility::stash('MSFT')->sell(3)->gfd();
    is( {$order->_dump(1)},
        {account => "--private--",
         instrument =>
             "https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/",
         price         => '5.00',
         quantity      => 3,
         ref_id        => "00000000-0000-0000-0000-000000000000",
         side          => "sell",
         symbol        => "MSFT",
         time_in_force => "gfd",
         trigger       => "immediate",
         type          => "market",
        },
        'dump is correct'
    );
}

sub close($s) {
    $s->with_roles(
             'Finance::Robinhood::Options::OrderBuilder::Leg::Role::ToClose');
}
{

    package Finance::Robinhood::Options::OrderBuilder::Leg::Role::ToClose;
    use Mojo::Base-role, -signatures;
    use strictures 2;
    use namespace::clean;
    use URI;
    use v5.30;
    use Data::Dump;
    no warnings qw[experimental::signatures];
    use feature 'signatures';
    around _dump => sub ($orig, $s, $test = 0) {
        my %data = $orig->($s, $test);
        (%data, position_effect => 'close');
    };
}

sub _test_close {
    t::Utility::stash('MSFT') // skip_all('No cached equity instrument');
    my $order = t::Utility::stash('MSFT')->sell(3)->gfd();
    is( {$order->_dump(1)},
        {account => "--private--",
         instrument =>
             "https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/",
         price         => '5.00',
         quantity      => 3,
         ref_id        => "00000000-0000-0000-0000-000000000000",
         side          => "sell",
         symbol        => "MSFT",
         time_in_force => "gfd",
         trigger       => "immediate",
         type          => "market",
        },
        'dump is correct'
    );
}

=head2 C<ratio( ... )>


=cut

sub ratio ($s, $ratio) {
    $s->with_roles(
                'Finance::Robinhood::Options::OrderBuilder::Leg::Role::Ratio')
        ->_ratio($ratio);
}
{

    package Finance::Robinhood::Options::OrderBuilder::Leg::Role::Ratio;
    use Mojo::Base-role, -signatures;
    use strictures 2;
    use namespace::clean;
    use URI;
    use v5.30;
    use Data::Dump;
    no warnings qw[experimental::signatures];
    use feature 'signatures';
    has ['_ratio'];
    around _dump => sub ($orig, $s, $test = 0) {
        my %data = $orig->($s, $test);
        (%data, ratio_quantity => $s->_ratio);
    };
}

sub _test_ratio {
    t::Utility::stash('MSFT') // skip_all('No cached equity instrument');
    my $order = t::Utility::stash('MSFT')->sell(3)->gfd();
    is( {$order->_dump(1)},
        {account => "--private--",
         instrument =>
             "https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/",
         price         => '5.00',
         quantity      => 3,
         ref_id        => "00000000-0000-0000-0000-000000000000",
         side          => "sell",
         symbol        => "MSFT",
         time_in_force => "gfd",
         trigger       => "immediate",
         type          => "market",
        },
        'dump is correct'
    );
}

=head2 C<ratio_quantity( )>


=head2 C<buy( )>


=head2 C<sell( )>

=cut

sub buy($s) {
    $s->with_roles(
                 'Finance::Robinhood::Options::OrderBuilder::Leg::Role::Buy');
}
{

    package Finance::Robinhood::Options::OrderBuilder::Leg::Role::Buy;
    use Mojo::Base-role, -signatures;
    use strictures 2;
    use namespace::clean;
    use URI;
    use v5.30;
    use Data::Dump;
    no warnings qw[experimental::signatures];
    use feature 'signatures';
    around _dump => sub ($orig, $s, $test = 0) {
        my %data = $orig->($s, $test);
        (%data, side => 'buy');
    };
}

sub _test_buy {
    t::Utility::stash('MSFT') // skip_all('No cached equity instrument');
    my $order = t::Utility::stash('MSFT')->sell(3)->gfd();
    is( {$order->_dump(1)},
        {account => "--private--",
         instrument =>
             "https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/",
         price         => '5.00',
         quantity      => 3,
         ref_id        => "00000000-0000-0000-0000-000000000000",
         side          => "sell",
         symbol        => "MSFT",
         time_in_force => "gfd",
         trigger       => "immediate",
         type          => "market",
        },
        'dump is correct'
    );
}

sub sell($s) {
    $s->with_roles(
                'Finance::Robinhood::Options::OrderBuilder::Leg::Role::Sell');
}
{

    package Finance::Robinhood::Options::OrderBuilder::Leg::Role::Sell;
    use Mojo::Base-role, -signatures;
    use strictures 2;
    use namespace::clean;
    use URI;
    use v5.30;
    use Data::Dump;
    no warnings qw[experimental::signatures];
    use feature 'signatures';
    around _dump => sub ($orig, $s, $test = 0) {
        my %data = $orig->($s, $test);
        (%data, side => 'sell');
    };
}

sub _test_sell {
    t::Utility::stash('MSFT') // skip_all('No cached equity instrument');
    my $order = t::Utility::stash('MSFT')->sell(3)->gfd();
    is( {$order->_dump(1)},
        {account => "--private--",
         instrument =>
             "https://api.robinhood.com/instruments/50810c35-d215-4866-9758-0ada4ac79ffa/",
         price         => '5.00',
         quantity      => 3,
         ref_id        => "00000000-0000-0000-0000-000000000000",
         side          => "sell",
         symbol        => "MSFT",
         time_in_force => "gfd",
         trigger       => "immediate",
         type          => "market",
        },
        'dump is correct'
    );
}

# Do it! (And debug it...)
sub _dump ($s, $test = 0) {
    use Data::Dump;
    ddx $s;
    (    # Defaults
       option_id       => $_->_option->id,
       option          => $_->_option->url,
       position_effect => 'open',
       ratio_quantity  => 1,
       side            => 'buy'
    );
}

=head2 C<describe( )>

    $leg->describe( );

Use this method to find a somewhat common way to describe the order for
display.

See C<Finance::Robinhood::Options::OrderBuilder::describe(...)>.

=cut

sub describe($s) {
    Finance::Robinhood::Options::OrderBuilder->new(_rh   => $s->_rh,
                                                   _legs => [$s]
    )->describe;
}

sub _test_describe {
    t::Utility::stash('MSFT') // skip_all('No cached equity instrument');

    #my $leg         = t::Utility::stash('MSFT')->buy(4);
    #my $description = $order->describe;
    #is_ok($description->{opening_strategy}, 'buy_call');
    # TODO: more order types
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
