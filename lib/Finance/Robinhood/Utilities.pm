package Finance::Robinhood::Utilities;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls forex

=head1 NAME

Finance::Robinhood::Utilities - Collection of Portable Utility Functions

=head1 SYNOPSIS

    use Finance::Robinhood::Utilities qw[gen_uuid];

    my $device_id = gen_uuid();

=cut

our $VERSION = '0.92_002';
use Exporter 'import';
our @EXPORT_OK = ('gen_uuid');

=head1 FUNCTIONS


=head2 C<gen_uuid( )>

Returns a UUID.

=cut

sub gen_uuid() {
    CORE::state $srand;
    $srand = srand() if !$srand;
    my $retval = join '', map {
        pack 'I',
            ( int( rand(0x10000) ) % 0x10000 << 0x10 ) | int( rand(0x10000) ) % 0x10000
    } 1 .. 4;
    substr $retval, 6, 1, chr( ord( substr( $retval, 6, 1 ) ) & 0x0f | 0x40 );    # v4
    return join '-', map { unpack 'H*', $_ } map { substr $retval, 0, $_, '' } ( 4, 2, 2, 2, 6 );
}

sub _test__gen_uuid {
    like( gen_uuid(), qr[^[0-9a-f]{8}(?:\-[0-9a-f]{4}){3}\-[0-9a-f]{12}$]i, 'generated uuid' );
}

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

1;
