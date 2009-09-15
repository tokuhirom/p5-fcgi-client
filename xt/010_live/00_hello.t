use strict;
use warnings;
use FCGI::Client;
use Test::More;

my $req = HTTP::Request->new(GET => '/');
my $client = FCGI::Client::Internal->new(path => 't/fcgi/hello.fcgi');
my ($stdout, $stderr) = $client->request($req);
is $stdout, "Content−type: text/html\r\n\r\nhello";
is $stderr, undef;

done_testing;
