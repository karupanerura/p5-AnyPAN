use strict;
use Test::More 0.98;

use_ok $_ for qw(
    CPAN::MirrorMerger
    CPAN::MirrorMerger::Agent
    CPAN::MirrorMerger::Algorithm::Simple
    CPAN::MirrorMerger::Index
    CPAN::MirrorMerger::Index::Merged
    CPAN::MirrorMerger::Logger
    CPAN::MirrorMerger::Logger::Null
    CPAN::MirrorMerger::Logger::Stderr
    CPAN::MirrorMerger::Mirror
    CPAN::MirrorMerger::MirrorCache
    CPAN::MirrorMerger::PackageInfo
    CPAN::MirrorMerger::RetryPolicy
    CPAN::MirrorMerger::Storage::Directory
);

done_testing;

