package FCGI::Client::Connection;
use Any::Moose;
use FCGI::Client::Constant;

has sock => (
    is       => 'ro',
    required => 1,
);

has keepalive => (
    is => 'ro',
    isa => 'Int',
    default => 0,
);

sub request {
    my ($self, $request) = @_;
    local $SIG{PIPE} = sub { Carp::cluck("SIGPIPE") };
    my $sock = $self->sock();
    $self->_send_request($request, $sock);
    return $self->_receive_response($sock);
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
            $sock->close() unless $self->keepalive;
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

1;
