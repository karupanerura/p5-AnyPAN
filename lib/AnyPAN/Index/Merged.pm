package AnyPAN::Index::Merged;
use strict;
use warnings;

use parent qw/AnyPAN::Index/;

use Class::Accessor::Lite
    ro => [qw/multiplex_index sources source_cache logger/];

sub save_with_included_packages {
    my ($self, $storage) = @_;

    for my $source (@{ $self->sources }) {
        my $index = $self->source_cache->get_or_fetch_index($source);

        my $previous_package_path = '';
        for my $package_info (@{ $index->packages }) {
            # skip contiguous packages for performance
            next if $previous_package_path eq $package_info->canonicalized_path();
            $previous_package_path = $package_info->canonicalized_path();

            # skip exists packages for performance
            my $save_key = $source->package_path($package_info->canonicalized_path);
            next if $storage->exists($save_key);

            my $package_path = eval {
                $self->source_cache->get_or_fetch_package($source, $package_info);
            };
            if (my $e = $@) {
                if (AnyPAN::Agent::Exception::NotFound->caught($e)) {
                    $self->logger->warn("skip package @{[ $package_info->path ]} on @{[ $source->name ]}");
                    next; # skip it
                }
                $self->logger->error("failed to fetch package @{[ $package_info->path ]} on @{[ $source->name ]}");
                die $e;
            }

            $storage->copy($package_path, $save_key);
        }
    }
    $self->save($storage);
}

1;
__END__
