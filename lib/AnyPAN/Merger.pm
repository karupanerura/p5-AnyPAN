package AnyPAN::Merger;
use strict;
use warnings;

use Class::Accessor::Lite ro => [qw/sources/];

use File::Spec;
use Path::Tiny ();

use AnyPAN;
use AnyPAN::Agent;
use AnyPAN::Source;
use AnyPAN::SourceCache;
use AnyPAN::RetryPolicy::ExponentialBackoff;
use AnyPAN::Logger::Null;
use AnyPAN::Merger::Algorithm::PreferLatestVersion;

our $DEFAULT_LOGGER = AnyPAN::Logger::Null->instance();
our $DEFAULT_RETRY_POLICY = AnyPAN::RetryPolicy::ExponentialBackoff->new(
    max_retries   => 5,
    interval      => 1,
    jitter_factor => 0.05,
);
our $DEFAULT_REQUEST_TIMEOUT = 30;
our $DEFAULT_SOURCE_CACHE_DIR = File::Spec->catdir(File::Spec->tmpdir(), 'AnyPAN-Merger');
our $DEFAULT_SOURCE_INDEX_CACHE_TIMEOUT = 300;

sub new {
    my ($class, %args) = @_;
    bless {
        sources => [],
    } => $class;
}

sub add_source {
    my ($self, $source_url) = @_;
    my $source = AnyPAN::Source->new($source_url);
    push @{ $self->{sources} } => $source;
}

sub merge {
    my ($self, $algorithm) = @_;
    $algorithm ||= _get_default_algorithm();

    return $algorithm->merge(@{ $self->sources });
}

sub _get_default_algorithm {
    return AnyPAN::Merger::Algorithm::PreferLatestVersion->new(
        source_cache => _get_default_source_cache(),
        logger       => $DEFAULT_LOGGER,
    );
}

sub _get_default_source_cache {
    return AnyPAN::SourceCache->new(
        cache_dir           => $DEFAULT_SOURCE_CACHE_DIR,
        index_cache_timeout => $DEFAULT_SOURCE_INDEX_CACHE_TIMEOUT,
        agent               => _get_default_agent(),
        logger              => $DEFAULT_LOGGER,
    );
}

sub _get_default_agent {
    return AnyPAN::Agent->new(
        agent        => __PACKAGE__."/$AnyPAN::VERSION",
        timeout      => $DEFAULT_REQUEST_TIMEOUT,
        logger       => $DEFAULT_LOGGER,
        retry_policy => $DEFAULT_RETRY_POLICY,
    );
}

1;
__END__
