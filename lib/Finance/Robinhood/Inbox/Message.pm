package Finance::Robinhood::Inbox::Message;
our $VERSION = '0.92_003';

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Inbox::Message - Represents a Single Conversation Message

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new( ... );
    my $messages = $rh->inbox();

    # TODO

=cut

sub _test__init {
    my $rh  = t::Utility::rh_instance(1);
    my $msg = $rh->inbox->threads->current->messages->current;
    isa_ok( $msg, __PACKAGE__ );
    t::Utility::stash( 'MSG', $msg );    #  Store it for later
}
use Moo;
use Types::Standard qw[Any ArrayRef Bool Dict Enum InstanceOf Maybe Num Str StrMatch];
use experimental 'signatures';
#
use Finance::Robinhood::Types qw[URL UUID Timestamp];
use Finance::Robinhood::Inbox::Sender;
#
use overload '""' => sub ( $s, @ ) { $s->id }, fallback => 1;
#
sub _test_stringify {
    t::Utility::stash('MSG') // skip_all();
    like( +t::Utility::stash('MSG'), qr[^\d+$] );
}
#

=head1 METHODS

=cut
has robinhood => ( is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood'] );

=head2 C<action( )>

If defined, this returns a hash reference with the following keys:

=over

=item C<display_text>

=item C<url>

=item C<value>

=back

=cut

has action => (
    is       => 'ro',
    isa      => Maybe [ Dict [ display_text => Str, url => URL, value => Num ] ],
    required => 1,
    coerce   => 1
);

=head2 C<created_at( )>

Returns a Time::Moment object.

=head2 C<updated_at( )>

Returns a Time::Moment object.

=cut

has [qw[created_at updated_at]] => ( is => 'ro', isa => Timestamp, coerce => 1, required => 1 );

=head2 C<id( )>

Returns the ID string which isn't a UUID for some reason.

=cut

has id => ( is => 'ro', isa => Str, required => 1 );

=head2 C<is_metadata( )>

Returns a boolean value.

=cut

has is_metadata => ( is => 'ro', isa => Bool, coerce => 1, required => 1 );

=head2 C<media( )>

TODO

=head2 C<remote_medias( )>

Returns a list.

=cut

has media         => ( is => 'ro', isa => Any, required => 1 );
has remote_medias => ( is => 'ro', isa => ArrayRef [Any], required => 1 );

=head2 C<message_config_id( )>



=head2 C<thread_id( )>


=cut

has [qw[message_config_id thread_id]] => ( is => 'ro', isa => Num, required => 1 );

=head2 C<message_type_config_id( )>


=head2 C<response_message_id( )>


=cut
has [qw[message_type_config_id response_message_id]] =>
    ( is => 'ro', isa => Maybe [Num], required => 1 );

=head2 C<responses( )>

Returns a list of possible default responses as an array of hashes. These
hashes hold the following keys:

=over

=item C<answer>

The value that will be returned if this response is selected.

=item C<display_text>

The text that should be shown to the user.

=back

=cut

has responses =>
    ( is => 'ro', isa => ArrayRef [ Dict [ answer => Num, display_text => Str ] ], required => 1 );

=head2 C<rich_text( )>

Returns a hash with the following keys:

=over

=item C<attributes>

=item C<text>

To be shown to the user.

=back

=cut

has rich_text =>
    ( is => 'ro', isa => Dict [ attributes => Maybe [Str], text => Str ], required => 1 );

=head2 C<sender( )>

Returns the Finance::Robinhood::Inbox::Sender object.

=cut

has _sender => ( is => 'ro', isa => Dict, required => 1, init_arg => 'sender' );
has sender  => (
    is       => 'ro',
    isa      => InstanceOf ['Finance::Robinhood::Inbox::Sender'],
    init_arg => undef,
    lazy     => 1,
    builder  => 1
);

sub _build_sender ($s) {
    Finance::Robinhood::Inbox::Sender->new( robinhood => $s->robinhood, %{ $s->_sender } );
}

sub _test_sender {
    t::Utility::stash('MSG') // skip_all();
    isa_ok( t::Utility::stash('MSG')->sender, 'Finance::Robinhood::Inbox::Sender' );
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
