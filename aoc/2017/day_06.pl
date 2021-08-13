#!/bin/perl -w
#
# https://adventofcode.com/2017/day/6

use strict;
use POSIX;

print "2017 Day 6\n";
my $puzzle = do { local $/; <DATA> }; # slurp it

(my ($steps, $length)) = redistribute(split(" ", $puzzle));
print "P1: Infinite loop detected after redistibuting for $steps cycles.\n";
print "P2: The length of the loop is $length cycles.\n";

sub redistribute {
	my %state = ();
	my $cycle = 0;
	my $size = scalar(@_);
	my $length = 0;
	
	while (1) {
		my $current = join(",", @_);
		return $cycle, $cycle - $state{$current} if (exists $state{$current});

		$state{$current} = $cycle++;
		my $max_index = -1;
		my $max_val = -1;
		for (my $i = 0; $i <= $#_; $i++) {
			if ($_[$i] > $max_val) {
				$max_val = $_[$i];
				$max_index = $i;
			}
		}

		my $q = POSIX::floor($max_val / $size);
		my $r = $max_val % $size;
		$_[$max_index] = 0;
		foreach my $inc (1 .. $r) {
			$max_index = ($max_index + 1) % $size;
			$_[$max_index] += $q + 1;
		}
		foreach my $inc (1 .. ($size - $r)) {
			$max_index = ($max_index + 1) % $size;
			$_[$max_index] += $q;
		}
	}
}

__DATA__
4	1	15	12	0	9	9	5	5	8	7	3	14	5	12	3