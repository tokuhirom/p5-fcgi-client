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

__PACKAGE__->meta->make_immutable;
