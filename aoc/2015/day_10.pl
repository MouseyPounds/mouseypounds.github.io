#!/bin/perl -w
#
# https://adventofcode.com/2015/day/10
#

use strict;
use POSIX;

my $debugging = 0;

my $puzzle = "1321131112";

print "2015 Day 10\n";
my $limit = 40;
my $next_limit = 50;
look_and_say(\$puzzle, 1, $limit);
print "\nP1: After $limit turns, string is length " . (length $puzzle) . "\n";
look_and_say(\$puzzle, $limit + 1, $next_limit);
print "\nP1: After $next_limit turns, string is length " . (length $puzzle) . "\n";

sub look_and_say {
	my $string = shift;
	my $start = shift;
	my $end = shift;
	
	my $turn;

	for ($turn = $start; $turn <= $end; $turn++) {
		my $next = "";
		my $current_digit = substr $$string, 0, 1;
		my $digit_count = 1;
		for (my $i = 1; $i < length $$string; $i++) {
			my $digit = substr $$string, $i, 1;
			if ($digit eq $current_digit) {
				$digit_count++;
			} else {
				$next .= "$digit_count$current_digit";
				$current_digit = $digit;
				$digit_count = 1;
			}
		}
		$next .= "$digit_count$current_digit";
		
		print "[$turn] $string -> $next\n" if $debugging;
		$$string = $next;
	}

	return;
}

__DATA__
