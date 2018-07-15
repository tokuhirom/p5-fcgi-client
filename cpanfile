requires 'Any::Moose', '0.17';
requires 'IO::Socket::UNIX';
requires 'perl', '5.008001';

on build => sub {
    requires 'Test::More';
};

on develop => sub {
    requires 'Test::TCP';
    requires 'HTTP::Request';
    requires 'FCGI';
    requires 'Test::Perl::Critic';
};

