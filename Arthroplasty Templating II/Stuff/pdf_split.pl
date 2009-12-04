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
if (-d $target) {
	print "$target already exists\n";
	exit 1;
}

process $source, $target;

sub process {
	my ($source, $target) = @_;
	print "process($source, $target);\n";
	
	rename $source, $target if -f $source && $source =~ /\.pdf$/i;
	
	if (-d $source) {
		mkdir $target;
		opendir(DIR, $source);
		foreach (readdir(DIR)) {
			process "$source/$_", "$target/$_" if $_ !~ /(?:\.|\.\.)$/;
		}
		closedir(DIR);
	}
}

exit 0;
