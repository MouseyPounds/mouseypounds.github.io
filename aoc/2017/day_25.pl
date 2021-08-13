#!/bin/perl -w
#
# https://adventofcode.com/2017/day/25
#
# We're not actually going to parse the input this time in the scrip and instead will just manually translate it.

use strict;
use List::Util qw(sum);

print "2017 Day 25\n";
my @tape = (0);
my $i = 0;
my $step = 0;
my $checksum_trigger = 12208951;
my $state = 'A';
while ($step++ < $checksum_trigger) {
	if ($state eq 'A') {
		if ($tape[$i] == 0) {
			$tape[$i] = 1;
			$i++;
			$state = 'B';
		} else {
			$tape[$i] = 0;
			$i--;
			$state = 'E';
		}
	} elsif ($state eq 'B') {
		if ($tape[$i] == 0) {
			$tape[$i] = 1;
			$i--;
			$state = 'C';
		} else {
			$tape[$i] = 0;
			$i++;
			$state = 'A';
		}
	} elsif ($state eq 'C') {
		if ($tape[$i] == 0) {
			$tape[$i] = 1;
			$i--;
			$state = 'D';
		} else {
			$tape[$i] = 0;
			$i++;
			$state = 'C';
		}
	} elsif ($state eq 'D') {
		if ($tape[$i] == 0) {
			$tape[$i] = 1;
			$i--;
			$state = 'E';
		} else {
			$tape[$i] = 0;
			$i--;
			$state = 'F';
		}
	} elsif ($state eq 'E') {
		if ($tape[$i] == 0) {
			$tape[$i] = 1;
			$i--;
			$state = 'A';
		} else {
			$tape[$i] = 1;
			$i--;
			$state = 'C';
		}
	} elsif ($state eq 'F') {
		if ($tape[$i] == 0) {
			$tape[$i] = 1;
			$i--;
			$state = 'E';
		} else {
			$tape[$i] = 1;
			$i++;
			$state = 'A';
		}
	}
	if ($i < 0) {
		unshift @tape, 0;
		$i++;
	} elsif ($i > $#tape) {
		push @tape, 0;
	}
}

my $cs = sum(@tape)		;
print "P1: The checksum value is $cs\n";

__DATA__
Begin in state A.
Perform a diagnostic checksum after 12208951 steps.

In state A:
  If the current value is 0:
    - Write the value 1.
    - Move one slot to the right.
    - Continue with state B.
  If the current value is 1:
    - Write the value 0.
    - Move one slot to the left.
    - Continue with state E.

In state B:
  If the current value is 0:
    - Write the value 1.
    - Move one slot to the left.
    - Continue with state C.
  If the current value is 1:
    - Write the value 0.
    - Move one slot to the right.
    - Continue with state A.

In state C:
  If the current value is 0:
    - Write the value 1.
    - Move one slot to the left.
    - Continue with state D.
  If the current value is 1:
    - Write the value 0.
    - Move one slot to the right.
    - Continue with state C.

In state D:
  If the current value is 0:
    - Write the value 1.
    - Move one slot to the left.
    - Continue with state E.
  If the current value is 1:
    - Write the value 0.
    - Move one slot to the left.
    - Continue with state F.

In state E:
  If the current value is 0:
    - Write the value 1.
    - Move one slot to the left.
    - Continue with state A.
  If the current value is 1:
    - Write the value 1.
    - Move one slot to the left.
    - Continue with state C.

In state F:
  If the current value is 0:
    - Write the value 1.
    - Move one slot to the left.
    - Continue with state E.
  If the current value is 1:
    - Write the value 1.
    - Move one slot to the right.
    - Continue with state A.