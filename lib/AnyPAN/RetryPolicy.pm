package AnyPAN::RetryPolicy;
use strict;
use warnings;

use Class::Accessor::Lite new => 1;

sub apply { require Carp; Carp::croak('this is abstract method') }

sub apply_and_doit {
    my $self = shift;
    my $code = shift;
    return $self->apply($code)->();
}

1;
__END__
