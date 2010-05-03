#!/usr/bin/perl

use strict;
use warnings;
use subs qw(process);

my $source = $ARGV[0];
unless (-d $source) {
	print "$source is not a directory\n";
	exit 1;
}

my $target = "$source/../PDFs";
unless (-d $target) {
	print "$target is not a directory\n";
	exit 1;
}

process $target, $source;

sub process {
	my ($target, $source) = @_;
	print "process($source, $target);\n";
	
	rename $target, $source if -f $target && $target =~ /\.pdf$/i;
	
	if (-d $target) {
		opendir(DIR, $target);
		foreach (readdir(DIR)) {
			process "$target/$_", "$source/$_" if $_ !~ /(?:\.|\.\.)$/;
		}
		closedir(DIR);
		rmdir $target;
	}
}

exit 0;
