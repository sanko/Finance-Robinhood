package Finance::Robinhood::Order;
use 5.008001;
use Carp;
our $VERSION = "0.01";
use Moo;
use strictures 2;
use namespace::clean;
use DateTime;
#
has $_ => (is => 'ro', required => 1)
    for (qw[average_price id cumulative_quantity fees price quantity
         reject_reason side state stop_price time_in_force trigger type url]);
has $_ => (
    is       => 'ro',
    required => 1,
    coerce   => sub {
        $_[0]
            =~ m[(\d{4})-(\d\d)-(\d\d)(?:T(\d\d):(\d\d):(\d\d)(?:\.(\d+))?(.+))?];

        # "2016-03-11T17:59:48.026546Z",
        #warn 'Y:' . $1;
        #warn 'M:' . $2;
        #warn 'D:' . $3;
        #warn 'h:' . $4;
        #warn 'm:' . $5;
        #warn 's:' . $6;
        #warn 'n:' . $7;
        #warn 'z:' . $8;
        DateTime->new(year       => $1,
                      month      => $2,
                      day        => $3,
                      hour       => $4,
                      minute     => $5,
                      second     => $6,
                      nanosecond => $7,
                      time_zone  => $8
        );
    }
) for (qw[created_at last_transaction_at updated_at]);
has $_ => (is => 'bare', required => 1, accessor => "_get_$_")
    for (qw[account cancel executions instrument position]);

sub account {
}

sub cancel {
}

sub executions {
}
sub instrument { }
sub position   { }
1;

=encoding utf-8

=head1 NAME

Finance::Robinhood::Order - Securities trade order

=head1 SYNOPSIS

    use Finance::Robinhood;

    my $rh = Finance::Robinhood->new( token => ... );
    my $bill = $rh->instrument('MSFT');
    my $order = $MC->place_buy_order({type => 'market', quantity => 3, instrument => $bill});

=head1 DESCRIPTION

This class represents a single buy or sell order. Objects are usually
created by Finance::Robinhood with either the C<place_buy_order( ... )>. or
C<place_sell_order( )> methods.

=head1 METHODS

This class has several getters and a few methods as follows...

=head2

=head1 LEGAL

This is a simple wrapper around the API used in the official apps. The author
provides no investment, legal, or tax advice and is not responsible for any
damages incured while using this software. Neither this software nor its
author are affiliated with Robinhood Financial LLC in any way.

For Robinhood's terms and disclosures, please see their website at http://robinhood.com/

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Other copyrights, terms, and conditions may apply to data transmitted through
this module. Please refer to the L<LEGAL> section.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=cut
