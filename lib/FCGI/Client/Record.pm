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
    while (length($header) != $HEADER_SIZE) {
        $sock->read_timeout(\$header, $HEADER_SIZE-length($header), length($header)) or return;
    }
    my $content_length = unpack('x4n', $header);
    my $content = '';
    if ($content_length != 0) {
        while (length($content) != $content_length) {
            $sock->read_timeout(\$content, $content_length-length($content), length($content)) or return;
        }
    }
    my $padding_length = unpack('x6C', $header);
    my $padding = '';
    if ($padding_length != 0) {
        while (length($padding) != $padding_length) {
            $sock->read_timeout(\$padding, $padding_length, 0) or return;
        }
    }
    FCGI::Client::Record->new(
        type       => unpack('xC', $header),
        request_id => unpack('xxn', $header),
        content    => $content || '',
    );
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

FCGI::Client::Record - record object

=head1 SYNOPSIS

    my $record = FCGI::Client::Record->read($sock);
    say $record->type;

