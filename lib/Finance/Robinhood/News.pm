package Finance::Robinhood::News;
our $VERSION = '0.92_003';

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

use Moo;
use Data::Dump;
use HTTP::Tiny;
use JSON::Tiny;
use Time::Moment;
use Types::Standard qw[ArrayRef Bool Enum InstanceOf Maybe Num Str StrMatch];
use URI;
use experimental 'signatures';
#
use Finance::Robinhood::Types qw[UUIDBroken UUID URL Timestamp];
#
sub _test__init {
    my $rh   = t::Utility::rh_instance(1);
    my $msft = $rh->news('MSFT')->current;
    my $btc  = $rh->news('d674efea-e623-4396-9026-39574b92b093')->current;
    isa_ok($msft, __PACKAGE__);
    t::Utility::stash('MSFT', $msft);    #  Store it for later
    isa_ok($btc, __PACKAGE__);
    t::Utility::stash('BTC', $btc);      #  Store it for later
}
#
has robinhood =>
    (is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood']);

=head2 C<api_source( )>

Returns the article's source if available.

These are short tags such as C<reuters> and C<benzinga>.

=head2 C<source( )>

Returns the article's source in a format suited for display.

These would be text like C<Reuters> and C<Benzinga>.

=head2 C<author( )>

If available, this will return the author who wrote the article.

=head2 C<num_clicks( )>

The current total number of times this article has been clicked by Robinhod's
users.

=head2 C<summary( )>

Returns a brief (often truncated) summary of the article.

=head2 C<title( )>

Returns the article's title.

=head2 C<uuid( )>

Returns the article's unique ID.

=cut

has [qw[api_source source]] => (is => 'ro', isa => Str, required => 1);
has author => (is => 'ro', isa => Maybe [Str], required => 1, predicate => 1);
has currency_id =>
    (is => 'ro', isa => UUIDBroken | StrMatch [qr[^None$]], predicate => 1);
has num_clicks => (is => 'ro', isa => Num, required => 1);
has [qw[summary title]] => (is => 'ro', isa => Str, required => 1);
has preview_text =>
    (is => 'ro', isa => Maybe [Str], required => 1, predicate => 1);
has uuid => (is => 'ro', isa => UUID | UUIDBroken, required => 1);

=head2 C<preview_image_url( )>

If this article has a thumbnail, this will return the URL as a URI object.

=head2 C<relay_url( )>

Returns a URI object containing the URL Robinhood would like you to use. This
will register as a click and will then redirect to the article itself.

=head2 C<url( )>

URI object containing a direct link to the article.

=cut

has [qw[preview_image_url relay_url url]] =>
    (is => 'ro', isa => URL, coerce => 1, requried => 1);

=head2 C<currency_id( )>

If the news is related to a particular forex currency, this will return a UUID.

=head2 C<currency( )>

If the news is related to a particular forex currency, this will return the
Finance::Robinhood::Currency object.

=cut

has currency => (is  => 'ro',
                 isa => Maybe [InstanceOf ['Finance::Robinhood::Currency']],
                 builder  => 1,
                 lazy     => 1,
                 init_arg => undef
);

sub _build_currency($s) {
    $s->has_currency_id &&
        $s->currency_id ne 'None'
        ? $s->robinhood->currency_by_id($s->currency_id)
        : ();
}

sub _test_currency {
    t::Utility::stash('BTC') // skip_all();
    isa_ok(t::Utility::stash('BTC')->currency,
           'Finance::Robinhood::Currency');
}

=head2 C<related_equities( )>

If the news is related to any particular equity instruments, this will return
the Finance::Robihood::Equity objects as a list reference.

=cut

has '_related_instruments' => (is       => 'ro',
                               isa      => ArrayRef [UUID],
                               requried => 1,
                               init_arg => 'related_instruments',
                               coerce   => 1
);
has related_equities => (
                  is  => 'ro',
                  isa => ArrayRef [InstanceOf ['Finance::Robinhood::Equity']],
                  builder  => 1,
                  lazy     => 1,
                  init_arg => undef
);

sub _build_related_equities($s) {
    scalar $s->_related_instruments
        ? [$s->robinhood->equities_by_id(@{$s->_related_instruments})]
        : [];
}

sub _test_related_equities {
    t::Utility::stash('MSFT') // skip_all();

    # List might be empty. :(
    scalar(t::Utility::stash('MSFT')->related_equities) || skip_all();
    isa_ok(t::Utility::stash('MSFT')->related_equities->[0],
           'Finance::Robinhood::Equity');
}

=head2 C<published_at( )>

    $article->published_at->to_string;

Returns the time the article was published as a Time::Moment object.

=head2 C<updated_at( )>

    $article->updated_at->to_string;

Returns the time the article was published or last updated as a Time::Moment
object.

=cut

has [qw[published_at updated_at]] =>
    (is => 'ro', isa => Timestamp, coerce => 1, required => 1);

sub _test_published_at {
    t::Utility::stash('MSFT') // skip_all();
    isa_ok(t::Utility::stash('MSFT')->published_at, 'Time::Moment');
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
