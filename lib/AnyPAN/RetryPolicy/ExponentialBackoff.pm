package AnyPAN::RetryPolicy::ExponentialBackoff;
use strict;
use warnings;

use parent qw/AnyPAN::RetryPolicy/;

use Time::HiRes ();

use Class::Accessor::Lite ro => [qw/max_retries interval jitter_factor/];

sub apply {
    my ($self, $code) = @_;
    return sub {
        my $wantarray = wantarray;

        my $e;
        my $retry_count = 0;
        my $interval = $self->interval * 1_000_000; # usec

        my @ret;
        while ($retry_count < $self->max_retries) {
            eval {
                if ($wantarray) {
                    @ret = $code->($retry_count, $e);
                } elsif (defined $wantarray,) {
                    $ret[0] = $code->($retry_count, $e);
                } else {
                    $code->($retry_count, $e);
                }
            };
            if ($@) {
                # retry
                $e = $@;
                $retry_count++;

                $interval *= 2;
                if ($self->jitter_factor) {
                    my $delta = $interval * $self->jitter_factor;
                    my $min   = $interval - $delta;
                    $interval = $min + rand(1+2*$delta);
                }

                Time::HiRes::usleep($interval);
                next;
            }

            $e = undef;
            last;
        }
        die $e if $e;

        return $wantarray ? @ret : $ret[0];
    };
}

1;
__END__
