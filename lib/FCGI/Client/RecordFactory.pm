package FCGI::Client::RecordFactory;
use strict;
use warnings;
use Carp ();
use FCGI::Client::Constant;

sub create_request {
    my ($self, $reqid, $env, $content) = @_;
    Carp::croak("env should be hashref") if ref($env) ne 'HASH';
    my $factory = __PACKAGE__;
    my $flags = 0;
    return join('',
        $factory->build_begin_request($reqid, FCGI_RESPONDER, $flags),
        $factory->build_params($reqid, %$env),
        $factory->build_params($reqid),
        ($content ? $factory->build_stdin($reqid, $content) : ''),
        $factory->build_stdin($reqid),
    );
}

# generate generic record
sub build_base {
    my ($class, $type, $request_id, $content) = @_;
    #  0 unsigned char version;
    #  1 unsigned char type;
    #  2 unsigned char requestIdB1; <= (B1<<8)+B0, network byte order
    #  3 unsigned char requestIdB0;
    #  4 unsigned char contentLengthB1;
    #  5 unsigned char contentLengthB0;
    #  6 unsigned char paddingLength;
    #  7 unsigned char reserved;
    #    unsigned char contentData[contentLength];
    #    unsigned char paddingData[paddingLength];
    #
    # n => An unsigned short (16−bit) in "network" (big−endian) order.
    # C => An unsigned char (octet) value.
    my $buf = pack('CCnnCC',
        FCGI_VERSION_1,
        $type,
        $request_id,
        length($content),
        0,
        0,
    );
    $buf .= $content;
    return $buf;
}

# generate FCGI_BEGIN_REQUEST record
sub build_begin_request {
    my ($class, $request_id, $role, $flags) = @_;
    # typedef struct {
    #     unsigned char roleB1;
    #     unsigned char roleB0;
    #     unsigned char flags;
    #     unsigned char reserved[5];
    # } FCGI_BeginRequestBody;
    my $content = pack(
        'nCCCCCC',
        $role,
        $flags,
        0,0,0,0,0
    );
    $class->build_base(FCGI_BEGIN_REQUEST, $request_id, $content);
}

# generate FCGI_PARAMS record
sub build_params {
    my ($class, $request_id, %params)  = @_;
    my $content = '';
    while (my ($k, $v) = each %params) {
        my $klen = length($k);
        my $vlen = length($v);
        $content .= ($klen < 127) ? pack('C', $klen) : pack('N', $klen);
        $content .= ($vlen < 127) ? pack('C', $vlen) : pack('N', $vlen);
        $content .= $k;
        $content .= $v;
    }
    $class->build_base(FCGI_PARAMS, $request_id, $content);
}

# generate FCGI_STDIN record
sub build_stdin {
    my ($class, $request_id, $content)  = @_;
    $content ||= '';
    $class->build_base(FCGI_STDIN, $request_id, $content);
}

1;
__END__

=head1 NAME

FCGI::Client::RecordFactory - FCGI record factory

=head1 HIGH LEVEL API METHODS

=over 4

=item FCGI::Client::RecordFactory->create_request($reqid, $env, $content);

This method creates set of request records.$env is environment variables same as CGI.
$content is request body.This method returns string of request records.You can send it to
socket.

=back

=head1 LOW LEVEL API METHODS

=over 4

=item FCGI::Client::RecordFactory->build_begin_request($reqid, FCGI_RESPONDER, $flags);

build FCGI_BEGIN_REQUEST record.

=item FCGI::Client::RecordFactory->build_params($reqid, %$env)

build FCGI_PARAMS record.

=item FCGI::Client::RecordFactory->build_stdin($reqid, $content);

build FCGI_STDIN record.

=back

=head1 SEE ALSO

L<FCGI::Client>

