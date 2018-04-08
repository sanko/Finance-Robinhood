use strict;
use Test::More 0.98;
use lib '../lib/';
$|++;
use_ok $_ for qw(
    Finance::Robinhood
);
my $rh = Finance::Robinhood->new();
#
my $msft = $rh->equity_quote('MSFT');
isa_ok $msft, 'Finance::Robinhood::Equity::Quote', 'Gathered quote data for single equity...';
is $msft->symbol(), 'MSFT', '...and it is Microsoft!';
#
my $by_symbol = $rh->equity_quotes( symbols => [ 'LUV', 'JBLU', 'DAL' ] );
isa_ok $by_symbol, 'Finance::Robinhood::Utils::Paginated',
    'Gathered quote data for a list by symbol';
is $by_symbol->next->symbol(), 'LUV',  'Southwest Airlines';
is $by_symbol->next->symbol(), 'JBLU', 'JetBlue Airways';
is $by_symbol->next->symbol(), 'DAL',  'Delta Air Lines';
#
my $by_instrument = $rh->equity_quotes(
    instruments => [
        '09bc1a2d-534d-49d4-add7-e0eb3be8e640', '9fcb8b24-6f4e-42a5-9300-c1062cd2fec2',
        'b9a6444e-ce3e-4186-be32-b82814d2b418'
    ]
);
isa_ok $by_instrument, 'Finance::Robinhood::Utils::Paginated',
    'Gathered quote data for a list by instrument id';
is $by_instrument->next->symbol(), 'LUV',  'Southwest Airlines';
is $by_instrument->next->symbol(), 'JBLU', 'JetBlue Airways';
is $by_instrument->next->symbol(), 'DAL',  'Delta Air Lines';

# Errors
my $fake = $rh->equity_quote('FAKE');
isa_ok $fake, 'Finance::Robinhood::Utils::Error', 'Failed to gather quote data for fake equity...';
is $fake->status, 404, '...which returns a 404';
#
my $fake_real_by_symbol = $rh->equity_quotes( symbols => [ 'FAKE', 'MSFT' ] );
isa_ok $fake_real_by_symbol, 'Finance::Robinhood::Utils::Paginated',
    'Gathered quote data for a list by symbol (fake and real)';
is $fake_real_by_symbol->next, (), '...$FAKE is undefined';
is $fake_real_by_symbol->next->symbol, 'MSFT', '...but $MSFT is defined';
#
my $fake_real_by_id = $rh->equity_quotes( instruments =>
        [ 'ba5eba11-d215-4866-9758-5ca1ab1eda1a', '50810c35-d215-4866-9758-0ada4ac79ffa' ] );
isa_ok $fake_real_by_id, 'Finance::Robinhood::Utils::Paginated',
    'Gathered quote data for a list by symbol (fake and real)';
is $fake_real_by_id->next, (), '...made up instrument id is undefined';
is $fake_real_by_id->next->symbol, 'MSFT',
    '...but 50810c35-d215-4866-9758-0ada4ac79ffa is Microsoft';
#
done_testing;
