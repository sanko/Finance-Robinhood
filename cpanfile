requires 'perl', '5.020';
requires 'IO::Socket::SSL', '2.060';
requires 'URI';
requires 'Moo';
requires 'MooX::Enumeration';
requires 'MooX::ChainedAttributes';
requires 'MooX::StrictConstructor';
requires 'HTTP::Tiny';
requires 'JSON::Tiny';
requires 'strictures', '2';
requires 'Role::Tiny', '2.000001';
requires 'Types::Standard';

requires 'Time::Moment';
requires 'Try::Tiny', '0.24';
requires 'Exporter::Tiny';

on 'test' => sub {
    requires 'Test2::V0';
    requires 'Dotenv';
};

on 'develop' => sub {
    requires 'Software::License::Artistic_2_0';
    requires 'Data::Dump';
    requires 'Perl::Tidy';
    requires 'Test::CPAN::Meta';
    requires 'Test::MinimumVersion::Fast';
    requires 'Test::PAUSE::Permissions';
    requires 'Test::Pod', '1.41';
    requires 'Test::Spellunker';
    requires 'Dotenv';
	requires 'MooX::StrictConstructor';
};

requires 'Data::Dump';
