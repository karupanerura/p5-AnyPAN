package CPAN::MirrorMerger::Logger;
use strict;
use warnings;

use Class::Accessor::Lite ro => [qw/level/], new => 1;

use Data::Dumper ();
use Time::Moment;

my %LEVEL_MAP = (
    error => 1000,
    warn  =>  500,
    info  =>  100,
    debug =>   10,
);

sub write_log { require Carp; Carp::croak('abstruct method') }

sub format_log {
    my ($self, $now, $level, $msg, $attr) = @_;
    unless (defined $attr) {
        return sprintf '%s [%s] %s', $now->to_string(), uc $level, $msg;
    }

    my $attr_str = do {
        local $Data::Dumper::Terse = 1;
        local $Data::Dumper::Indent = 0;
        local $Data::Dumper::Sortkeys = 1;
        Data::Dumper::Dumper($attr);
    };
    return sprintf '%s [%s] %s (%s)', $now->to_string(), uc $level, $msg, $attr_str;
}

sub _log {
    my ($self, $level, $msg, $attr) = @_;
    return if $LEVEL_MAP{$level} < $LEVEL_MAP{$self->level};

    my $now = Time::Moment->now_utc();
    my $payload = $self->format_log($now, $level, $msg, $attr);
    $self->write_log($payload);
}

sub error {
    my ($self, $msg, $attr) = @_;
    $self->_log(error => $msg, $attr);
}

sub warn {
    my ($self, $msg, $attr) = @_;
    $self->_log(warn => $msg, $attr);
}

sub info {
    my ($self, $msg, $attr) = @_;
    $self->_log(info => $msg, $attr);
}

sub debug {
    my ($self, $msg, $attr) = @_;
    $self->_log(debug => $msg, $attr);
}

1;
__END__
