package CPAN::MirrorMerger;
use strict;
use warnings;

our $VERSION = "0.03";

use Class::Accessor::Lite ro => [qw/mirrors/];

use File::Spec;
use Path::Tiny ();

use CPAN::MirrorMerger::Agent;
use CPAN::MirrorMerger::Mirror;
use CPAN::MirrorMerger::MirrorCache;
use CPAN::MirrorMerger::RetryPolicy;
use CPAN::MirrorMerger::Logger::Null;
use CPAN::MirrorMerger::Algorithm::Simple;

our $DEFAULT_LOGGER = CPAN::MirrorMerger::Logger::Null->instance();
our $DEFAULT_RETRY_POLICY = CPAN::MirrorMerger::RetryPolicy->new(
    max_retries   => 5,
    interval      => 1,
    jitter_factor => 0.05,
);
our $DEFAULT_REQUEST_TIMEOUT = 30;
our $DEFAULT_MIRROR_CACHE_DIR = File::Spec->catdir(File::Spec->tmpdir(), 'CPAN-MirrorMerger');
our $DEFAULT_MIRROR_INDEX_CACHE_TIMEOUT = 300;

sub new {
    my ($class, %args) = @_;
    bless {
        mirrors => [],
    } => $class;
}

sub add_mirror {
    my ($self, $mirror_url) = @_;
    my $mirror = CPAN::MirrorMerger::Mirror->new($mirror_url);
    push @{ $self->{mirrors} } => $mirror;
}

sub merge {
    my ($self, $algorithm) = @_;
    $algorithm ||= _get_default_algorithm();

    return $algorithm->merge(@{ $self->mirrors });
}

sub _get_default_algorithm {
    return CPAN::MirrorMerger::Algorithm::Simple->new(
        mirror_cache => _get_default_mirror_cache(),
        logger       => $DEFAULT_LOGGER,
    );
}

sub _get_default_mirror_cache {
    return CPAN::MirrorMerger::MirrorCache->new(
        cache_dir           => $DEFAULT_MIRROR_CACHE_DIR,
        index_cache_timeout => $DEFAULT_MIRROR_INDEX_CACHE_TIMEOUT,
        agent               => _get_default_agent(),
        logger              => $DEFAULT_LOGGER,
    );
}

sub _get_default_agent {
    return CPAN::MirrorMerger::Agent->new(
        agent        => __PACKAGE__."/$VERSION",
        timeout      => $DEFAULT_REQUEST_TIMEOUT,
        logger       => $DEFAULT_LOGGER,
        retry_policy => $DEFAULT_RETRY_POLICY,
    );
}

1;
__END__

=encoding utf-8

=head1 NAME

CPAN::MirrorMerger - CPAN Mirror index merger for many legacy company internal CPAN mirrors.

=head1 SYNOPSIS

    use CPAN::MirrorMerger;
    use CPAN::MirrorMerger::Storage::Directory;

    my $merger = CPAN::MirrorMerger->new();

    $merger->add_mirror('http://backpan.perl.org/');
    $merger->add_mirror('https://cpan.metacpan.org/');

    $merger->merge()->save(
        CPAN::MirrorMerger::Storage::Directory->new(path => '/tmp/merged'),
    );

=head1 DESCRIPTION

CPAN::MirrorMerger is ...

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut

