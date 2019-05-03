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

# TODO: Forex
my %limits;
my $range = 1.5;             # Percent
#
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
my $rh = Finance::Robinhood->new->login(
    $username,
    $password,
    challenge_callback => sub {
        my $data = shift;
        promptUser( sprintf 'Login challenge issued (check your %s)', $data->{type} );
    },
    mfa_callback => sub {
        promptUser('MFA code required');
    }
);
$rh || die $rh;
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

    # Forex
    my @holdings = grep { $_->quantity_available > 0 } $rh->forex_holdings( nonzero => 1 )->all;
    for my $holding (@holdings) {
        my $currency = $holding->currency;
        my $pair     = $currency->pair;
        CORE::say $currency->name . ' (' . $pair->symbol . ')' if $verbose;

        #ddx $holding;
        #my $hist = $holding->currency->histo
        my $quote = $pair->quote;
        if ($verbose) {
            CORE::say 'b / a / s:  $'
                . $quote->bid_price . ' / $'
                . $quote->ask_price . ' / $'
                . ( $quote->ask_price - $quote->bid_price );
            CORE::say 'stop:       $' . $limits{ $pair->symbol } if $limits{ $pair->symbol } // 0;
            CORE::say 'stop value: $' . $limits{ $pair->symbol } * $holding->quantity_available
                if $limits{ $pair->symbol } // 0;
            CORE::say 'ask value:  $' . $quote->ask_price * $holding->quantity_available;
            CORE::say 'bid value:  $' . $quote->bid_price * $holding->quantity_available;
        }
        for my $cost ( $holding->cost_bases ) {

            #ddx $cost;
            my $actual = $cost->direct_cost_basis;

            #* $quote->bid_price
            CORE::say 'real cost:  $' . $actual if $verbose;
            my $change = ( 100 * ( ( $quote->bid_price * $holding->quantity_available ) - $actual )
                    / $actual );
            CORE::say '   change:   ' . $change . '%' if $verbose;
            my $minus_range_percent = $quote->bid_price - ( $quote->bid_price * ( $range / 100 ) );

            #warn $minus_range_percent;
            $limits{ $pair->symbol } = $minus_range_percent
                if $minus_range_percent > ( $limits{ $pair->symbol } // 0 );
            if ( $limits{ $pair->symbol } >= $quote->bid_price ) {
                my $order = $pair->sell( $holding->quantity_available )->limit( $quote->bid_price )
                    ->ioc->submit;

                #ddx $order;
                delete $limits{ $pair->symbol };
            }
        }
    }
    #
    CORE::say '-' x 10 if $verbose && ( @positions || @holdings );
    sleep 300;
}

sub promptUser {
    my ( $prompt, $default ) = @_;
    my $retval;
    if ( -t STDIN && -t STDOUT ) {
        print $prompt . ( length $default ? " [$default]" : '' ) . ': ';
        $retval = readline(STDIN);
        chomp $retval;
    }
    else {
        require Prima;
        require Prima::Application;
        Prima::Application->import();
        require Prima::MsgBox;
        $retval = Prima::MsgBox::input_box( $prompt, $prompt, $default // '' );
    }
    $retval ? $retval : $default ? $default : $retval;
}
