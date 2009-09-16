use strict;
use warnings;
use Test::More;
use FCGI::Client::Internal;

my $client = FCGI::Client::Internal->new(path => 't/fcgi/post.fcgi');
my ( $stdout, $stderr ) = $client->request(
    +{
        REQUEST_METHOD => 'POST',
        QUERY_STRING   => 'foo=bar',
    },
    "wow\n"
);
is $stdout, "Content−type: text/html\r\n\r\nhello: wow\n";
is $stderr, undef;

done_testing;
