package CPAN::MirrorMerger::MirrorCache;
use strict;
use warnings;

use Class::Accessor::Lite ro => [qw/cache_dir index_cache_timeout agent logger/];

use Path::Tiny ();
use CPAN::MirrorMerger::Index;
use CPAN::MirrorMerger::Logger::Null;

sub new {
    my ($class, %args) = @_;
    $args{logger} ||= CPAN::MirrorMerger::Logger::Null->instance();

    my $cache_dir = Path::Tiny->new(delete $args{cache_dir});
    bless {
        %args,
        cache_dir => $cache_dir,
        index_cache => {},
    } => $class;
}

sub get_or_fetch_index {
    my ($self, $mirror) = @_;
    if ($self->{index_cache}->{$mirror->name}) {
        $self->logger->debug("memory cache hit mirror: @{[ $mirror->name ]}");
        return $self->{index_cache}->{$mirror->name};
    }

    my $cache_dir = $self->cache_dir->child($mirror->name);
    $cache_dir->mkpath();

    my $index_url = $mirror->index_url();
    my $index_path = $cache_dir->child($index_url->path);

    my $timeout_at = time - $self->index_cache_timeout;
    if (!$index_path->exists || $index_path->stat->mtime < $timeout_at) {
        $index_path->parent->mkpath();
        $self->logger->info("download mirror @{[ $mirror->name ]} index");
        $self->agent->download($index_url, $index_path);
    }

    my $index = CPAN::MirrorMerger::Index->parse($index_path, $mirror);
    $self->{index_cache}->{$mirror->name} = $index;
    return $index;
}

sub get_or_fetch_package {
    my ($self, $mirror, $package_info) = @_;

    my $cache_dir = $self->cache_dir->child($mirror->name);
    $cache_dir->mkpath();

    my $package_url  = $mirror->package_url($package_info->canonicalized_path);
    my $package_path = $cache_dir->child($package_url->path);

    unless ($package_path->exists) {
        $package_path->parent->mkpath();
        $self->logger->info("download package @{[ $package_info->path ]} from @{[ $mirror->name ]}");
        $self->agent->download($package_url, $package_path);
    }

    return $package_path;
}

1;
__END__
