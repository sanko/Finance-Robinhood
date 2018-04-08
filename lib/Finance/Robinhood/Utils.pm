package Finance::Robinhood::Utils;
use base 'Exporter::Tiny';
our @EXPORT = qw[v4_uuid];

# The apps use psedudo-secure v4 UUIDs so we will too.
sub v4_uuid {
    my $uuid = '';
    for ( 1 .. 4 ) {
        $uuid .= pack 'I',
            ( ( int( rand(65536) % 65536 ) << 16 ) | ( int( rand(65536) ) % 65536 ) );
    }
    substr $uuid, 6, 1, chr( ord( substr( $uuid, 6, 1 ) ) & 0x0f | 0x40 );
    join '-', map { unpack 'H*', $_ } map { substr $uuid, 0, $_, '' } ( 4, 2, 2, 2, 6 );
}

# warn _create_v4_uuid if !caller;
1;
