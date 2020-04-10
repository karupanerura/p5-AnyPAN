package CPAN::MirrorMerger::Logger::Null;
use strict;
use warnings;
use feature qw/say/;

use parent qw/CPAN::MirrorMerger::Logger/;

my $_INSTANCE = __PACKAGE__->new(level => 'error');

sub instance { $_INSTANCE }

sub write_log {}  # nop
sub format_log {} # nop

1;
__END__
