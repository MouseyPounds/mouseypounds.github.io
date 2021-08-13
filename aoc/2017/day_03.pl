#!/bin/perl -w
#
# https://adventofcode.com/2017/day/3

use strict;

print "2017 Day 3\n";
my $puzzle = "361527";

my $dist = calc_dist($puzzle);
print "P1: The distance from square $puzzle is $dist steps.\n";

my %grid;
my $val = stress_test(\%grid, $puzzle);
print "P1: The first stress-test value greater than $puzzle is $val.\n";

# The distance can be determined directly without constructing the spiral with a relatively short algorithm.
# The bottom-right corner of every "ring" is a perfect square; we are calling this n_sq and iteratively determining n.
# Once we identify n_sq, we can quickly get its corner coordinate c (e.g. if we start at 0,0 then 25 is at x=2) and from
# there figure out which side of the ring our target is on and then count the distance from the midpoint of that side.
sub calc_dist {
	my $loc = shift;
	return 0 if ($loc == 1);

	my ($d, $n, $n_sq);
	for ($n = 1; $n < 1e10; $n += 2) { if ($n * $n >= $loc) { $n_sq = $n * $n; last; } }
	my $c = ($n - 1) / 2;
	for (my $m = 2; $m <= 8; $m += 2) {
		if ($loc >= $n_sq - $c*$m) { 
			$d = $c + abs($loc - ($n_sq - $c*($m - 1)));
			last;
		}
	}
	return $d;
}

# For part 2, however, since each value relies on both its position and previously-calculated values, we don't have much
# choice other than to build the spiral. We can walk it in the order R, U, L, D increasing the distance traveled by 1
# after every two moves. (e.g. R1, U1, L2, D2, R3, ...) As we walk we will store calculated values in a hash and then
# use that for neighbor lookup to calculate the next value. Grid structure must be passed in as a reference in order
# to make it easier to do multiple calls to this function to check multiple values. It can be empty.
sub stress_test {
	my $gridref = shift;
	my $target = shift;
	
	$gridref->{"0,0"} = 1 unless (exists $gridref->{"0,0"});
	
	my $x = 0;
	my $y = 0;
	my $d = -1;
	my @dir = ( [1, 0], [0, -1], [-1, 0], [0, 1] );
	my $i = 0;
	my $step = 0;
	my $val = 1;
	while (1) {
		$i++;
		$step++ if ($i % 2);
		$d = ($d + 1) % 4;
		for (my $j = 0; $j < $step; $j++) {
			$x += $dir[$d][0];
			$y += $dir[$d][1];
			$val = calc_val($gridref, $x, $y);
			return $val if ($val > $target);
		}
	}
}

sub calc_val {
	my $gridref = shift;
	my $x = shift;
	my $y = shift;

	if (exists $gridref->{"$x,$y"}) { return $gridref->{"$x,$y"}; }
	my $val = 0;
	for (my $i = -1; $i <= 1; $i++) {
		for (my $j = -1; $j <= 1; $j++) {
			next unless ($i or $j);
			my $xx = $x + $i;
			my $yy = $y + $j;
			$val += $gridref->{"$xx,$yy"} if (exists $gridref->{"$xx,$yy"});
		}
	}
	$gridref->{"$x,$y"} = $val;
	return $val;
}

__DATA__
