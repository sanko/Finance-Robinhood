package Finance::Robinhood::Inbox::Thread;
our $VERSION = '0.92_003';

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Inbox::Thread - Represents a Single Conversation Thread

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new( ... );
    my $messages = $rh->inbox();

    # TODO

=cut

sub _test__init {
    my $rh     = t::Utility::rh_instance(1);
    my $thread = $rh->inbox->threads->current;
    isa_ok( $thread, __PACKAGE__ );
    t::Utility::stash( 'THREAD', $thread );    #  Store it for later
}
use Moo;
use Types::Standard qw[ArrayRef Bool Dict Enum InstanceOf Maybe Num Str StrMatch];
use experimental 'signatures';
#
use Finance::Robinhood::Types qw[URL UUID Timestamp];
use Finance::Robinhood::Inbox::Message;
#
use overload '""' => sub ( $s, @ ) { $s->id }, fallback => 1;
#
sub _test_stringify {
    t::Utility::stash('THREAD') // skip_all();
    like( +t::Utility::stash('THREAD'), qr[^\d+$] );
}
#

=head1 METHODS

=cut

has robinhood => ( is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood'] );

=head2 C<avatar_color( )>

If defined, this is a hex color code.

=cut

has avatar_color => ( is => 'ro', isa => Str, required => 1 );

=head2 C<avatar_url( )>

If defined, this returns a URI object with the link to an avatar asset.

=head2 C<has_avatar_url( )>

Returns true if C<avatar_url( )> would return a defined value.

=cut

has avatar_url => (
    is        => 'ro',
    isa       => Maybe [URL],
    coerce    => 1,
    required  => 1,
    predicate => 1
);

=head2 C<display_name( )>

The name to be shown as the conversation's "name" (for lack of a better
description).

=cut

has display_name => ( is => 'ro', isa => Str, required => 1 );

=head2 C<entity_url( )>

If defined, this returns a URI object. Normally, it returns a url that resolves
to a deep link within the official apps.

=head2 C<has_entity_url( )>

Returns true if C<entity_url( )> would return a defined value.

=cut

has entity_url => (
    is        => 'ro',
    isa       => Maybe [URL],
    coerce    => 1,
    required  => 1,
    predicate => 1
);

=head2 C<id( )>

Returns the internal ID used to refer to this thread internally. For some
reason, this is a string of digits and not a UUID.

=cut

has id => ( is => 'ro', isa => Str, required => 1 );

=head2 C<is_critical( )>

Returns true if the message is critical and should be shown to the user ASAP.

=head2 C<is_muted( )>

Returns true if notifications and alert for this thread have been muted.

=head2 C<is_read( )>

Returns true if all messages in this thread have been marked as read.

=cut

has [qw[is_critical is_muted is_read]] => ( is => 'ro', isa => Bool, coerce => 1, required => 1 );

=head2 C<most_recent_message( )>

Returns the most recent message as a Finance::Robinhood::Inbox::Message object.

=cut

has _most_recent_message => (
    is        => 'ro',
    isa       => Maybe [Dict],
    required  => 1,
    init_arg  => 'most_recent_message',
    predicate => 1
);
has most_recent_message => (
    is       => 'ro',
    isa      => Maybe [ InstanceOf ['Finance::Robinhood::Inbox::Message'] ],
    lazy     => 1,
    builder  => 1,
    init_arg => undef,
    required => 1
);

sub _build_most_recent_message ($s) {
    Finance::Robinhood::Inbox::Message->new(
        robinhood => $s->robinhood,
        %{ $s->_most_recent_message }
    );
}

# Private?
has options => (
    is       => 'ro',
    isa      => Dict [ allows_free_text => Bool, has_settings => Bool ],
    coerce   => 1,
    required => 1
);

=head2 C<pagination_id( )>

Returns the ID used to gather the next page of data.

=cut

has pagination_id => ( is => 'ro', isa => Str, required => 1 );

=head2 C<short_display_name( )>

Returns the string that should be shown when space is tight. This is typically
a single ticker symbol.

=cut

has short_display_name => ( is => 'ro', isa => Str, required => 1 );

=head2 C<equity_orders( [...] )>

    my $msgs = $thread->messages();

An iterator containing Finance::Robinhood::Inbox::Message objects is returned.
You need to be logged in for this to work.


If you would only like messages before or after a certain time, you can do
that!

    my $msgs = $thread->messages(before => Time::Moment->now->minus_years(2));
    # Also accepts ISO 8601

    my $msgs = $thread->messages(after => Time::Moment->now->minus_days(7));
    # Also accepts ISO 8601

=cut

sub messages ( $s, %opts ) {

    #- `after` - greater than or equal to a date; timestamp or ISO 8601
    #- `before` - less than or equal to a date; timestamp or ISO 8601
    my $url = URI->new( 'https://api.robinhood.com/inbox/threads/' . $s->id . '/messages/' );
    $url->query_form(
        {
            $opts{before} ? ( 'before' => +$opts{before} ) : (),
            $opts{after}  ? ( 'after'  => +$opts{after} )  : ()
        }
    );
    Finance::Robinhood::Utilities::Iterator->new(
        robinhood => $s->robinhood,
        url       => $url,
        as        => 'Finance::Robinhood::Inbox::Message'
    );
}

sub _test_messages {
    t::Utility::stash('THREAD') // skip_all();
    isa_ok(
        t::Utility::stash('THREAD')->messages,
        'Finance::Robinhood::Utilities::Iterator'
    );
    isa_ok(
        t::Utility::stash('THREAD')->messages->next,
        'Finance::Robinhood::Inbox::Message'
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
