use strict;
use warnings;

use AnyPAN::ReverseProxy;
use AnyPAN::Storage::Directory;

my $merger = AnyPAN::ReverseProxy->new(
    storage => AnyPAN::Storage::Directory->new(path => '/path/to/merged'),
);

$merger->add_source('https://cpan.metacpan.org/');

$merger->to_app();
