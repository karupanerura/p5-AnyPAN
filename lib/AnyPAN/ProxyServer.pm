package AnyPAN::ProxyServer;
use strict;
use warnings;

use parent qw/Plack::Component/;

use Plack::Util::Accessor qw/storage logger source_cache/;

use Plack::Request;
use Plack::Response;
use Plack::MIME;
use Path::Tiny;

use AnyPAN;
use AnyPAN::Merger;
use AnyPAN::Source;
use AnyPAN::SourceCache;
use AnyPAN::RetryPolicy::NoRetry;
use AnyPAN::PackageInfo;
use AnyPAN::Logger::Stderr;

our $DEFAULT_LOGGER = AnyPAN::Logger::Stderr->new(level => $ENV{CPAN_SOURCE_MERGER_PROXY_LOG_LEVEL} || 'warn');
our $DEFAULT_REQUEST_TIMEOUT = 10;
our $DEFAULT_RETRY_POLICY = AnyPAN::RetryPolicy::NoRetry->instance();

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->{sources} = [];

    # set default
    $self->{logger} ||= $DEFAULT_LOGGER;
    $self->{source_cache} ||= _get_default_source_cache($self->{logger});

    return $self;
}

sub prepare_app {
    my $self = shift;
    unless ($self->storage) {
        die "storage is required";
    }

    unless (@{ $self->{sources} }) {
        die "sources are required";
    }
}

sub add_source {
    my ($self, $source_url) = @_;
    my $source = AnyPAN::Source->new($source_url);
    $self->logger->debug("add @{[ $source->name ]} as source");
    push @{ $self->{sources} } => $source;
}

sub call {
    my ($self, $env) = @_;
    my $req = Plack::Request->new($env);

    # GET/HEAD request only
    unless ($req->method eq 'GET' || $req->method eq 'HEAD') {
        return $self->_res_405()->finalize();
    }

    # path routing
    if ($req->path =~ m!^/authors/id/([A-Z])/(\1[A-Z])/\2[-A-Z0-9]*/.+$!o) {
        return $self->proxt_to_storage_or_sources($req)->finalize();
    } elsif ($req->path eq '/modules/02packages.details.txt.gz') {
        return $self->proxy_to_storage($req)->finalize();
    }

    return $self->_res_404()->finalize();
}

sub proxt_to_storage_or_sources {
    my ($self, $req) = @_;

    # try proxy to storage
    my $res = $self->proxy_to_storage($req);
    return $res if $res->status == 200;

    # remove "/authors/id/" (e.g. D/DU/DUMMY/Foo.tar.gz)
    my $path = substr $req->path, length "/authors/id/";
    my $package_info = AnyPAN::PackageInfo->new(path => $path);
    my $content_type = Plack::MIME->mime_type($path);
    for my $source (@{ $self->{sources} }) {
        # fetch from source
        my $package_path = eval {
            $self->source_cache->get_or_fetch_package($source, $package_info)
        };
        if (my $e = $@) {
            if (AnyPAN::Agent::Exception::NotFound->caught($e)) {
                $self->logger->debug("skip package $path on @{[ $source->name ]}");
                next; # skip it
            }
            $self->logger->error("failed to fetch package $path on @{[ $source->name ]}");
            die $e;
        }

        $self->logger->debug("found @{[ $req->path ]} from @{[ $source->name ]}");

        # save to storage
        my $save_key = $source->package_path($package_info->canonicalized_path);
        $self->storage->copy($package_path, $save_key);

        # create response
        my $fh = $package_path->openr_raw();
        my $res = Plack::Response->new(200, [
            'Content-Type'   => $content_type,
            'Content-Length' => $package_path->stat->size,
            'Cache-Control'  => 'private',
        ], $fh);
        return $res;
    }

    return $self->_res_404();
}

sub proxy_to_storage {
    my ($self, $req) = @_;
    my $storage_key = substr $req->path, 1; # remove first slash
    my $content_type = Plack::MIME->mime_type($storage_key);

    # check from storage
    my $storage_path = $self->storage->fetch($storage_key);
    return $self->_res_404() unless $storage_path;

    # create response
    $self->logger->debug("found $storage_key from storage");
    my $fh = $storage_path->openr_raw();
    my $res = Plack::Response->new(200, [
        'Content-Type'   => $content_type,
        'Content-Length' => $storage_path->stat->size,
        'Cache-Control'  => 'private',
    ], $fh);
    return $res;
}

sub _res_404 { shift->_res_simple(404, 'Not Found') }
sub _res_405 { shift->_res_simple(405, 'Method Not Allowed') }

sub _res_simple {
    my ($self, $status, $content) = @_;
    return Plack::Response->new($status, [
        'Content-Type'   => 'text/plain',
        'Content-Length' => length $content,
        'Cache-Control'  => 'no-cache,no-store',
    ], $content);
}

sub _get_default_source_cache {
    my $logger = shift;
    return AnyPAN::SourceCache->new(
        cache_dir           => $AnyPAN::Merger::DEFAULT_SOURCE_CACHE_DIR,
        index_cache_timeout => $AnyPAN::Merger::DEFAULT_SOURCE_INDEX_CACHE_TIMEOUT,
        agent               => _get_default_agent($logger),
        logger              => $logger,
    );
}

sub _get_default_agent {
    my $logger = shift;
    return AnyPAN::Agent->new(
        agent        => __PACKAGE__."/$AnyPAN::VERSION",
        timeout      => $DEFAULT_REQUEST_TIMEOUT,
        logger       => $logger,
        retry_policy => $DEFAULT_RETRY_POLICY,
    );
}

1;
__END__

=pod

=encoding utf-8

=head1 NAME

AnyPAN::ProxyServer - Merged DarkPAN proxy server PSGI application

=head1 SYNOPSIS

    use AnyPAN::ProxyServer;
    use AnyPAN::Storage::Directory;

    my $merger = AnyPAN::ProxyServer->new(
        storage => AnyPAN::Storage::Directory->new(path => '/tmp/merged'),
    );

    $merger->add_source('http://backpan.perl.org/');
    $merger->add_source('https://cpan.metacpan.org/');

    $merger->to_app();

=head1 DESCRIPTION

TODO

=head1 SEE ALSO

L<perl>

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut
