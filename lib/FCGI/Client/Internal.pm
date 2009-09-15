package FCGI::Client::Internal;
use Mouse;
use FCGI::Client::Constant;
use File::Temp ();
use autodie;
use HTTP::Request;
use HTTP::Request::AsCGI;
use IO::Socket::UNIX;
use FCGI::Client::RecordFactory;
use FCGI::Client::Record;

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
        my $type = $res->type;
        if ($type == FCGI_STDOUT) {
            $stdout .= $res->content;
        } elsif ($type == FCGI_STDERR) {
            $stderr .= $res->content;
        } elsif ($type == FCGI_END_REQUEST) {
            $sock->close();
            return ($stdout, $stderr);
        } else {
            die "unknown response type: " . $res->type;
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

__PACKAGE__->meta->make_immutable;
