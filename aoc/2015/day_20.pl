#!/bin/perl -w
#
# https://adventofcode.com/2015/day/20
#

use strict;
use POSIX;

my $debugging = 0;

$| = 1;

my $puzzle = 34000000;

print "2015 Day 20\n";
print "\nPart 1:\n";
my $house = get_house($puzzle, 10);
print "P1: House $house is the first house to receive at least $puzzle presents.\n";

print "\nPart 2:\n";
$house = get_house($puzzle, 11, 50);
print "P2: House $house is the first house to receive at least $puzzle presents.\n";

sub get_house {
	my $present_goal = shift;
	my $multiplier = shift;
	my $limit = shift;
	
	$limit = 0 if (not defined $limit);
	
	my $num_presents = 0;
	my $house = 0;
	#my $house = 7e5; # high starting point while fine-tuning the algorithm
	
	while ($num_presents < $present_goal) {
		$house++;
		# Elf that matches house number always gives a present regardless of limits.
		$num_presents = $house * $multiplier;
		# The limit addition from part 2 can really complicate the logic if we are trying to
		# be smart about things and not just check every single number. As a general rule, we
		# would like to limit our check of elves to those below sqrt(house) and try to include
		# the other elf in the factor pair (e, h/e) whenever possible.
		if ($limit == 0 or $house <= $limit) {
			# Case 1: All elves count, including elf # 1
			$num_presents += $multiplier;
			for (my $elf = 2; $elf <= sqrt($house); $elf++) {
				if ($house % $elf == 0) {
					$num_presents += $multiplier * ($elf + $house/$elf);
					$num_presents -= $multiplier * $elf if ($elf**2 == $house);
				}
			}		
		} elsif ($house <= $limit**2) {
			# Case 2: Elves below h/limit are done but their opposites still count
			for (my $elf = 2; $elf <= sqrt($house); $elf++) {
				if ($house % $elf == 0) {
					if ($elf < $house/$limit) {
						$num_presents += $multiplier * ($house/$elf);
					} else {
						$num_presents += $multiplier * ($elf + $house/$elf);
					}
					$num_presents -= $multiplier * $elf if ($elf**2 == $house);
				}
			}		
		} else {
			# Case 3: h/limit is now past sqrt(h) so there are a group of elves
			# where both they and their opposites are done.
			for (my $elf = 2; $elf <= sqrt($house); $elf++) {
				if ($house % $elf == 0) {
					if ($elf <= $limit) {
						$num_presents += $multiplier * ($house/$elf);
					}
				}
			}
		}
		printf "[%7d] %8d\r", $house, $num_presents;
	}
	
	return $house;
}