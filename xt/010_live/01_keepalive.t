use strict;
use warnings;
use Test::More;
use FCGI::Client::Internal;

my $client = FCGI::Client::Internal->new(path => 't/fcgi/keepalive.fcgi');
my $con = FCGI::Client::Connection->new(sock => $client->create_socket(), keepalive => 1);
for (0..10) {
    my ( $stdout, $stderr ) = $con->request(
        +{
            REQUEST_METHOD => 'GET',
        },
        ''
    );
    is $stdout, "Content−type: text/html\r\n\r\nhello";
}

done_testing;
