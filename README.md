[![MetaCPAN Release](https://badge.fury.io/pl/CPAN-MirrorMerger.svg)](https://metacpan.org/release/CPAN-MirrorMerger) [![Actions Status](https://github.com/karupanerura/p5-CPAN-MirrorMerger/workflows/test/badge.svg)](https://github.com/karupanerura/p5-CPAN-MirrorMerger/actions)
# NAME

CPAN::MirrorMerger - CPAN Mirror index merger for many legacy company internal CPAN mirrors.

# SYNOPSIS

    use CPAN::MirrorMerger;
    use CPAN::MirrorMerger::Storage::Directory;

    my $merger = CPAN::MirrorMerger->new();

    $merger->add_mirror('http://backpan.cpantesters.org/');
    $merger->add_mirror('https://cpan.metacpan.org/');

    $merger->merge()->save(
        CPAN::MirrorMerger::Storage::Directory->new(path => '/tmp/merged'),
    );

# DESCRIPTION

CPAN::MirrorMerger is ...

# LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

karupanerura <karupa@cpan.org>
