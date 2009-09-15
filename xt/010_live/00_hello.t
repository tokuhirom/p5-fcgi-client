use strict;
use warnings;
use Test::More;
use FCGI::Client::Internal;

my $req = HTTP::Request->new(GET => '/?foo=bar');
my $client = FCGI::Client::Internal->new(path => 't/fcgi/hello.fcgi');
my ($stdout, $stderr) = $client->request($req);
is $stdout, "Content−type: text/html\r\n\r\nhello\nfoo=bar";
is $stderr, "hello, stderr\n";

done_testing;
