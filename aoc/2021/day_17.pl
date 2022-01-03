#!/bin/perl -w
#
# https://adventofcode.com/2021/day/17
#
# Solutions using mathematical analysis rather than brute force. Assumes that x_min > 0 and y_max < 0

use strict;
use POSIX qw(floor ceil);

print "2021 Day 17\n";
my $input = do { local $/; <DATA> }; # slurp it
#$input = "target area: x=20..30, y=-10..-5";
(my ($x_min, $x_max, $y_min, $y_max)) = $input =~ /([-\d]+)/g;

# First we calculate which x velocity values will settle to 0 inside the target area.
# These come from using the sum of integers formula and solving x_min <= (n)(n+1)/2 <= x_max
my $settle_min = ceil((-1 + sqrt(1 + 8 * $x_min))/2);
my $settle_max = floor((-1 + sqrt(1 + 8 * $x_max))/2);
die "No valid settling velocities; these methods won't work\n" if ($settle_max < $settle_min);
my @settled = ($settle_min .. $settle_max);

# Max height will be achieved if the last time step goes from y=0 to y=y_min and x has already settled
# Starting y velocity must have been |y_min|-1 and we must have taken 2*|y_min| time steps to reach the
# target area. We can get the actual max height from the sum of integers 1 .. |y_min|-1
my $max_height = ($y_min)*($y_min + 1)/2;
my $max_time = 2 * abs($y_min);
print "Part 1: We can reach a max height of $max_height\n";

# Now we consider which x & y velocities will finish in the target area at a given time step.
# We will iterate time from 1 to 2*|y_min|; the latter because of the max height analysis earlier.
my %good_start = ();
for (my $t = 1; $t <= $max_time; $t++) {
	# To determine valid y velocities we start with y(t) = vy + (vy-1) + (vy-2) + ... + (vy-(t-1))
	# This simpifies to y(t) = vy*t - sum(0..t-1) = vy*t - (t-1)(t)/2 which is then solved for vy
	my $vy_min = ceil($y_min/$t + ($t-1)/2);
	my $vy_max = floor($y_max/$t + ($t-1)/2);
	my @good_y = ($vy_min .. $vy_max);
	# Determining valid x velocities is a little trickier because of the possibility of settling.
	# We start with the same formulas used for vy but we need to adjust the bounds because if
	# vx < t then these formulas may have given us invalid values based on negative velocities.
	my $vx_min = ceil($x_min/$t + ($t-1)/2);
	my $vx_max = floor($x_max/$t + ($t-1)/2);
	if ($vx_max < $t) {
		$vx_max = -1; # Will cause entire region to be thrown out
	} elsif ($vx_min < $t) {
		$vx_min = $t; # Collapses region, possibly to single value if vx_max == t
	}
	my @good_x = ($vx_min .. $vx_max);
	# Finally we will go back and include any settled values where vx < t was actually okay.
	push @good_x, grep {$_ < $t} @settled;
	# Now that we have all the good velocities, add all combinations to our collection.
	foreach my $x (@good_x) {
		foreach my $y (@good_y) {
			$good_start{"$x,$y"} = $t;
		}
	}
}
print "Part 2: There were ", scalar(keys %good_start), " starting velocity pairs which hit the target\n";

__DATA__
target area: x=282..314, y=-80..-45