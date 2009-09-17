use strict;
use warnings;

package FCGI::Client::Constant;

sub import {
    my $const = {
        # protocol version
        FCGI_VERSION_1         =>  1,

        # Mask for flags component of FCGI_BeginRequestBody
        FCGI_KEEP_CONN         =>  1,

        # request role
        FCGI_RESPONDER         =>  1,
        FCGI_AUTHORIZER        =>  2,
        FCGI_FILTER            =>  3,

        # Values for protocolStatus component of FCGI_EndRequestBody
        FCGI_REQUEST_COMPLETE  =>  0,
        FCGI_CANT_MPX_CONN     =>  1,
        FCGI_OVERLOADED        =>  2,
        FCGI_UNKNOWN_ROLE      =>  3,

        # packet type
        FCGI_BEGIN_REQUEST     =>  1,
        FCGI_ABORT_REQUEST     =>  2,
        FCGI_END_REQUEST       =>  3,
        FCGI_PARAMS            =>  4,
        FCGI_STDIN             =>  5,
        FCGI_STDOUT            =>  6,
        FCGI_STDERR            =>  7,
        FCGI_DATA              =>  8,
        FCGI_GET_VALUES        =>  9,
        FCGI_GET_VALUES_RESULT => 10,
        FCGI_UNKNOWN_TYPE      => 11,
    };
    my $pkg = caller(0);
    no strict 'refs';
    while (my ($k, $v) = each %$const) {
        *{"$pkg\::$k"} = sub () { $v };
    }
}

1;
