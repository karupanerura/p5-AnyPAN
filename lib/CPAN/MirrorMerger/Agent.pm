package CPAN::MirrorMerger::Agent;
use strict;
use warnings;

use Class::Accessor::Lite ro => [qw/furl retry_policy logger/];

use Furl;
use Furl::Response;
use Path::Tiny ();
use CPAN::MirrorMerger::Logger::Null;

sub new {
    my ($class, %args) = @_;
    my $retry_policy = delete $args{retry_policy};
    my $logger = delete $args{logger} || CPAN::MirrorMerger::Logger::Null->instance();
    bless {
        furl => Furl->new(%args),
        retry_policy => $retry_policy,
        logger => $logger,
    }, $class;
}

sub download {
    my ($self, $url, $path) = @_;

    # file:///...
    if ($url->scheme eq 'file') {
        $self->logger->debug("copy @{[ $url->file ]} to $path");

        my $src = Path::Tiny->new($url->file);
        $src->copy($path);
        return Furl::Response->new(0, 200, 'OK', [
            'Content-Type'   => 'application/octet-stream',
            'Content-Length' => -s $src,
        ], 'DUMMY');
    }

    return $self->retry_policy->apply_and_doit(sub {
        my ($retry_count, $e) = @_;
        $self->logger->warn("retry request: $retry_count", { error => $e }) if $retry_count;
        $self->logger->debug("download $url to $path");

        my $tempfile = Path::Tiny->tempfile();

        my $fh = $tempfile->openw_raw();
        my $res = $self->furl->request(
            method     => 'GET',
            url        => $url,
            write_file => $fh,
        );
        close $fh
            or die "$!: $tempfile";

        unless ($res->is_success) {
            $self->logger->debug("error status: @{[ $res->status_line ]}");
            if ($res->status == 404) {
                CPAN::MirrorMerger::Agent::Exception::NotFound->throw(
                    message => "Failed to download: $url (@{[ $res->status_line ]})",
                );
            }
            die "Failed to download: $url (@{[ $res->status_line ]})";
        }

        $tempfile->copy($path);

        return $res;
    });
}

package # hide from PAUSE
    CPAN::MirrorMerger::Agent::Exception::NotFound;

use parent qw/Exception::Tiny/;


1;
__END__
