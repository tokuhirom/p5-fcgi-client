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

has timeout => (
    is => 'ro',
    isa => 'Int',
    default => 10,
);

sub request {
    my ($self, $env, $content) = @_;
    local $SIG{PIPE} = sub { Carp::cluck("SIGPIPE") };
    my $orig_alarm;
    my @res;
    eval {
        $SIG{ALRM} = sub { Carp::confess('REQUESET_TIME_OUT') };
        $orig_alarm = alarm($self->timeout);
        my $sock = $self->sock();
        $self->_send_request($env, $content);
        @res = $self->_receive_response($sock);
    };
    if ($@) {
        die $@;
    } else {
        return @res;
    }
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
    die 'connection breaked from server process?';
}
sub _send_request {
    my ($self, $env, $content) = @_;
    my $record = "FCGI::Client::RecordFactory";
    my $reqid = int(rand(1000));
    my $flags = $self->keepalive ? FCGI_KEEP_CONN : 0;
    my $sock = $self->sock();
    $sock->print($record->begin_request($reqid, FCGI_RESPONDER, $flags));
    $sock->print($record->params($reqid, %$env));
    $sock->print($record->params($reqid));
    if ($content) {
        $sock->print($record->stdin($reqid, $content));
    }
    $sock->print($record->stdin($reqid));
}

1;
