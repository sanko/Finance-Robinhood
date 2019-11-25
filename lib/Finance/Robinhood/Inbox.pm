package Finance::Robinhood::Inbox;
our $VERSION = '0.92_003';

=encoding utf-8

=for stopwords watchlist watchlists untradable urls

=head1 NAME

Finance::Robinhood::Inbox - Contains a List of Conversation Threads

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new( ... );
    my $messages = $rh->inbox();

    # TODO

=cut

sub _test__init {
    my $rh    = t::Utility::rh_instance(1);
    my $inbox = $rh->inbox;
    isa_ok($inbox, __PACKAGE__);
    t::Utility::stash('INBOX', $inbox);    #  Store it for later
}
use strictures 2;
use namespace::clean;
use Moo;
use Types::Standard qw[Bool Enum InstanceOf Maybe Num Str StrMatch];
use experimental 'signatures';
#
use Finance::Robinhood::Types qw[URL UUID Timestamp];
use Finance::Robinhood::Utilities::Iterator;
use Finance::Robinhood::Inbox::Thread;
#
has robinhood =>
    (is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood']);

=head1 METHODS


=cut

has threads => (is  => 'ro',
                isa => InstanceOf ['Finance::Robinhood::Utilities::Iterator'],
                builder  => 1,
                required => 1,
                init_arg => undef
);

sub _build_threads ($s) {
    Finance::Robinhood::Utilities::Iterator->new(
                            robinhood => $s->robinhood,
                            url => 'https://api.robinhood.com/inbox/threads/',
                            as  => 'Finance::Robinhood::Inbox::Thread'
    );
}

sub _test_threads {
    t::Utility::stash('INBOX') // skip_all();
    isa_ok(t::Utility::stash('INBOX')->threads,
           'Finance::Robinhood::Utilities::Iterator');
    isa_ok(t::Utility::stash('INBOX')->threads->next,
           'Finance::Robinhood::Inbox::Thread');
}
#
#    @retrofit2.http.GET("inbox/help/topics/{topicId}/channels/")
#    io.reactivex.Single<com.robinhood.models.api.ApiHelpTopicChannels> getHelpTopicChannels(@retrofit2.http.Path("topicId") java.lang.String str);
#
#    @retrofit2.http.GET("inbox/help/topics/")
#    io.reactivex.Single<com.robinhood.models.api.ApiHelpTopics> getHelpTopics(@retrofit2.http.Query("parent_topic_id") java.lang.String str);
#
#    @retrofit2.http.GET("inbox/should_badge/")
#    io.reactivex.Single<com.robinhood.models.api.ApiShouldBadge> getShouldBadge();
#
#    @retrofit2.http.GET("inbox/threads/{threadId}/")
#    io.reactivex.Single<com.robinhood.models.api.ApiThread> getThread(@retrofit2.http.Path("threadId") java.lang.String str);
#
#    @retrofit2.http.GET("inbox/threads/{threadId}/messages/")
#    io.reactivex.Single<com.robinhood.models.api.ApiMessageResult> getThreadMessages(@retrofit2.http.Path("threadId") java.lang.String str, @retrofit2.http.Query("before") java.lang.String str2, @retrofit2.http.Query("after") java.lang.String str3);
#
#    @retrofit2.http.GET("inbox/settings/thread/{threadId}/")
#    io.reactivex.Single<com.robinhood.models.api.ApiNotificationThreadSettingsItem> getThreadNotificationSettingsV4(@retrofit2.http.Path("threadId") java.lang.String str);
#
#    @retrofit2.http.GET("inbox/settings/{threadId}/")
#    io.reactivex.Single<com.robinhood.models.api.ApiNotificationSettingsV3> getThreadSettings(@retrofit2.http.Path("threadId") java.lang.String str);
#
#    @retrofit2.http.GET("inbox/threads/")
#    io.reactivex.Single<com.robinhood.models.PaginatedResult<com.robinhood.models.api.ApiThread>> getThreads();
#
#    @retrofit2.http.POST("inbox/threads/read/")
#    io.reactivex.Single<com.robinhood.models.PaginatedResult<com.robinhood.models.api.ApiThread>> markThreadsAsRead(@retrofit2.http.Body com.robinhood.models.api.ApiMarkThreadsAsReadRequest apiMarkThreadsAsReadRequest);
#
#    @retrofit2.http.POST("inbox/help/email/")
#    io.reactivex.Single<com.robinhood.models.api.ApiPostHelpEmailResponse> postHelpEmail(@retrofit2.http.Body com.robinhood.models.api.ApiPostHelpEmailRequest apiPostHelpEmailRequest);
#
#    @retrofit2.http.POST("inbox/saw_badge/")
#    io.reactivex.Single<com.robinhood.models.api.ApiShouldBadge> postSawBadge();
#
#    @retrofit2.http.POST("inbox/threads/")
#    io.reactivex.Single<com.robinhood.models.api.ApiThread> postThread(@retrofit2.http.Body com.robinhood.models.api.ApiPostThreadRequest apiPostThreadRequest);
#
#    @retrofit2.http.POST("inbox/threads/{threadId}/messages/")
#    io.reactivex.Single<com.robinhood.models.api.ApiMessage> submitMessage(@retrofit2.http.Path("threadId") java.lang.String str, @retrofit2.http.Body com.robinhood.models.api.ApiSubmitMessageRequest apiSubmitMessageRequest);
#
#    @retrofit2.http.POST("inbox/threads/{threadId}/messages/{messageId}/")
#    io.reactivex.Single<com.robinhood.models.api.ApiMessage> submitResponse(@retrofit2.http.Path("threadId") java.lang.String str, @retrofit2.http.Path("messageId") java.lang.String str2, @retrofit2.http.Body com.robinhood.models.api.ApiSubmitResponseRequest apiSubmitResponseRequest);

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
