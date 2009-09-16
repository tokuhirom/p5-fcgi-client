package FCGI::Client::Connection;
use Any::Moose;
use FCGI::Client::Constant;
use Time::HiRes qw(time);
use List::Util qw(max sum);
use POSIX qw(EAGAIN);

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
    warn 'send request';
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
    while (my $res = FCGI::Client::Record->read($self)) {
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

# returns 1 if socket is ready, undef on timeout
sub wait_socket {
    my ( $self, $sock, $is_write, $wait_until ) = @_;
    do {
        my $vec = '';
        vec( $vec, $sock->fileno, 1 ) = 1;
        if (
            select(
                $is_write ? undef : $vec,
                $is_write ? $vec  : undef,
                undef,
                max( $wait_until - time, 0 )
            ) > 0
          )
        {
            return 1;
        }
    } while ( time < $wait_until );
    return;
}

# returns (positive) number of bytes read, or undef if the socket is to be closed
sub read_timeout {
    my ( $self, $buf, $len, $off, ) = @_;
    my $sock = $self->sock;
    my $timeout = $self->timeout;
    my $wait_until = time + $timeout;
    while ( $self->wait_socket( $sock, undef, $wait_until ) ) {
        if ( my $ret = $sock->sysread( $$buf, $len, $off ) ) {
            return $ret;
        }
        elsif ( !( !defined($ret) && $! == EAGAIN ) ) {
        warn $::main::pid;
        wait;
        use Carp; Carp::cluck($ret);
        warn $!;
            last;
        }
    }
    return;
}

1;
