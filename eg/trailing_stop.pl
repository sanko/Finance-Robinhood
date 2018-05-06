#!/usr/bin/env perl
use strict;
use warnings;

# Install Perl dist first:
# > cpanm -n Finance::Robinhood
use lib '../lib', 'lib';
use Getopt::Long qw(GetOptions);
use Pod::Usage qw(pod2usage);
use Finance::Robinhood;
use Try::Tiny;
$|++;
#
my (
    $help, $man,    # Pod::Usage
    $verbose,       # Debugging
    $username, $password,    # New login
    $percent                 # How much rope to give us
);
## Parse options and print usage if there is a syntax error,
## or if usage was explicitly requested.
GetOptions(
    'help|?'       => \$help,
    man            => \$man,
    'verbose+'     => \$verbose,
    'username|u:s' => \$username,
    'password|p:s' => \$password,
    'percent|%t=f' => \$percent
    ) or
    pod2usage(2);
$percent //= 3;    # Defaults

#$verbose++;
#
pod2usage(1) if $help;
pod2usage( -verbose => 2 ) if $man;
pod2usage("$0: Not sure how far away to keep orders.") if !$percent;
pod2usage(
    -message => "$0: Missing or incomplete username/password combo given.",
    -verbose => 1,
    -exitval => 1
) if !( $username && $password );

#$Finance::Robinhood::DEBUG = $verbose;    # Debugging!
#
my $rh = new Finance::Robinhood( username => $username, password => $password );
while (1) {
    my @positions = $rh->equity_positions( nonzero => \1 )->all;
    for my $position (@positions) {
        my @orders_outstanding = grep { $_->state =~ m[queued|confirmed|partially_filled] }
            grep { $_->trigger eq 'stop' }    # Don't mess with manually set orders
            grep { $_->side eq 'sell' }
            $rh->equity_orders( instrument => $position->instrument )->all;
        my $last_price = $position->instrument->quote->last_trade_price;
        my $target_price = $last_price - ( $last_price * ( $percent / 100 ) );
        if ( $position->instrument->min_tick_size ) {
            require POSIX;
            $target_price
                = $position->instrument->min_tick_size
                * POSIX::floor(
                ( $target_price + .05 * $position->instrument->min_tick_size ) / $target_price );
        }
        $target_price = sprintf( ( $last_price >= 1 ? '%.02f' : '%.04f' ), $target_price );
        my $quantity = $position->quantity - $position->shares_held_for_sells;
        map { $quantity += $_->cancel->quantity }
            grep { $_->price < $target_price } @orders_outstanding;
        next if !$quantity;
        my $order = $position->instrument->place_order(
            side          => 'sell',
            type          => 'market',
            price         => $target_price,
            quantity      => $quantity,
            trigger       => 'stop',
            stop_price    => $target_price,
            time_in_force => 'gtc'
            )    #->cancel
    }
    sleep 15;
}
