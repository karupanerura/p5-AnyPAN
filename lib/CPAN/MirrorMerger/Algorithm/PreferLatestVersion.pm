package CPAN::MirrorMerger::Algorithm::PreferLatestVersion;
use strict;
use warnings;

use Class::Accessor::Lite ro  => [qw/mirror_cache logger/];

use List::UtilsBy qw/rev_nsort_by sort_by/;
use Time::Moment;
use CPAN::MirrorMerger::Index::Merged;
use CPAN::MirrorMerger::Logger::Null;

sub new {
    my ($class, %args) = @_;
    $args{logger} ||= CPAN::MirrorMerger::Logger::Null->instance();
    return bless \%args => $class;
}

sub merge {
    my ($self, @mirrors) = @_;
    my $now = Time::Moment->now_utc();

    my %multiplex_index = ();
    for my $mirror (@mirrors) {
        my $index = $self->mirror_cache->get_or_fetch_index($mirror);
        for my $package_info (@{ $index->packages }) {
            $self->logger->debug("add package @{[ $package_info->path ]} from @{[ $mirror->name ]}");

            my $candidates = ($multiplex_index{$package_info->module} ||= []);
            if (@$candidates == 0) {
                push @$candidates => $package_info;
                next;
            }

            # optimize for performance
            if ($candidates->[0]->compareble_version <= $package_info->compareble_version) {
                unshift @$candidates => $package_info;
                next;
            } elsif ($candidates->[-1]->compareble_version >= $package_info->compareble_version) {
                push @$candidates => $package_info;
                next;
            }

            use sort 'stable';
            push @$candidates => $package_info;
            @$candidates = rev_nsort_by { $_->compareble_version } @$candidates;
        }
    }

    my %headers = (
        File           => '02packages.details.txt',
        URL            => '/modules/02packages.details.txt',
        Description    => 'Merged CPAN Mirrors ('.(join ', ', sort map $_->name, @mirrors).')',
        Columns        => 'package name, version, path',
        'Intended-For' => 'Automated fetch routines, namespace documentation.',
        'Written-By'   => 'CPAN::MirrorMerger',
        'Line-Count'   => scalar keys %multiplex_index,
        'Last-Updated' => $now->strftime('%a, %d %b %Y %H:%M:%S %Z'),
    );
    my @packages = map { $multiplex_index{$_}[0] } sort_by { uc } keys %multiplex_index;

    return CPAN::MirrorMerger::Index::Merged->new(
        headers         => \%headers,
        packages        => \@packages,
        mirrors         => \@mirrors,
        mirror_cache    => $self->mirror_cache,
        multiplex_index => \%multiplex_index,
        logger          => $self->logger,
    );
}


1;
__END__
