package FCGI::Client::Record;
use Any::Moose;
use FCGI::Client::Constant;
use FCGI::Client::RecordHeader;

has header     => ( is => 'ro', isa => 'FCGI::Client::RecordHeader', handles => [qw/request_id content_length type/] );
has content    => ( is => 'ro', isa => 'Str' );


__PACKAGE__->meta->make_immutable;

=head1 NAME

FCGI::Client::Record - record object

=head1 SYNOPSIS

    my $record = FCGI::Client::Record->read($sock);
    say $record->type;

