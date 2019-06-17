use Test2::V0;
use Test2::Tools::Subtest qw/subtest_streamed/;
use lib '../../lib', '../lib', 'lib';
$|++;

# DEV note: To run *all* tests, you need to provide login info.
# Do this by setting RHUSER, RHPASS, and RHDEVICE environment variables.
#
my @classes = (
    'Finance::Robinhood',

    # ACATS
    'Finance::Robinhood::ACATS::Transfer',
    'Finance::Robinhood::ACATS::Transfer::Position',

    # Equity user data
    'Finance::Robinhood::Equity::Account',
    'Finance::Robinhood::Equity::Account::InstantEligibility',
    'Finance::Robinhood::Equity::Account::MarginBalances',
    'Finance::Robinhood::Equity::Account::Portfolio',
    'Finance::Robinhood::Equity::Position', 'Finance::Robinhood::User',
    'Finance::Robinhood::User::AdditionalInfo',
    'Finance::Robinhood::User::BasicInfo',
    'Finance::Robinhood::User::Employment',
    'Finance::Robinhood::User::IDInfo',
    'Finance::Robinhood::User::InternationalInfo',
    'Finance::Robinhood::User::Profile',

    # Stocks, ETFs, ETNs, etc.
    'Finance::Robinhood::Equity::Fundamentals',
    'Finance::Robinhood::Equity::Instrument',
    'Finance::Robinhood::Equity::Order',
    'Finance::Robinhood::Equity::Order::Execution',
    'Finance::Robinhood::Equity::OrderBuilder',
    'Finance::Robinhood::Equity::Quote', 'Finance::Robinhood::Equity::Split',
    'Finance::Robinhood::Equity::Earnings',
    'Finance::Robinhood::Equity::Earnings::Call',
    'Finance::Robinhood::Equity::Earnings::EPS',
    'Finance::Robinhood::Equity::Earnings::Report',
    'Finance::Robinhood::Equity::Mover',
    'Finance::Robinhood::Equity::Prices',
    'Finance::Robinhood::Equity::PriceMovement',
    'Finance::Robinhood::Equity::Tag', 'Finance::Robinhood::Equity::Ratings',
    'Finance::Robinhood::Equity::Historicals',
    'Finance::Robinhood::Equity::Historicals::Datapoint',

    # Equity and Forex watchlists
    'Finance::Robinhood::Equity::Watchlist',
    'Finance::Robinhood::Equity::Watchlist::Element',
    'Finance::Robinhood::Forex::Watchlist',

    # Trading Venue data
    'Finance::Robinhood::Equity::Market',
    'Finance::Robinhood::Equity::Market::Hours',

    # Forex user data
    'Finance::Robinhood::Forex::Account',
    'Finance::Robinhood::Forex::Activation',
    'Finance::Robinhood::Forex::Portfolio',
    'Finance::Robinhood::Forex::Holding', 'Finance::Robinhood::Forex::Cost',

    # Forex
    'Finance::Robinhood::Forex::Halt', 'Finance::Robinhood::Forex::Pair',
    'Finance::Robinhood::Forex::Currency',
    'Finance::Robinhood::Forex::Order',
    'Finance::Robinhood::Forex::Order::Execution',
    'Finance::Robinhood::Forex::OrderBuilder',
    'Finance::Robinhood::Forex::Quote',
    'Finance::Robinhood::Forex::Historicals',
    'Finance::Robinhood::Forex::Historicals::Datapoint',

    # Options
    'Finance::Robinhood::Options::Chain',
    'Finance::Robinhood::Options::Chain::Ticks',
    'Finance::Robinhood::Options::Chain::Underlying',
    'Finance::Robinhood::Options::Instrument',

    # Generic
    'Finance::Robinhood::News', 'Finance::Robinhood::Notification',
    'Finance::Robinhood::Search',

    # Utility
    'Finance::Robinhood::Utilities', 'Finance::Robinhood::Utilities::Iterator'
);
for my $class (sort @classes) {
    subtest_streamed $class => sub {
        eval <<"T"; bail_out("$class did not compile: $@") if $@;
use lib '../lib';
use $class;
package $class;
use Test2::V0 ':DEFAULT', '!call', call => {-as => 'test_call'};
T
        subtest_streamed $class . '::' . $_ => sub {
            $class->$_();
            }
            for _get_tests($class);
        t::Utility::clear_stash($class);
    }
}
#
done_testing();

sub _get_tests {
    my $class = shift;
    no strict 'refs';
    sort grep { $class->can($_) } grep {/^_test_.+/} keys %{$class . '::'};
}
#
package t::Utility;
my %state;
use Test2::V0;

sub rh_instance {
    my $auth = shift // !1;
    if (!defined $state{$auth}) {
        eval 'require Finance::Robinhood';
        bail_out("Oh junk!: $@") if $@;
        if ($auth) {
            my ($user, $pass, $device)
                = ($ENV{RHUSER}, $ENV{RHPASS}, $ENV{RHDEVICE});
            skip_all('No auth info in environment')
                unless $user && $pass && $device;
            $state{$auth} = Finance::Robinhood->new(device_token => $device)
                ->login($user, $pass);
        }
        else {
            $state{$auth} = Finance::Robinhood->new;
        }
    }
    $state{$auth};
}
my %stash;    # Don't leak

sub stash {
    my ($package, $filename, $line) = caller;
    my ($key, $data) = @_;
    $stash{$package}{$key} = $data if defined $data;
    $stash{$package}{$key};
}
sub clear_stash { delete $stash{+shift} }
