package Finance::Robinhood::Watchlist;
use Moo;
use Finance::Robinhood::Watchlist::Item;
has 'name' => ( is => 'ro', required => 1 );
has 'user' => ( is => 'ro', lazy => 1, builder => sub { $Finance::Robinhood::Endpoints{'user'} } );
has '_url' => (
    is       => 'ro',
    init_arg => 'url',
    lazy     => 1,
    builder  => sub {
        my $s = shift;
        sprintf $Finance::Robinhood::Endpoints{'watchlists/{name}'}, $s->name;
    }
);
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
        my @groups;
        push @groups, [ splice @ids, 0, 75 ] while @ids;
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
