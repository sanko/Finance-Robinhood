package Finance::Robinhood::News;
use Moo;
#
has [
    qw[api_source author currency_id instrument
        num_clicks
        preview_image_height preview_image_url preview_image_width
        relay_url
        source
        summary title
        url
        uuid]
] => ( is => 'ro' );
has [qw[published_at updated_at]] => (
    is     => 'ro',
    coerce => sub {
        $_[0] ? Time::Moment->from_string( $_[0] ) : ();
    }
);
1;
