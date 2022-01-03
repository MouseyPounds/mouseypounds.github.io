#!/bin/perl -w
#
# https://adventofcode.com/2021/day/24
#

use strict;

print "2021 Day 24\n";
my $input = do { local $/; <DATA> }; # slurp it
my @program = split("\n", $input);

# By manually stepping through the code we learn the following:
# - There is a block of 18 instructions run on each successive digit which differ only
#   in 3 particular values which we call "magic numbers" magic{1}, magic{2}, & magic{3}.
# - The algorithm of these code blocks does the following:
#   1) the current digit is checked against (z % 26 + magic{2})
#   2) z divides itself by either 1 or 26 (magic{1})
#   3a) if step 1 is true, a lot of stuff zeroes out; z will get smaller if magic{1} = 26
#   3b) if step 1 is false, z = z*26 + digit + magic{3}
# - Furthermore, magic{1} is 26 on half of the digit checks and so if those 7 checks
#   are all true z will eventually divide itself down to 0 and we'll have a valid id.
# - Because of the multiplying and dividing by 26, we can simplify the validity check
#   down to 7 pairwise digit comparisons which are related to magic{2} and magic{3}.

# The core of this program is to extract the magic numbers from the instructions and
# automatically build up the pairwise comparison rules which will later let us choose
# the correct ID numbers. Whenever magic{1} is 1 we need to push the current digit position
# and magic{3} onto the stack and then when magic{1} is 26 we pop off the most recent
# digit/magic pair to create the comparison. The comparison itself comes from:
# prev_digit + prev_magic3 + curr_magic2 == curr_digit which we simplify a bit.
# Note that along the way we also save all 3 magic numbers for each block even though
# we only need some of them for the comparisons. This is due to the legacy sim_MONAD()
# function that uses them; that function is part of an abandoned brute-force attempt that
# we didn't want to completely remove.
my %magic = ( 1 => [], 2 => [], 3 => [] );
my @stack = ();
my @comparisons = ();
foreach my $i (0..13) {
	($_, $_, $magic{1}[$i]) = split(" ", $program[18*$i + 4]);
	($_, $_, $magic{2}[$i]) = split(" ", $program[18*$i + 5]);
	($_, $_, $magic{3}[$i]) = split(" ", $program[18*$i + 15]);
	
	if ($magic{1}[$i] == 26) {
		my $a = pop @stack;
		push @comparisons, { 'digit_a' => $a->[0], 'diff' => $a->[1] + $magic{2}[$i], 'digit_b' => $i };
	} else {
		push @stack, [ $i, $magic{3}[$i] ];
	}
}

# Creating the id numbers based on the comparison rules. We make the earliest digit as
# large as possible for max (and small as possible for min) subject to the comparison
# and the constraint of keeping both in the range of 1 .. 9
my @digits_max = (0) x 14;
my @digits_min = (0) x 14;
foreach my $c (@comparisons) {
	if ($c->{'diff'} < 0) {
		$digits_max[$c->{'digit_a'}] = 9;
		$digits_max[$c->{'digit_b'}] = 9 + $c->{'diff'};
		$digits_min[$c->{'digit_a'}] = 1 - $c->{'diff'};
		$digits_min[$c->{'digit_b'}] = 1;
	} else {
		$digits_max[$c->{'digit_a'}] = 9 - $c->{'diff'};
		$digits_max[$c->{'digit_b'}] = 9;
		$digits_min[$c->{'digit_a'}] = 1;
		$digits_min[$c->{'digit_b'}] = 1 + $c->{'diff'};
	}
}

my $id = join('', @digits_max);
die "High id {$id} failed to verify\n" if (run_MONAD(\@program, $id));
print "Part 1: Highest valid ID is $id\n";

$id = join('', @digits_min);
die "Low id {$id} failed to verify\n" if (run_MONAD(\@program, $id));
print "Part 2: Lowest valid ID is $id\n";

# Not even used anymore. Part of a "faster" brute force attempt.
sub sim_MONAD {
	my $magic = shift;
	my $id = shift;

	my %reg = ( 'x' => 0, 'y' => 0, 'z' => 0, 'w' => 0 );
	my $max_z = 26**7;
	
	for (my $i = 0; $i < length($id); $i++) {
		my $digit = substr($id, $i, 1);
		$max_z /= $magic->{1}[$i];
		$reg{'x'} = ($reg{'z'} % 26 + $magic->{2}[$i]);
		$reg{'z'} = int($reg{'z'}/$magic->{1}[$i]);
		if ($digit != $reg{'x'}) {
			$reg{'z'} = 26 * $reg{'z'} + $digit + $magic->{3}[$i];
		}
		last if ($reg{'z'} > $max_z);
	}
	return $reg{'z'};
}

# Direct MONAD simulation; only used to verify our two answers.
sub run_MONAD {
	my $prog = shift;
	my $id = shift;

	my %reg = ( 'x' => 0, 'y' => 0, 'z' => 0, 'w' => 0 );
	my $id_index = 0;

	for (my $i = 0; $i <= $#$prog; $i++) {
		$prog->[$i] =~ /^(\w+) (.*)$/;
		my $inst = $1;
		my @arg = split(" ", $2);
		
		if ($inst eq 'inp') {
			my $val = substr($id,$id_index++,1);
			$reg{$arg[0]} = $val;
		} elsif ($inst eq 'add') {
			$reg{$arg[0]} = $reg{$arg[0]} + ($arg[1] =~ /[a-z]/ ? $reg{$arg[1]} : $arg[1]);
		} elsif ($inst eq 'mul') {
			$reg{$arg[0]} = $reg{$arg[0]} * ($arg[1] =~ /[a-z]/ ? $reg{$arg[1]} : $arg[1]);
		} elsif ($inst eq 'div') {
			$reg{$arg[0]} = int($reg{$arg[0]} / ($arg[1] =~ /[a-z]/ ? $reg{$arg[1]} : $arg[1]));
		} elsif ($inst eq 'mod') {
			$reg{$arg[0]} = $reg{$arg[0]} % ($arg[1] =~ /[a-z]/ ? $reg{$arg[1]} : $arg[1]);
		} elsif ($inst eq 'eql') {
			$reg{$arg[0]} = $reg{$arg[0]} == ($arg[1] =~ /[a-z]/ ? $reg{$arg[1]} : $arg[1]) ? 1 : 0;
		} else {
			warn "Unknown instruction '$inst'\n";
		}
		print "$i z is $reg{'z'}\n" if (($i + 1)%18==0);
	}
	return $reg{'z'}
}
__DATA__
inp w
mul x 0
add x z
mod x 26
div z 1
add x 14
eql x w
eql x 0
mul y 0
add y 25
mul y x
add y 1
mul z y
mul y 0
add y w
add y 16
mul y x
add z y
inp w
mul x 0
add x z
mod x 26
div z 1
add x 11
eql x w
eql x 0
mul y 0
add y 25
mul y x
add y 1
mul z y
mul y 0
add y w
add y 3
mul y x
add z y
inp w
mul x 0
add x z
mod x 26
div z 1
add x 12
eql x w
eql x 0
mul y 0
add y 25
mul y x
add y 1
mul z y
mul y 0
add y w
add y 2
mul y x
add z y
inp w
mul x 0
add x z
mod x 26
div z 1
add x 11
eql x w
eql x 0
mul y 0
add y 25
mul y x
add y 1
mul z y
mul y 0
add y w
add y 7
mul y x
add z y
inp w
mul x 0
add x z
mod x 26
div z 26
add x -10
eql x w
eql x 0
mul y 0
add y 25
mul y x
add y 1
mul z y
mul y 0
add y w
add y 13
mul y x
add z y
inp w
mul x 0
add x z
mod x 26
div z 1
add x 15
eql x w
eql x 0
mul y 0
add y 25
mul y x
add y 1
mul z y
mul y 0
add y w
add y 6
mul y x
add z y
inp w
mul x 0
add x z
mod x 26
div z 26
add x -14
eql x w
eql x 0
mul y 0
add y 25
mul y x
add y 1
mul z y
mul y 0
add y w
add y 10
mul y x
add z y
inp w
mul x 0
add x z
mod x 26
div z 1
add x 10
eql x w
eql x 0
mul y 0
add y 25
mul y x
add y 1
mul z y
mul y 0
add y w
add y 11
mul y x
add z y
inp w
mul x 0
add x z
mod x 26
div z 26
add x -4
eql x w
eql x 0
mul y 0
add y 25
mul y x
add y 1
mul z y
mul y 0
add y w
add y 6
mul y x
add z y
inp w
mul x 0
add x z
mod x 26
div z 26
add x -3
eql x w
eql x 0
mul y 0
add y 25
mul y x
add y 1
mul z y
mul y 0
add y w
add y 5
mul y x
add z y
inp w
mul x 0
add x z
mod x 26
div z 1
add x 13
eql x w
eql x 0
mul y 0
add y 25
mul y x
add y 1
mul z y
mul y 0
add y w
add y 11
mul y x
add z y
inp w
mul x 0
add x z
mod x 26
div z 26
add x -3
eql x w
eql x 0
mul y 0
add y 25
mul y x
add y 1
mul z y
mul y 0
add y w
add y 4
mul y x
add z y
inp w
mul x 0
add x z
mod x 26
div z 26
add x -9
eql x w
eql x 0
mul y 0
add y 25
mul y x
add y 1
mul z y
mul y 0
add y w
add y 4
mul y x
add z y
inp w
mul x 0
add x z
mod x 26
div z 26
add x -12
eql x w
eql x 0
mul y 0
add y 25
mul y x
add y 1
mul z y
mul y 0
add y w
add y 6
mul y x
add z y