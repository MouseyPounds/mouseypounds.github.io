#!/bin/perl -w
#
# https://adventofcode.com/2018/day/9

use strict;
use List::Util qw(max);

print "2018 Day 9\n\n";
my $puzzle = do { local $/; <DATA> }; # slurp it
(my ($num_players, $last_marble)) = $puzzle =~ /(\d+)/g;

my $win = play_game($num_players, $last_marble);
print "P1: With $num_players players and a last marble of $last_marble, the winning score is $win.\n";

$last_marble *= 100;
$win = play_game($num_players, $last_marble);
print "\nP2: With $num_players players and a last marble of $last_marble, the winning score is $win.\n";

# There isn't really a standard doubly-linked-list implementation in perl because for the vast majority of situations normal
# arrays work fine. AoC likes to make part 2 of puzzles do tens of millions of iterations on large arrays where the
# performance of splice degrades immensely, so we find ourselves in that minority situation and need to come up with a plan.
#
# We have previously implemented a single linked-list with an array where the index represented the value and the actual
# element value was a "pointer" to the next element (e.g. $a[5] = 3 means that 3 follows 5). Since this time we need a
# doubly-linked-list we are going to try a two-dimensional array where element[0] is previous and element[1] is next.
# Note that we won't actually be removing anything from this array; "removed" marbles just get orphaned.
sub play_game {
	my $num_players = shift;
	my $last_marble = shift;

	my @circle = ( [1,1], [0,0] );
	my $current = 1;
	# Note that because we will later determine the player with a modulus operation, the score for the final player is index 0.
	my @scores = map { 0 } (0 .. $num_players - 1);
	for (my $marble = 2; $marble <= $last_marble; $marble++) {
		#print "At start of turn for marble $marble, current is $current and the circle is:\n", print_circle(\%circle), "\n";
		if ($marble % 23 == 0) {
			# Move 7 marbles backwards, and then remove this marble.
			foreach (1 .. 7) { $current = $circle[$current][0]; }
			my $removal = $current;
			$circle[$circle[$removal][0]][1] = $circle[$removal][1];
			$circle[$circle[$removal][1]][0] = $circle[$removal][0];
			$current = $circle[$removal][1];
			my $player = ($marble % $num_players);
			$scores[$player] += $marble + $removal;
		} else {
			# Here we need to move forward one spot then insert the next marble after that and make that the new current.
			$current = $circle[$current][1];
			$circle[$marble][0] = $current;
			$circle[$marble][1] = $circle[$current][1];
			$circle[$circle[$current][1]][0] = $marble;
			$circle[$current][1] = $marble;
			$current = $marble;
		}
	}
	return max(@scores);
}

__DATA__
411 players; last marble is worth 71058 points