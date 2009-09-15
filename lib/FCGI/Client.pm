use warnings;
use strict;

package FCGI::Client;
our $VERSION = '0.01';
use HTTP::Request;
use autodie;
use HTTP::Request::AsCGI;
use IO::Socket::UNIX;
use Carp;
use 5.010;

{
    package FCGI::Client::Internal;
    use Mouse;
    use FCGI::Client::Constant;
    use File::Temp ();

    has path   => ( is => 'ro', isa     => 'Str' );
    has sock_path => (
        is      => 'ro',
        isa     => 'Str',
        lazy    => 1,
        default => sub { File::Temp::tmpnam() },
    );
    has child_pid => (
        is      => 'rw',
        isa     => 'Int',
        lazy    => 1,
        default => sub {
            my $self = shift;
            my $path = $self->sock_path;   # generate common path before fork(2)
            my $pid  = fork();
            if ( $pid > 0 ) {              # parent
                return $pid;
            }
            else {
                my $sock = IO::Socket::UNIX->new(
                    Local  => $path,
                    Listen => 10,
                ) or die $!;
                open *STDIN, '>&', $sock;    # dup(2)
                exec $self->path;
                die "should not reach here: $!";
            }
        }
    );

    sub DEMOLISH {
        my $self = shift;
        if ($self->child_pid) {
            kill 'TERM' => $self->child_pid;
            wait;
        }
        unlink $self->sock_path;
    }

    sub request {
        my ($self, $request) = @_;
        local $SIG{PIPE} = sub { Carp::cluck("SIGPIPE") };
        my $sock = $self->create_socket();
        $self->_send_request($request, $sock);
        return $self->_receive_response($sock);
    }
    sub create_socket {
        my $self = shift;
        $self->child_pid();    # invoke child

        my $path = $self->sock_path;
        my $retry = 30;
        while ($retry-- >= 0) {
            my $sock = IO::Socket::UNIX->new( Peer => $path, );
            return $sock if $sock;
            sleep 0.1;
        }
        die "cannot open socket $path: $!";
    }
    sub _receive_response {
        my ($self, $sock) = @_;
        my ($stdout, $stderr);
        while (my $res = FCGI::Client::Record->read($sock)) {
            given ($res->type) {
                when (FCGI_STDOUT) {
                    $stdout .= $res->content;
                }
                when (FCGI_STDERR) {
                    $stderr .= $res->content;
                }
                when (FCGI_END_REQUEST) {
                    $sock->close();
                    return ($stdout, $stderr);
                }
                default {
                    die "unknown response type: " . $res->type;
                }
            }
        }
        die 'should not reache here';
    }
    sub _send_request {
        my ($self, $request, $sock) = @_;
        my $record = "FCGI::Client::RecordFactory";
        my $flags = 0;
        $sock->print($record->begin_request(1, FCGI_RESPONDER, $flags));
        {
            my $c = HTTP::Request::AsCGI->new($request); # XXX don't use HTTP::Request::AsCGI
            $sock->print($record->params(1, %{$c->environment}));
        }
        $sock->print($record->params(1));
        if ($request->content) {
            $sock->print($record->stdin(1, $request->content));
        }
        $sock->print($record->stdin(1));
    }
}

{
    package FCGI::Client::Record;
    use Mouse;
    use FCGI::Client::Constant;
    has type       => ( is => 'ro', isa => 'Int' );
    has request_id => ( is => 'ro', isa => 'Int' );
    has content    => ( is => 'ro', isa => 'Str' );

    # factory method
    sub read {
        my ($class, $sock) = @_;
        my $HEADER_SIZE = 8;
        my $header = '';
        my $read;
        while (length($header) != $HEADER_SIZE) {
            $read += $sock->read($header, $HEADER_SIZE-length($header));
        }
        my $content_length = unpack('x4n', $header);
        my $content = '';
        while (length($content) != $content_length) {
            $sock->read($content, $content_length-length($content));
        }
        my $padding_length = unpack('x6C', $header);
        my $padding = '';
        while (length($padding) != $padding_length) {
            $sock->read($padding, $padding_length-length($padding));
        }
        FCGI::Client::Record->new(
            type       => unpack('xC', $header),
            request_id => unpack('xxn', $header),
            content    => $content,
        );
    }
}

{
    package FCGI::Client::RecordFactory;
    use FCGI::Client::Constant;
    sub generate {
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
    sub begin_request {
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
        $class->generate(FCGI_BEGIN_REQUEST, $request_id, $content);
    }
    sub params {
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
        $class->generate(FCGI_PARAMS, $request_id, $content);
    }
    sub stdin {
        my ($class, $request_id, $content)  = @_;
        $content ||= '';
        $class->generate(FCGI_STDIN, $request_id, $content);
    }
}

1;
__END__

=head1 NAME

FCGI::Client -

=head1 SYNOPSIS

    use FCGI::Client;
    use HTTP::Request;

    my $req = HTTP::Request->new('GET' => '/');

    my $fcgi = FCGI::Client::Internal->new(
        path => '/path/to/your.fcgi',
    );
    my $res = $fcgi->request($req);

=head1 DESCRIPTION

FCGI::Client is

=head1 TODO

    support external server

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom @*(#RJKLFHFSDLJF gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
