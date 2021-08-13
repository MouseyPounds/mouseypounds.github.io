#!/bin/perl
#
# https://adventofcode.com/2019/day/12

use strict;
use POSIX;

my @moon = ();
my @moon2 = ();

while (<DATA>) {
	my ($x, $y, $z) = /x=(.*), y=(.*), z=(.*)/;
	push @moon, { 'pos' => {'x' => $x, 'y' => $y, 'z' => $z }, 'vel' => { 'x' => 0, 'y' => 0, 'z' => 0 } };
	push @moon2, { 'pos' => {'x' => $x, 'y' => $y, 'z' => $z }, 'vel' => { 'x' => 0, 'y' => 0, 'z' => 0 } };
}

for (my $t = 1; $t <= 1000; $t++) {
	# gravity
	for (my $i = 0; $i <= $#moon; $i++) {
		for (my $j = $i + 1; $j <= $#moon; $j++) {
			foreach my $axis (qw(x y z)) {
				if ($moon[$i]->{'pos'}{$axis} < $moon[$j]->{'pos'}{$axis}) {
					$moon[$i]->{'vel'}{$axis}++;
					$moon[$j]->{'vel'}{$axis}--;
				} elsif ($moon[$i]->{'pos'}{$axis} > $moon[$j]->{'pos'}{$axis}) {
					$moon[$i]->{'vel'}{$axis}--;
					$moon[$j]->{'vel'}{$axis}++;
				}
			}
		}
	}
	# velocity
	for (my $i = 0; $i <= $#moon; $i++) {
		foreach my $axis (qw(x y z)) {
			$moon[$i]->{'pos'}{$axis} += $moon[$i]->{'vel'}{$axis};
		}
	}
	# summary
	if ($t % 1000 == 0) {
		print "\nAfter $t step(s):\n";
		for (my $i = 0; $i <= $#moon; $i++) {
			print print_moon($moon[$i]);
		}
	}
}

print "\nEnergy Summary:\n";
my $sum = 0;
for (my $i = 0; $i <= $#moon; $i++) {
	printf "%d: pe=%2d, ke=%2d, te=%4d\n", $i, calc_pe($moon[$i]), calc_ke($moon[$i]), calc_te($moon[$i]);
	$sum += calc_te($moon[$i]);
}
print "Total energy: $sum\n\n";

# Optimizations for part 2:
# - Since each axis is independent, you can search for the period of repetition for each.
# - Velocities will be zero halfway through the cycle, so we can check for that and then multiply by 2 later.
my %found = ( 'x' => 0, 'y' => 0, 'z' => 0 );
my $t = 0;
my $done = 0;
while (not $done) {
	$t++;
	# gravity
	for (my $i = 0; $i <= $#moon2; $i++) {
		for (my $j = $i + 1; $j <= $#moon2; $j++) {
			foreach my $axis (qw(x y z)) {
				if ($moon2[$i]->{'pos'}{$axis} < $moon2[$j]->{'pos'}{$axis}) {
					$moon2[$i]->{'vel'}{$axis}++;
					$moon2[$j]->{'vel'}{$axis}--;
				} elsif ($moon2[$i]->{'pos'}{$axis} > $moon2[$j]->{'pos'}{$axis}) {
					$moon2[$i]->{'vel'}{$axis}--;
					$moon2[$j]->{'vel'}{$axis}++;
				}
			}
		}
	}
	# velocity
	for (my $i = 0; $i <= $#moon2; $i++) {
		foreach my $axis (qw(x y z)) {
			$moon2[$i]->{'pos'}{$axis} += $moon2[$i]->{'vel'}{$axis};
		}
	}
	# check for period
	foreach my $axis (qw(x y z)) {
		my $state = "";
		for (my $i = 0; $i <= $#moon2; $i++) {
			$state .= sprintf "%d,", $moon2[$i]->{'vel'}{$axis};
		}
		if ($found{$axis} == 0 and $state eq "0,0,0,0,") {
			print "Found midpoint for axis $axis at step $t\n";
			$found{$axis} = $t;
			if ($found{'x'} != 0 and $found{'y'} != 0 and $found{'z'} != 0) {
				$done = 1;
				last;
			}
		}
	}
}
print "Initial state will be repeated at twice LCM of $found{'x'}, $found{'y'}, $found{'z'}\n";
{
	# LCM algorithm being used: increment smallest value by its base amount until all 3 are the same
	# This is slow as hell and the LCM for my puzzle input is 292653556339368 after doubling.

	my @n = ($found{'x'}, $found{'y'}, $found{'z'});
	my @m = ($found{'x'}, $found{'y'}, $found{'z'});
	my $done = 0;
	while (not $done) {
		if ($m[0] == $m[1] and $m[0] == $m[2]) {
			$done = 1;
		} elsif ($m[0] <= $m[1] and $m[0] <= $m[2]) {
			$m[0] += $n[0];
		} elsif ($m[1] <= $m[0] and $m[1] <= $m[2]) {
			$m[1] += $n[1];
		} else {
			$m[2] += $n[2];
		}
	}
	print "LCM found: $m[0]\nPuzzle solution: " . (2*$m[0]) . "\n";
}

sub print_moon {
	my $m = shift;
	
	return sprintf "pos=<x=%3d, y=%3d, z=%3d >, vel=<x=%3d, y=%3d, z=%3d>\n",
		$m->{'pos'}{'x'}, $m->{'pos'}{'y'}, $m->{'pos'}{'z'}, $m->{'vel'}{'x'}, $m->{'vel'}{'y'}, $m->{'vel'}{'z'};
}

sub calc_pe {
	my $m = shift;
	return abs($m->{'pos'}{'x'}) + abs($m->{'pos'}{'y'}) + abs($m->{'pos'}{'z'});
}

sub calc_ke {
	my $m = shift;
	return abs($m->{'vel'}{'x'}) + abs($m->{'vel'}{'y'}) + abs($m->{'vel'}{'z'});
}

sub calc_te {
	my $m = shift;
	return calc_pe($m) * calc_ke($m);
}
	
__DATA__
<x=-4, y=3, z=15>
<x=-11, y=-10, z=13>
<x=2, y=2, z=18>
<x=7, y=-1, z=0>