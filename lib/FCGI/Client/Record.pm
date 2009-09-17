package FCGI::Client::Record;
use Any::Moose;
use FCGI::Client::Constant;
use FCGI::Client::RecordHeader;

has header     => ( is => 'ro', isa => 'FCGI::Client::RecordHeader', handles => [qw/request_id content_length type/] );
has content    => ( is => 'ro', isa => 'Str' );

# factory method
sub read {
    my ($class, $sock) = @_;
    my $HEADER_SIZE = &FCGI::Client::RecordHeader::SIZE;
    my $header_raw = '';
    while (length($header_raw) != $HEADER_SIZE) {
        $sock->read_timeout(\$header_raw, $HEADER_SIZE-length($header_raw), length($header_raw)) or return;
    }
    my $header = FCGI::Client::RecordHeader->new(raw => $header_raw);
    my $content_length = $header->content_length;
    my $content = '';
    if ($content_length != 0) {
        while (length($content) != $content_length) {
            $sock->read_timeout(\$content, $content_length-length($content), length($content)) or return;
        }
    }
    my $padding_length = $header->padding_length;
    my $padding = '';
    if ($padding_length != 0) {
        while (length($padding) != $padding_length) {
            $sock->read_timeout(\$padding, $padding_length, 0) or return;
        }
    }
    return FCGI::Client::Record->new(
        header     => $header,
        content    => $content,
    );
}

__PACKAGE__->meta->make_immutable;

=head1 NAME

FCGI::Client::Record - record object

=head1 SYNOPSIS

    my $record = FCGI::Client::Record->read($sock);
    say $record->type;

