package TestLogger;
use strict;
use warnings;

use parent qw/CPAN::MirrorMerger::Logger/;

use Test2::API qw/context/;

my $_INSTANCE = __PACKAGE__->new(level => $ENV{AUTHOR_TESTING} ? 'debug' : 'info');

sub instance { $_INSTANCE }

sub write_log {
    my ($self, $msg) = @_;
    my $ctx = context();
    $ctx->note($msg);
    $ctx->release;
}

1;
