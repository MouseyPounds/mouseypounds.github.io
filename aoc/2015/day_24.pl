#!/bin/perl -w
#
# https://adventofcode.com/2015/day/24
#
# We originally started with a customized permutator that also cut the list into the required number of groups, but it
# turned out to be too slow and memory intensive. That combined with the realization that we needed combinations rather
# than permutations led to just using a library function for that part.

use strict;
use POSIX;
use List::Util qw(sum product max);
use Math::Combinatorics;

my $debugging = 0;

$| = 1;

print "2015 Day 24\n";
my $puzzle = do { local $/; <DATA> }; # slurp it
my @weights = split("\n", $puzzle);

print "\nPart 1:\n";
(my ($pkg, $qe)) = pack_sleigh(\@weights, 3);
print "P1: Optimal first group has $pkg packages with a quantum entanglement of $qe\n";

print "\nPart 2:\n";
($pkg, $qe) = pack_sleigh(\@weights, 4);
print "P2: Optimal first group has $pkg packages with a quantum entanglement of $qe\n";

sub pack_sleigh {
	my $packages = shift;	# Array Ref of the weight values
	my $num_groups = shift;	# Scalar for how many groups
	
	my $weight_goal = sum(@$packages) / $num_groups;
	print "Group weight goal: $weight_goal\n";
	# We are going to grab combinations of larger & larger sizes until we hit our weight goal
	my $start = POSIX::ceil($weight_goal / max(@$packages));
	my $min_qe = '';
	my $p;
	for ($p = $start; $p <= $#$packages; $p++) {
		my $coms = Math::Combinatorics->new(count => $p, data => $packages);
		while (my @c = $coms->next_combination()) {
			my $weight = sum(@c);
			printf "Checking group size of $p: W = %3d  Min QE = $min_qe\r", $weight;
			if ($weight == $weight_goal) {
				# Here is where we should be verifying that the rest of the packages split correctly.
				my $qe = product(@c);
				$min_qe = $qe if ($min_qe eq '' or $qe < $min_qe);
			}
		}
		last unless ($min_qe eq '');
	}
	return ($p, $min_qe);
}

__DATA__
1
3
5
11
13
17
19
23
29
31
41
43
47
53
59
61
67
71
73
79
83
89
97
101
103
107
109
113