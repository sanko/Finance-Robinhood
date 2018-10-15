package Finance::Robinhood::Tag;
use Moo;
has [qw[description name slug]] => ( is => 'ro' );
has '_instruments' => ( is => 'ro', init_arg => 'instruments' );

has 'instruments' => (
    is       => 'ro',
    lazy     => 1,
    init_arg => undef,
    builder  => sub {
        my @ids = map { m[/([a-f\d\-]*)/$] } @{shift->_instruments};
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
