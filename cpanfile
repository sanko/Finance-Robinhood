requires 'perl', '5.012';

requires 'HTTP::Tiny', '0.056';
requires 'Carp', '1.36';
#requires 'Data::Dump';
requires 'Moo', '2.003004';
requires 'MooX::Singleton';
requires 'JSON::Tiny', '0.54';
requires 'strictures', '2';
requires 'namespace::clean', '0.26';
requires 'IO::Socket::SSL', '2.020';
requires 'DateTime::Tiny';
requires 'Date::Tiny';
requires 'Try::Tiny', '0.24';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

