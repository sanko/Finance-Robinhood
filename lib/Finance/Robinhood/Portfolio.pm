package Finance::Robinhood::Portfolio;
use 5.010;
use Carp;
our $VERSION = "0.09";
use Moo;
use strictures 2;
use namespace::clean;
#
sub BUILDARGS {
    my $class = shift;
    return @_ > 1 ?
        {@_}
        : {
          (rh => $_[0][0],
           %{  +Finance::Robinhood::_send_request(
                   $_[0][0],
                   'GET',
                   Finance::Robinhood::endpoint('portfolios') . $_[0][1] . '/'
               )
           }
          )
        };

    # if the scrape failed (bad id, etc.) let Moo error out :)
}
has $_ => (is => 'ro', required => 1)
    for (qw[adjusted_equity_previous_close equity equity_previous_close
         excess_maintenance excess_maintenance_with_uncleared_deposits
         excess_margin excess_margin_with_uncleared_deposits
         extended_hours_equity extended_hours_market_value last_core_equity
         last_core_market_value market_value unwithdrawable_deposits
         url withdrawable_amount]
    );
has $_ => (is       => 'ro',
           required => 1,
           coerce   => \&Finance::Robinhood::_2_datetime
) for (qw[start_date]);
has $_ => (
    is       => 'bare',
    accessor => "_get_$_",
    weak_ref => 1,
    required => 1,

    #lazy     => 1,
    #builder  => sub { shift->account()->_get_rh() }
) for (qw[rh]);
has $_ => (is => 'bare', required => 1, accessor => "_get_$_")
    for (qw[account]);

sub account {
    my $self = shift;
    my $result
        = $self->_get_rh()->_send_request('GET', $self->_get_account());
    return $result
        ?
        Finance::Robinhood::Account->new(rh => $self->_get_rh, %$result)
        : ();
}

sub historicals {
    my ($self, $interval, $span) = @_;
    return
        scalar $self->_get_rh()->_send_request('GET',
                        Finance::Robinhood::endpoint('portfolios/historicals')
                            . $self->id
                            . "/?interval=$interval&span=$span");
}

sub id {
    my $_re = Finance::Robinhood::endpoint('portfolios') . '(.+)/';
    shift->url =~ m[$_re]o;
    $1;
}

sub refresh {
    return $_[0]
        = Finance::Robinhood::Portfolio->new([$_[0]->_get_rh, $_[0]->id]);
}
1;

=encoding utf-8

=head1 NAME

Finance::Robinhood::Portfolio - Current and Historical Financial Standing Information

=head1 SYNOPSIS

    use Finance::Robinhood::Robinhood;

    my $rh = Finance::Robinhood->new(token => ...);

    #
    my $portfolio = $rh->portfolios()->{results}[0];
    print 'I may withdraw $'. $portfolio->withdrawable_amount();

=head1 DESCRIPTION

This class represents a single financial portfolio. Objects are usually
created by Finance::Robinhood. If you're looking for information about your
portfolio, use
C<Finance::Robinhood-E<gt>portfolios()> to gather a list.

=head1 METHODS

This class has several getters and a few methods as follows...

=head2 C<adjusted_equity_previous_close( )>

=head2 C<equity( )>

=head2 C<equity_previous_close( )>

=head2 C<excess_maintenance( )>

=head2 C<excess_maintenance_with_uncleared_deposits( )>

=head2 C<excess_margin( )>

=head2 C<excess_margin_with_uncleared_deposits( )>

=head2 C<extended_hours_equity( )>

=head2 C<extended_hours_market_value( )>

=head2 C<historicals( ... )>

    # Snapshots of basic data for every five minutes of the previous week
    my $progress = $portfolio->historicals('10minute', 'week');

You may retrieve historical data with this method. The first argument is
an interval of time and must be either C<5minute>, C<10minute>, C<day>, or
C<week>.

The second argument is a span of time indicating how far into the past you
would like to retrieve and may be one of the following: C<day>, C<week>,
C<year>, or C<5year>.

So, to get five years of weekly historical data, you would write...

    my $iHist = $portfolio->historicals('week', '5year');

This method returns a hash which contains the following keys:

=over

=item C<interval>

The value you passed.

=item C<span>

The value you passed.

=item C<total_return>

=item C<equity_historicals>

Which is a list of hashes which contain the following keys:

=over

=item C<adjusted_close_equity>

=item C<adjusted_open_equity>

=item C<begins_at>

=item C<close_equity>

=item C<close_market_value>

=item C<net_return>

=item C<open_equity>

=item C<open_market_value>

=item C<session>

=back

=back

=head2 C<last_core_equity( )>

=head2 C<last_core_market_value( )>

=head2 C<market_value( )>

The total value of the portfolio.

=head2 C<start_date( )>

The day the portfolio was initiated.

=head2 C<unwithdrawable_deposits( )>

=head2 C<withdrawable_amount( )>

The amount of settled cash eligible for withdraw.

=head2 C<id( )>

Returns the string Robinhood uses to identify this portfolio.

=head2 C<refresh( )>

Refreshes the data behind this object.

=head1 LEGAL

This is a simple wrapper around the API used in the official apps. The author
provides no investment, legal, or tax advice and is not responsible for any
damages incurred while using this software. Neither this software nor its
author are affiliated with Robinhood Financial LLC in any way.

For Robinhood's terms and disclosures, please see their website at http://robinhood.com/

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify
it under the terms found in the Artistic License 2.

Other copyrights, terms, and conditions may apply to data transmitted through
this module. Please refer to the L<LEGAL> section.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut
