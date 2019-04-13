package Finance::Robinhood::Error;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Error - What You Find When Things Go Wrong

=head1 SYNOPSIS

    use Finance::Robinhood;

    my $rh = Finance::Robinhood->new->login( 'timbob35', 'hunter3' );    # Wrong password
    $rh || die $rh; # false value is retured; stringify it as a fatal error

=head1 DESCRIPTION

When this distribution has trouble with anything, this is returned.

Error objects evaluate to untrue values.

Error objects stringify to the contents of C<detail( )> or 'Unknown error.'

=head1 METHODS

=cut

our $VERSION = '0.92_002';
use Mojo::Base-base, -signatures;
use Mojo::URL;
use overload 'bool' => sub ( $s, @ ) {0},
    '""'     => sub ( $s, @ ) { $s->detail // 'Unknown error.' },
    fallback => 1;
#

=head2 C<detail( )>

	warn $error->detail;

Returns a string. If this is a failed API call, the message returned by the
service is here.

=cut

has _rh => undef => weak => 1;

has ['detail'];

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
