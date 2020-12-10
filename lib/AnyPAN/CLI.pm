package AnyPAN::CLI;
use strict;
use warnings;

use Class::Accessor::Lite new => 1, ro => [qw/
    verbose
    with_packages
    source_cache_dir
    index_cache_timeout
    request_timeout
    max_retries
    retry_interval
    retry_jitter_factor
    source_urls
/];

use Getopt::Long 2.36 ();
use Pod::Usage qw/pod2usage/;

use AnyPAN;
use AnyPAN::Merger;
use AnyPAN::Agent;
use AnyPAN::Source;
use AnyPAN::SourceCache;
use AnyPAN::RetryPolicy::ExponentialBackoff;
use AnyPAN::Merger::Algorithm::PreferLatestVersion;
use AnyPAN::Logger::Stderr;

sub new_with_argv {
    my ($class, @argv) = @_;
    my $parser = $class->create_option_parser();
    my @specs  = $class->create_option_specs();

    my %opts;
    $parser->getoptionsfromarray(\@argv, \%opts, @specs)
        or pod2usage(1);

    my %args = $class->convert_options(\%opts, \@argv);
    return $class->new(%args);
}

sub create_option_parser {
    my $parser = Getopt::Long::Parser->new();
    $parser->configure(qw/posix_default no_ignore_case bundling auto_help/);
    return $parser;
}

sub create_option_specs {
    return qw/
        verbose|v+
        with-packages
        source-cache-dir=s
        index-cache-timeout=i
        request-timeout=i
        max-retries=i
        retry-interval=f
        retry-jitter-factor=f
    /;
}

sub convert_options {
    my ($class, $opts, $argv) = @_;
    return (
        verbose             => $opts->{'verbose'}             || 0,
        with_packages       => $opts->{'with-packages'}       || 0,
        source_cache_dir    => $opts->{'source-cache-dir'}    || $AnyPAN::Merger::DEFAULT_SOURCE_CACHE_DIR,
        index_cache_timeout => $opts->{'index-cache-timeout'} || $AnyPAN::Merger::DEFAULT_SOURCE_INDEX_CACHE_TIMEOUT,
        request_timeout     => $opts->{'request-timeout'}     || $AnyPAN::Merger::DEFAULT_REQUEST_TIMEOUT,
        max_retries         => $opts->{'max-retries'}         || $AnyPAN::Merger::DEFAULT_RETRY_POLICY->max_retries,
        retry_interval      => $opts->{'retry-interval'}      || $AnyPAN::Merger::DEFAULT_RETRY_POLICY->interval,
        retry_jitter_factor => $opts->{'retry-jitter-factor'} || $AnyPAN::Merger::DEFAULT_RETRY_POLICY->jitter_factor,
        source_urls         => $argv,
    );
}

sub run {
    my $self = shift;

    my $logger       = $self->create_logger();
    my $retry_policy = $self->create_retry_policy();
    my $agent        = $self->create_agent(logger => $logger, retry_policy => $retry_policy);
    my $source_cache = $self->create_source_cache(logger => $logger, agent => $agent);
    my $algorithm    = $self->create_algorithm(source_cache => $source_cache);
    my $storage      = $self->create_storage();

    my $merger = AnyPAN::Merger->new();
    for my $source_url (@{ $self->source_urls }) {
        $merger->add_source($source_url);
    }

    my $index = $merger->merge($algorithm);
    if ($self->with_packages) {
        $index->save_with_included_packages($storage);
    } else {
        $index->save($storage);
    }
}

sub create_logger {
    my $self = shift;

    my $logger = AnyPAN::Logger::Stderr->new(
        level => $self->verbose == 0 ? 'warn'
               : $self->verbose == 1 ? 'info'
               : $self->verbose >= 2 ? 'debug'
               : 'warn'
    );

    return $logger;
}

sub create_retry_policy {
    my $self = shift;

    my $retry_policy = AnyPAN::RetryPolicy::ExponentialBackoff->new(
        max_retries   => $self->max_retries,
        interval      => $self->retry_interval,
        jitter_factor => $self->retry_jitter_factor,
    );

    return $retry_policy;
}

sub create_agent {
    my ($self, %args) = @_;

    my $agent = AnyPAN::Agent->new(
        agent        => "AnyPAN/$AnyPAN::VERSION",
        timeout      => $self->request_timeout,
        logger       => $args{logger},
        retry_policy => $args{retry_policy},
    );

    return $agent;
}

sub create_source_cache {
    my ($self, %args) = @_;

    my $source_cache = AnyPAN::SourceCache->new(
        cache_dir           => $self->source_cache_dir,
        index_cache_timeout => $self->index_cache_timeout,
        agent               => $args{agent},
        logger              => $args{logger},
    );

    return $source_cache;
}

sub create_algorithm {
    my ($self, %args) = @_;

    my $algorithm = AnyPAN::Merger::Algorithm::PreferLatestVersion->new(%args);
    return $algorithm;
}

sub create_storage { require Carp; Carp::croak('abstruct method') }

1;
__END__
