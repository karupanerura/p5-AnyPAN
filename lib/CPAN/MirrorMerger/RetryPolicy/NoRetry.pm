package CPAN::MirrorMerger::RetryPolicy::NoRetry;
use strict;
use warnings;

use parent qw/CPAN::MirrorMerger::RetryPolicy/;

my $_INSTANCE = __PACKAGE__->new();
sub instance { $_INSTANCE }

sub apply { $_[1] }

1;
__END__
