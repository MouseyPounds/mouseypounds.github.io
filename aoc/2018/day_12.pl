#!/bin/perl -w
#
# https://adventofcode.com/2018/day/12

use strict;
use List::Util qw(max);

print "2018 Day 12\n\n";
my $initial = "";
my %rules = ();
while (<DATA>) {
	if (/^initial state: (.*)/) {
		$initial = $1;
	} elsif (/(.*) => (.)/) {
		$rules{$1} = $2;
	}
}

my $max_gens = 20;
my $sum = advance_generations($initial, $max_gens);
print "P1: After $max_gens generations, the sum of pot numbers which contain plants is $sum.\n";

$max_gens = 5e10;
$sum = advance_generations($initial, $max_gens);
print "P2: After $max_gens generations, the sum of pot numbers which contain plants is $sum.\n";

# The generation advancement is fairly straightforward and of course will not scale to the ridiculous
# numbers necessary for part 2. Note that we expand the string by one character in each direction at
# each iteration because of the rules "...#. => #" and ".#... => #" which were present in our input.
# The way we handle part 2 is to look for a stable pattern where the sum grows by a consistent amount.
# This naively assumes a very simple repeating pattern and is probably not a good general solution.

sub advance_generations {
	my $plants = shift;
	my $max_gens = shift;
	
	my $last_sum = 0;
	my $sum = 0;

	my $last_diff = 0.1;
	my $repeats = 0;
	my $convergence_threshold = 5;
	
	for (my $gen = 1; $gen <= $max_gens; $gen++) {
		my $last = ".$plants.";
		$last_sum = $sum;
		$plants = $last;
		# edges outside of loop because the checks extend beyond string, even with extending each time.
		substr($plants, 0, 1, $rules{".." . substr($last, 0, 3)});
		substr($plants, 1, 1, $rules{"." . substr($last, 0, 4)});
		substr($plants, -2, 1, $rules{substr($last, -4, 4) . "."});
		substr($plants, -1, 1, $rules{substr($last, -3, 3) . ".."});
		for (my $i = 2; $i < length($plants) - 2; $i++) {
			substr($plants, $i, 1, $rules{substr($last, $i-2, 5)});
		}
		
		# Sum calculation must be done inside the loop due to convergence check.
		# Note that pot zero is currently at position $gen in the $plants string.
		$sum = 0;
		for (my $i = 0; $i < length($plants); $i++) {
			if (substr($plants, $i, 1) eq '#') {
				$sum += $i - $gen;
			}
		}
		my $diff = $sum - $last_sum;
		if ($diff == $last_diff) {
			$repeats++;
			if ($repeats >= $convergence_threshold) {
				my $gens_to_skip = $max_gens - $gen;
				$sum += $gens_to_skip*$diff;
				$gen = $max_gens;
				last;
			}
		} else {
			$repeats = 0;
			$last_diff = $diff;
		}
	}
	return $sum;
}

__DATA__
initial state: #....#.#....#....#######..##....###.##....##.#.#.##...##.##.#...#..###....#.#...##.###.##.###...#..#

#..#. => #
#...# => #
.##.# => #
#.... => .
..#.. => .
#.##. => .
##... => #
##.#. => #
.#.## => #
.#.#. => .
###.. => .
#..## => .
###.# => .
...## => .
#.#.. => #
..... => .
##### => #
..### => .
..#.# => #
....# => .
...#. => #
####. => #
.#... => #
#.#.# => #
.##.. => #
..##. => .
##..# => .
.#..# => #
##.## => #
.#### => .
.###. => #
#.### => .