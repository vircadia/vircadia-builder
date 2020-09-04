#!/usr/bin/perl -w
package VircadiaBuilder::Common;

use strict;
use Term::ANSIColor;

use Exporter;
our (@EXPORT, @ISA);

my $timestamp = make_timestamp();
my $logdir    = "$ENV{HOME}/.vircadia-builder/logs/$timestamp";
my $log_fh;
our $collect_system_info;


BEGIN {
	@ISA = qw(Exporter);
	@EXPORT = qw( info info_ok warning important debug fatal write_to_log init_log $collect_system_info  );
}

sub info {
	my $text = shift;
	print STDERR $text;

	write_to_log($text);
}

sub info_ok {
	my $text = shift;
	print STDERR color('bold green');
	print STDERR $text;
	print STDERR color('reset');

	write_to_log($text);
}

sub warning {
	my $text = shift;
	print STDERR color('bold red');
	print STDERR $text;
	print STDERR color('reset');

	write_to_log($text);
}

sub important {
	my $text = shift;
	print STDERR color('bold white');
	print STDERR $text;
	print STDERR color('reset');

	write_to_log($text);
}

sub debug {
	my $text = shift;
	write_to_log($text);
}

sub fatal {
	my $text = shift;

	write_to_log("FATAL ERROR!\n");
	write_to_log($text);


	if ( $collect_system_info ) {
		important("Collecting additional system info to aid with debugging...\n");
		read_from_cmd_into_file("$logdir/df"   , { fail_ok => 1, no_log => 1}, "df");
		read_from_cmd_into_file("$logdir/uname", { fail_ok => 1, no_log => 1}, "uname", "-a");
		read_from_cmd_into_file("$logdir/dmesg", { fail_ok => 1, no_log => 1}, "dmesg");

		system("cp", "/proc/cpuinfo", "$logdir/cpuinfo");
		system("cp", "/proc/meminfo", "$logdir/meminfo");

	} else {
		important("To aid with debugging, please re-run with the --collect-info argument.\n");
	}

	close $log_fh;


	my $compressed = "vircadia-builder-error-$timestamp.tar.gz";
	run( { fail_ok => 1, no_log => 1, quiet => 1 }, "tar", "-czf", $compressed, $logdir);


	print STDERR color('bold red');
	print STDERR "\nFatal error:\n";
	print STDERR $text;
	print STDERR "\n\n";
	print STDERR color('reset');
	print STDERR "Logs have been collected in ";
	print STDERR color('bold white');

	if ( -f $compressed ) {
		print STDERR "$compressed\n";
	} else {
		print STDERR "$logdir\n";
	}

	print STDERR "Please notify Dale Glass#8576 on Discord of this problem.\n";
	print STDERR color('reset');
	exit 1;
}

sub write_to_log {
	my $text = shift;

	if ( $log_fh && fileno($log_fh) ) {
		print $log_fh $text;
	}
}


sub init_log() {
	mkdir("$ENV{HOME}/.vircadia-builder");
	mkdir("$ENV{HOME}/.vircadia-builder/logs");
	mkdir($logdir);

	open($log_fh, ">", "$logdir/log.txt") or warn("Couldn't create log '$logdir/log.txt': $!");
}


sub make_timestamp {
	# Avoid need for strftime
	my ($sec, $min, $hour, $mday, $month, $year) = localtime(time);
	return sprintf("%04i-%02i-%02i_T%02i_%02i_%02i", $year + 1900, $month, $mday, $hour, $min, $sec);
}

1;
