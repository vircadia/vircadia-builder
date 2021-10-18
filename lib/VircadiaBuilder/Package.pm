#!/usr/bin/perl -w
use warnings;
use strict;

package VircadiaBuilder::Package;

=pod

=head1 NAME

VircadiaBuilder::Package;

=head1 DESCRIPTION

This module is the base for package generation.

=head1 FUNCTIONS

=item set_install_dir($dir)

Sets the install directory

This is where Vircadia has been installed, and where the files
will be copied from for packaging.

=item set_version($version)

Sets the version of the software

This may be included in the package.

=item set_packaging_data($data)

Sets the packaging data

This is a structure from the .conf that includes dependency
lists and other packaging metadata.

=item is_complete

Verifies that all the required parameters were set. Used
internally for self-checks to ensure build() has everything
it needs.

Derived classes should call the base version, then add any
additional checks they need on top of that.

=item get_dependencies

Returns the dependency list based on the set data, and the
components to be packaged.

=item set_output_file($file)

Sets the output file explicitly.

If this function not used, the filename will be auto-generated,
and can be obtained with get_output_file()

=item get_output_file()

If set_output_file was called, it returns whatever value it was passed.

Otherwise returns an automatically generated filename.

=cut

sub new {
    my ($class) = @_;

    my $self = {};

    bless $self, $class;
    return $self;
}




sub set_install_dir {
    my ($self, $val) = @_;
    $self->{install_dir} = $val;
}


sub set_version {
    my ($self, $val) = @_;
    $self->{version} = $val;
}

sub set_packaging_data {
    my ($self, $val) = @_;
    $self->{packaging_data} = $val;
}

sub set_targets {
    my ($self, @vals) = @_;
    $self->{targets} = \@vals;
}

sub set_git_repo {
    my ($self, $val) = @_;
    $self->{git_repo} = $val;
}

sub set_git_commit {
    my ($self, $val) = @_;
    $self->{git_commit} = $val;
}

sub set_output_file {
    my ($self, $file) = @_;
    $self->{output_file} = $file;
}

sub is_complete {
    my ($self) = @_;

    return
        exists $self->{install_dir} &&
        exists $self->{version} &&
        exists $self->{packaging_data} &&
        exists $self->{targets} &&
        exists $self->{git_repo} &&
        exists $self->{git_commit};
}


sub get_dependencies {
    my ($self) = @_;

    my %packages;
    my $deps = $self->{packaging_data}->{dependencies};

    foreach my $target (@{ $self->{targets}}) {
        if ( exists $deps->{$target} ) {
            foreach my $pkg (@{$deps->{$target}}) {
                $packages{$pkg} = 1;
            }
        }
    }

    return sort keys %packages;
}

sub get_output_file {
    fatal("Internal error: method must be overriden");
}

sub build {
    fatal("Internal error: method must be overriden");
}

1;