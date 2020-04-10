package TestUtil;
use strict;
use warnings;

use Exporter 5.57 'import';
our @EXPORT_OK = qw/mirror_url/;

use Path::Tiny ();
use FindBin ();

my $mirror_dir = Path::Tiny->new($FindBin::Bin)->child('testdata', 'mirrors');

sub mirror_url {
    my $name = shift;
    return 'file://'.$mirror_dir->child($name);
}

1;
__END__
