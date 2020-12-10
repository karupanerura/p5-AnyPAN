use strict;
use warnings;

use Test2::V0;

use lib 't/lib';
use TestUtil qw/source_url/;
use TestLogger;

use Path::Tiny ();
use AnyPAN::Merger;
use AnyPAN::Storage::Directory;

use AnyPAN::Source;
use AnyPAN::Index;

local $AnyPAN::Merger::DEFAULT_SOURCE_CACHE_DIR = Path::Tiny->tempdir(CLEANUP => 1);
local $AnyPAN::Merger::DEFAULT_LOGGER = TestLogger->instance();

my $merger = AnyPAN::Merger->new();
$merger->add_source(source_url('mirror1.example.test'));
$merger->add_source(source_url('mirror2.example.test'));
$merger->add_source(source_url('mirror3.example.test'));

my $merged_dir = Path::Tiny->tempdir(CLEANUP => 1);
$merger->merge()->save_with_included_packages(
    AnyPAN::Storage::Directory->new(path => $merged_dir->stringify),
);

my $source = AnyPAN::Source->new('file://'.$merged_dir);
my $index_path = $merged_dir->child('modules', '02packages.details.txt.gz');
my $index = AnyPAN::Index->parse($index_path, $source);
is $index->packages, array {
    item object {
        call source  => $source;
        call module  => 'Foo::Bar';
        call version => '0.02';
        call path    => 'D/DU/DUMMY/Foo-Bar-0.02.tar.gz';
        end();
    };
    item object {
        call source  => $source;
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

