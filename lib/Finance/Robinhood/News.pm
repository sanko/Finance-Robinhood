package Finance::Robinhood::News;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::News - Represents a Single News Article

=head1 SYNOPSIS

    use Text::Wrap qw[wrap];
    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;
    CORE::say wrap( '', '    ', $_->title . '\n' . $_->summary ) for $rh->feed->take(10);

=head1 METHODS

=cut

use Mojo::Base-base, -signatures;
use Mojo::URL;
use Time::Moment;
#
has _rh => undef => weak => 1;
has [
    'api_source', 'author',            'currency_id', 'instrument',
    'num_clicks', 'preview_image_url', 'source',      'summary',
    'title',      'uuid',              'relay_url',   'url'
];

=head2 C<published_at( )>

	$article->published_at->to_string;

Returns the time the article was published as a Time::Moment object.

=cut

sub published_at($s) {
    Time::Moment->from_string( $s->{published_at} );
}

sub _test_published_at {
    plan( tests => 2 );
    my $rh   = new_ok('Finance::Robinhood');
    my $msft = $rh->news('MSFT');
    isa_ok( $msft->next->published_at, 'Time::Moment' );
    done_testing();
}

=head2 C<updated_at( )>

	$article->updated_at->to_string;

Returns the time the article was published or last updated as a Time::Moment
object.

=cut

sub updated_at($s) {
    Time::Moment->from_string( $s->{updated_at} );
}

sub _test_updated_at {
    plan( tests => 2 );
    my $rh   = new_ok('Finance::Robinhood');
    my $msft = $rh->news('MSFT');
    isa_ok( $msft->next->updated_at, 'Time::Moment' );
    done_testing();
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
