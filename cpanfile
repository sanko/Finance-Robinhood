requires 'perl', '5.010';

requires 'HTTP::Tiny', '0.056';
requires 'Carp';
requires 'Data::Dump';
requires 'Moo';
requires 'JSON::Tiny';
requires 'strictures', '2';
requires 'namespace::clean';

requires 'DateTime';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

