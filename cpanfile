requires 'perl', '5.020';
requires 'IO::Socket::SSL', '2.060';
requires 'Mojo::Base';
requires 'Mojo::URL';
requires 'Mojo::UserAgent';
requires 'strictures', '2';

requires 'Time::Moment';
requires 'Try::Tiny', '0.24';
requires 'Exporter::Tiny';

on 'test' => sub {
    requires 'Test2::V0';
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
}
