package CPAN::MirrorMerger::Index;
use strict;
use warnings;

use Class::Accessor::Lite ro => [qw/headers packages/], new => 1;

use CPAN::MirrorMerger::PackageInfo;

use IO::Uncompress::Gunzip;

my @WELLKNOWN_HEADERS = qw/
    File
    URL
    Description
    Columns
    Intended-For
    Written-By
    Line-Count
    Last-Updated
/;

sub parse {
    my ($class, $index_path, $mirror) = @_;

    my $fh = IO::Uncompress::Gunzip->new($index_path->openr_raw);

    my %headers;
    my @packages;

    my $context = 'header';
    while (defined(my $line = <$fh>)) {
        chomp $line;
        if ($line eq '') {
            $context = 'index';
            next;
        }

        if ($context eq 'header') {
            my ($key, $value) = split /\s*:\s*/, $line;
            $headers{$key} = $value;
        } elsif ($context eq 'index') {
            my ($module, $version, $path) = split /\s+/, $line;

            push @packages => CPAN::MirrorMerger::PackageInfo->new(
                mirror  => $mirror,
                module  => $module,
                version => $version,
                path    => $path,
            );
        }
    }

    return $class->new(
        headers  => \%headers,
        packages => \@packages,
    );
}

sub save {
    my ($self, $storage) = @_;

    my $tempfile = Path::Tiny->tempfile();

    # write index
    my $fh = $tempfile->openw_raw();
    $self->_write_to($fh);
    close $fh or die "$!: $tempfile";

    $storage->copy($tempfile, 'modules/02packages.details.txt.gz');
}

sub _write_to {
    my ($self, $fh) = @_;

    my %header = %{ $self->headers };
    for my $name (@WELLKNOWN_HEADERS) {
        my $value = delete $header{$name};
        printf $fh "%-14s%s\n", "$name:", $value;
    }
    for my $name (sort keys %header) {
        my $value = $header{$name};
        printf $fh "%-14s%s\n", "$name:", $value;
    }
    print $fh "\n";

    for my $package_info (@{ $self->packages }) {
        printf $fh "%-35s %6s  %s\n", $package_info->module, $package_info->version, $package_info->path;
    }
}

1;
__END__
