package AnyPAN::Source;
use strict;
use warnings;

use URI;
use URI::Escape ();

use Class::Accessor::Lite ro => [qw/name base_url/];

sub new {
    my ($class, $url) = @_;
    my $base_url = URI->new($url)->canonical();

    my $scheme = $base_url->scheme;
    my $name;
    if ($scheme eq 'http' || $scheme eq 'https' || $scheme eq 'ftp') {
        $name = $base_url->host;
    } elsif ($scheme eq 'file') {
        $name = URI::Escape::uri_escape_utf8($base_url->file);
    } else {
        die "Unknown source URL scheme: $url";
    }

    bless {
        name     => $name,
        base_url => $base_url,
    } => $class;
}

sub index_url {
    my $self = shift;
    my $index_url = $self->base_url->clone();
    $index_url->path(_join_path($index_url->path, 'modules/02packages.details.txt.gz'));
    return $index_url;
}

sub package_url {
    my ($self, $path) = @_;

    my $package_url = $self->base_url->clone();
    $package_url->path(_join_path($package_url->path, $self->package_path($path)));
    return $package_url;
}

sub package_path {
    my ($self, $path) = @_;
    return "authors/id/$path";
}

sub _join_path {
    my $path = join '/', @_;
    $path =~ s!/+!/!g; # canonicalize
    return $path;
}

1;
__END__
