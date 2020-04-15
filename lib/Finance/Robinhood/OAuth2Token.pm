package Finance::Robinhood::OAuth2Token {

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::OAuth2Token - Private Authorization Data

=head1 SYNOPSIS

    # Don't use this directly

=cut

    # RH produces basic JWT auth tokens with useful data
    our $VERSION = '0.92_003';
    #
    use Moo;
    use Time::Moment;
    use Types::Standard qw[ArrayRef Enum InstanceOf Maybe Num Split Str];
    use experimental 'signatures';
    #
    #
    has [qw[access_token refresh_token]] => ( is => 'ro', isa => Str, required => 1 );
    #
    has expires_in => ( is => 'ro', isa => Num );
    has token_type => ( is => 'ro', isa => Str, default => 'Bearer' );
    has scope => (
        is  => 'ro',
        isa => ( ArrayRef [ Enum [qw[internal read banking]] ] )->plus_coercions( Split [qr[\|]] ),
        coerce   => 1,
        required => 1,
        default  => sub { ['internal'] }
    );
    has [qw[backup_code mfa_code]] => ( is => 'ro', isa => Maybe [Str], predicate => 1 );
    #
    has birth => (
        is       => 'ro',
        default  => sub ($s) { Time::Moment->now },
        init_arg => undef,
        isa      => InstanceOf ['Time::Moment']
    );

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
}
