use inc::Module::Install;
name 'FCGI-Client';
all_from 'lib/FCGI/Client.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
