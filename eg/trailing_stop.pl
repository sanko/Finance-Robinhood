#!/usr/bin/env perl
use strict;
use warnings;

# Install Perl dist first:
# > cpanm -n Finance::Robinhood
use lib '../lib', 'lib';
use Getopt::Long qw(GetOptions);
use Pod::Usage qw(pod2usage);
binmode STDOUT, ':utf8';
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
) or pod2usage(2);
$percent //= 3;              # Defaults

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

#
my $rh = Finance::Robinhood->new->login( $username, $password );

while (1) {
    # Equities
    my @positions = $rh->equity_positions( nonzero => 1 )->all;
    for my $position (@positions) {
        my $instrument = $position->instrument;
        CORE::say(
            ( $instrument->simple_name // $instrument->name ) . ' (' . $instrument->symbol . ')' )
            if $verbose;
        my @orders_outstanding = grep { $_->state =~ m[queued|confirmed|partially_filled] }
            grep { $_->trigger eq 'stop' }    # Don't mess with manually set orders
            grep { $_->side eq 'sell' }
            $rh->equity_orders( instrument => $position->instrument )->all;
        my $quote      = $instrument->prices( delayed => 0, source => 'consolidated' ); # Live quote
        my $last_price = $quote->price;
        my $target_price = $last_price - ( $last_price * ( $percent / 100 ) );
        CORE::say 'b / a / s: ' . join ' / $', $quote->bid_price, $quote->ask_price,
            $quote->ask_price - $quote->bid_price
            if $verbose;

        if ( $position->instrument->min_tick_size ) {
            require POSIX;
            $target_price
                = $position->instrument->min_tick_size
                * POSIX::floor(
                ( $target_price + .05 * $instrument->min_tick_size ) / $target_price );
        }
        $target_price = sprintf( ( $last_price >= 1 ? '%.02f' : '%.04f' ), $target_price );
        CORE::say 'cost basis:  $'
            . $position->average_buy_price
            . ' (gain/loss $'
            . sprintf( '%.2f', $last_price - $position->average_buy_price ) . ')'
            if $verbose;
        CORE::say 'stop target: $' . $target_price
            if $verbose;    # .  ' ($' . sprintf('%.2f', $last_price - $target_price) . ')';
        my $quantity
            = $position->quantity
            - $position->shares_held_for_options_collateral
            - $position->shares_held_for_options_events
            - $position->shares_held_for_sells
            - $position->shares_held_for_stock_grants;
        map { $quantity += $_->cancel->quantity }
            grep { $_->price < $target_price } @orders_outstanding;
        next if !$quantity;
        CORE::say 'Setting new order to panic sell ' . $quantity . ' shares at $' . $target_price
            if $verbose;

        my $order
            = $position->instrument->sell($quantity)->limit($target_price)->stop($target_price)
            ->gtc->submit;
    }
    sleep 15;
}
