package CPAN::MirrorMerger::Logger::Stderr;
use strict;
use warnings;
use feature qw/say/;

use parent qw/CPAN::MirrorMerger::Logger/;

sub write_log {
    my ($self, $msg) = @_;
    say STDERR "$msg";
}

1;
__END__
