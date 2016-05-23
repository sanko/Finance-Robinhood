#!/usr/bin/env perl
use strict;
use warnings;
use lib '..\lib';
use Getopt::Long qw(GetOptions);
use Pod::Usage qw(pod2usage);
use Finance::Robinhood;
use Text::CSV;
$|++;
#
my ($help, $man,    # Pod::Usage
    $verbose,       # Debugging
    $username, $password,    # New login
    $token,                  # Stored access token
    $filename,               # Where to write CSV
    $all                     # Include cancelled orders
);
## Parse options and print usage if there is a syntax error,
## or if usage was explicitly requested.
GetOptions('help|?'     => \$help,
           man          => \$man,
           'verbose+'   => \$verbose,
           'username:s' => \$username,
           'password:s' => \$password,
           'token:s'    => \$token,
           'output=s'   => \$filename,
           'all+'       => \$all
) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-verbose => 2) if $man;
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
#
my $csv = Text::CSV->new({eol => "\n"})
    || die 'Cannot use CSV: ' . Text::CSV->error_diag();
my $fh;
if (defined $filename) {
    open $fh, '>', $filename or die "Failed to open $filename: $!";
    END { close $fh if $fh }
}
else { $fh = *STDOUT; }
#
my $page  = 1;
my $tally = 0;
my $cursor;
while (1) {
    print "Gathering page $page of data... " if defined $filename;
    my $orders = $rh->list_orders({cursor => $cursor});
    print "okay\n" if defined $filename;
    my %output;
    for my $order (@{$orders->{results}}) {
        next if $order->state ne 'filled' && !$all;
        my $executions = $order->executions;
        my $instrument = $order->instrument;
        for my $key (
            grep {
                !m[(account|rh|instrument|executions|cancel|position|url)]
            } keys %$order
            )
        {   push @{$output{$key}}, $order->$key;
        }
        push @{$output{symbol}}, $instrument->symbol;
        my $value = 0;
        if ($order->state eq 'filled') {
            $value += $_->{price} * $_->{quantity} for @{$order->executions};
        }
        push @{$output{price}}, $value;
    }
    $csv->print($fh, [reverse sort keys %output]) if !$tally;
    for my $i (0 .. $#{$output{symbol}}) {
        $tally++;
        $csv->print($fh, [map { $output{$_}[$i] } reverse sort keys %output]);
    }
    last if !defined $orders->{next};
    $page++;
    $cursor = $orders->{next};
}
printf "Wrote $tally records to $filename" if defined $filename;
__END__

=head1 NAME

export_orders - Exports all orders to a CSV file from the Command Line

=head1 SYNOPSIS

export_orders [options]

 Examples:
   buy -username=getMoney -password=*** -output=Robinhood.csv

 Options:
   -username        your Robinhood username
   -password        your Robinhood password
   -token           your Robinhood access token
   -output          filename to store the csv data in
   -all             include cancelled orders

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

=item B<-output>

Where would you like to store the CSV data? Without a filename, this prints to
STDOUT

=item B<-verbose>

Dumps a lot of random debugging stuff to the terminal including private keys.

B<Be very careful where you use this!>

=item B<-all>

Include cancelled orders with the filled. This is probably not very usefull.

=item B<-help>

Print a brief help message and exits.

=item B<-man>

Prints the manual page and exits.

=back

=head1 DESCRIPTION

B<export_orders> will gather data on your I<entire> account history and
convert it to a CSV file.

=cut
