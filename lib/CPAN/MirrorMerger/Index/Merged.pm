package CPAN::MirrorMerger::Index::Merged;
use strict;
use warnings;

use parent qw/CPAN::MirrorMerger::Index/;

use Class::Accessor::Lite
    ro => [qw/multiplex_index mirrors mirror_cache logger/];

sub save_with_included_packages {
    my ($self, $storage) = @_;

    for my $mirror (@{ $self->mirrors }) {
        my $index = $self->mirror_cache->get_or_fetch_index($mirror);

        my $previous_package_path = '';
        for my $package_info (@{ $index->packages }) {
            # skip contiguous packages for performance
            next if $previous_package_path eq $package_info->canonicalized_path();
            $previous_package_path = $package_info->canonicalized_path();

            # skip exists packages for performance
            my $save_key = $mirror->package_path($package_info->canonicalized_path);
            next if $storage->exists($save_key);

            my $package_path = eval {
                $self->mirror_cache->get_or_fetch_package($mirror, $package_info);
            };
            if (my $e = $@) {
                if (CPAN::MirrorMerger::Agent::Exception::NotFound->caught($e)) {
                    $self->logger->warn("skip package @{[ $package_info->path ]} on @{[ $mirror->name ]}");
                    next; # skip it
                }
                $self->logger->error("failed to fetch package @{[ $package_info->path ]} on @{[ $mirror->name ]}");
                die $e;
            }

            $storage->copy($package_path, $save_key);
        }
    }
    $self->save($storage);
}

1;
__END__
