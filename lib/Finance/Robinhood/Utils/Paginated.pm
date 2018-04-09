package Finance::Robinhood::Utils::Paginated;

=encoding utf-8

=head1 NAME

Finance::Robinhood::Utils::Paginated - Represent paginated data in an iterative object

=head1 SYNOPSIS

    use Finance::Robinhood;

    my $rh = Finance::Robinhood->new();

    my $instruments = $rh->instruments();

    while(my $instrument = $instruments->next()) {
        # Do something fun here
    }

=cut

use Moo;
our $VERSION = '0.9.0_001';
use Finance::Robinhood::Utils::Client;

=head1 METHODS

Some data returned by Robinhood's API is so exhaustive that it is broken up into pages.

This class wraps that data in a friendly way.

=cut

has '_results' => ( is => 'rw', predicate => 1 );
has '_next'    => ( is => 'rw', init_arg  => 'next', predicate => 1, clearer => 1 );
has '_class'   => ( is => 'ro', init_arg  => 'class', predicate => 1 );

=head2 C<next( )>

    while (my $record = $paginator->next()) { ... }

Returns the next record in the current page. If all records have been exhausted then
the next page will automatically be loaded. This way if you want to ignore pagination
you can just call C<next( )> over and over again to walk through all the records.

When we're out of pages and items, an undefined value is returned.

=cut

sub next {
    my ($s) = @_;
    my $records = $s->_results();
    return shift(@$records) if $records && scalar @$records;
    my ( $status, $data ) = $s->next_page;
    return $data if defined $status && $status != 200;
    $records = $s->_results();
    return shift(@$records) if $records && scalar @$records;
    return $data;
}

=head2 C<next_page( )>

    while (my $records = $paginator->next_page()) { ... }

Returns an array ref of records for the next page.

=cut

sub next_page {
    my ($s) = @_;
    return if !$s->_has_next();
    my $page = $s->_next();
    my ( $status, $data ) = Finance::Robinhood::Utils::Client->instance->get($page);
    if ( !$data || !$data->{next} || $data->{next} eq $page ) {
        $s->_clear_next;
    }
    else { $s->_next( $data->{next} ) }
    $data->{results} = [ map { $_ = $_ ? $s->_class->new($_) : $_ } @{ $data->{results} } ]
        if $s->_has_class;
    $s->_results( $data->{results} );
    return ( $status, $data->{results} );
}

=head2 all

    my $records = $paginator->all();

This is rolls through every page building one giant array ref of all records.

=cut

sub all {
    my ($s) = @_;
    my @records;
    while ( my $items = $s->next_page() ) {
        push @records, @$items;
    }
    return \@records;
}
1;
