#!/bin/perl -w
#
# https://adventofcode.com/2018/day/6

use strict;

print "2018 Day 6\n\n";
my $puzzle = do { local $/; <DATA> }; # slurp it
my @points = map { [split(/, */)] } split(/\n/, $puzzle);

my $min_x = 1000;
my $min_y = 1000;
my $max_x = 0;
my $max_y = 0;
my %count = ( "" => 0 );
my $safe = 0;
my %grid = ();
foreach my $p (@points) {
	$count{"$p->[0],$p->[1]"} = 0;
	$min_x = $p->[0] if ($p->[0] < $min_x);
	$min_y = $p->[1] if ($p->[1] < $min_y);
	$max_x = $p->[0] if ($p->[0] > $max_x);
	$max_y = $p->[1] if ($p->[1] > $max_y);
}

# find closest point for everything within the grid bounds
for (my $y = $min_y; $y <= $max_y; $y++) {
	for (my $x = $min_x; $x <= $max_x; $x++) {
		my $closest = "";
		my $min_dist = 1000;
		my $total = 0;
		foreach my $p (@points) {
			my $dist = (abs($x - $p->[0]) + abs($y - $p->[1]));
			if ($dist < $min_dist) {
				$closest = "$p->[0],$p->[1]";
				$min_dist = $dist;
			} elsif ($dist == $min_dist) {
				$closest = "";
			}
			$total += $dist;
		}
		$grid{"$x,$y"} = $closest;
		$count{$closest}++ if ($closest ne "");
		$safe++ if ($total < 10000);
	}
}
# mark everything on a border as part of an infinite region
foreach my $y ($min_y, $max_y) {
	for (my $x = $min_x; $x <= $max_x; $x++) {
		delete $count{$grid{"$x,$y"}};
	}
}
foreach my $x ($min_x, $max_x) {
	for (my $y = $min_y; $y <= $max_y; $y++) {
		delete $count{$grid{"$x,$y"}};
	}
}
# find remaining maximum
my $max = 0;
foreach my $p (keys %count) {
	next if ($p eq "");
	$max = $count{$p} if ($count{$p} > $max);
}
print "P1: The largest finite area is $max units.\n";
print "\nP2: The size of the safe region within 10000 of all coordinates is $safe units\n";

__DATA__
81, 46
330, 289
171, 261
248, 97
142, 265
139, 293
309, 208
315, 92
72, 206
59, 288
95, 314
126, 215
240, 177
78, 64
162, 168
75, 81
271, 258
317, 223
210, 43
47, 150
352, 116
316, 256
269, 47
227, 343
125, 290
245, 310
355, 301
251, 282
353, 107
254, 298
212, 128
60, 168
318, 254
310, 303
176, 345
110, 109
217, 338
344, 330
231, 349
259, 208
201, 57
200, 327
354, 111
166, 214
232, 85
96, 316
151, 288
217, 339
62, 221
307, 68