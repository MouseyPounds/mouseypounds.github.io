#!/bin/perl -w
#
# https://adventofcode.com/2020/day/18

use strict;
use POSIX;

print "2020 Day 18\n";

my $puzzle = do { local $/; <DATA> }; # slurp it
my @lines = split("\n", $puzzle);

my $total = 0;
map { $total += do_math(0, split '') } @lines;
print "P1: Total of evaluations with no precedence is $total\n";

$total = 0;
map { $total += do_math(1, split '') } @lines;
print "P2: Total of evaluations with higher addition precedence is $total\n";

sub do_math {
	my $use_precedence = shift;
	
	my @rpn_q = ();
	my @op_stack = ();
	
	# Shunting Yard Algorithm as described on <https://en.wikipedia.org/wiki/Shunting-yard_algorithm>
	# Simplified to only deal with positive, single-digit operands and 2 operations (+,*)
	while (my $token = shift) {
		if ($token =~ /[0-9]/) {
			push @rpn_q, $token;
		} elsif ($token eq '+' or $token eq '*') {
			if ($use_precedence) {
				while (scalar(@op_stack) and $op_stack[$#op_stack] eq '+' and $token eq '*') { push @rpn_q, pop @op_stack; }
			} else {
				while (scalar(@op_stack) and $op_stack[$#op_stack] ne '(' ) { push @rpn_q, pop @op_stack; }
			}
			push @op_stack, $token;
		} elsif ($token eq '(') {
			push @op_stack, $token;
		} elsif ($token eq ')') { # pop any other operators to output then pop & discard the matching opener
			while (scalar(@op_stack) and $op_stack[$#op_stack] ne '(') { push @rpn_q, pop @op_stack; }
			if (scalar(@op_stack) and $op_stack[$#op_stack] eq '(') { pop @op_stack; }
		}
	}
	while (my $op = pop @op_stack) { push @rpn_q, $op; }

	# Evaluating the RPN queue; reusing the operator stack for the operands and output
	while (my $token = shift @rpn_q) {
		if ($token =~ /[0-9]/) {
			push @op_stack, $token;
		} else {
			my $x = pop @op_stack;
			my $y = pop @op_stack;
			if ($token eq '+') {
				push @op_stack, ($x + $y);
			} elsif ($token eq '*') {
				push @op_stack, ($x * $y);
			}
		}
	}
	return pop @op_stack;
}

# Original recursive parser implemented for part 1. Later replaced with the RPN version.
sub do_math_naive {
	my ($ans, $op);
	while (my $token = shift) {
		if ($token eq '(') {
			my $sub_ans = do_math_naive(@_);
			# the recursion will do the actual math until the matching closing paren, but
			# we now have to remove those operands and operators from our input queue.
			my $level = 1;
			while ($level > 0 and my $t = shift) {
				if ($t eq '(') { $level++; } elsif ($t eq ')') { $level-- }
			}
			# then we push the answer from the recursion back onto the front.
			unshift @_, $sub_ans;
		} elsif ($token eq ')') {
			return($ans);
		} elsif ($token =~ /[0-9]/) {
			if (not defined $ans) {
				$ans = $token;
			} else {
				if ($op eq '+') {
					$ans += $token;
				} elsif ($op eq '*') {
					$ans *= $token;
				}
			}
		} elsif ($token eq '+' or $token eq '*') {
			$op = $token;
		}
	}
	return $ans;
}

__DATA__
(3 * (4 * 8) * 5 * 7 * 3) + 8
4 * (6 * 4 * 6) + 8 + 4
(5 + 7) * 2 * 4 + 6 + 7 + (2 + 2 + 6 + (9 + 3 + 7 * 3))
(4 * 8 + 2 * (7 + 6 + 7) * 2) + ((4 * 2 + 4) + (6 + 7 * 2 * 3) + 5 * 2) * (4 + (4 + 5 + 4) * 7 * 8 * 4 + (7 * 7 + 5 * 3 * 6)) + 8
(3 + 3 + (6 * 4 * 9 * 3 * 6) + (5 * 8 + 7 * 9) * 8 * 7) + 9 + 3 * 8 * 4 + (7 + 4 * 7)
7 + (6 * (6 * 8 * 2) * (8 + 4 + 7 + 5 + 4 * 6) * 5) + 8 * (2 * (9 + 3 * 2) + 3 * 9 * 9 + 7) * 8 + 3
3 + (2 + 8 * 2 + 3 + 6) * 8 * (3 + 7 + 8 + (2 + 9 * 4 * 6) * 3) * 5 + 7
6 * 2 * 7 * (8 + (9 * 4 * 7 + 7 * 4) * 9) + 9
3 + 4 + (8 * 4) + 3 + ((7 * 9 + 8 + 5 * 5) + 8) + (2 + 7)
9 * 3 + ((8 + 2) * 5 + 2) * 6
((5 + 9 * 4 + 9 * 4 + 3) + 4) + ((3 * 7 * 5 + 7) + (8 + 6) + (6 + 9 * 4 + 7)) + 9 + 5 * 3 * 5
(6 * 7 + 5) + 9 * 9 + 4 * 7 * (4 + 9 + 9 * 2 * (4 * 8 * 5 * 7))
((5 + 7 + 7 * 8) + 3 + 4 * (2 + 2 + 9 + 3 * 7 * 9)) + 2 * 9 + 2 * 4
9 * 2 + (3 * 3 + 5 + 7) * (2 * 3 * 9 * 8) * 2 + 3
5 + 5 + (7 + 9 * (9 + 9 * 2) + 4)
(8 + (4 * 7 + 2 * 8) * 3 * 8 * 3) * (7 + 4 + 4 + 8 * 5 * 9) * 2 + 4
3 * 3 * ((2 * 3 * 8 + 4 + 3 * 3) + 4 * 7 + 3 * 5) * 9
3 * (8 * 5 + 9)
9 + 8 + (8 + 5 * 2 * (6 + 8) * 4)
6 + 8 + 3 * 5 * 2
7 * 9 + ((8 + 8 * 5 * 9) * 3 * 3 + 7)
5 + 9 + (3 + 6 * 4)
(6 + 2 + 7 + 6 * 8) + (3 * 6 + 7 + 2 * 4 * 6)
(8 * (4 * 2 * 2 * 5 + 6) * 8 * 8) + (9 * 4 + 9 * 2 + 9 * 5) + 7 * 2 * ((6 + 6 + 7 + 6 * 6) + 7)
(6 * 3 * 4 * (5 * 5 * 9 + 5 + 9)) + 2 + (5 + (8 + 9 * 5 * 3) * 2 * 3 * 8) + 7
8 * (6 + 6)
7 + 9 + (8 * (7 + 3 * 8 + 3 * 8 * 5) * 8 * 7)
(8 + 6 + 6 + 9 + 3) * ((2 * 6 + 8 + 7 * 2) + 9 * 7 * 7) + 5
((5 + 8) + (4 + 5 * 3 + 2) + (4 * 4 * 7 + 8 + 6) * 2 * 9) + 7 * 3 * 7 + 9 + 5
4 * 2 * (3 * 7) * 5 + 8
8 + (4 * 7 * 6 + 8 * (2 + 4 + 5 + 2)) + 5 * 7 * 9 * 3
(5 + 6 * 4) + 4 * 9
(3 * 2 * 2) * (5 * (4 + 7 + 7)) * 3
8 + (5 * 4 * 3 + (4 * 5 + 6))
3 * 5 + 3 + 3 + 6 * 2
(6 + 9 * 4 + (5 * 9 * 6) * 7) + 5
7 * 6 + 7 * (2 + 7)
4 * (2 + 6 * 9 + 7 + 7) + 6 + 8 * (8 * 7 + 7)
5 * 9 + (6 * 4 * 5) + 4 + (4 + 6 + 4 * 4 * 9) + 9
(5 + (4 * 8 + 6) * 7) + 6 + (3 * 6) * (3 * 7 * 3 * 7 * 3 * 9) * (4 + 8 * 5 + 7 * (8 + 2 * 9 + 4 + 8)) + 4
6 + 6 * (3 + (4 * 8 * 2 * 7) * 2 + 9)
2 + 2 + (9 + 8 * 7 + 5) + 7
2 * 8 + ((5 + 7 + 5) * 3 + 9) + 7
3 * (7 + 4 * 7 * 3 * 3 * 8) + 9 + 2 + 4
8 + 4 + 5 * 2 + 3
((6 * 2 + 2) * 9 + 7) + 9 * 2 * (7 * 6 + 4 * 3 * 3) + (8 + 8 + (6 + 5 * 8 * 6) + 6 + (9 * 9 + 4 + 2 + 6) + 2)
9 + 9 + 6 + 9 * (8 + 4 * 7 + 2 * 9 + 6)
(4 + 8) * 6 + 5
(5 * 3 * 2) + 8
7 + 7 + (6 * 9) + (3 + 4 + (9 + 3 * 6) + 5 * (4 * 6 * 6) + 9) + (6 + 8 + 7) * (3 + 3)
(2 * 8) + 3 + (4 * (7 * 9 * 9 + 6) * (7 + 2 * 5 * 6) * 3 * 7 + 2) * 7
3 * 4 * 6 * 2 + 9 + (8 + (4 * 9 + 8 * 9) * 6)
3 + 7 + (3 * 6 + 2 * 6 + 6 * 4) * (3 * (7 + 4) * (4 * 9 + 7 * 9) + 5 * 8 + 9)
4 + (7 * 8 * 8 * 7 * 5) + 7 * 6 * 7
(5 + 3 * 6 * 8 * 9 + 4) * 9 + (2 + 4 + 4 * 6 + 4 * 7) + (7 + (9 + 8 + 3)) * 6 + 4
(7 * 8 + 8 * 7 + 5 + 4) * 2 + (6 + 4 + 7) + (8 * 6)
9 * 8 + 8 * 3
9 + (7 + (8 * 5 * 5) * 7 + 6 + 2) * 7 + 7 + (3 + 2 + 5 + (3 + 4) + 9) + 2
9 * 7 + 3 * 9 * 6 * (3 + (2 * 6 + 5 * 3 + 7) * 4 * (8 * 8 * 2))
((4 * 6 + 9) * 6 + (4 + 5 + 8) + 8) + 9 * 6 * 8 + 3
6 + 4 * (2 * 3 * (7 + 8 * 6) + 8 + 4)
(8 * 8 + 4 * 8 + 7) + 2 * 4 * 3 * 7
(3 * (7 * 4 * 6 * 5 + 7 * 7)) * 7 + 6
7 * 3 * 3 * 2 + (2 + (3 + 7 * 8 + 4 * 4) + (4 + 3 + 5) * (5 + 2 * 3 * 3 + 9) + 6 + (4 * 3 + 4 + 6))
5 * (4 * 7 + 6) * 8
9 + 7 + 7 + 2 * 2
8 * (9 * 2 * 2 * 3) + (9 + (9 + 3 + 6 + 2 * 7 + 8)) + 6 + 4 + 7
7 * 2 + ((6 * 7 * 8) * 6 * 7) + 6 + (9 * 8 + 7) + (3 * 3 * (9 + 8) + 8 * 6 * 2)
(9 * (2 + 5 * 2) + 3 * 7) * (8 * 3 + 2) + 3 + (6 * 9 + 9 * 8 + 8 * 2) + ((2 + 5 + 3 + 8 + 6) + 4 * 6)
(8 * (9 + 4) * 4 + 8 * 7 + 3) + 2 * (3 + 2 * 2) * (6 + 8) + (5 * 9 * 7 + 7 * 2) + 4
6 * 8 * 7 + ((6 + 6 + 8 * 4 + 8) * 3) + 4
2 * 8 * (7 + 7)
(9 + 8) + 3 + (5 * 7 + 9 + 6 + 6)
2 * 6 + 9 * 6 * 3
3 + (5 + 2 + 7 * 3 * 9) * 8 * 6 * 4 + 3
(3 * 9 + 2 * 7) + 6 + (9 + (9 + 9 + 4 * 4)) + (7 * 7 + 8 + 4 * 4)
7 * 2 + 7 * ((8 + 9 + 7 + 4) * 7 + (7 + 4 + 7 * 3 * 4 + 2) + 8)
(9 + 3 * 9) + (4 * 9 + 7 + 2) + 7 + (7 * (3 + 4 + 8 * 9) + 8) + 9
8 + (4 + 3 + 4 + 9 + 7) * 7 + 6
8 * (9 + (5 + 8)) + 8
4 * (7 + 8 * (8 * 5 + 9 + 3)) * 4
2 + 5 + 7 * (7 * 6 + 6 * 5) * (8 * (7 + 3 + 6 + 4 * 8) + (8 + 6) * (4 * 7 + 2)) * 9
4 * 2 + 7 + (2 * 2 + 8 + 2 * (7 + 8 + 9)) * 5
(6 + (9 + 9 * 2 + 4 + 2)) * 6
(2 + 4 * 8 + 3) * 9 + 7 * 6 + 3
2 * 6 * ((8 * 3) * 8) * 4 * 5
4 + 5 * (5 + (8 + 8 * 2) * 8 * 5) + 3
9 * 7 * 7 + 9 * (7 * 8 + (7 * 4 * 4 * 2 + 5 * 3) + 5 + 5 + (3 + 2 * 4 + 8 * 9)) + 9
2 * ((5 * 8 + 8 + 5 + 6 * 3) * 3 * (3 * 6) * 2) + 8 * 9
9 + (6 + (4 + 3) + 5 + 2 + (6 + 4 * 8 + 7 * 2) * (8 * 6 * 8 + 6 * 4 * 5)) + 6
6 + (9 * 9 + 7 + 3) * 7 * (3 * 5 * 5 * 8) * 8
6 * 7 * 4 * 9 * 6 + (7 + 3 + 9)
4 * 3 + 7
8 * 4 + (6 + 8) + 8
9 * 7 + ((7 * 6 * 7 * 6 * 3 * 5) * 7 * 6 + 3 * 2) + ((4 * 5 * 6) * 5 * 7 + (2 * 6 * 2)) * 8 + 3
7 * 6 + 4 * (4 * 6 + 6 * 4 * 8)
7 + 8 + 3 + 3
6 + 8 + (8 * (3 * 2 * 3 + 5 * 8 + 3) + 7) * ((4 * 4 * 7 * 7 * 9 + 5) * 6 + 7) * 2 * (2 + 3)
7 + 7 * 2 * (4 * 3 + (4 * 2)) + 6 + 4
(5 * 6 + 3) * 8 + (2 + 8)
(8 + 8 * 3 + 9 + 5 * 9) + 4 * 9
9 + 4 * 8 + 5 + 6 + 4
4 * 4 + 5 + 3 + ((4 + 3) * 7 * (3 + 9))
(6 * 9 + 3 + 4 * 8 * 2) * (6 * 5) * 5 * 9 * 5 + 3
9 * 2 + 3 + ((3 * 5 * 5 + 8) + 7 * 8 * (2 + 3 + 9) * (6 + 2 + 8)) + 3 + 8
(3 + 9 * 6 + 4) + (7 * (9 * 6 * 2 * 4 + 8) * 4 * 4 + 9 * 3) + 7 * 6 * (7 * 6 + 2 * 2 + (5 + 8 * 4 + 3 * 7) + 3)
6 * (6 * 5 * 7 + (3 + 5)) + 9 + (3 * 2 + 6) + 4
8 * 9 + 8 + (5 + 8) * 8 + (2 + 7 + 7 * 8 * 3 * 5)
9 * 8 * 4 * 3
6 * (3 + 5 * 9 + (3 * 5 * 4 + 6 + 6 + 3) * 8)
(7 + 8 + 7 + 4 * 5) * 8 * (7 * 8 + 9 * 2)
9 * 4 * (2 + 2 + (8 * 4 + 8 + 9 * 4 + 4) * 6 + 4 + 5) * (3 * 4 * 5) * 6
5 * 6
5 * 3 * 4 + (9 * (2 + 9 * 8 + 8 + 3)) + 4 + 7
8 + 9 + (7 * (6 * 9 * 2 + 8) * 7 * (2 * 3) * 6) + 3 + (8 + 4 + (7 + 2 * 2 + 2 + 3) + 3 + (3 * 3 * 9 + 7 * 5 * 3) * 4) + 2
8 * 8 * (8 + (3 + 7 + 9 + 2) + 4)
(2 + 7 + 8 * 8 * 7 * 6) + 2 + 7 * 7
5 + (4 * 9) * 7
7 + 5 + 4
(3 * 3 * (3 * 6 + 9)) * (6 + 6 * 4 + 7 + 6)
(6 + 7 + (3 + 8 * 9 * 7) * 8) + 3 * 6 * 9 * 3 + (7 + 3 * (9 * 3 * 5 + 5))
3 * (7 * 2 + 8 + (2 * 4 + 4 * 3)) * 7 * (4 * 8)
(3 * 9 + 6 * 9 * 7) + 7 * 4 * 4 + ((5 * 7 + 8 + 4 * 8 * 8) + 6 * 3 * 8 + 5 + 4)
4 + (2 + 7 * 4 * (5 + 3 * 4 * 3 + 3 + 6)) * 6
3 + (7 * 4 + (5 + 7 + 2 + 8) * (4 * 5) * 6) + ((4 + 5) + (7 * 4) + (4 + 3) * (5 * 6)) + 5
(7 * 9 + (7 * 3) + 5 + (7 + 3 + 3 * 9 + 2 * 6)) + 2 * 6 * 9 + 3 + 4
((8 + 5 + 3 * 5 * 5) * 4 + (6 * 5 + 8 + 6 + 4 + 5) + 2 * 6 * 6) * (2 + 2 + 3) * 7 + 8 * (7 + 8 + 7 * 6 + 7 * (2 + 5 * 2 + 3)) * 4
3 + 2 + 7 + (9 * 7 * 3 * (9 * 2)) * 2
5 + 6 + 7 * 4 * ((6 + 8 * 2 + 6 + 3 + 3) + (3 + 3 + 8) * 5 * 5 * 9 + 5)
3 + 5 * 2 + (3 + (6 + 5 * 4 + 2) * 2 + 4 + 4 + 2) * 2
3 + 5
4 + (9 * (9 + 7 + 4 * 3 * 3) * 8 + 6 + (7 + 8)) + 3 * 6 * 5 * 6
(2 * 4 * 6 + 6) + (2 + 6 * 3 + 4 * 7 * 6) * 8 * 6
5 + (3 * 9 * 9 + 4 + (4 + 6) + (5 + 9 + 4)) + 9 * 3 * 6
((6 + 3) * 8 + 7 * 4) + 3
5 + (5 * (5 + 8 + 2 + 5 + 7 * 8) + (5 * 4 * 5 + 9) + (6 * 3) + (7 * 7)) * 5
((4 + 4 * 8 + 6 * 8) * (9 + 6 * 9) * (6 * 9)) * 9 + 9 * 4
5 * 6
8 + (5 * 5 + 4 * 5 * 9 * 2)
8 + 5 + (5 + 6 + 4 * 6)
3 * 5 * 6 + 9 + (4 + 2 * 2 * 2 + 4)
8 * 6 + 4 + (5 * (4 * 9) + 2 * (8 + 3 * 2) + 2) * 7
7 * (8 * 6) + 7 * (2 * (4 + 5 * 5 + 6) + (9 + 4 * 4 + 6 * 7) * 3 * 9 * 4) * (3 * (3 * 8 + 8 + 7) + (9 * 2 + 8 + 8 * 2)) * 7
9 + 3 * 9 * (6 + 5 * 6 * 9 + 8) + (9 * 4 * 9 * 5 + 9) + 2
4 + 5 + 7
5 * 5 + ((2 + 5 + 4 + 3 + 4) * 8 + 4 * 3) * 5 * 9 * (8 * 2)
(6 * (2 * 2 + 7 + 7)) * 2 + (9 + 2 * 2 + 2 + (7 * 3 * 5 * 9 + 2 + 7)) + 9 + 7 * 2
(9 + 2 + 6) + (6 * 6 * (5 * 6 + 9 * 6 + 8) + 8 + 7 + 2) * 4 * ((2 + 2 * 5 + 7) * 9)
6 + 9 + (8 * 3) + (7 + 6 + 6 * 3 * 2 + 9) * 7
6 + (3 * (4 * 6 + 3 * 4 + 7 + 8))
3 + (3 + 2) + 9 * (9 + (2 * 3 * 2 * 6 + 9) + 8) + (5 * 7) + (7 + 4 * 9 * 5 + 4)
2 * 5 * (2 + 8 * (4 * 9)) * 8 + (5 + 7 * (5 + 8 * 9 * 9 * 8) * 4 * 8 * 5)
2 * 8 + (2 + (5 + 3) + (2 * 3 + 3 + 6 * 4))
6 + 3 + 9 + 5 + 5 + ((3 + 3 + 4 * 8) * 4)
5 * ((3 + 6 + 7 * 6 * 8) * 3 + 8 + 7) + 2 + (2 * 6 + (5 + 5) * 9) + 3
9 * ((5 + 6 * 4 + 2) * 5 * 7 + (6 * 9 + 2 + 7)) + 4 + 4 * 2
6 * ((3 * 5 + 6 * 5 + 8 * 3) * 4 * (6 + 7 + 8 + 5 + 3) + 8 + 4 * (6 * 5 + 7 * 9 * 5)) + 5 * 5 * 7 + 4
(7 + 2) + 9 * 8 + 3 * 8 * 7
2 * 5 + 3 + (2 + 9) * 3
(5 * 6 + 9 + 5 + 9 + 3) * (3 + 5 + 6 * 2 + 2) * 5 * 6 * 2
(6 + 8 * 3 * 9 + 2 + 2) + 2 + 2 * 6 * 3
8 + (2 * 4 * (7 * 9) + 4) * 4 * 8 * 4 * 5
3 * (9 + (6 * 4 * 9 * 3 * 5) + 9 + (7 * 3 + 4) * 2 * 8) * 5 + 3 + 3 * (4 * 5)
3 * (2 + 2 + 2 + (9 + 7 + 6 * 3)) + 7
8 * ((3 * 5 * 8 + 9) * (4 * 6 * 6 + 6 + 7) + 6 * 7 + 8 + (3 + 7 * 8 + 6 + 4)) + 4 * 2 * (5 * 2)
3 * 2 * 4 * 7 * 9 * ((2 * 7 + 3 * 4 * 3 * 4) * 9 * 3 * 5)
(9 * 5) * ((7 + 4 + 4 + 5 * 4) * 5 + 8 + 8 * 2 * 2) * 2
3 + (4 + 7 * 2 * (9 + 9 * 9 * 5 + 7) * 5) * 5
(3 + (7 * 5 + 6 * 4) * 4 * 3 * 3 + 7) * 9 * 7
(2 + (3 * 3 * 6 + 4) * 6 * 8) + 2 + 9
9 * 4 + 4 + 7 * (6 + 6 * (9 * 2 + 6 + 5) + (3 + 5 * 9)) * 6
((9 + 6 + 7) * 2 + 2 * (6 + 9) * 8) * 7 * 6 + 6
3 * 5 + (5 * 2 + 8 + 5) + (8 + 9 * 9 + 5)
6 * 2 + (6 * 2 * 6 + (8 * 8 + 7 + 7))
3 * 6 + 3 * (4 + 9 * 7 + (8 + 6 * 3 + 4) * 7 * 9)
8 + (4 * 9 + 7 + (9 + 9 * 4 + 9))
8 * ((7 * 6 * 4 + 4) + 3)
6 + 7 * 6 + (6 + 6 + 4 * (2 * 2) + (2 + 7 + 2)) * 3
6 + 8
(6 + 5 + 6 * (3 * 2) * (5 * 7 * 3) * 5) + (6 * 3 + 8) * 6 * 2 + 6 + 6
3 * (7 + (6 + 8 + 9 * 4 + 5 + 4) * 4) * ((9 * 9 * 8 * 5 * 7 + 5) + 7 * 5) * 8 + 8 * 6
(8 * (3 * 5 * 9 + 3 + 4 * 2) * 5 + 6 * 7) * 5 + (6 + (5 + 3 * 3 + 3 * 2) * 4 * 4)
5 * (6 * (7 + 9)) + (9 + 9 + 2) + (2 * 2 + (2 * 9 * 6 + 8 * 2) + 4) * 6 + 2
((4 + 8) * 4 + 2 + 6 * 7 + (7 * 4 * 8 * 6 + 3)) * 8 * 2 + 5 + 9
5 + (5 * 9 * 4 * 3) * (7 * 3 * 7) * 6
(7 * 5 + 2 + 7) * (2 + 3 + 5 + 6 * (4 + 4 + 9)) + 9 + 2 * 5
((5 * 9 * 6 + 5 * 9) + 2 + 7 + 9 * (4 + 6 + 8)) + ((8 * 9) + 4 * 3 + 7 * 7 * 2)
9 + 9 + ((7 + 8 + 6 * 3) * 7)
((6 * 2 + 3 + 8 * 5) * 4 * (5 + 7 * 5)) + 4 + 5 + 6 * 2 * (6 + 2)
8 * ((4 * 8 * 3 * 4 + 5) + 3 + 6 + 9 * 9 + 3) + (7 * (8 * 2) * 9) * (8 * 9 + 2 + 7) + (4 * (2 * 8) + 3 + 2 + (7 * 2 * 6))
2 + 8 * ((2 * 2 + 3 * 6 + 5) + 8) + 6
(2 * (5 + 7 * 3 * 9 * 6) * (4 + 9) * (8 + 2 * 9)) + 9 * 2
2 * 4 * 4 * 9 + 7
4 + 7 + 6 + (6 + (8 + 8 + 7 + 5 * 2) * 7 * 2) + 8
3 + 4 + (4 * (9 + 4 + 5)) + 7 * 8 * 7
9 + 8 * 7 * 4 * ((8 + 2 * 4 + 6 * 9 * 2) + 3 * 3 + (2 * 5 * 5 + 2 + 9 * 9)) * 7
(8 * (5 * 7 + 7 + 2 + 7) + 3 * 9) + 9 * ((6 * 2 + 8 * 8 + 9 + 7) * 2 + (3 * 3) + (7 + 4) + 9 * 5) + (4 * 8 * 4) + 2 + 9
(3 * 5 + (7 + 4 * 8 + 7)) + ((8 + 5 * 6 * 5 + 3) * 2 * (3 * 9 + 4 * 2 + 3))
5 * 6 * 3 + (8 + 6 * 6 + 6)
6 * (5 * 7) + 2 * (3 + 7 * 5)
(9 + 6 + 2 * 7) * 2 * 7 + 6
5 + 3 * ((8 * 5 + 8 + 4) * 7 * 8 * 7 * (2 * 6 * 4 + 5 * 9)) + 3 + 4
3 + 9 + 6 + (4 + 3) * 2 * 7
((6 + 7 + 8 * 3) * 6 + 9) + 4 * 9 * 8
9 * 2 + (6 + 9 * 5) * (8 + 5 * 9 + 9 * 7 * 9) * 6
9 + 8 * 5 * (4 + (9 * 4 + 5 * 8 + 5) * 7 * (7 * 3 * 4 * 7) + 2) + 5
2 + 6 * (6 + 5 * 7 * 2 * 2) + 5
3 + (5 + 5) + 8 * (8 * 4)
(3 * 2) + 5 + 4 * 6 + 3 * (3 + 8)
8 + (2 * (5 * 7 + 4 + 7) * 4 + 5) + (8 * 9 * (7 + 2) + 5) + (6 + 7 * (6 * 8 * 8 + 9) + 6 * 8)
(2 + (8 * 3 + 3 + 5 * 8 * 7) + (7 * 6 + 4) + 8) + (2 + 7 * 9) + 9 * 8 * (4 + 5)
8 + (6 * 7 * 8 + (5 + 3 * 9 * 7) * 2) + (2 + 3 + 5 * 9) * 8 * 6 * 5
8 * 3 * 8 + (5 * (6 * 6) * 3 + 6) + ((8 * 5 + 8 * 4 * 7 + 5) * 6 * 7 + 9 * 6 + 8)
3 + 3 * 4 + (4 * 3 * 2) + 2 + 5
6 + 4 + 3 + (2 + 3 * (2 + 6 + 9 * 8 + 4) * 5 + (2 * 5 + 5 * 6 + 6) + 5)
3 + 2 * 4 + 6 + 4 * (6 + 2 + 9 * 2 + 8 + 4)
(6 * 9 + 2 * 7) + 7
(8 + 5 * 2) + 7 * (5 * (8 + 5 * 8 + 6 * 7) + (3 * 9 * 9 + 9 * 6) * 5 * 7 * 9) + 6 * 2 * (9 * 9 + (5 + 7 * 4 * 4 * 9 + 6) + (6 * 3 + 7 + 6 + 4 + 8) + 8 * 5)
6 * 7 * (4 * 9 * (2 * 5 * 3 * 3 * 8 * 9) * 7) + 9 * (2 + 5) + 4
8 * 8 + 7 + (7 + 9 * 7)
((3 * 5 * 3) * (6 * 8 * 5 + 8) * 7 + 6) + 7 * 9 + (5 * 3 + 2 * 5 * 8 + 6) + (5 * 7)
7 + 7 * (2 * 9 + 6) * 4 * 4 + 9
(5 * 8 + (8 * 9 + 3 * 2 * 7 * 9)) * 8 * 8 + 3 + 7
6 + 5 + 8 * 2 * (7 * 6 * (5 * 8 * 4)) + 6
(9 + 4 * 2 * (6 + 2 * 2 * 4 + 7 * 9)) + 8
(5 * 3 * 2) * 2 + 2 * 6 * 8 * 8
4 * (2 * (5 + 6 + 6) + 6 + (7 * 2 * 9 * 9) + 4 + (4 * 9 * 7))
8 + (8 * 6 + 2) * 3 * 6 * 3 + 7
3 + 8 * ((6 + 6) * 9 * (9 * 4) + 4 * 4 + 5) + (3 * (7 + 3 * 4 * 6 * 4) * 8 + 7 * (6 + 7 + 7 * 5 + 9)) + (6 + 6 * 9 + (6 + 6 * 2 * 4 * 5))
8 + 4 * 7 * ((9 + 5 + 9 + 7) + 5) + 7
8 * 7 + (8 * 9 + 3) + 7
9 * (9 * 2 * (3 + 3 + 7))
((9 + 9 * 8) * (4 + 8 + 7 * 6 * 5 + 3) + 5 + 3 * 4 + (7 + 7 * 3 * 6 * 3)) * 6 + 5 * 9
2 + 7 * ((3 * 6) * (6 * 5) + 4 + 9 + (4 + 2 + 3 * 3 * 5))
(9 * (7 + 7) + 5 * 2 + 5) + 6 * 3 * 3 * 8
(7 + (8 * 6 + 7) * 7 + (2 * 7 + 3) * 7 * 9) * 7 + 5 * ((7 * 5 + 2 + 5 * 2) + 6 + (7 + 9 * 3 + 8 * 6))
(9 * 2 + 5 * 3 * 8 + 4) * ((4 + 9 + 8) + 6 * 7 * 3 * 8 + 3) * 6 + 5 + 4 * ((9 + 4 + 6 * 4) + (2 + 7) * 5 * 5 * 3 + 5)
((9 * 6 * 3 * 6) * 3 * 9 + (6 + 7 + 5) * 6) * (7 * (4 * 9 + 7 + 8 + 6)) * 7 * 6 + (2 * 4 + 9 * 5 * 2)
7 * (8 + 5 + 4 + 7)
((5 + 8 * 2 * 8 + 6) * 8) + 8 + 2 * 2
(2 * 5 * 5 + (5 * 5 + 5 * 9 + 2)) * 9 * 2 + (6 * 7 + 5)
(9 * 5 * 9) + 4 * 8 + 2 * (5 * 7 * 4 + (8 * 4 + 3 + 8) + 9)
7 + 3 * (5 + (5 * 4 * 4 + 9 + 9) * (6 * 8 + 3 * 8) * 5)
7 * 6 + 7 + 3
(5 + 6) + 5 * (6 + 7)
9 * 2 * 9 + (9 + 6 * 4 + 4 * (5 + 4 + 8 * 2 * 9 * 3))
7 + (8 + 2 * 6 + 9 * (2 * 6 * 3 + 4 + 2 + 6) + 9) + 3 + (9 * 8 + (9 + 3 * 6 * 5) + 6 * 8 * 2) * (2 * 4 + 5) + ((2 + 7 + 2 * 6) * 3 + 7 * 6)
7 + 9 * ((3 * 2) * (7 + 5 + 8)) + 8 * 5
2 + 3 * 6 + 8 + 2 * (9 * 9 + 8 + (6 + 3 + 4 * 4 + 4 * 6))
4 * 2 + 6 * ((6 * 9 * 5 * 7 + 8 + 7) * 5 + (4 + 2 + 6) * 9 + 3 * 3)
8 * (2 + 3 * 5) + 7 + 8 * (9 + 2 * 8 + 4 * 9) + 8
(9 * 2 + 6) + 3 * ((5 + 6 * 3) + 4) + 6
6 * 3 * (3 + (4 * 4 + 5 * 7) * 4 + (4 + 5 + 2 + 8 + 4 + 3)) * 9 + 7
8 * 3 * 6 + 6 + 7 + 2
(6 + 4 * (6 * 2 * 9 * 4) * 2) + 9 + 4 * 7 + 8 * 4
5 + (7 * (4 + 5 + 9 * 5) * 2 * 5)
(4 * (6 * 3 * 6) + 7 + (4 + 6 + 8 + 3 + 3 + 9)) + 6 + (3 * 6)
3 * 8 * (7 * 8 + 2 + 4 + 5 + 4) * 8 + 9 + 3
3 + 4 + 7 + 6
(6 * (9 * 5 + 2 + 8 + 7 * 6) + 4) * 3 * 2 + 3
8 * 6 + (6 + 2 + 7 + (7 * 5)) * 6 * (8 * 4 * (4 * 5 + 4) + 2)
7 * 5 + 2
(6 + 3) + 2 * (3 * 6 + 5 + 6) * 9
6 * (2 * (8 + 8 * 6 * 5 + 8 + 3) + 2 * 9 + 4 + 4) + 5 + 6
5 + 2 + (4 + 2) * (4 * (8 + 3) * 9) * 2
9 + 2 * 4 * 5 + 6 + (9 * 8 + 2 * (8 * 4) * 7 + 8)
2 * 2 * 2 * 6 + 6 * 8
6 + (4 + 7 * 4 * 5 + 2 + 4) * 2 * 8
(5 * 6 + (9 * 7 + 2 * 2 * 7) * 8 * 3 + 5) + 5
(9 + (6 * 8 + 9)) + 7 * 7 * ((8 + 7 + 6 * 9 + 4) * 3 + 6 * (4 + 5) * 2) + (6 * 5 + 9 * 2 + 5 + (7 + 5 * 5)) + 9
((5 + 8 + 7 * 8 * 6) + 9 + 2) + 9 + 6 + (6 + 2 + 4)
(8 + 5 + 2 * (8 * 6 * 2 * 3 + 7 * 5) + 8 + 8) * 7 * 7 + 2
6 * ((7 * 8 + 6 * 8) * 2 + 5 + (3 + 8)) * 2 + 9
4 + 3 + 8 * (6 * 7 * 8 * 6 * 3 + 2) * 9 + 6
3 * ((9 + 7 + 4 * 7) + 3 * 3) + 8
2 + ((5 * 8 * 6 + 4 * 5 + 6) + 2 + 3 * 9 * 7) + 6 * 7
3 * 3 * (5 + 8 * 4 + (3 * 3 + 6) + 2) * 6 + ((8 + 3 + 7 + 5 + 7 * 6) * (8 * 9 + 8 + 2) * 8 + 2) * 3
(6 + 3 * 9 * 9 * 4) + 7 * 6 + 3 + 6 + 8
6 * 2 + (7 + 9 + 6 + 4 + 9)
(6 + 8 + 8 + (6 + 4 * 2 * 2 * 4) + 7) * 8 * 7
3 * 7 + 9
(6 + 7 * (2 * 3 * 6 * 8 + 6) + 8 + 3) * 4 + (4 * 9 + (5 + 8 * 4 + 6 + 6) * 6 * 5)
9 * ((7 * 2) + 9 * 2 * 5) * (6 * 4 * 3 + (8 + 3 + 7 * 9 + 8) + 4) + (2 + 4 + 4 + 9)
3 + (9 * 6) * 4 * 8
6 * (3 + (4 * 7 * 7 * 4 + 7) * 5 + (9 + 5) * (9 + 9 + 5 + 7 + 2 + 2))
7 + ((6 + 2 + 3 * 9) + 4 + 5 + 2 + 8) * (8 + 9 + 9 + 9 * 6) + 9
7 * (6 + (7 + 5 * 3 + 4 * 9 + 3) + 2)
6 * (7 * 7 + (4 * 3 + 2 + 7 + 5 + 6) + 4 + 7) + 4 * 6
(2 * 2 * 9 + (9 * 7 + 8)) + 6 + (9 + 7) + 8 + 4 + (7 * 5 + 8 + 8 * (2 + 5 + 7 + 5 * 9))
2 * (6 * (8 * 8 * 2 * 3 + 8 * 9) + 3) + 3 * 5 + 7 + (7 + 2 * 2 * 4)
6 * (8 * (4 * 3 + 3 * 4) * (7 + 4 + 5 * 5 + 2) * (6 * 4 * 6 + 9 * 9) + 2 * 5)
8 + (4 + 5 + 6 + (4 + 7) + 3 * 8) + 3 + 4
((9 * 7 + 2 * 6 + 7) * 2 * 8) * 7 + 2 + (6 + (2 * 6) + 7 * (5 * 4 * 6 * 7 + 9) + 8 + 2) * (8 + 2 + 5 * (6 * 8 + 5 * 4) * 7 + 4)
(5 + 2 + (8 * 2 + 2 * 9) + (4 * 8) * 8 + 9) * 9 + 9 * 2 * (2 + (3 * 3) * (5 * 2 * 4 * 2) * 3 + 7) + 8
4 * (4 + (8 + 6) + 9 * 8) * 4 * 6 + (5 * 3 * 3 * 5 * (8 * 2) + 8)
8 + 5 + 2 + (9 * 7 * (4 * 5 + 6 * 5 * 6 + 8)) + 8 + 7
(8 + 9 * 4) + 8 * ((5 * 6 + 9 * 2 * 4 + 8) + 6 * 7 * 4 + 4 * 2) + 8 * (5 + (2 * 7 + 6 * 4 * 8) + 2) + 2
(7 + 3 * 8 * 2) * (6 * 5 * (2 * 3 * 5 * 7 + 8 * 8) + 7 + 7 * (2 * 3)) + 9
7 + 4 + (3 + 2 + 4) * 4 * 4
((3 * 2) + 3) * (2 * 6) + 2 + 6 * 6 + (3 + (2 * 5 * 3 * 2 * 9 + 2) * 3 * 8 + 3)
9 * ((6 + 2) + 3 + (9 + 7 + 9)) * 8 + 8 + 5 * 3
(8 + 4) * 6 + 2 * (6 * 6 + 4 + 9 + 9 + 6) * (2 * 7) * 9
(2 + 9 + 9 * 6 * 2 * 5) * 2 + 2 + 2 * (7 * 3 + 6 * 7 + 5 * 7)
4 + 8 * 7 * (6 * 7 + (9 * 2 * 8 + 8) + 4 + 5 + 2) * 5 * 7
5 + (7 * 6 + (3 * 2 * 7 * 5) + 4 * 6 + 2) * 2
7 * (4 * 6 * 2 * 3 + (6 * 8 * 4) * 6) + 3 + 6
4 + 3 * ((3 + 3 * 5 + 4 * 3 * 2) * (3 * 6 + 7 * 7 + 9) * 7) + (8 + 2 + 9 + 5 * 8 * 8) + (7 + 8 + 9 + 4 + 2 * 4) + 7
6 * (5 + 2 + 6 + (7 + 9 + 4 * 3) + 8) + 6 * 5 * 8 * 7
7 + 9 * (2 * 9) * 8 + (2 * 2 * 8 * 4 * (7 * 3 * 4 * 2 * 9 * 3) * 5) * (9 + 2 + 3 + 3 + 4)
6 * 3 * (9 * 6 + 7 + 9 * 2 + 2)
5 * ((3 + 5 + 4 + 7) + (5 + 7) * (2 * 5 + 5 + 9 + 7)) + (9 + 7) * 8
(7 + 7 * 5 + 2 + 7 + 3) * 9
9 + (3 * 7 * 4) + 8 * 2 + 2
(3 + 7 + 3 * 6 * (2 + 2) * 8) + 3
3 * (9 + (8 + 4) + (3 * 7 * 6 + 9 * 7 + 7) * (8 * 7 * 9 + 6) * 9 * 7) + 4
5 * 2 * 4 + (4 * 5 + 6 + (6 * 8 + 4 + 2) * 5) + (7 + 2) + ((6 + 7) + 5 * 5 * 5 + 5 * 6)
7 * (7 * 3 * (8 * 2 * 8 * 2 + 4) * 8) * (6 + (4 * 7 * 6 * 8 + 2) + 2 + (2 + 6) * 4) + 7 * 6 + 4
8 * 3 + ((5 + 4 + 4 + 2) * (6 * 8 * 6) * (5 * 7 * 2) + 4) + 8 + 5 * 2
5 * 5 * (6 * 2 * 5 + (8 + 9 * 5 + 5) + 5)
(4 * 5 * 2) + 5 * 9 + 3 * 9
7 * 8 + ((3 + 9 * 5 + 4) + 9 + (3 + 7 * 8 + 7) + (2 + 9 * 3) * 5) + 6 * 6
(4 * (8 + 4) + (8 + 2 + 9 + 3 + 2 * 9) + 4 * 7 * 6) + 9
7 * (5 + 5 * 2 * 3) + 4
(8 + (6 * 9 * 7 + 4 * 3) * 6 * 9) * 3 * ((2 * 4 * 5 + 2 * 7) + 4 + (8 * 9 * 9 + 9 + 6 + 7) * 3 + 9 + 3)
(3 + (7 + 5 + 4 + 9)) * 4 * 5 * 8 + 6 + 6
(6 * 9 * 8) * (2 + 9 + (6 + 2 * 9 * 4) * (3 * 6 + 5 * 6 * 9) * 9 + 8) + 3 * 3
((4 * 4 + 4) * 9 * 9 * (3 * 5 + 5 * 4 * 5) + 8) + 8 * 7 * 8
4 + 4 * (2 + 5 * 7 + 2 * 7 + 3) + 5 * 2
6 * (3 * (6 + 8 * 7 + 5 * 3 * 4) * 8 * (4 * 3)) * 7 + 6 + 3
2 + 4 + 5 + 6 + 9 + ((3 * 7 + 4 + 8 + 6) + 5 * 2 + 4 * 6)
(8 + 5 * 8 * 7 * 9) + 9 * 5 + 3
5 + 3 * 4 + (6 + 2 * (6 * 2 + 6 + 3) * 2 * 6 + (9 * 9 * 3)) + 2 + 6
3 * 5 * (5 + (2 + 5) * (6 + 8) + 2 + 4 * 5) * 7
4 + 7 + 4 + 9 + 2 * (3 + (7 + 2 + 4 * 9 * 3) * 6 * 7)
((9 * 9) * 5) + ((6 * 3 + 6 * 6 + 2 + 3) + (9 + 7 + 8) + 5 * (3 + 4)) * (8 + 4 + 9)
3 + ((5 * 6 + 2 * 3 + 9) * (6 * 8)) * 7 + 6 * 8 + 8
8 * 5 * 5 * 9 * ((5 * 6) * 6 * (2 * 8 * 9 * 3) + 7 * (9 * 3) * 3) * 9
2 * (5 + 2 + (4 + 6 + 7 + 9 + 7 + 4)) * 5 + 9 * 9
(5 + 6) + 7 + 8 * (4 + 3 * 3 + 5 * (5 * 3 + 8))
4 * ((6 * 7 + 8 * 3) + 8 * (8 * 2 * 7 * 8 * 2 + 7) * 4 + 9) + 7 + 3 + 9 * 5
7 + (5 * 7 * 4 + (9 + 7 + 2 + 5 * 4 * 2)) + 5 + 2
(9 + 7 * 8) + 7 * 3 * 3
3 * 6 + 9 * 6 + 8 + 5
2 * 3 * 8 + ((6 * 6 + 2) + 2)
5 + 3 + 7 + (2 + (4 + 6 * 7 + 7 + 5 * 7) + 4)
4 * 6
(7 * 6) * 6 * 4 + 2
6 + ((7 + 9 * 3 + 9) * 2 * (6 * 4 * 5) + 3) + 5 + 9
(5 + 3 + (4 + 8 * 6 + 6 + 6) + 4 * 6) * (3 + 6 * (9 + 3 + 6) + 7 + 4 * 3) * 3 * (2 + 5 * 2 + (6 + 5 + 8 * 9 * 8 * 3) + 2 * 6)
(6 * 5 * 5 * 6) + 3 * (5 + 8) * (4 * 7 + 8 * 6 + (4 + 9 + 6) + 4) + 4
3 + (2 * 6 * 5 + 9 * 3) + 6
9 * (3 * 4 * 8 * 4 + 4)
(9 * (2 + 9 * 6 + 5 * 6 + 2) * (8 * 4 * 6 * 8) * 5) * 7 + (7 + 5 + 3 + 5 + 7 * 9) + (6 * 7) + 8
(4 + 3 * 7) + (4 + 5 * 9 + (8 * 6 * 3) + (4 + 2 * 2) + 3) + 4 + 7 * (9 * 9 + 7 + (8 * 4) * 4 * 6)
((3 * 2 + 2) * 4 + 3 * 2 + 9) * 4 + 7
(7 + 2 + 6 + 7) + 8 + 4 + (3 + 3 + 9) + 8
(7 * 4 * (9 * 2 + 4 + 6)) + 6 * 5 + 9 * 7
7 + 3 + 3 + 8 + (4 * 5 * 9 * 9 * (8 * 4 + 9 + 2 + 4 * 8))
4 * 3 + 7 * 7 + (4 * 8 * 9) + 2
(4 + 2 + 8 * 9 + 5) * 5 + 8 * (7 * 5 * 5) * 9 * 9
9 * (2 + 5 + (2 * 5 * 5) * 6 * 8 * (8 * 9 + 6 * 2 * 4)) + 5 + 3
4 + 2 + 2 + 3 + (7 * 5 + 3 + 7 + (6 + 6 * 7))
(9 * 3 + 6 + 5) + (3 + 3 + 5 + 9)
3 * ((8 * 6) * 7 * 4) + 9 + 6 + 9
2 + (6 * 7 + 7 + 6 * (7 * 6 * 2 + 4 + 6 + 7))
(4 * 6 * 7) * 6 * (3 * 7) + 2
(3 * 7) * ((9 * 3 * 5) + 9 + 8 + 4 + 4 * 7) + 3 + 8 + 6 + 2
(5 * 5) + (3 * 4 + 8 * (6 + 8 * 5 + 7 * 3)) + 8 * (9 * 2)
(3 + (2 * 7 + 9) * 2) * 3 * 7 + 2 + 4 * 9
9 * 9 + 4 * 3 * (8 * 4 * (2 * 9 + 6 + 6 + 2))
7 * ((5 * 7 + 5 * 4 + 9 + 9) * 4 + 4 + 6 + 2) + 6 * (7 * 5 + 5 + (2 + 9 * 4 + 7) + (8 * 7 + 4 + 5 + 5) + 2) * 7
(8 + (4 * 3 + 9 * 2 + 2 * 7) + 7 * 2 * 5) * 3
5 * 2 * 9 * (5 + 5) + (6 + 3) * (2 + 3 * (5 + 5 + 6) + (9 + 2 + 7) + 5)
(9 * 8 + 6 + 9) * 8 * 8
(4 * 4 + 7 + 2) + 7 * 2 + (4 + 3)
2 * 8 + 5 + (2 + (3 * 9 * 8 * 8 + 2 * 5) * 8 * 2 * 2 + 4) + ((3 * 7 + 7 * 5 * 5 + 5) * 8 * 5 * 8 + 6) + 5
(2 * (9 + 3 + 8 * 8) + 6) * 3 * 9 * (7 + 7) * (2 * 2) * 5
((6 * 3 + 3) * 6 + 5) + 3 + 4