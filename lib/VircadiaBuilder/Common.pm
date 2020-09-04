#!/usr/bin/perl -w
package VircadiaBuilder::Common;

use strict;
use Term::ANSIColor;
use Symbol qw(gensym);
use Exporter;
use IPC::Open3;
our (@EXPORT, @ISA);

my $timestamp = make_timestamp();
my $logdir    = "$ENV{HOME}/.vircadia-builder/logs/$timestamp";
my $log_fh;
our $collect_system_info;


BEGIN {
	@ISA = qw(Exporter);
	@EXPORT = qw( run info info_ok warning important debug fatal write_to_log init_log $collect_system_info  );
}

sub error_to_text {
	my ($retval, $errstr, $exec_failed) = @_;

	if ( $retval == -1 ) {
		return "failed to execute: $errstr";
	} elsif ( $retval & 127 ) {
		return sprintf("died with signal %d, %s coredump",
			($retval & 127), ( $retval & 128 ) ? 'with' : 'without');
	} else {
		if ( $exec_failed ) {
			return "failed to start with error '$errstr'";
		} else {
			return sprintf("exited with value %d", $retval >> 8)
		}
	}
}

sub secs_to_time {
	my ($secs) = @_;

	## Avoid POSIX::floor -- maybe unnecessarily?
	my $hours = sprintf("%d", $secs / 3600);
	$secs -= ($hours*3600);

	my $mins = sprintf("%d", $secs / 60);
	$secs -= ($mins * 60);

	return sprintf("%d:%02d:%02d", $hours, $mins, $secs);
}

sub run {
	my (@command) = @_;
	my %opts;

	if ( ref($command[0]) eq "HASH" ) {
		%opts = %{ shift(@command) }
	}

	my $cmdstr = join(' ', @command);
	debug("RUN: $cmdstr\n");
	my $out_buf = "";
	my $start = time;


	my ($in, $out);
	my $err = gensym(); # Ok, this is a horrible interface
	my $pid;

	eval {
		$pid = open3($in, $out, $err, @command);
	};
	if ( $@ =~ /^open3:/ ) {
		my $errstr = $@;
		$errstr =~ s/^open3://;

		if ( $opts{fail_ok} ) {
			warning("Failed to run '$cmdstr'. Command failed to start: $errstr\n");
			return;
		} else {
			fatal("Failed to run '$cmdstr'. Command failed to start: $errstr\n");
		}
	} elsif ( $@ ) {
		if (!$opts{fail_ok}) {
			fatal("Unrecognized error when trying to run '$cmdstr': $@\n");
		}
	}

	debug("Program started as PID $pid\n");

	close $in if ($in);
	my $select = IO::Select->new();
	$select->add($out);
	$select->add($err);

	CMDLOOP: while(my @ready = $select->can_read()) {
		foreach my $fh (@ready) {
			my $data = "";
			my $bytes = sysread($fh, $data, 16384);
			last CMDLOOP if ( $bytes == 0 );

			debug($data) unless $opts{no_log};

			if ( $fh == $out && $opts{keep_buf} ) {
				$out_buf .= $data;
			}

			if (!$opts{quiet}) {
				print $data        if ( $fh == $out && !$opts{keep_buf});
				print STDERR $data if ( $fh == $err );
			}
		}
	}

	waitpid($pid, 0);
	my $retval = $?;
	my $errstr = $!;

	debug("\nCommand '$cmdstr' " . error_to_text($retval, $errstr) . "  after " . secs_to_time(time - $start) . "\n");

	if ( $retval != 0 ) {
		if ( $opts{fail_ok} ) {
			warning( "Command '$cmdstr' " . error_to_text($?, $!) . "\n" );
		} else {
			fatal( "Command '$cmdstr' " . error_to_text($?, $!) . "\n" );
		}
	}

	return  wantarray ? split(/\n/, $out_buf) : $out_buf;
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
