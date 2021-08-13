#!/bin/perl -w
#
# https://adventofcode.com/2016/day/19
#
# Given the large circle size involved, we figured there would be some sort of exploitable pattern so we examined the results
# from sizes 2 to ~50 with a simplistic brute force algorithm (later discarded) to find such a pattern.
#
# For part 1, the pattern is pretty simple: elf 1 will get the presents on any size equal to a power of 2 and then for succeeding
# circle sizes, the next odd elf will get them. This leads to a formula of elf = (1 + 2*(size - n)) where n is the highest power
# of two less than (or equal to) the size. And we could figure out that highest power with a base-2 log.
#
# For part 2, things are more complicated: At a size of 3^n, the winning elf is the last elf (3^n). The winning elf then
# starts at 1 for 3^n + 1 and continues incrementing by 1 until 2*3^n. After that it increments by 2 until reaching 3^(n+1).
# After a little bit of algebra we can condense this down to (size - 3^n) if (size < 2*3^n) and (2*size - 3^(n+1)) after.
# This works for n = the highest power of 3 strictly less than size, so when we calculate the log we do it on size-1.

use strict;
use POSIX;

print "2016 Day 19\n\n";
my $puzzle = 3018458;

my $elf = 1 + 2 * ($puzzle - 2 ** POSIX::floor(log($puzzle)/log(2)));
print "P1 (Math): Elf $elf gets all the presents when stealing to the left.\n";

my $pow = POSIX::floor(log($puzzle - 1)/log(3));
$elf = ($puzzle < 2 * 3**$pow) ? $puzzle - 3**$pow : 2*$puzzle - 3**($pow + 1);
print "P2 (Math): Elf $elf gets all the presents when stealing across the circle.\n";

$elf = elf_game($puzzle, 1);
print "\nP1 (Simulation): Elf $elf gets all the presents when stealing to the left.\n";

$elf = elf_game($puzzle, 2);
print "P2 (Simulation): Elf $elf gets all the presents when stealing across the circle.\n";

# Although we have nice compact math answers for this puzzle, we wanted to revisit and see if we could also get a decent
# simulation method that isn't too slow. Our first idea for simulation bogged down due to repeated splicing of large arrays.
# Now we are trying something discussed by /u/aceshades based on using two lists and rotating after each removal.
#
# The basic idea is to initally split the elves into two equal arrays with the front-half ordered L to R and the back half
# R to L. Then the elf who loses their presents will be on the right end of one of these two. Once they are removed,
# we rotate the lists (back R -> front R and front L -> back L) in order to keep the elf whose turn is next at the head
# of the front list. Note that the order of rotations means when there is just 1 elf left they get swapped between the arrays
# before the while loop notices and exits. Since we are only accessing the arrays on the ends this should be significantly
# faster than trying to splice out the middle of a single array. Also, we can use the same logic for part 1 by just keeping
# the front list at a single element.
sub elf_game {
	my $num = shift;
	my $version = shift;
	
	my $middle = ($version == 1) ? 1 : POSIX::floor($num / 2);
	my @front = (1 .. $middle);
	my @back = reverse ($middle + 1 .. $num);
	
	while (scalar(@back)) {
		(@front > @back) ? pop @front : pop @back;
		# Note that if we are down to 1 elf, the rotation swaps them between the lists
		unshift @back, shift @front;
		push @front, pop @back;
	}
	return $front[0];
}

__DATA__
