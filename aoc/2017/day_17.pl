#!/bin/perl -w
#
# https://adventofcode.com/2017/day/17

use strict;

print "2017 Day 17\n\n";
my $puzzle = 366;

my @buffer = (0);
my $steps = 2017;
my $position = spinlock(\@buffer, $puzzle, $steps);
print "P1: After $steps steps, the number after $steps in the buffer is ", $buffer[$position + 1], "\n";

$steps = 5e7;
$position = spinlock(\@buffer, $puzzle, $steps, 1);
print "P1: After $steps steps, the number after 0 in the buffer is $position\n";

# For part 1, we take a simple, direct approach and just splice in the new value every time. A linked list style
# implementation would probably be faster, but this should be okay for the small number of iterations required.
# Returns the position of the last element insterted.
#
# Of course, part 2 went and asked for 50 million iterations and we are not storing (or splicing) an array that size.
# Because tht number is always inserted *after* the calculated position, the first element will always be 0,
# and the value requested for part 2 must be the second element (index 1). This leads us to adding a "simulate"
# option that just counts up to the requested value and keeps track of what is happening with that element
# without actually changing anything. In simulation mode, it returns the value for index 1.
sub spinlock {
	my $buffer = shift;
	my $increment = shift;
	my $end_value = shift;
	my $simulate = shift;
	
	$simulate = 0 unless (defined $simulate);

	my $position = 0;
	my $index_1 = -1;
	for (my $i = 1; $i <= $end_value; $i++) {
		# Note how the step counter $i is also the length of the array (before insertion) and the number inserted.
		$position = 1 + (($position + $increment) % $i);
		if ($simulate) {
			$index_1 = $i if ($position == 1);
		} else {
			splice(@$buffer, $position, 0, $i);
		}
	}
	return $simulate ? $index_1 : $position;
}

