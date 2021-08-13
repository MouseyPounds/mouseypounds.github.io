#!/bin/perl -w
#
# https://adventofcode.com/2018/day/14

use strict;
use List::Util qw(sum);

print "2018 Day 14\n\n";
my $puzzle = do { local $/; <DATA> }; # slurp it
my $limit = $puzzle;

# We originally had elves in an array and we looped it every time, but it turns out that has a big performance hit which
# can be resolved by using 2 explicit scalars and just assuming we won't ever need to increae the number of elves.
# We also originally used an array for recipes which meant there was some swapping back and forth between strings and
# arrays. Once part 2 required searching for a pattern, this was retooled into a purely string implementation.
my $recipes = "37";
my ($e1, $e2) = (0, 1);
#$limit = 2018;
while (length($recipes) < ($limit + 10)) {
	my $s1 = 0 + substr($recipes, $e1, 1);
	my $s2 = 0 + substr($recipes, $e2, 1);
	my $score = $s1 + $s2;
	$recipes .= "$score";
	$e1 = ($e1 + 1 + $s1) % length($recipes);
	$e2 = ($e2 + 1 + $s2) % length($recipes);
}

my $answer = substr($recipes, $limit, 10);
print "P1: The next 10 recipes after recipe $limit have scores of $answer.\n";

#$limit = "59414";
# Global match so that we can take advantage of `pos`; since each iteration will only increase the string by 1 or 2
# characters (max with 2 elves is a score of 18), we are setting pos to 1 more than the pattern length from the end.
until ($recipes =~ m/$limit/g) {
	my $s1 = 0 + substr($recipes, $e1, 1);
	my $s2 = 0 + substr($recipes, $e2, 1);
	my $score = $s1 + $s2;
	$recipes .= "$score";
	$e1 = ($e1 + 1 + $s1) % length($recipes);
	$e2 = ($e2 + 1 + $s2) % length($recipes);

	pos($recipes) = -1 - length($limit);
}
$answer = pos($recipes) - length($limit);
print "P2: The score pattern $limit first appears after $answer recipes.\n";

__DATA__
165061