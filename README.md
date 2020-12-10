[![MetaCPAN Release](https://badge.fury.io/pl/AnyPAN.svg)](https://metacpan.org/release/AnyPAN) [![Actions Status](https://github.com/karupanerura/p5-AnyPAN/workflows/test/badge.svg)](https://github.com/karupanerura/p5-AnyPAN/actions)
# NAME

AnyPAN - CPAN Mirror and DarkPAN merging toolkit

# SYNOPSIS

    use AnyPAN::Merger;
    use AnyPAN::Storage::Directory;

    my $merger = AnyPAN::Merger->new();

    $merger->add_source('http://backpan.perl.org/');
    $merger->add_source('https://cpan.metacpan.org/');

    $merger->merge()->save_with_included_packages(
        AnyPAN::Storage::Directory->new(path => '/tmp/merged'),
    );

# DESCRIPTION

AnyPAN is ...

# LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

karupanerura <karupa@cpan.org>
