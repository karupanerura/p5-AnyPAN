package TestUtil;
use strict;
use warnings;

use Exporter 5.57 'import';
our @EXPORT_OK = qw/source_url/;

use Path::Tiny ();
use FindBin ();

my $source_dir = Path::Tiny->new($FindBin::Bin)->child('testdata', 'sources');

sub source_url {
    my $name = shift;
    return 'file://'.$source_dir->child($name);
}

1;
__END__
