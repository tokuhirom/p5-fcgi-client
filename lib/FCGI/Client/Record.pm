package FCGI::Client::Record;
use Any::Moose;
use FCGI::Client::Constant;
has type       => ( is => 'ro', isa => 'Int' );
has request_id => ( is => 'ro', isa => 'Int' );
has content    => ( is => 'ro', isa => 'Str' );

# factory method
sub read {
    my ($class, $sock) = @_;
    my $HEADER_SIZE = 8;
    my $header = '';
    $sock->read_timeout(\$header, $HEADER_SIZE-length($header), length($header)) or return;
    my $content_length = unpack('x4n', $header);
    my $content = '';
    while (length($content) < $content_length) {
        $sock->sock->sysread($content, $content_length-length($content));
    }
    my $padding_length = unpack('x6C', $header);
    my $padding = '';
    while (length($padding) < $padding_length) {
        $sock->sock->sysread($padding, $padding_length-length($padding));
    }
    FCGI::Client::Record->new(
        type       => unpack('xC', $header),
        request_id => unpack('xxn', $header),
        content    => $content,
    );
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

FCGI::Client::Record - record object

=head1 SYNOPSIS

    my $record = FCGI::Client::Record->read($sock);
    say $record->type;

