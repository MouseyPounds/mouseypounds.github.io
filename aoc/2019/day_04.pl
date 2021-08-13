#!/bin/perl
#
# https://adventofcode.com/2019/day/4

use strict;
use POSIX;

my $min = 402328;
my $max = 864247;
my $count = 0;
my $count2 = 0;

for (my $i = $min; $i <= $max; $i++) {
	my @digits = split('', "$i");
	my $dbl = 0;
	my %counts = ();
	my $last = 0;
	my $prob = 0;
	foreach my $d (@digits) {
		if ($d < $last) {
			$prob = 1;
			last;
		} elsif (not $dbl and $d == $last) {
			$dbl = 1;
		}
		$counts{$d} = 0 if (not exists $counts{$d});
		$counts{$d}++;
		$last = $d;
	}
	if ($dbl and not $prob) {
		#print "$i";
		$count++;
		foreach my $c (keys %counts) {
			if ($counts{$c} == 2) {
				$count2++;
				#print " p2 qual";
				last;
			}
		}
		#print "\n";
	};
}

print "\nTotal Pt 1: $count\nTotal Pt 2: $count2\n";