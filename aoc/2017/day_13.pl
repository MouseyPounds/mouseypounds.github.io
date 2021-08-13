#!/bin/perl -w
#
# https://adventofcode.com/2017/day/13
#
# Part 2 solution takes 2-3 min on dinosaur system. There's probably some clever way to exploit the Chinese
# Remainder Thm to cut that time down, but we just didn't want to put in the work to figure it out.

use strict;
use List::Util qw(reduce);

print "2017 Day 13\n\n";
my $puzzle = do { local $/; <DATA> }; # slurp it
my %scanners = map { /(\d+)/g } split('\n', $puzzle);

my $severity = calc_severity(\%scanners);
print "P1: The total severity of the trip is $severity\n";

my $delay;
my $limit = 1e10;
for ($delay = 0; $delay < $limit; $delay++) {
	$severity = calc_severity(\%scanners, $delay);
	last unless (defined $severity);
}
if ($delay < $limit) {
	print "P2: Earliest delay for a safe trip is $delay ps.\n";
} else {
	print "P2: No safe trips found in delays less than $limit ps.\n";
}

# Examining the pattern, a scanner at layer n, depth d will catch you if n % (2d - 2) == 0.
# So we just make that check for every scanner; for the dealy factor in part 2, it is just added to n.
# Note that you can still have severity 0 if you are only caught by a sensor at layer 0 so we return undef instead;
sub calc_severity {
	my $scan_ref = shift;
	my $delay = shift;
	
	$delay = 0 unless (defined $delay);
	my $severity = 0;
	my $caught = 0;
	foreach my $k (keys %$scan_ref) {
		if ( ($k + $delay) % (2 * $scan_ref->{$k} - 2) == 0 ) {
			$severity += $k * $scan_ref->{$k};
			$caught = 1;
		}
	}
	return $caught ? $severity : undef;
}
	

__DATA__
0: 3
1: 2
2: 4
4: 4
6: 5
8: 6
10: 8
12: 8
14: 6
16: 6
18: 9
20: 8
22: 6
24: 10
26: 12
28: 8
30: 8
32: 14
34: 12
36: 8
38: 12
40: 12
42: 12
44: 12
46: 12
48: 14
50: 12
52: 12
54: 10
56: 14
58: 12
60: 14
62: 14
64: 14
66: 14
68: 14
70: 14
72: 14
74: 20
78: 14
80: 14
90: 17
96: 18