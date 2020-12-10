use strict;
use Test::More 0.98;

use_ok $_ for qw(
    AnyPAN
    AnyPAN::Agent
    AnyPAN::CLI
    AnyPAN::CLI::FileStorage
    AnyPAN::Index
    AnyPAN::Index::Merged
    AnyPAN::Logger
    AnyPAN::Logger::Null
    AnyPAN::Logger::Stderr
    AnyPAN::Merger
    AnyPAN::Merger::Algorithm::PreferLatestVersion
    AnyPAN::Source
    AnyPAN::SourceCache
    AnyPAN::PackageInfo
    AnyPAN::ProxyServer
    AnyPAN::RetryPolicy
    AnyPAN::RetryPolicy::ExponentialBackoff
    AnyPAN::RetryPolicy::NoRetry
    AnyPAN::Storage::Directory
);

done_testing;

