use strict;
use warnings;

use AnyPAN::ProxyServer;
use AnyPAN::Storage::Directory;

my $merger = AnyPAN::ProxyServer->new(
    storage => AnyPAN::Storage::Directory->new(path => '/path/to/merged'),
);

$merger->add_source('https://cpan.metacpan.org/');

$merger->to_app();
