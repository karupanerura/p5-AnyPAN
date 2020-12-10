package AnyPAN;
use strict;
use warnings;

our $VERSION = "0.08";

1;
__END__

=encoding utf-8

=for stopwords DarkPAN

=head1 NAME

AnyPAN - CPAN Mirror and DarkPAN merging toolkit

=head1 SYNOPSIS

    use AnyPAN::Merger;
    use AnyPAN::Storage::Directory;

    my $merger = AnyPAN::Merger->new();

    $merger->add_source('http://backpan.perl.org/');
    $merger->add_source('https://cpan.metacpan.org/');

    $merger->merge()->save_with_included_packages(
        AnyPAN::Storage::Directory->new(path => '/tmp/merged'),
    );

=head1 DESCRIPTION

AnyPAN is ...

=head1 LICENSE

Copyright (C) karupanerura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

karupanerura E<lt>karupa@cpan.orgE<gt>

=cut

