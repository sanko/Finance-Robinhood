package Finance::Robinhood::News;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::News - Represents a Single News Article

=head1 SYNOPSIS

    use Text::Wrap qw[wrap];
    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;
    CORE::say wrap( '', '    ', $_->title . "\n" . $_->summary ) for $rh->news('TSLA')->take(10);

=head1 METHODS

=cut

our $VERSION = '0.92_003';

sub _test__init {
    my $rh   = t::Utility::rh_instance(1);
    my $msft = $rh->news('MSFT')->current;
    my $btc  = $rh->news('d674efea-e623-4396-9026-39574b92b093')->current;
    isa_ok($msft, __PACKAGE__);
    t::Utility::stash('MSFT', $msft);    #  Store it for later
    isa_ok($btc, __PACKAGE__);
    t::Utility::stash('BTC', $btc);      #  Store it for later
}
use Mojo::Base-base, -signatures;
use Mojo::URL;
use Time::Moment;
#
has _rh => undef => weak => 1;

=head2 C<api_source( )>

Returns the article's source.

=head2 C<author( )>

If available, this will return the author who wrote the article.

=head2 C<num_clicks( )>

The current total number of times this article has been clicked by Robinhod's
users.

=head2 C<source( )>

Returns the article's source in a format suited for display.

=head2 C<summary( )>

Returns a brief (often truncated) summary of the article.

=head2 C<title( )>

Returns the article's title.

=head2 C<uuid( )>

Returns the article's unique ID.

=cut

has ['api_source', 'author', 'num_clicks', 'source',
     'summary',    'title',  'uuid'
];

=head2 C<preview_image_url( )>

If this article has a thumbnail, this will return the URL as a Mojo::Url
object.

=cut

sub preview_image_url($s) {
    $s->{preview_image_url} ? Mojo::URL->new($s->{preview_image_url}) : ();
}

sub _test_preview_image_url {
    t::Utility::stash('MSFT') // skip_all();
    isa_ok(t::Utility::stash('MSFT')->preview_image_url, 'Mojo::URL');
    t::Utility::stash('BTC') // skip_all();
    isa_ok(t::Utility::stash('BTC')->preview_image_url, 'Mojo::URL');
}

=head2 C<relay_url( )>

Returns a Mojo::URL object containing the URL Robinhood would like you to use.
This will register as a click and will then redirect to the article itself.

=cut

sub relay_url($s) {
    $s->{relay_url} ? Mojo::URL->new($s->{relay_url}) : ();
}

sub _test_relay_url {
    t::Utility::stash('MSFT') // skip_all();
    isa_ok(t::Utility::stash('MSFT')->relay_url, 'Mojo::URL');
    t::Utility::stash('BTC') // skip_all();
    isa_ok(t::Utility::stash('BTC')->relay_url, 'Mojo::URL');
}

=head2 C<url( )>

Mojo::URL object containing a direct link to the article.

=cut

sub url($s) {
    $s->{url} ? Mojo::URL->new($s->{url}) : ();
}

sub _test_url {
    t::Utility::stash('MSFT') // skip_all();
    isa_ok(t::Utility::stash('MSFT')->url, 'Mojo::URL');
    t::Utility::stash('BTC') // skip_all();
    isa_ok(t::Utility::stash('BTC')->url, 'Mojo::URL');
}

=head2 C<currency_id( )>

If the news is related to a particular forex currency, this will return the
Finance::Robinhood::Forex::Currency object.

=cut

sub currency($s) {
    $s->{currency_id} ? $s->_rh->forex_currency_by_id($s->{currency_id}) : ();
}

sub _test_currency {
    t::Utility::stash('BTC') // skip_all();
    isa_ok(t::Utility::stash('BTC')->currency,
           'Finance::Robinhood::Forex::Currency');
}

=head2 C<instrument( )>

If the new is related to a particular equity instrument, this will return the
Finance::Robihood::Equity::Instrument object.

=cut

sub instrument($s) {
    $s->{instrument}
        ? $s->_rh->equity_instruments_by_id($s->{instrument}
        =~ m'^.+/([0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12})/$'i
        )
        : ();
}

sub _test_instrument {
    t::Utility::stash('MSFT') // skip_all();
    isa_ok(t::Utility::stash('MSFT')->instrument,
           'Finance::Robinhood::Equity::Instrument');
}

=head2 C<published_at( )>

    $article->published_at->to_string;

Returns the time the article was published as a Time::Moment object.

=cut

sub published_at($s) {
    Time::Moment->from_string($s->{published_at});
}

sub _test_published_at {
    t::Utility::stash('MSFT') // skip_all();
    isa_ok(t::Utility::stash('MSFT')->published_at, 'Time::Moment');
}

=head2 C<updated_at( )>

    $article->updated_at->to_string;

Returns the time the article was published or last updated as a Time::Moment
object.

=cut

sub updated_at($s) {
    Time::Moment->from_string($s->{updated_at});
}

sub _test_updated_at {
    t::Utility::stash('MSFT') // skip_all();
    isa_ok(t::Utility::stash('MSFT')->updated_at, 'Time::Moment');
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
