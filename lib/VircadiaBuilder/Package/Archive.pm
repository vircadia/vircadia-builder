#!/usr/bin/perl

package VircadiaBuilder::Package::Archive;
use strict;
use warnings;
use base 'VircadiaBuilder::Package';
use VircadiaBuilder::Common;
use File::Basename qw(dirname basename);
use Data::Dumper qw(Dumper);

sub new {
    my ($class) = @_;
    my $self = $class->SUPER::new(@_);
    bless $self, $class;

    $self->{compressor} = "xz";
    return $self;
}


sub get_output_file {
    my ($self) = @_;
    return $self->{output_file} if ( $self->{output_file });

    my $filename = $self->{install_dir};

    if ( $self->{compressor} eq "xz" ) {
        $filename .= ".tar.xz";
    } elsif ( $self->{compressor} eq "zstd") {
        $filename .= ".tar.zstd";
    } else {
        fatal("Internal error: unknown compressor $self->{compressor}");
    }

    return $filename;
}

sub build {
    my ($self) = @_;
    if (!$self->is_complete()) {
        fatal("Internal error: Missing parameters for generating archive");
    }

    
    my $compressor_arg;
    my $dest_filename = $self->get_output_file();
    my $base_dir     = dirname($self->{install_dir});
    my $rel_inst_dir = basename($self->{install_dir});

    if ( $self->{compressor} eq "xz" ) {
        $compressor_arg = "--xz";

        # Enable parallel compression
        $ENV{XZ_OPT} = "-T0"; 
    } elsif ( $self->{compressor} eq "zstd") {
        $compressor_arg = "--zstd";

        # Parallel compression, maximum normal compression mode.
        $ENV{ZSTD_NBTHREADS} = 0;
        $ENV{ZSTD_CLEVEL} = 19;
    } else {
        fatal("Internal error: unknown compressor $self->{compressor}");
    }

    $self->_make_install_script();

    run("tar", "-c", $compressor_arg,
        "-f", $dest_filename,
        "-C", $base_dir,
        $rel_inst_dir );

    return 1;
}

sub _make_install_script {
    my ($self) = @_;

    my @packages = $self->get_dependencies;

    open(my $script, '>', $self->{install_dir} . "/install.sh");
    chmod(0755, $script);
    print $script "#!/bin/bash\n\n";
    print $script "dnf install -y " . join(' ', @packages) . "\n";
    close $script;
}


1;