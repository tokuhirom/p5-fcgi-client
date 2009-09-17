package FCGI::Client::RecordHeader;
use Any::Moose;
use FCGI::Client::Constant;
has raw        => ( is => 'ro', isa => 'Str' );

sub SIZE () { 8 } ## no critic
sub content_length { unpack('x4n', $_[0]->raw ) }
sub padding_length { unpack('x6C', $_[0]->raw ) }
sub type           { unpack('xC',  $_[0]->raw ) }
sub request_id     { unpack('xxn',  $_[0]->raw ) }

__PACKAGE__->meta->make_immutable;
