use strict;
use Test::More 0.98;
use lib '../lib';
my @classes = qw[
    Finance::Robinhood
    Finance::Robinhood::News
    Finance::Robinhood::Equity::Instrument
    Finance::Robinhood::Equity::Fundamentals
    Finance::Robinhood::Equity::Quote
    Finance::Robinhood::Utility::Iterator];

for my $class (@classes) {
    use_ok($class) or BAIL_OUT("$class did not compile");
    eval "package $class; Test::More->import();";
    subtest $class . '::' . $_ => sub { $class->$_() }
        for _get_tests($class);
}
#
done_testing();

sub _get_tests {
    my $class = shift;
    no strict 'refs';
    sort grep { $class->can($_) } grep {/^_test_.+/} keys %{ $class . '::' };
}
