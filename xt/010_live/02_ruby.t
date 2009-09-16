use strict;
use warnings;
use Test::More;
use FCGI::Client::Internal;

my $client = FCGI::Client::Internal->new(path => 't/fcgi/ruby.rb');
my ( $stdout, $stderr ) = $client->request(
    +{
        REQUEST_METHOD => 'GET',
        QUERY_STRING   => 'foo=bar',
    },
    ''
);
is $stdout, "Content−type: text/html\r\n\r\nhello\nfoo=bar";
is $stderr, "hello, stderr\n";

done_testing;
