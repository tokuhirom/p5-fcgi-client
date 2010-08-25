#!/usr/bin/perl
use FCGI;

my $req = FCGI::Request();
while ($req->Accept() >= 0) {
    sleep 60;
}

