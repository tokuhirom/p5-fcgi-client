#!/opt/local/bin/perl
warn "FCGI!";
use FCGI;

my $req = FCGI::Request();
while ($req->Accept() >= 0) {
    print("Content−type: text/html\r\n\r\nhello");
    $req->Finish();
}

