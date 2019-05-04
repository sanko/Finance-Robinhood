package Finance::Robinhood::OAuth2::Token;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::OAuth2::Token - Private Authorization Data

=head1 SYNOPSIS

    # Don't use this directly

=cut

our $VERSION = '0.92_003';
use Mojo::Base-base;
#
has _rh => undef => weak => 1;
has ['access_token',  'backup_code', 'expires_in', 'mfa_code',
     'refresh_token', 'scope',       'token_type'
];

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
