requires 'Any::Moose', '0.17';
requires 'IO::Socket::UNIX';
requires 'perl', '5.008001';

on build => sub {
    requires 'Test::More';
};
