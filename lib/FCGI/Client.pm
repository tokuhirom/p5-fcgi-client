use warnings;
use strict;

package FCGI::Client;
our $VERSION = '0.01';
use autodie;
use Carp;
use 5.010;

1;
__END__

=head1 NAME

FCGI::Client -

=head1 SYNOPSIS

    use FCGI::Client;
    use HTTP::Request;

    my $req = HTTP::Request->new('GET' => '/');

    my $fcgi = FCGI::Client::Internal->new(
        path => '/path/to/your.fcgi',
    );
    my $res = $fcgi->request($req);

=head1 DESCRIPTION

FCGI::Client is

=head1 TODO

    support external server

=head1 AUTHOR

Tokuhiro Matsuno E<lt>tokuhirom @*(#RJKLFHFSDLJF gmail.comE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
