use inc::Module::Install;
name 'FCGI-Client';
all_from 'lib/FCGI/Client.pm';

requires 'autodie';
requires 'IO::Socket::UNIX';
requires 'HTTP::Request';
requires 'Try::Tiny';

author_requires 'FCGI';

tests 't/*.t';
recursive_author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
