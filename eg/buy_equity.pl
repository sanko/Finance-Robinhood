#!/usr/bin/env perl
use strict;
use warnings;

# Install Perl dist first:
# > cpanm -n Finance::Robinhood
use lib '../lib', 'lib';
use Mojo::Util qw(extract_usage getopt);
binmode STDOUT, ':utf8';
use Finance::Robinhood;
use Try::Tiny;
$|++;
## Parse options and print usage if there is a syntax error,
## or if usage was explicitly requested.
getopt
    'help|?'       => \my $help,
    'verbose|v'    => \my $verbose,
    'username|u:s' => \my $username,
    'password|p:s' => \my $password,
    'device|d:s'   => \my $device,
    'symbol|s=s'   => \my $symbol,
    'quantity|q=i' => \my $quantity,
    'at=s'         => \my $limit;
#
die extract_usage if $help;    # || !(my $config = shift);
die "Error: I'm not sure what to buy.\n\n" . extract_usage if !$symbol;
die "Error: Not sure how many shares of $symbol to buy.\n\n" . extract_usage
    if !$quantity;
die "Error: Missing or incomplete username/password combo given.\n\n" .
    extract_usage
    if !($username && $password);
#
my $rh
    = Finance::Robinhood->new($device ? (device_token => $device) : ())
    ->login(
    $username,
    $password,
    challenge_callback => sub {
        my $data = shift;
        promptUser(sprintf 'Login challenge issued (check your %s)',
                   $data->{type});
    },
    mfa_callback => sub {
        promptUser('MFA code required');
    }
    );
$rh || die $rh;

# What are we buying today?
my $instrument = $rh->equity_instrument_by_symbol($symbol);
$instrument || die $instrument;

# Figure out what we're willing to pay...
my $quote = $instrument->prices(delayed => 0, source => 'consolidated');
$limit
    = defined $limit
    ? $limit =~ m[^(?:[.]\d+|\d+(?:[.]\d*)?)$]
        ? $limit
        : $limit eq 'ask' ? $quote->ask_price
    : $limit eq 'bid' ? $quote->bid_price
    : $quote->price
    : $quote->price;

# Get to work!
my $order
    = $instrument->buy($quantity)->limit($limit)->extended_hours->submit;
die $order if !$order;
printf 'Limit order to buy %d share%s of %s (%s) placed for $%f/share at %s',
    $order->quantity(), ($order->quantity() > 1 ? 's' : ''),
    $instrument->symbol(), $instrument->name(), $limit, $order->updated_at()
    if $verbose;

sub promptUser {
    my ($prompt, $default) = @_;
    my $retval;
    if (-t STDIN && -t STDOUT) {
        print $prompt . (length $default ? " [$default]" : '') . ': ';
        $retval = readline(STDIN);
        chomp $retval;
    }
    else {
        require Prima;
        require Prima::Application;
        Prima::Application->import();
        require Prima::MsgBox;
        $retval = Prima::MsgBox::input_box($prompt, $prompt, $default // '');
    }
    $retval ? $retval : $default ? $default : $retval;
}
__END__

=head1 NAME

buy_equity - Crazy Basic Equity Buying Example

=head1 SYNOPSIS

  Usage: buy_equity [options]

    buy_equity -username mike34 -password '$lM#lO@9n4ofsnamkfsa' -symbol TSLA -quantity 15
    buy_equity -u mike34 -p '$lM#lO@9n4ofsnamkfsa' -s MSFT -q 15 -at 240.49
    buy_equity -u mike34 -p '$lM#lO@9n4ofsnamkfsa' -s BRK.B -q 2 -at bid

  Options:
    -?, --help                   Print a brief help message and exits
    -v, --verbose                Turns on status text during program run
    -u, --username <string>      Your account name or email address
    -p, --password <string>      Your password
    -d, --device <UUID>          The device ID for your client
    -s, --symbol <string>        Ticker symbol to place an order for
    -q, --quantity <integer>     Number of shares to place an order for
    --at [<float>|ask|bid|last]  What price should the resulting limit order be:
                                    - <float> - you choose the price
                                    - ask   - places an order at the current ask
                                    - bid   - places an order at the current bid price
                                    - last  - places an order at the the most recent price paid
                                 The default is the last paid price

=head1 DESCRIPTION

This program is a very dumb bare bones example to find an equity instrument
by its symbol, gather live quote data, and place an order to buy a number of
shares.

For now, we only support limit orders in this example.

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
