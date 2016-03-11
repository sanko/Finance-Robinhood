requires 'perl', '5.008001';

requires 'HTTP::Tiny';
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

