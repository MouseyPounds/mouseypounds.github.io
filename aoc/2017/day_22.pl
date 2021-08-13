#!/bin/perl -w
#
# https://adventofcode.com/2017/day/22

use strict;

print "2017 Day 22\n\n";
my $puzzle = do { local $/; <DATA> }; # slurp it
my @lines = split("\n", $puzzle);

my %grid = ();
(my ($vx, $vy)) = parse_input(\%grid, \@lines);

# directions are n e s w
my $dir = 0;
my @delta = ( [0, -1], [1, 0], [0, 1], [-1, 0] );
my %change = ('.' => '#', '#' => '.');
my %turn = ('.' => -1, '#' => 1);

my $limit = 1e4;
my $infections = 0;
my $burst;
for ($burst = 0; $burst < $limit; $burst++) {
	$dir = ($dir + $turn{$grid{"$vx,$vy"}}) % scalar(@delta);
	$grid{"$vx,$vy"} = $change{$grid{"$vx,$vy"}};
	$infections++ if ($grid{"$vx,$vy"} eq '#');
	$vx += $delta[$dir][0];
	$vy += $delta[$dir][1];
	$grid{"$vx,$vy"} = '.' unless (exists $grid{"$vx,$vy"});
}
print "P1: The virus had $burst bursts of activity and $infections of them caused an infection.\n";

# reset for part 2
%grid = ();
($vx, $vy) = parse_input(\%grid, \@lines);
%change = ('.' => 'W', 'W' => '#', '#' => 'F', 'F' => '.');
%turn = ('.' => -1, 'W' => 0, '#' => 1, 'F' => 2);
$limit = 1e7;
$infections = 0;
$dir = 0;
for ($burst = 0; $burst < $limit; $burst++) {
	$dir = ($dir + $turn{$grid{"$vx,$vy"}}) % scalar(@delta);
	$grid{"$vx,$vy"} = $change{$grid{"$vx,$vy"}};
	$infections++ if ($grid{"$vx,$vy"} eq '#');
	$vx += $delta[$dir][0];
	$vy += $delta[$dir][1];
	$grid{"$vx,$vy"} = '.' unless (exists $grid{"$vx,$vy"});
}
print "P2: The virus had $burst bursts of activity and $infections of them caused an infection.\n";

sub parse_input {
	my $grid_ref = shift;
	my $lines = shift;
	
	for (my $y = 0; $y <= $#$lines; $y++) {
		my @row = split '', $lines->[$y];
		for (my $x = 0; $x <= $#row; $x++) {
			$grid_ref->{"$x,$y"} = $row[$x];
		}
	}

	return ( ((-1 + length $lines->[0]) / 2), ($#$lines / 2) );
}

__DATA__
#.##.###.#.#.##.###.##.##
.##.#.#.#..####.###.....#
...##.....#..###.#..#.##.
##.###.#...###.#.##..##.#
###.#.###..#.#.##.#.###.#
.###..#.#.####..##..#..##
..###.##..###.#..#...###.
........##..##..###......
######...###...###...#...
.######.##.###.#.#...###.
###.##.###..##..#..##.##.
.#.....#.#.#.#.##........
#..#..#.#...##......#.###
#######.#...#..###..#..##
#..#.###...#.#.#.#.#....#
#.#####...#.##.##..###.##
..#..#..#.....#...#.#...#
###.###.#...###.#.##.####
.....###.#..##.##.#.###.#
#..#...######.....##.##.#
###.#.#.#.#.###.##..###.#
..####.###.##.#.###..#.##
#.#....###....##...#.##.#
###..##.##.#.#.##..##...#
#.####.###.#...#.#.....##