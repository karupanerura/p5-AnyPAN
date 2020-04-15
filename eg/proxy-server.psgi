use strict;
use warnings;

use CPAN::MirrorMerger::ProxyServer;
use CPAN::MirrorMerger::Storage::Directory;

my $merger = CPAN::MirrorMerger::ProxyServer->new(
    storage => CPAN::MirrorMerger::Storage::Directory->new(path => '/path/to/merged'),
);

$merger->add_mirror('https://cpan.metacpan.org/');

$merger->to_app();
