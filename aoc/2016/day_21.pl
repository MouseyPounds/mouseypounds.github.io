#!/bin/perl -w
#
# https://adventofcode.com/2016/day/21
#

use strict;
use POSIX;

print "2016 Day 21\n";
my $puzzle = do { local $/; <DATA> }; # slurp it
my @ops = split("\n", $puzzle);

my $pass = "abcdefgh";
my ($scrambled) = scramble($pass, \@ops);
print "\nP1 solution: Password '$pass' becomes '$scrambled' after scrambling.\n";

$pass = "fbgdceah";
my ($unscrambled) = unscramble($pass, \@ops);
print "\nP2 solution: Password '$pass' becomes '$unscrambled' after unscrambling.\n";

sub scramble {
	my $p = shift;
	my $op = shift;

	my $len = length $p;
	my ($x, $y, $temp1, $temp2);
	
	for (my $i = 0; $i <= $#$op; $i++) {
		if (($x, $y) = $op->[$i] =~ /swap position (\d+) with position (\d+)/) {
			$temp1 = substr($p, $x, 1);
			substr($p, $x, 1, substr($p, $y, 1));
			substr($p, $y, 1) = $temp1;
		} elsif (($x, $y) = $op->[$i] =~ /swap letter (\w) with letter (\w)/) {
			$temp1 = index($p, $x);
			$temp2 = index($p, $y);
			substr($p, $temp1, 1, $y);
			substr($p, $temp2, 1, $x);
		} elsif (($x, $y) = $op->[$i] =~ /rotate (\w+) (\d+) steps?/) {
			$y %= $len;
			$temp1 = ($x eq 'left') ? $y : $len - $y;
			$p = substr("$p$p", $temp1, $len);
		} elsif (($x) = $op->[$i] =~ /rotate based on position of letter (\w)/) {
			$temp1 = index($p, $x);
			$temp2 = (1 + $temp1 + (($temp1 >= 4) ? 1 : 0)) % $len;
			$p = substr("$p$p", $len - $temp2, $len);
		} elsif (($x, $y) = $op->[$i] =~ /reverse positions (\d+) through (\d+)/) {
			$temp1 = $y - $x + 1;
			substr($p, $x, $temp1, reverse substr($p, $x, $temp1));
		} elsif (($x, $y) = $op->[$i] =~ /move position (\d+) to position (\d+)/) {
			$temp1 = substr($p, $y, 1);
			if ($x < $y) { 
				substr($p, $y-1, 1, ($temp1 . substr($p, $x, 1, "")));
			} else {
				substr($p, $y, 1, (substr($p, $x, 1, "") . $temp1));
			}
		} else {
			warn "Unknown operation: $op->[$i]";
		}
	}
	return $p;
}

# To unscramble, we need to process operations in reverse order and reverse each operation.
# The most difficult reversal is the "rotate based on position of letter" operation. Note that
# it is only guaranteed reversible for size 8 passwords (like the actual input, but not examples.)
# Changing the ">=4" part of the rule to ">=len/2" would help for other even lengths, but odd
# lengths would need further adjustments.
sub unscramble {
	my $p = shift;
	my $op = shift;

	my $len = length $p;
	my ($x, $y, $temp1, $temp2);
	
	for (my $i = $#$op; $i >= 0; $i--) {
		if (($x, $y) = $op->[$i] =~ /swap position (\d+) with position (\d+)/) {
			# unchanged
			$temp1 = substr($p, $x, 1);
			substr($p, $x, 1, substr($p, $y, 1));
			substr($p, $y, 1) = $temp1;
		} elsif (($x, $y) = $op->[$i] =~ /swap letter (\w) with letter (\w)/) {
			# unchanged
			$temp1 = index($p, $x);
			$temp2 = index($p, $y);
			substr($p, $temp1, 1, $y);
			substr($p, $temp2, 1, $x);
		} elsif (($x, $y) = $op->[$i] =~ /rotate (\w+) (\d+) steps?/) {
			# switched the trinary conditional from 'left' to 'right'
			$y %= $len;
			$temp1 = ($x eq 'right') ? $y : $len - $y;
			$p = substr("$p$p", $temp1, $len);
		} elsif (($x) = $op->[$i] =~ /rotate based on position of letter (\w)/) {
			# rotation changed direction and new formula based on odd/even
			$temp1 = index($p, $x);
			$temp1 = $len if ($temp1 == 0);
			$temp2 = ( ( (1 + $temp1)+ (($temp1 % 2 == 0) ? (1 + $len) : 0) ) / 2 ) % $len;
			$p = substr("$p$p", $temp2, $len);
		} elsif (($x, $y) = $op->[$i] =~ /reverse positions (\d+) through (\d+)/) {
			# unchanged
			$temp1 = $y - $x + 1;
			substr($p, $x, $temp1, reverse substr($p, $x, $temp1));
		} elsif (($y, $x) = $op->[$i] =~ /move position (\d+) to position (\d+)/) {
			# switch x & y, done in the elsif
			$temp1 = substr($p, $y, 1);
			if ($x < $y) { 
				substr($p, $y-1, 1, ($temp1 . substr($p, $x, 1, "")));
			} else {
				substr($p, $y, 1, (substr($p, $x, 1, "") . $temp1));
			}
		} else {
			warn "Unknown operation: $op->[$i]";
		}
	}
	return $p;
}

__DATA__
swap position 2 with position 7
swap letter f with letter a
swap letter c with letter a
rotate based on position of letter g
rotate based on position of letter f
rotate based on position of letter b
swap position 3 with position 6
swap letter e with letter c
swap letter f with letter h
rotate based on position of letter e
swap letter c with letter b
rotate right 6 steps
reverse positions 4 through 7
rotate based on position of letter f
swap position 1 with position 5
rotate left 1 step
swap letter d with letter e
rotate right 7 steps
move position 0 to position 6
swap position 2 with position 6
swap position 2 with position 0
swap position 0 with position 1
rotate based on position of letter d
rotate right 2 steps
rotate left 4 steps
reverse positions 0 through 2
rotate right 2 steps
move position 6 to position 1
move position 1 to position 2
reverse positions 2 through 5
move position 2 to position 7
rotate left 3 steps
swap position 0 with position 1
rotate based on position of letter g
swap position 5 with position 0
rotate left 1 step
swap position 7 with position 1
swap letter g with letter h
rotate left 1 step
rotate based on position of letter g
reverse positions 1 through 7
reverse positions 1 through 4
reverse positions 4 through 5
rotate left 2 steps
swap letter f with letter d
swap position 6 with position 3
swap letter c with letter e
swap letter c with letter d
swap position 1 with position 6
rotate based on position of letter g
move position 4 to position 5
swap letter g with letter h
rotate based on position of letter h
swap letter h with letter f
swap position 3 with position 6
rotate based on position of letter c
rotate left 3 steps
rotate based on position of letter d
swap position 0 with position 7
swap letter e with letter d
move position 6 to position 7
rotate right 5 steps
move position 7 to position 0
rotate left 1 step
move position 6 to position 2
rotate based on position of letter d
rotate right 7 steps
swap position 3 with position 5
move position 1 to position 5
rotate right 0 steps
move position 4 to position 5
rotate based on position of letter b
reverse positions 2 through 4
rotate right 3 steps
swap letter b with letter g
rotate based on position of letter a
rotate right 0 steps
move position 0 to position 6
reverse positions 5 through 6
rotate left 2 steps
move position 3 to position 0
swap letter g with letter b
move position 6 to position 1
rotate based on position of letter f
move position 3 to position 2
reverse positions 2 through 7
swap position 0 with position 4
swap letter e with letter b
rotate left 4 steps
reverse positions 0 through 4
rotate based on position of letter a
rotate based on position of letter b
rotate left 6 steps
rotate based on position of letter d
rotate left 7 steps
swap letter c with letter d
rotate left 3 steps
move position 4 to position 6
move position 3 to position 2
reverse positions 0 through 6