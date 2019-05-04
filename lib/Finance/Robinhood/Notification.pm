package Finance::Robinhood::Notification;

=encoding utf-8

=for stopwords watchlist watchlists untradable urls btw

=head1 NAME

Finance::Robinhood::Notification - Represents a Single Notification Card

=head1 SYNOPSIS

    use Text::Wrap qw[wrap];
    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;
    CORE::say wrap( '', '    ', $_->title . "\n" . $_->message ) for $rh->notifications->take(10);

=head1 METHODS

=cut

our $VERSION = '0.92_003';
use Mojo::Base-base, -signatures;
use Mojo::URL;
use Time::Moment;

sub _test__init {
    my $rh            = t::Utility::rh_instance(1);
    my $notifications = $rh->notifications;
    my $notification;
    do {
        $notification = $notifications->next;
        } while $notification &&
        $notification->type ne 'referral_hook_asset_stock';
    $notification // skip_all('Failed to fine executied equity order');
    isa_ok($notification, __PACKAGE__);
    t::Utility::stash('CARD', $notification);    #  Store it for later
}
use overload '""' => sub ($s, @) { $s->{url} }, fallback => 1;

sub _test_stringify {
    t::Utility::stash('CARD') // skip_all();
    like(+t::Utility::stash('CARD'),
         qr'^https://midlands.robinhood.com/notifications/stack/[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}/$'i
    );
}
#
has _rh => undef => weak => 1;

=head2 C<call_to_action( )>

Text provided to direct attention to the action. C<See More>, C<View Article>,
etc.

=head2 C<fixed( )>

If true, this notification is locked into place.

=head2 C<font_size( )>

For display, this sets a uniform type size.

=head2 C<icon( )>

Returns which icon should be used. These are built into the apps, btw.

=head2 C<message( )>

The actual text shown in the notification card.

=head2 C<show_if_unsupported( )>


=head2 C<side_image( )>

Returns a hash with asset information for the official clients.

=head2 C<type( )>

Returns the type of notification.

=head2 C<title( )>

Returns the article's title.

=head2 C<type( )>

What sort of notification is is. C<news>, C<top_sp500_gainers>, etc.

=cut

has ['call_to_action', 'fixed',
     'font_size',      'icon',
     'message',        'show_if_unsupported',
     'side_image',     'title',
     'type'
];

=head2 C<action( )>

Returns the (usually app internal) action that should take place when the
notification is activated.

=cut

sub action($s) {
    Mojo::URL->new($s->{action});
}

sub _test_action {
    t::Utility::stash('CARD') // skip_all();
    isa_ok(t::Utility::stash('CARD')->action, 'Mojo::URL');
}

=head2 C<time( )>

    $notification->time->to_string;

Returns the time the notification was published as a Time::Moment object.

Note that some notifications do not have a timestamp.

=cut

sub time($s) {
    $s->{time} ? Time::Moment->from_string($s->{time}) : ();
}

sub _test_time {
    t::Utility::stash('CARD') // skip_all();
    isa_ok(t::Utility::stash('CARD')->time, 'Time::Moment');
}

=head2 C<dismiss( )>

    $notification->dismiss();

Marks the notification as read and hides it from the stack.

=cut

sub dismiss ($s) {
    $s->_rh->_post($s->{url} . 'dismiss/')->is_success;
}

sub _test_dismiss {    # I'd rather not mark a notification as read...
    skip_all();
}

=head2 C<id( )>

Returns a UUID.

=cut

sub id($s) {
    $s->{url}
        =~ m'^.+/([0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12})/$'i;
}

sub _test_id {
    t::Utility::stash('CARD') // skip_all();
    like(t::Utility::stash('CARD')->id,
         qr'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'i
    );
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
