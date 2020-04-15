use Test2::V0;    # Samesame
use Test2::Tools::Subtest qw[subtest_streamed];
use Test2::Tools::Compare qw[isnt];
use Dotenv;
use lib '../../lib', '../lib', 'lib';
$|++;

=for dev testing

DEV note: To run *all* tests, you need to provide login info. Do this by setting RHUSER, RHPASS, and RHDEVICE
environment variables. The easiest way to do that is to put in a .env file in the dist's base directory which will be
loaded in this file. It should look like this...

    RHDEVICE = c893a722-5674-4924-85ac-3d3620eb80ba
    RHUSER = yourusername
    RHPASS = yourpasswordhere
    RHSTRICT = 1

=cut

eval {
    Dotenv->load( grep { -f $_ } '../../.env', '../.env', './.env' );
};
my @classes = (

    # Working
    'Finance::Robinhood',                       'Finance::Robinhood::Currency',
    'Finance::Robinhood::Currency::Activation', 'Finance::Robinhood::Currency::Halt',
    'Finance::Robinhood::Currency::Order',      'Finance::Robinhood::Currency::OrderBuilder',
    'Finance::Robinhood::Currency::Quote',      'Finance::Robinhood::Currency::Position',
    'Finance::Robinhood::Currency::Portfolio',  'Finance::Robinhood::Currency::Pair',
    'Finance::Robinhood::Currency::Watchlist',  'Finance::Robinhood::Equity',
    'Finance::Robinhood::Equity::Prices',       'Finance::Robinhood::Equity::Account',
    'Finance::Robinhood::Equity::List',         'Finance::Robinhood::Equity::Order',
    'Finance::Robinhood::Equity::OrderBuilder', 'Finance::Robinhood::Inbox',
    'Finance::Robinhood::Inbox::Message',       'Finance::Robinhood::Inbox::Sender',
    'Finance::Robinhood::Inbox::Thread',        'Finance::Robinhood::News',
    'Finance::Robinhood::Notification',         'Finance::Robinhood::User',
    'Finance::Robinhood::Utilities::Iterator',  'Finance::Robinhood::Utilities::Response',
    'Finance::Robinhood::Cash', 'Finance::Robinhood::Cash::Card', 'Finance::Robinhood::Cash::ATM',

    # Testing
    # Unknown
    #'Finance::Robinhood::Types',
    #'Finance::Robinhood::ACATS',
    #
    #'Finance::Robinhood::Options::Order',
    #'Finance::Robinhood::Options::Position',
    #'Finance::Robinhood::Options::Event',
    #'Finance::Robinhood::Options::Contract',
    #'Finance::Robinhood::Options::Quote',
    #'Finance::Robinhood::Options::Chain',
    #'Finance::Robinhood::Options::Order',
    #'Finance::Robinhood::Types',
    #'Finance::Robinhood::Options',
    #'Finance::Robinhood::Currency::Order',
    #'Finance::Robinhood::Currency::Historicals',
    #'Finance::Robinhood::Currency::Pair',
    #'Finance::Robinhood::Currency::OrderBuilder',
    #'Finance::Robinhood::Currency::Halt',
    #'Finance::Robinhood::Currency::Quote',
    #'Finance::Robinhood::Currency::Account',
    #'Finance::Robinhood::OAuth2Token',
    #'Finance::Robinhood::Equity::Collection',
    #'Finance::Robinhood::Equity::Account::Portfolio',
    #'Finance::Robinhood::Equity::Account::CashBalances',
    #'Finance::Robinhood::Equity::Account::MarginEligibility',
    #'Finance::Robinhood::Equity::Account::MarginBalances',
    #'Finance::Robinhood::Equity::Account',
    #'Finance::Robinhood::Equity::Fundamentals',
    #'Finance::Robinhood::Equity::Mover',
    #'Finance::Robinhood::Equity::Order',
    #'Finance::Robinhood::Equity::Watchlist::Element',
    #'Finance::Robinhood::Equity::Position',
    #'Finance::Robinhood::Equity::Watchlist',
    #'Finance::Robinhood::Equity::OrderBuilder',
    #'Finance::Robinhood::Equity::PriceMovement',
    #'Finance::Robinhood::Equity::List',
    #'Finance::Robinhood::Equity::Market',
    #'Finance::Robinhood::Equity::Account',
    #'Finance::Robinhood::Equity::Market::Hours',
    #'Finance::Robinhood::Utilities',
);

=cut
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
    'Finance::Robinhood::Equity::PriceBook',
    'Finance::Robinhood::Equity::PriceBook::Datapoint',

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
    'Finance::Robinhood::Options::Event',
    'Finance::Robinhood::Options::Event::CashComponent',
    'Finance::Robinhood::Options::Event::EquityComponent',
    'Finance::Robinhood::Options::Order',
    'Finance::Robinhood::Options::Order::Execution',
    'Finance::Robinhood::Options::Order::Leg',
    'Finance::Robinhood::Options::OrderBuilder',
    'Finance::Robinhood::Options::OrderBuilder::Leg',
    'Finance::Robinhood::Options::Position',
    'Finance::Robinhood::Options::Quote',
    'Finance::Robinhood::Options::Historicals',
    'Finance::Robinhood::Options::Historicals::Datapoint',

    # Generic
    'Finance::Robinhood::News', 'Finance::Robinhood::Notification',
    'Finance::Robinhood::Search',

    # Utility
    'Finance::Robinhood::Utilities', 'Finance::Robinhood::Utilities::Iterator'
);
=cut

diag('No auth info in environment. Some tests will be skipped')
    unless $ENV{RHUSER} && $ENV{RHPASS} && $ENV{RHDEVICE};
for my $class ( sort @classes ) {

    #subtest_streamed $class => sub {
    eval <<"T"; bail_out("$class did not compile: $@") if $@;
use lib '../lib';
{package $class;eval 'use MooX::StrictConstructor;use MooX::InsideOut;' if defined \$ENV{RHSTRICT}};
use $class;
package $class;
use strictures 2;
use Test2::V0 ':DEFAULT', '!call', call => {-as => 'test_call'};
T

    #};
    subtest_streamed $class . '::' . $_ => sub {
        $class->$_();
        }
        for _get_tests($class);
    t::Utility::clear_stash($class);
}
#
done_testing();

sub _get_tests {
    my $class = shift;
    no strict 'refs';
    sort grep { $class->can($_) } grep {/^_test_.+/} keys %{ $class . '::' };
}
#
package    # Hide it!
    t::Utility;
my %state;
use Test2::V0;
use experimental 'signatures';

sub rh_instance($auth = 0) {
    if ( !defined $state{$auth} ) {
        eval 'require Finance::Robinhood';
        bail_out("Oh junk!: $@") if $@;
        if ($auth) {
            my ( $user, $pass, $device ) = ( $ENV{RHUSER}, $ENV{RHPASS}, $ENV{RHDEVICE} );
            skip_all('No auth info in environment') unless $user && $pass && $device;
            $state{$auth} = Finance::Robinhood->new(
                username     => $user,
                password     => $pass,
                device_token => $device,
                mfa_callback => sub {
                    promptUser('MFA code required');
                },
                challenge_callback => sub {
                    my ($challenge) = @_;
                    my $response = promptUser( sprintf 'Login challenge issued (sent via %s)',
                        $challenge->type );
                    warn $response;
                    $challenge->respond($response);
                }
            );
        }
        else {
            $state{$auth} = Finance::Robinhood->new;
        }
    }
    $state{$auth};
}
my %stash;    # Don't leak

sub stash {
    my ( $package, $filename, $line ) = caller;
    my ( $key, $data ) = @_;
    $stash{$package}{$key} = $data if defined $data;
    $stash{$package}{$key};
}
sub clear_stash { delete $stash{ +shift } }

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
