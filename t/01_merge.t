use strict;
use warnings;

use Test2::V0;

use lib 't/lib';
use TestUtil qw/mirror_url/;
use TestLogger;

use Path::Tiny ();
use CPAN::MirrorMerger;
use CPAN::MirrorMerger::Storage::Directory;

use CPAN::MirrorMerger::Mirror;
use CPAN::MirrorMerger::Index;

local $CPAN::MirrorMerger::DEFAULT_MIRROR_CACHE_DIR = Path::Tiny->tempdir(CLEANUP => 1);
local $CPAN::MirrorMerger::DEFAULT_LOGGER = TestLogger->instance();

my $merger = CPAN::MirrorMerger->new();
$merger->add_mirror(mirror_url('mirror1.example.test'));
$merger->add_mirror(mirror_url('mirror2.example.test'));
$merger->add_mirror(mirror_url('mirror3.example.test'));

my $merged_dir = Path::Tiny->tempdir(CLEANUP => 1);
$merger->merge()->save(
    CPAN::MirrorMerger::Storage::Directory->new(path => $merged_dir->stringify),
);

my $mirror = CPAN::MirrorMerger::Mirror->new('file://'.$merged_dir);
my $index_path = $merged_dir->child('modules', '02packages.details.txt.gz');
my $index = CPAN::MirrorMerger::Index->parse($index_path, $mirror);
is $index->packages, array {
    item object {
        call mirror  => $mirror;
        call module  => 'Foo::Bar';
        call version => '0.02';
        call path    => 'D/DU/DUMMY/Foo-Bar-0.02.tar.gz';
        end();
    };
    item object {
        call mirror  => $mirror;
        call module  => 'Hoge::Fuga';
        call version => '0.01';
        call path    => 'D/DU/DUMMY/Hoge-Fuga-0.01.tar.gz';
        end();
    };
    end();
}, '02packages.details.txt.gz contents';
is $merged_dir->child('authors', 'id', 'D', 'DU', 'DUMMY', 'Foo-Bar-0.01.tar.gz'), object {
    call exists => T;
    end();
}, 'Foo-Bar-0.01.tar.gz';
is $merged_dir->child('authors', 'id', 'D', 'DU', 'DUMMY', 'Foo-Bar-0.02.tar.gz'), object {
    call exists => T;
    end();
}, 'Foo-Bar-0.02.tar.gz';
is $merged_dir->child('authors', 'id', 'D', 'DU', 'DUMMY', 'Hoge-Fuga-0.01.tar.gz'), object {
    call exists => T;
    end();
}, 'Hoge-Fuga-0.01.tar.gz';

done_testing;

