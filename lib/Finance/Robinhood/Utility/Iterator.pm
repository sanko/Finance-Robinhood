package Finance::Robinhood::Utility::Iterator;

=encoding utf-8

=for stopwords th

=head1 NAME

Finance::Robinhood::Utility::Iterator - Sugary Access to Paginated Data

=head1 SYNOPSIS

    use Finance::Robinhood;
    my $rh = Finance::Robinhood->new;
    my $instruments = $rh->instruments();

    for my $instrument ($instruments->all) {
        CORE::say $instrument->symbol;
    }

=cut

use Mojo::Base-base, -signatures;
use Mojo::URL;

=head1 METHODS



=cut

# Destructive iterator because memory isn't free
# inspired by Array::Iterator and rust's Vec and IntoIter
has _rh => undef => weak => 1;
has [
    '_current', '_next_page', '_class', '_first_page',

    # midlands returns a count with news and feed which is nice
    'count'
];
has _results => sub { [] };

=head2 C<reset( )>

Reset the iterator. All elements will be removed and you'll basically start
from scratch.

=cut

sub reset($s) {
    $s->_next_page( $s->_first_page // $s->_next_page );
    $s->_current( () );
    $s->_results( [] );
}

sub _test_reset {
    plan( tests => 3 );
    my $rh          = new_ok('Finance::Robinhood');
    my $instruments = $rh->instruments;
    isa_ok( $instruments, 'Finance::Robinhood::Utility::Iterator', '...instruments call works' );
    my $next = $instruments->next;
    $instruments->take(300);
    $instruments->reset;
    is_deeply( $instruments->next, $next, '->reset() worked' );
    done_testing();
}

=head2 C<current( )>

Get the current element without removing it from the stack. This is
non-destructive but will move the cursor if there is no current element.

=cut

sub current($s) {
    $s->_current // $s->next;
    $s->_current;
}

sub _test_current {
    plan( tests => 4 );
    my $rh          = new_ok('Finance::Robinhood');
    my $instruments = $rh->instruments;
    isa_ok( $instruments, 'Finance::Robinhood::Utility::Iterator', '...instruments call works' );
    my $next = $instruments->next;
    isa_ok( $instruments->current, 'Finance::Robinhood::Equity::Instrument' );
    is_deeply( $instruments->current, $next, '->current() is correct' );
    done_testing();
}

=head2 C<next( )>

Gets the next element and removes it from the stack. If there are no elements
and all pages have been exhausted, this will return an undefined value.

=cut

sub next($s) {
    $s->_check_next_page;
    my ( $retval, @values ) = @{ $s->_results };
    $s->_results( \@values );
    $s->_current($retval);
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
    plan( tests => 3 );
    my $rh          = new_ok('Finance::Robinhood');
    my $instruments = $rh->instruments;
    isa_ok( $instruments, 'Finance::Robinhood::Utility::Iterator', '...instruments call works' );
    my $peek = $instruments->peek;
    is_deeply( $instruments->next, $peek, '->peek() is correct' );
    done_testing();
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
    $s->_current( $retval[-1] );
    @retval;
}

sub _test_take {
    plan( tests => 4 );
    my $rh          = new_ok('Finance::Robinhood');
    my $instruments = $rh->instruments;
    isa_ok( $instruments, 'Finance::Robinhood::Utility::Iterator', '...instruments call works' );
    {
        my @take = $instruments->take(3);
        is( 3, scalar @take, '...take(3) returns 3 items' );
    }
    {
        my @take = $instruments->take(300);
        is( 300, scalar @take, '...take(300) returns 300 items' );
    }
    done_testing();
}

=head2 C<all( )>

Grabs every page and returns every element we see.

=cut

sub all($s) {
    my @retval;
    push @retval, $s->take( $s->count // 1000 ) until !$s->has_next;
    $s->_current( $retval[-1] );
    @retval;
}

sub _test_all_and_has_next {
    plan( tests => 4 );
    my $rh          = new_ok('Finance::Robinhood');
    my $instruments = $rh->instruments;
    isa_ok( $instruments, 'Finance::Robinhood::Utility::Iterator', '...instruments call works' );
    diag('Grabbing all instruments... please hold...');
    my @take = $instruments->all;
    cmp_ok( 11000, '<=', scalar(@take), sprintf '...all() returns %d items', scalar @take );
    isnt( $instruments->has_next, !!1, '...has_next() works at the end of the list' );
    done_testing();
}

# Check if we need to slurp the next page of elements to fill a position
sub _check_next_page ( $s, $count = 1 ) {
    my @push = @{ $s->_results };
    my $pre  = scalar @push;
    $s->_first_page // $s->_first_page( $s->_next_page );
    while ( ( $count > scalar @push ) && defined $s->_next_page ) {
        my $res = $s->_rh->_get( $s->_next_page );

        #use Data::Dump;
        #ddx $res;
        #ddx $res->json;
        #die;
        if ( $res->is_success ) {
            my $json = $res->json;
            $s->_next_page( $json->{next} );
            push @push,
                map { defined $s->_class ? $s->_class->new( _rh => $s->_rh, %$_ ) : $_ }
                @{ $json->{results} };
        }
        else {    # Trouble! Let's not try another page
            $s->_next_page( () );
        }
    }
    $s->_results( \@push ) if scalar @push > $pre;
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
