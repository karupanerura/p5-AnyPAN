package AnyPAN::PackageInfo;
use strict;
use warnings;

use version;

use Class::Accessor::Lite ro => [qw/source module path/], new => 1;

my $ZERO_VERSION = version->declare('0.000_000');

sub version :method { shift->{version} } ## XXX: avoid name conflict

sub compareble_version {
    my $self = shift;
    return $ZERO_VERSION if $self->version eq 'undef';

    my $compareble_version = eval { ::version->parse($self->version) };
    return $self->{compareble_version} //= $compareble_version // $ZERO_VERSION;
}

sub canonicalized_path {
    my $self = shift;
    return $self->{canonicalized_path} if exists $self->{canonicalized_path};

    my $path = $self->path;

    # XXX: fix backpan's path
    if ($path !~ m![A-Z0-9]/[A-Z0-9]{2}/!) {
        my $p2 = substr $path, 0, 2;
        my $p1 = substr $p2, 0, 1;
        $path = "$p1/$p2/$path";
    }

    return $self->{canonicalized_path} = $path;
}

1;
__END__
