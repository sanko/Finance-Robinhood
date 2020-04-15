package Finance::Robinhood::Notification {
    our $VERSION = '0.92_003';

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

    use Moo;
    use MooX::StrictConstructor;
    use Data::Dump;
    use HTTP::Tiny;
    use JSON::Tiny;
    use Time::Moment;
    use Types::Standard qw[ArrayRef Bool Dict Enum InstanceOf Maybe Num Str StrMatch];
    use URI;
    use experimental 'signatures';
    #
    use Finance::Robinhood::Types qw[URL UUID Timestamp];
    #
    sub _test__init {
        my $rh = t::Utility::rh_instance(1);
        my $notification;
        for my $n ( $rh->notifications->all ) {
            $notification = $n if $n->type ne 'referral_hook_asset_stock';
        }
        $notification // skip_all('Failed to find notification');
        isa_ok( $notification, __PACKAGE__ );
        t::Utility::stash( 'CARD', $notification );    #  Store it for later
    }
    use overload '""' => sub ( $s, @ ) { $s->url }, fallback => 1;

    sub _test_stringify {
        t::Utility::stash('CARD') // skip_all();
        like(
            +t::Utility::stash('CARD'),
            qr'^https://midlands.robinhood.com/notifications/stack/[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}/$'i
        );
    }
    #
    has robinhood => ( is => 'ro', predicate => 1, isa => InstanceOf ['Finance::Robinhood'] );

=head2 C<action( )>

The internal deep link that can be triggred by this notification.

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

Forces clients to display notifications even if the application and/or account
does not support the action.

=head2 C<side_image( )>

If available, this returns a hash with asset information for the official
Android and iOS clients.

=head2 C<time( )>

    $notification->time->to_string;

Returns the time the notification was published as a Time::Moment object.

Note that some notifications do not have a timestamp.

=head2 C<title( )>

Returns the article's title.

=head2 C<type( )>

What sort of notification is is. C<news>, C<top_sp500_gainers>, etc.

=cut

    has url    => ( is => 'ro', isa => URL, coerce => 1, predicate => 1 );
    has action => ( is => 'ro', isa => URL, coerce => 1, predicate => 1 );
    has call_to_action => ( is => 'ro', isa => Str,  predicate => 1 );
    has fixed          => ( is => 'ro', isa => Bool, coerce    => 1, predicate => 1 );
    has font_size => ( is => 'ro', isa => Enum [qw[normal large]], predicate => 1 );
    has icon      => (
        is        => 'ro',
        isa       => Enum [qw[announcement bank bell down news order up star]],
        predicate => 1
    );
    has message             => ( is => 'ro', isa => Str,  predicate => 1 );
    has show_if_unsupported => ( is => 'ro', isa => Bool, coerce    => 1, predicate => 1 );
    has side_image => (
        is  => 'ro',
        isa => Maybe [
            Dict [
                android => Dict [ asset_path => Str, width => Num ],
                ios     => Dict [ asset_path => Str, width => Num ]
            ]
        ],
        predicate => 1
    );
    has time  => ( is => 'ro', isa => Maybe [Timestamp], coerce   => 1, requried => 1 );
    has title => ( is => 'ro', isa => Str,               required => 1 );
    has type => (
        is  => 'ro',
        isa => Maybe [
            Enum [
                qw[bank
                    currency_sell_executed
                    currency_buy_executed
                    upcoming_earnings pending_withdrawal
                    top_sp500_gainers top_sp500_losers margin_sell_executed news web_welcome
                    user_top_mover earnings_call_now us_uk_announcement
                    from_stock_reward_claimed
                    ]
            ]
        ],
        predicate => 1
    );
    has dismiss_url => ( is => 'ro', isa => Maybe [URL], coerce => 1, predicate => 1 );

    sub _test_action {
        t::Utility::stash('CARD') // skip_all();
        isa_ok( t::Utility::stash('CARD')->action, 'URI' );
    }

=head2 C<dismiss( )>

    $notification->dismiss();

Marks the notification as read and hides it from the stack.

=cut

    sub dismiss ($s) {
        $s->robinhood->_req( POST => $s->url . 'dismiss/' )->success;
    }

    sub _test_dismiss {    # I'd rather not mark a notification as read...
        skip_all();
    }

=head2 C<id( )>

Returns a UUID.

=cut

    has id => ( is => 'ro', isa => UUID, lazy => 1, coerce => 1, init_arg => 'url' );

    sub _test_id {
        t::Utility::stash('CARD') // skip_all();
        like(
            t::Utility::stash('CARD')->id,
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
}
