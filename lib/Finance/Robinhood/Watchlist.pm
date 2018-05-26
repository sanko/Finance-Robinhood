package Finance::Robinhood::Watchlist;
use Moo;
use Finance::Robinhood::Watchlist::Item;
has [qw[name user]] => ( is => 'ro' );
has '_url' => ( is => 'ro', init_arg => 'url' );
has 'items' => (
    is       => 'ro',
    lazy     => 1,
    init_arg => undef,
    builder  => sub {
        Finance::Robinhood::Utils::Paginated->new(
            class => 'Finance::Robinhood::Watchlist::Item',
            next  => $_[0]->_url
        );
    }
);
has 'instruments' => (
    is       => 'ro',
    lazy     => 1,
    init_arg => undef,
    builder  => sub {
        my @ids = map { $_->url =~ m[/([a-f\d\-]*)/$] } Finance::Robinhood::Utils::Paginated->new(
            class => 'Finance::Robinhood::Watchlist::Item',
            next  => [ $_[0]->_url ]
        )->all;
        warn scalar @ids;
        my @groups;
        push @groups, [ splice @ids, 0, 75 ] while @ids;
        warn scalar @$_ for @groups;
        Finance::Robinhood::Utils::Paginated->new(
            class => 'Finance::Robinhood::Equity::Instrument',
            next  => [
                map {
                    Finance::Robinhood::Utils::Client::__url_and_args(
                        $Finance::Robinhood::Endpoints{'instruments'},
                        { ids => $_ } )
                } @groups
            ]
        );
    }
);
1;
