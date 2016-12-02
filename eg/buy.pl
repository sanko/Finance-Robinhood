#!/usr/bin/env perl
use strict;
use warnings;
use lib '..\lib';
use Getopt::Long qw(GetOptions);
use Pod::Usage qw(pod2usage);
use Finance::Robinhood;
$|++;
#
my ($help, $man,    # Pod::Usage
    $verbose,       # Debugging
    $username, $password,    # New login
    $token,                  # Stored access token
    $symbol, $quantity
);                           # What to buy and how much
## Parse options and print usage if there is a syntax error,
## or if usage was explicitly requested.
GetOptions('help|?'     => \$help,
           man          => \$man,
           'verbose+'   => \$verbose,
           'username:s' => \$username,
           'password:s' => \$password,
           'token:s'    => \$token,
           'symbol=s'   => \$symbol,
           'quantity=i' => \$quantity
) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;
pod2usage("$0: Not sure what to buy.")                       if !$symbol;
pod2usage("$0: Not sure how many shares of $symbol to buy.") if !$quantity;
pod2usage(
    -message =>
        "$0: Missing or incomplete username/password combo given and no authorization token either.",
    -verbose => 1,
    -exitval => 1
) if !(($username && $password) || ($token));
$Finance::Robinhood::DEBUG = $verbose;    # Debugging!
#
my $rh = new Finance::Robinhood($token ? (token => $token) : ());
if ($username && $password && !$token) {
    $rh->login($username, $password) || exit;
    print "*** In the future, you may use $0 -token="
        . $rh->token()
        . " ...\n";
}
my $account = $rh->accounts()->{results}[0];   # Accounts are a paginated list
my $instrument = $rh->instrument($symbol);     # Find the instrument we want
my $order =
    Finance::Robinhood::Order->new(
                     account    => $account,
                     instrument => $instrument,
                     type       => 'market',
                     price => $instrument->quote()->{results}[0]->bid_price(),
                     trigger       => 'immediate',
                     time_in_force => 'gfd',
                     side          => 'buy',
                     quantity      => $quantity
    );
$order
    && printf
    'Market order to buy %d share%s of %s (%s) placed for $%f/share at %s',
    $order->quantity(),
    ($order->quantity() > 1 ? 's' : ''),
    $order->instrument->symbol(),
    $order->instrument->name(),
    $order->price(),
    $order->updated_at();
__END__

=head1 NAME

buy - Buy Stocks for Free from the Command Line

=head1 SYNOPSIS

buy -symbol=... -quantity=... [options]

 Examples:
   buy -username=getMoney -password=*** -symbol=MSFT -quantity=2000
   buy -token=9afcdbe... -symbol=MSFT -quantity=2000

 Options:
   -username        your Robinhood username
   -password        your Robinhood password
   -token           your Robinhood access token
   -symbol          trading symbol of the security *
   -quantity        number of shares to buy *

   -help            brief help message
   -man             full documentation

    * required arguments

=head1 OPTIONS

=over 4

=item B<-username>

Your Robinhood username.

=item B<-password>

Your Robinhood password.

=item B<-token>

Robinhood provides access tokens for authorization which is great because you
don't need to keep providing your username or password on the command line!

You can get it by passing a false C<-token> arg along with your C<-username>
and C<-password>:

    $ buy -username=secret -password=supersecret -token=0 -symbol=MSFT -quantity=200

And on subsequent runs, just provide the C<-token>:

    $ buy -token=a9c321... -symbol=RHT -quantity=50

=item B<-symbol>

The ticker symbol of the security you'd like to place an order for.

=item B<-quantity>

The number of shares you'd like to order.

=item B<-verbose>

Dumps a lot of random debugging stuff to the terminal including private keys.

B<Be very careful where you use this!>

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<buy> will place a market order for the security of your choice to
be executed immediatly.

=cut
