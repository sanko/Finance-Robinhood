package Finance::Robinhood::Utilities::Iterator;
our $VERSION = '0.92_003';

# Destructive iterator because memory isn't free
# inspired by Array::Iterator and rust's Vec and IntoIter

=encoding utf-8

=for stopwords th

=head1 NAME

Finance::Robinhood::Utilities::Iterator - Sugary Access to Paginated Data

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = t::Utility::rh_instance(1);
    my $instruments = $rh->instruments();

    for my $instrument ($instruments->all) {
        CORE::say $instrument->symbol;
    }

=cut

#
use strictures 2;
use namespace::clean;
use HTTP::Tiny;
use JSON::Tiny;
use URI;
use Moo;
use Types::Standard qw[InstanceOf Maybe Str ArrayRef Any];
use Finance::Robinhood::Types qw[URL];
use experimental 'signatures';
#
has robinhood => ( is => 'ro', required => 1, isa => InstanceOf ['Finance::Robinhood'] );
#
has _results => ( is => 'rwp', default => sub { [] }, isa => ArrayRef [Any] );
has as       => (
    is        => 'rwp',
    required  => 0,
    isa       => Maybe [ InstanceOf ['Type::Tiny'] | Str ],
    predicate => 1
);
has _next_page => (
    is       => 'rwp',
    isa      => Maybe [URL],
    required => 1,
    init_arg => 'url',
    coerce   => 1
);
has _current    => ( is => 'rwp', isa => Maybe [Any], predicate => 1 );
has _first_page => ( is => 'rwp', isa => Maybe [ InstanceOf ['URI'] ], predicate => 1 );

# midlands returns a count with news and feed which is nice
has count => (
    is        => 'rwp',
    builder   => 1,
    lazy      => 1,
    clearer   => '_clear_count',
    predicate => 1
);

sub _build_count($s) {

    #use Data::Dump;
    #ddx $s;
    my @all = $s->all;
    scalar @all;
}

=head1 METHODS

=head2 C<reset( )>

Reset the iterator. All elements will be removed and you'll basically start
from scratch.

=cut

sub reset($s) {
    $s->_set__next_page( $s->_first_page // $s->_next_page );
    $s->_set__current( () );
    $s->_set__results( [] );
    $s->_clear_count;
}

sub _test_reset {
    my $rh          = t::Utility::rh_instance(0);
    my $instruments = $rh->equities;
    isa_ok( $instruments, __PACKAGE__ );
    my $next = $instruments->next;
    $instruments->take(300);
    $instruments->reset;
    is( $instruments->next, $next );
}

=head2 C<current( )>

Get the current element without removing it from the stack. This is
non-destructive but will move the cursor if there is no current element.

=cut

sub current($s) {
    $s->_has_current || $s->_set__current( $s->peek );
    $s->_current;
}

sub _test_current {
    my $rh          = t::Utility::rh_instance(0);
    my $instruments = $rh->equities;

    # Make sure the first element is auto-loaded
    isa_ok( $instruments,          __PACKAGE__ );
    isa_ok( $instruments->current, 'Finance::Robinhood::Equity' );

    # Make sure next() loads current() properly
    my $next = $instruments->next;
    is( $instruments->current, $next );
}

=head2 C<next( )>

Gets the next element and removes it from the stack. If there are no elements
and all pages have been exhausted, this will return an undefined value.

=cut

sub next($s) {
    $s->_check_next_page;
    my ( $retval, @values ) = @{ $s->_results };
    $s->_set__results( \@values );
    $s->_set__current($retval);
    $retval;
}

=head2 C<peek( ... )>

    my $ten_more = $list->peek(10);

Returns the I<n>th element without removing it from the stack. The index is
optional and, by default, the first element is returned.

=cut

sub peek ( $s, $pos = 1 ) {
    $s->_check_next_page($pos);
    $s->_results->[ $pos - 1 ];
}

sub _test_peek {
    my $rh          = t::Utility::rh_instance(0);
    my $instruments = $rh->equities;
    isa_ok( $instruments, __PACKAGE__ );
    my $peek = $instruments->peek;
    is( $instruments->next, $peek );
}

=head2 C<has_next( ... )>

Returns a boolean indicating whether or not we have another I<X> elements. The
length is optional and checks the results for a a single element by default.

=cut

sub has_next ( $s, $pos = 1 ) {
    $s->_check_next_page($pos);
    !!defined $s->_results->[ $pos - 1 ];
}

=head2 C<take( ... )>

Removes a number of elements from the stack and returns them. By default, this
returns a single element.

=cut

# Grab a certain number of elements
sub take ( $s, $count = 1 ) {
    $s->_check_next_page($count);
    my @retval;
    for ( 1 .. $count ) { push @retval, $s->next; last if !$s->has_next }
    $s->_set__current( $retval[-1] );
    @retval;
}

sub _test_take {
    my $rh          = t::Utility::rh_instance(0);
    my $instruments = $rh->equities;
    isa_ok( $instruments, __PACKAGE__ );
    {
        my @take = $instruments->take(3);
        is( 3, scalar @take, '...take(3) returns 3 items' );
    }
    {
        my @take = $instruments->take(300);
        is( 300, scalar @take, '...take(300) returns 300 items' );
    }
}

=head2 C<all( )>

Grabs every page and returns every element we see.

=cut

sub all($s) {
    my @retval;
    push @retval, $s->take( $s->has_count ? $s->count : 1000 ) until !$s->has_next;
    $s->_set__current( $retval[-1] );
    wantarray ? @retval : \@retval;
}

sub _test_all_and_has_next {
    my $rh          = t::Utility::rh_instance(0);    # Do not log in!
    my $instruments = $rh->equities;
    isa_ok( $instruments, __PACKAGE__ );
    diag('Grabbing all instruments... please hold...');
    my @take = $instruments->all;
    cmp_ok(
        11000, '<=', scalar(@take), sprintf '...all() returns %d items',
        scalar @take
    );
    isnt(
        $instruments->has_next, !!1,
        '...has_next() works at the end of the list'
    );
}

# Check if we need to slurp the next page of elements to fill a position
sub _check_next_page ( $s, $count = 1 ) {
    my @push = @{ $s->_results };
    my $pre  = scalar @push;
    $s->_first_page // $s->_set__first_page( $s->_next_page );
    while ( ( $count > scalar @push ) && $s->_next_page ) {
        my $res = $s->robinhood->_req( GET => $s->_next_page );
        if ( $res->success ) {
            $s->_set__next_page(
                  $res->json->{next} && $res->json->{next} ne $s->_next_page
                ? $res->json->{next}
                : ()
            );

            #require($s->class) if $s->has_class;
            push @push,
                $s->has_as
                ? @{ $res->as( $s->as )->{results} }
                : @{ $res->json->{results} };
            $s->_set_count( $res->json->{count} )
                if defined $res->json->{count};
        }
        else {    # Trouble! Let's not try another page
            $s->_set__next_page(undef);
        }
    }
    $s->_set__results( \@push ) if scalar @push > $pre;
}

sub _test_check_next_page {
    my $rh = t::Utility::rh_instance(0);                                      # Do not log in!
    is( $rh->equities_by_id('c7d4323d-9512-4b15-977a-7cb2d1381d00'), () );    # Fake id
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
