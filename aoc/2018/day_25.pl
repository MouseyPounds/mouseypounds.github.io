#!/bin/perl -w
#
# https://adventofcode.com/2018/day/25

use strict;

print "2018 Day 25\n\n";
my $puzzle = do { local $/; <DATA> }; # slurp it

my @unknown = ();
my @known = ();
foreach my $line (split("\n", $puzzle)) {
	# copy in coordinate array and add an extra field for constellation id
	push @unknown, [split(',', $line), -1];
}

my $con = 1;
my $start_k = 0;
push @known, shift @unknown;
$known[0][4] = $con;

while (scalar(@unknown)) {
	# Basic process is to iterate over newly-added known stars and check all
	# still unknown stars to see if they are close enough to join a constellation.
	# If so, we assign them the appropriate constellation id and mark them for
	# later transfer into the known array once the looping is finished.
	my $end_k = $#known;
	for (my $k = $start_k; $k <= $end_k; $k++) {
		my @indices_to_move = ();
		for (my $u = 0; $u <= $#unknown; $u++) {
			if (dist($known[$k],$unknown[$u]) <= 3) {
				$unknown[$u][4] = $known[$k][4];
				push @indices_to_move, $u;
			}
		}
		# Descending-order sort so that the splices don't mess up the ids.
		foreach my $i (sort {$b <=> $a} @indices_to_move) {
			push @known, splice(@unknown, $i, 1);
		}
	}
	if ($end_k == $#known) {
		# No new stars were marked known, so try to start a new constellation.
		if (scalar @unknown) {
			$unknown[0][4] = ++$con;
			push @known, shift @unknown;
		}
	}
	$start_k = $end_k + 1;
}

print "P1: There are $con constellations.\n";

sub dist {
	(my ($a, $b)) = @_;
	return abs($a->[0] - $b->[0]) + abs($a->[1] - $b->[1]) + abs($a->[2] - $b->[2]) + abs($a->[3] - $b->[3]);
}

__DATA__
-6,-7,-6,0
0,-4,5,-4
-4,8,-1,-6
0,-2,-4,-7
8,8,1,6
5,-7,-1,4
-1,-4,1,-7
0,7,6,0
-1,-8,-4,-6
4,0,0,-1
6,2,-7,-1
-2,3,0,0
7,0,-6,0
0,-8,-4,-4
1,6,8,-7
8,-3,-1,8
5,1,-2,4
-4,-5,-3,5
-3,-3,8,8
7,-2,-3,8
5,-8,8,-1
-6,-7,6,3
-5,4,-7,-5
6,-5,3,-1
3,-8,-8,-8
1,0,8,7
1,1,6,-4
7,-3,-4,-2
4,0,-4,6
-2,7,-2,8
1,6,6,-7
-4,-3,-1,-1
4,0,-3,-6
-7,2,0,2
4,0,-5,-5
8,7,-3,8
-7,4,0,-3
4,0,1,6
-2,-6,0,3
-8,0,7,-2
8,-3,6,4
4,2,-2,-8
7,1,0,7
-2,8,2,-5
2,1,1,4
-6,-5,-4,8
6,-7,0,-8
-3,1,2,0
1,5,-3,-7
8,0,2,-7
1,6,0,-1
-6,4,2,-8
0,-6,-5,-8
4,0,-6,-3
-2,-3,6,-6
6,-1,0,-3
5,4,-6,8
7,-4,-3,0
-5,-5,7,7
0,8,-6,7
-3,4,1,5
2,3,-5,5
-4,6,4,8
-8,-2,0,-7
3,5,-3,1
-5,-6,8,-7
-6,1,5,2
-1,-4,-8,-5
0,-1,-8,-8
4,-3,8,7
-1,3,-1,8
-6,4,-6,8
-7,-3,-5,2
-7,-2,-7,1
1,8,0,-8
6,0,3,-5
1,4,0,6
7,-3,2,6
0,6,3,-1
-3,7,1,3
-6,-7,-6,-1
0,5,5,-1
-8,6,0,-1
7,0,-2,-5
-4,1,-4,0
-2,8,-1,5
-8,2,7,-5
-1,-4,-6,5
-6,8,4,-2
1,6,1,5
3,0,7,-5
3,5,3,0
-8,7,3,-7
-6,6,1,-4
7,6,-5,3
4,-2,3,-5
-3,5,-5,0
5,-1,-7,4
2,7,-6,-2
-7,0,5,-1
-3,8,-1,6
0,-3,-4,5
3,4,8,7
-7,3,3,-1
-8,-5,5,-2
-7,3,-6,3
2,-6,7,3
-7,-2,-3,-7
-8,0,-2,-6
1,-3,6,-3
3,-8,-5,-8
5,0,8,0
-8,0,-3,0
1,-5,3,-1
0,5,1,7
0,8,-1,-8
-8,-7,3,2
-2,-1,-2,-1
0,5,5,2
4,2,-5,-8
0,3,0,-8
5,1,6,-6
-8,8,8,-3
-8,-2,7,-1
5,-3,4,2
-3,7,-8,2
8,-4,4,3
0,-8,8,7
4,0,1,-2
7,8,0,6
-2,3,-4,-3
8,-3,0,-2
0,7,1,2
-6,2,4,3
8,2,-7,-1
0,-7,-5,7
3,-2,-6,8
-4,-1,-8,2
3,-3,-5,-5
-3,8,-8,0
-3,8,-1,-4
0,6,2,-5
-3,5,6,1
0,-1,8,-5
0,0,-5,5
7,1,-2,-7
-8,-2,-6,4
0,-4,1,4
1,-6,6,-3
1,5,-2,7
-4,5,-4,0
7,6,-8,6
-1,-2,-6,6
6,0,7,-8
-4,-2,5,0
-3,8,-7,7
0,0,3,-6
1,-6,-6,-6
2,-2,-6,-2
7,7,0,1
7,-1,0,-3
3,1,4,0
7,7,-4,6
6,6,3,-1
-1,4,4,0
-3,2,7,5
0,1,6,-7
-6,4,-1,-6
1,4,-4,0
-5,-8,4,-2
-6,5,-2,4
-8,-4,7,3
6,-2,0,6
-3,3,6,6
-5,-8,7,-7
-1,-2,-5,-4
-3,-4,-7,6
1,6,7,4
-1,3,-7,3
3,-7,1,1
6,-5,-5,-8
3,0,-1,4
1,-5,-1,-6
-8,-4,-2,8
6,8,5,5
-3,-7,5,-7
5,-4,6,5
-2,4,-5,7
8,3,-6,-2
8,1,0,5
4,4,0,6
1,4,6,3
-8,2,-5,6
3,-6,-5,0
-7,0,1,-2
5,7,-1,7
2,-8,2,-3
2,-3,8,0
8,1,7,-5
4,-3,1,0
2,8,6,0
-5,7,-4,-1
-8,-6,-3,5
-8,2,-7,6
3,1,-3,-7
-5,2,-7,5
-4,-7,7,0
8,-4,5,-6
4,-3,-2,6
-1,-7,3,-5
-3,-5,-3,-2
-8,2,5,-3
-6,5,8,-4
-4,5,-5,7
2,7,3,-1
0,3,3,0
-6,-4,4,0
2,3,-1,7
6,6,-3,6
-7,5,0,-4
-1,0,1,3
5,-1,5,-1
0,-6,-2,-8
-3,0,0,6
3,-8,4,-3
-1,-5,-5,0
-8,-2,4,-4
-5,0,3,4
-8,-3,0,-6
7,-7,-2,-6
8,7,-7,1
5,7,-7,8
7,-1,2,-5
-2,5,-7,2
-1,-6,0,-3
-6,1,-6,5
-2,-5,-6,1
8,8,7,4
-5,0,3,6
0,8,-4,0
-7,-2,-2,5
-8,-1,-6,-7
6,-6,-7,-6
-2,-7,7,0
1,4,1,2
-2,8,-3,3
6,3,6,-4
0,-1,7,-4
0,5,0,0
-4,0,4,-8
-3,0,-7,6
4,-2,-5,-5
2,0,-7,-3
0,3,6,-3
-3,5,0,1
-6,5,-1,2
-4,-2,2,-6
-2,2,-8,5
0,3,3,6
-5,-5,5,0
8,1,-6,2
-1,-2,-4,3
-7,7,0,4
-4,6,-8,8
-1,0,5,-3
7,-1,7,-1
3,-6,-5,-2
-8,-5,6,6
5,2,-2,-2
1,-3,0,0
-3,0,1,6
-5,6,4,4
-2,8,-1,-7
-4,3,-8,-2
-1,0,6,8
7,-6,-5,-7
-8,-5,0,6
0,-2,7,4
8,7,-7,-8
4,2,5,-6
-5,-2,-7,-8
2,7,8,2
0,-4,5,2
-2,8,3,1
0,-8,3,-8
0,-7,6,0
-2,1,-7,0
8,3,5,-1
8,2,6,-6
-5,-2,8,-7
-5,-8,0,0
-8,-5,-4,-8
5,-3,6,-3
-7,-1,-6,-6
-1,-2,8,-3
-2,-7,2,-4
7,2,0,6
-1,-6,8,-6
-8,-6,0,0
4,-7,0,5
6,0,5,6
-5,7,-3,5
-7,5,-4,-8
-8,-2,6,-3
-1,6,-8,4
0,-8,-5,5
-2,-7,-1,-1
2,4,-4,1
8,7,-4,0
-4,0,-4,8
4,-7,-7,-8
0,-5,4,3
6,3,0,6
-7,0,-3,5
-5,6,-7,-3
6,0,-3,1
8,3,-5,-6
8,-1,6,-2
4,-6,6,-3
4,-7,-6,-2
3,7,-6,-3
-8,0,3,7
-7,5,7,7
7,5,-3,-8
0,4,0,-2
-1,-6,4,4
0,4,7,-5
-5,2,2,1
-6,-8,-1,-6
8,4,2,4
-4,-4,1,0
3,5,0,-1
-5,-3,5,0
-5,-8,7,-6
0,-7,4,-7
3,2,-8,-4
8,-7,8,-1
-2,6,-1,5
8,-1,0,5
-6,5,-7,-2
5,3,7,3
0,-8,6,-1
2,-6,0,-5
1,-3,-7,-7
7,-6,-6,-4
0,1,7,7
1,-3,-3,-4
0,-1,-1,1
-8,8,8,7
2,5,-4,-1
0,5,2,4
-1,-2,-5,2
-5,7,8,-8
0,-8,2,4
-4,-5,-8,3
-3,-7,0,0
-3,-8,3,-5
4,1,1,3
5,8,5,-8
1,2,8,0
-3,2,2,5
-4,-1,-1,-4
0,8,-4,-4
-4,0,-8,8
-8,4,3,-8
-7,-5,-2,6
-7,-4,6,-6
-5,3,7,-1
-5,-7,-1,5
6,7,6,-6
-3,3,-3,6
-3,3,-6,-5
7,-4,6,-7
6,-1,8,7
-4,5,-7,2
-5,2,-4,-6
7,0,-6,-4
-1,8,2,2
5,-4,-6,-7
8,2,-8,0
-3,5,0,-8
4,-3,-1,0
1,-3,-5,-5
8,5,0,3
8,-3,-7,-1
-2,-7,-3,-8
-6,0,-5,-6
-2,-5,3,-5
-8,4,-7,-3
-4,-7,-8,4
-8,0,-4,0
7,5,6,5
-2,4,-5,6
-4,-6,3,1
-5,4,-2,-7
0,-3,8,3
-8,0,6,-6
1,-1,3,6
-6,7,5,4
-5,4,-5,6
0,-6,3,5
-5,7,0,-8
1,5,1,0
4,-3,6,3
-5,-1,2,-2
4,7,-2,5
0,-3,8,7
-8,0,0,6
4,0,-6,1
7,0,4,-2
8,-2,-7,-7
0,-7,-3,-3
-1,-5,0,-5
-1,-4,-8,5
7,-2,5,-7
-1,6,-8,5
3,-4,5,-8
5,-6,-1,0
-5,1,-1,-8
-3,-5,-8,2
2,-3,0,5
-3,4,-1,-3
1,4,0,-4
-2,7,1,0
0,-5,-7,-3
1,5,-2,-2
-2,-4,1,-5
1,4,-2,-4
-4,-2,-1,-5
-3,3,7,-5
4,4,6,7
0,0,-8,2
5,4,-5,-6
-3,5,0,7
3,0,2,8
5,0,4,6
-8,-3,-2,-8
-3,8,1,-5
2,7,7,6
7,6,7,8
2,7,-6,6
2,0,-6,8
1,7,0,4
-4,0,0,6
2,1,-3,-3
-1,-3,6,-5
-6,-3,0,-3
-8,6,0,-4
-7,-8,-6,1
0,0,8,0
-2,-8,-6,-1
-5,-6,-8,-8
7,-6,5,-4
8,-1,2,-6
-5,-7,7,-6
5,1,0,3
0,8,0,-3
-1,6,-6,-8
-4,-5,0,-2
0,3,0,-3
-1,0,0,-4
-7,6,-2,3
8,-1,5,7
0,7,-3,1
-2,-5,2,8
5,1,-5,-1
6,-6,-8,6
-5,6,-7,-2
2,1,1,0
-8,3,8,-2
3,6,-5,0
0,5,1,-1
1,-4,6,-7
5,-7,-3,7
-5,3,-7,-3
2,2,7,-2
-6,-7,0,8
-8,-5,7,-1
6,5,-4,5
4,6,-1,-3
-5,-3,-1,8
4,7,0,-7
-7,-7,5,5
-2,0,-1,-3
-2,4,0,1
2,0,0,4
3,0,3,-6
8,-6,6,-7
0,3,0,0
0,-4,-1,6
6,-7,3,-2
-5,-8,-2,-7
-3,3,0,1
-8,-8,2,0
6,6,3,0
-1,-7,-4,0
6,6,-3,0
0,1,0,3
3,0,-1,-1
-6,-8,4,6
-3,1,-4,8
-8,-1,1,-5
-6,2,0,1
-3,-2,-6,7
0,6,5,1
-2,-1,6,5
-1,-8,0,-4
3,0,-1,-4
3,3,-5,0
-5,-5,7,-2
3,0,4,0
-6,6,6,-7
7,-1,-7,5
-2,-5,5,6
-3,-3,2,0
-6,-8,6,-2
7,7,4,-5
0,3,-6,-8
7,2,-1,4
0,3,6,-2
7,6,-7,5
0,4,5,-3
0,-6,-2,0
-7,-7,-7,4
0,-1,1,-3
7,6,-6,4
6,6,1,-6
3,-6,-2,3
-3,6,-6,-8
4,2,-2,-2
0,2,-5,-8
-5,4,3,0
-6,-6,-1,1
0,-2,-8,-6
-5,7,2,7
-3,5,-3,-8
-5,-2,-4,-3
-6,5,-2,-8
0,8,-8,-2
-7,1,-1,-7
-8,-6,-2,-1
3,-7,6,0
6,6,-5,-1
-3,-8,6,-1
-4,8,5,0
-3,8,-6,-6
-1,-7,5,-7
-8,7,1,3
-1,4,-3,-2
0,5,2,6
3,8,2,-3
-2,-6,4,7
-2,-8,4,-2
8,-4,5,1
1,1,5,4
0,0,-3,-4
3,4,1,2
-2,7,-7,-8
5,1,3,-7
-8,6,0,-7
5,-5,2,8
3,-7,3,7
0,0,2,0
-7,-2,3,-2
-7,1,-8,-8
6,5,-7,1
-2,4,-5,-6
0,1,6,0
-1,0,-3,-7
-3,8,-2,1
6,5,3,1
-1,-6,6,0
-3,-6,7,-8
6,6,0,0
7,-8,4,0
1,0,0,-6
2,0,1,4
-4,0,7,-5
3,-4,5,-5
8,8,0,-1
-1,1,-5,0
3,6,5,-4
0,-3,-4,0
6,-1,-7,8
0,-2,0,-2
-8,0,3,0
-4,4,1,4
-5,4,0,3
0,-5,-6,1
0,4,-5,3
-3,2,0,-2
-4,-6,0,7
-7,0,2,-7
2,-3,-6,2
-7,5,-7,-4
0,-3,-1,0
7,3,7,7
4,3,-3,4
3,8,-3,8
-4,5,-8,-4
5,5,6,2
0,-7,-1,1
-6,-8,0,-5
-5,6,0,2
0,-7,-2,-8
-3,3,2,-4
8,6,-5,0
4,-4,-4,-8
-1,2,-6,8
-7,-7,4,0
2,-5,-8,-5
-3,-4,2,0
4,5,0,0
-5,8,-5,-8
6,5,6,4
4,3,0,5
3,-6,-7,-2
1,2,5,5
-1,2,-2,-1
-8,0,-3,-1
-4,5,-3,8
5,6,0,-4
-1,-4,0,-8
-3,7,1,7
1,1,-5,8
-2,-4,4,-1
0,0,-7,-1
4,0,5,-3
-1,8,-1,6
-3,1,-4,-2
-3,-7,-4,-5
2,-2,-4,-1
4,-4,5,-2
7,-7,-4,3
1,0,-2,-6
7,-4,7,-4
6,-6,8,-7
-7,4,-3,-8
-1,-1,6,-2
0,0,-2,-6
-7,0,-5,-4
1,-5,0,8
-8,-2,6,-6
7,3,-3,-2
1,2,0,-2
2,-3,8,-2
-7,-5,0,-5
-4,8,-3,-5
-4,-2,-8,5
4,-8,3,5
3,-5,0,-6
-3,6,5,5
3,-1,0,6
0,-1,6,-7
1,-8,8,-5
3,0,-6,-5
7,3,7,8
2,-3,-1,-2
-6,7,-6,-3
2,8,7,-5
0,4,0,6
-4,-6,-1,-8
-7,2,1,-5
5,1,0,4
-6,6,-1,7
7,-1,0,7
3,2,3,0
8,6,-6,8
5,-3,-7,-5
6,-5,-6,0
5,8,4,-3
-6,-5,0,-6
-5,2,-2,-5
1,3,4,0
0,0,-1,-7
1,7,-5,4
-6,-5,3,2
-1,-2,-7,-1
0,1,-6,-3
-3,-4,0,-7
3,6,-1,1
1,5,-3,7
3,0,-2,-6
8,6,2,2
-1,7,0,5
6,2,2,6
-6,-1,-6,-5
0,0,2,-1
0,2,2,0
-5,0,-1,-7
0,6,4,7
-5,0,7,1
-5,-8,-5,7
0,-3,7,0
-4,3,-3,-6
-4,0,8,1
8,1,7,2
-6,-3,-8,-6
-4,-4,8,8
3,8,7,-4
0,4,5,7
-3,-6,1,6
0,8,-8,5
-8,4,-4,8
-3,3,-8,-5
2,7,0,0
0,7,-6,-3
1,6,4,3
8,7,-5,0
0,8,-8,-1
7,1,7,7
8,3,-6,0
6,0,6,-3
-3,1,6,-8
-6,-2,3,1
7,0,7,2
5,8,0,0
0,1,-6,8
0,-5,5,1
0,-6,8,-6
0,8,4,-7
5,-2,-7,5
-3,5,2,-3
-6,-6,-6,5
-7,-1,-3,1
3,8,-6,-8
-4,7,2,4
-1,-5,-6,4
0,3,-3,0
-3,-3,0,2
-3,0,-8,-5
1,0,3,-3
7,-3,4,-2
6,-6,5,-4
-1,-3,-8,-7
0,1,-1,-6
4,-3,6,8
0,-5,7,1
-8,1,2,8
2,-2,4,-1
-5,4,5,5
-3,-8,4,7
-6,1,-5,-8
5,6,5,2
6,2,-7,3
5,-5,8,7
-7,1,1,2
-3,-1,0,-3
-8,8,-2,7
2,2,4,6
-4,0,6,-6
-3,2,7,4
7,-2,1,-7
-6,-4,-8,-3
-1,7,5,-6
3,1,-2,7
-4,1,-7,-7
3,-8,-2,0
3,1,-7,5
7,-5,6,-5
1,0,5,-4
0,-3,-4,-6
2,7,1,6
-7,7,4,-6
3,0,1,-5
3,-8,1,8
7,5,-2,-7
3,-1,0,0
5,-6,8,6
1,8,-3,7
1,-1,-5,0
1,3,6,-5
-1,6,-5,-3
4,1,-8,2
5,8,3,8
7,8,7,1
-6,0,4,0
0,-1,0,-5
5,6,-6,-3
8,5,2,6
-2,0,4,5
-2,4,0,8
7,-1,0,3
5,7,7,-5
-1,2,-6,-1
-6,5,-6,-5
0,-7,5,-7
-1,2,3,-5
3,4,0,3
2,-2,7,4
8,-3,8,0
3,-2,-2,0
1,0,-2,1
-5,-6,-4,0
7,1,4,1
8,3,-1,-1
-4,3,0,7
-5,0,6,-7
0,-5,-2,6
8,3,-3,-3
2,-8,5,-5
-2,1,-4,3
-2,-3,-6,-2
3,4,4,4
-8,4,2,6
6,0,5,0
0,-1,6,-4
-2,-8,4,-6
-2,6,0,1
-2,-8,-5,1
-8,-6,-6,-2
3,-5,-1,-2
7,-2,2,-8
-6,-2,-1,7
8,2,-1,-8
6,5,-6,-8
5,-3,5,2
-4,-2,-6,1
5,-8,-5,3
7,1,-7,-6
2,0,-8,7
-2,4,2,0
3,-5,7,-5
-7,7,-5,4
-7,-8,0,-4
-4,7,0,4
-3,-3,0,-1
-6,-5,-3,4
4,1,0,2
2,2,-2,-2
1,7,1,0
7,1,-5,0
-1,0,-4,-7
-6,-8,6,-7
0,7,-3,-5
1,0,-7,6
8,8,1,3
4,-8,5,-6
5,3,-2,0
8,-3,-6,-4
-4,2,3,6
4,3,0,7
6,-8,0,3
-6,4,-8,4
6,1,-7,-8
-3,-3,4,3
6,0,-1,7
1,8,-5,8
-5,5,5,-6
2,0,-8,-5
7,3,-6,-5
1,4,-8,-2
-4,4,0,-1
-3,6,1,3
4,-8,-3,-1
5,8,4,4
0,-7,8,2
6,7,0,-2
-4,-4,0,-6
-4,-4,-5,8
-2,-4,-7,-7
2,4,-2,-3
-2,6,-3,-1
-7,-6,6,-2
8,-2,4,5
-6,7,2,2
-5,4,7,3
-7,2,4,-1
-3,6,-7,-5
4,-6,4,6
5,1,6,4
-8,-4,-7,-8
-4,-8,3,8
-4,8,-3,-7
7,4,-7,4
-8,-7,0,-3
0,-5,-7,3
3,3,-1,-6
-6,1,-6,7
-3,-7,0,-8
5,6,6,5
1,-2,-3,-1
1,-4,3,6
1,-7,-2,3
-8,8,7,1
-2,4,-8,5
-3,3,-8,-4
-6,7,7,-1
1,5,0,5
1,-7,0,3
3,-1,-4,6
-7,0,-8,-2
4,7,-5,3
-4,7,-2,-4
3,6,1,-6
3,-8,5,-2
2,-5,-4,-2
0,1,6,2
0,5,-3,4
-5,-6,-2,7
4,-1,-2,-5
-5,-8,4,-6
7,-6,-7,-4
-5,0,-6,3
2,6,6,3
2,6,4,-6
1,7,-4,5
-2,0,6,-2
8,-8,8,8
4,6,2,-2
-7,8,-3,-7
2,2,-8,-7
6,-5,-8,-7
3,5,1,2
1,1,-5,-6
0,-4,4,-8
2,-5,-4,7
-6,-8,-5,-2
8,-3,-7,-4
3,5,8,-2
7,-6,-8,2
-6,-8,-3,0
-3,4,-5,0
4,-1,-6,8
7,-6,7,-6
-5,4,4,3
4,0,-6,8
-2,1,-3,0
0,1,7,-7
0,6,3,0
3,0,-6,-4
2,5,8,-3
5,-4,8,-1
0,-7,-8,-7
8,2,8,-5
2,-3,7,5
8,4,-7,-4
8,-3,1,-8
-8,0,-3,1
5,6,-7,2
-1,-4,0,7
-2,0,4,3
6,4,5,2
2,0,-5,0
5,4,0,2
8,0,-3,-6
3,-1,-2,-8
-2,7,-4,8
1,3,6,6
-3,-4,-8,6
1,6,5,5
-4,5,1,-4
6,-3,3,-4
0,6,6,-4
2,2,5,1
-4,-1,-1,-8
7,2,5,2
-1,-6,-4,4
5,-4,-5,0
-6,4,0,6
7,8,-4,0
-1,-5,4,0
4,3,4,1
3,-6,7,-5
0,3,-2,1
-7,-2,0,-2
-5,-6,0,-2
-2,7,3,3
1,7,-8,-1
-5,-4,0,8
-5,8,-1,5
-7,5,4,7
-5,-4,0,7
1,3,-8,4
8,0,-6,-2
8,5,-5,4
7,-2,-6,2
1,-4,1,-4
0,3,1,0
7,2,-7,-2
-2,3,-2,-7
-5,-7,-3,-8
0,-3,5,-8
8,1,-2,1
-2,5,8,1
2,-5,-3,-1
-1,-5,3,-6
-7,-4,-2,8
4,1,-1,3
6,2,8,3
-1,-5,0,5
5,3,0,5
-4,-6,0,3
-2,0,3,3
8,7,0,-5
1,1,3,8
1,7,-3,6
5,-2,-1,4
-7,4,-1,-7
-5,7,-5,3
-2,-2,-4,0
-3,2,-7,2
7,-2,-4,1
8,-2,-2,4
-1,-6,-6,5
6,-7,-1,-3
-8,-6,8,-5
6,0,-7,1
-1,8,-8,7
-4,2,0,1
0,4,-1,4
6,6,1,-4
-1,-2,7,-5
-3,4,-3,8
4,-8,-3,-2
-1,-8,1,-5
0,-4,-2,-5
-6,-8,-4,-1
4,0,-6,-7
3,-3,-4,-1
-1,3,-1,4
0,4,7,-1
-4,8,7,1
3,1,-4,0
8,-4,-2,0
-5,-2,-5,-8
6,-8,-2,1
5,2,-3,0
0,-8,7,8
1,-5,4,6
6,-6,-8,-8
8,-3,-2,-2
8,-4,8,-8
6,-8,-1,-3
-8,2,-4,-1
7,-1,-3,-5
0,-1,-3,-4
-8,-1,-7,-8
0,-1,2,-6
-2,1,-8,4
-5,1,-8,8
-5,-2,6,0
6,-6,1,8
-4,6,-1,-6
3,-5,5,-4
-8,-7,6,6
0,1,5,0
5,0,1,6
8,-1,-1,-1
-7,-5,5,8
6,1,0,2
7,8,1,4
2,5,-6,-3
3,-1,1,-2
1,4,1,4
2,0,4,6
8,8,2,-7
-5,-7,2,5
-5,-2,1,-7
0,-5,-5,4
-1,-5,1,2
-4,1,-1,0
1,0,-1,2
1,7,0,-6
-5,5,0,7
8,-7,-3,3
1,5,0,0
6,5,7,7
-2,5,8,-5
-7,4,6,-2
-5,4,-2,4
-4,1,-1,-1
-6,-7,-3,-7
-4,-6,-8,-8
-8,7,8,-1
4,0,7,-3
1,7,-1,-2
-8,3,0,-3
6,4,8,8
-7,6,5,-8
8,1,-3,-1
-4,2,0,-4
5,-8,3,3
-5,2,-5,-6
-8,6,2,-6
-1,6,7,8
2,8,-7,-7
0,-3,3,-2
5,-6,6,-3
-7,-4,0,-6
-3,2,0,-1
-7,-1,6,6
-5,-3,2,-4
4,0,-6,7
4,5,-8,0
-2,5,4,4
6,-1,-2,-1
-5,1,-1,3
0,-7,5,-1
0,0,0,3
7,0,3,-5
8,2,-6,4
2,1,3,6
2,-3,-7,4
6,0,3,-6
6,-1,-6,8
8,-1,-7,6
-6,-5,-5,2
0,8,-8,-8
-6,0,5,3
1,-3,2,0
-5,0,-4,-4
-5,-8,0,-6
-6,-7,-7,-2
-2,3,-4,0
-5,0,-8,8
7,6,-4,8
4,-5,4,8
0,8,5,-6
7,7,1,-2
1,-7,0,4
-1,6,4,5
3,-6,-8,-7
5,-7,-1,0
-4,-4,2,6
0,2,6,0
8,-5,3,2
-4,-4,2,0
3,5,-6,-3
-3,-5,-6,-4
-8,5,1,3
-3,-6,0,3
0,5,-4,-8
-6,-3,4,5
0,3,5,-8
-6,5,-5,-3
-6,0,-8,-7
5,2,4,-5
-2,-6,-3,5
3,1,-1,-1
3,-6,0,5
-4,0,4,3
8,0,0,8
-7,-2,2,3
-5,7,-1,-6
4,8,1,0
-3,4,-2,2
1,6,8,6
-7,-2,-3,6
-8,-8,0,-7
-1,-5,-5,6
7,5,3,-5
7,2,7,-8
0,6,8,5
4,1,-6,1
-2,-3,7,1
4,-8,2,0
7,5,-2,0
5,-5,5,-1
0,0,-6,-8
-3,4,-3,-6
0,5,7,-1
2,-1,-7,-5
-3,1,-7,1
2,-1,4,0
0,7,4,5
8,0,3,-3
-1,3,1,-8
-4,-3,-5,-2
8,-5,6,6
8,5,2,3
-5,3,-7,-1
-8,-5,7,-6
6,0,-8,-1
-8,-3,8,-4
7,8,3,-4
-3,5,3,7
-8,5,0,5
-7,4,4,1
2,-4,4,-4
-2,5,-6,5
-4,1,-4,-1
8,0,-5,-2
4,6,-1,0
6,-5,-4,-4
8,4,0,0
0,-4,-4,4
-3,-7,-8,1
7,-7,2,-4
4,5,-3,0
-8,-7,-6,5
3,-3,5,-3
8,-4,-4,-1
-8,-5,6,-2
3,0,-3,6
-8,2,7,-7
8,7,6,4
-2,-2,8,-7
5,5,5,0
0,7,2,-1
6,-4,-6,-8
-1,-1,0,-8
-7,0,-1,-1
2,-2,-8,2
-1,-1,0,5
2,7,6,7
-5,0,0,5
6,0,0,3
4,-6,0,7
-6,-4,8,6
-2,-6,-4,-3
-7,-3,-6,-3
0,6,0,-8
1,5,-3,4
7,-8,-8,-8
-1,-4,-3,-6
6,4,4,0
-7,-5,-5,-3
5,3,-7,0
5,0,6,-1
0,8,2,0
-2,-7,-6,5
1,4,-7,-3
-5,3,1,-3
6,7,5,1
0,0,0,-7
1,-5,-4,-5
4,6,-3,3
0,-8,-6,6
0,4,-6,-3
-3,3,2,0
3,-8,6,-4
7,-3,-6,5
0,-1,8,-3
0,4,6,-8
0,-2,-4,5
6,0,-7,-6
-6,-2,8,-7
7,-6,4,0
2,1,-4,-2
1,-7,-3,-1
-3,0,5,4
-3,5,3,5
6,1,-8,-3
1,-4,4,4
1,-7,-2,6
4,1,-6,0
-1,6,4,-3
-1,7,-6,-4
-8,6,2,6
-1,0,-1,8
7,-5,1,-3
-8,2,-1,-5
2,0,4,7
5,6,0,0
5,8,6,-3
-5,-7,4,-6
-5,8,-5,8
-2,6,6,-3
-1,-1,5,-8
-6,3,4,0
2,-1,-2,-8
8,0,5,-8
-6,0,-4,0