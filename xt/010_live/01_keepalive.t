use strict;
use warnings;
use Test::More;
use FCGI::Client::Internal;

my $client = FCGI::Client::Internal->new(path => 't/fcgi/hello.fcgi');
my $con = FCGI::Client::Connection->new(sock => $client->create_socket(), keepalive => 1);
for (0..10) {
    my ( $stdout, $stderr ) = $con->request(
        +{
            REQUEST_METHOD => 'GET',
            QUERY_STRING   => 'foo=bar',
        },
        ''
    );
    is $stdout, "Content−type: text/html\r\n\r\nhello\nfoo=bar";
    is $stderr, "hello, stderr\n";
}

done_testing;
