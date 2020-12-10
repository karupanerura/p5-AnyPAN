package AnyPAN::CLI::FileStorage;
use strict;
use warnings;

use parent qw/AnyPAN::CLI/;

use Class::Accessor::Lite ro => [qw/output_dir/];

use Pod::Usage qw/pod2usage/;
use AnyPAN::Storage::Directory;

sub create_option_specs {
    my $class = shift;
    my @specs = $class->SUPER::create_option_specs();
    return (
        @specs,
        'output-dir|o=s',
    );
}

sub convert_options {
    my ($class, $opts, $argv) = @_;

    # required option
    pod2usage(1) unless $opts->{'output-dir'};

    my %args = $class->SUPER::convert_options($opts, $argv);
    $args{output_dir} = $opts->{'output-dir'};
    return %args;
}

sub create_storage {
    my $self = shift;
    return AnyPAN::Storage::Directory->new(
        path => $self->output_dir,
    );
}

1;
__END__
