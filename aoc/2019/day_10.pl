#!/bin/perl
#
# https://adventofcode.com/2019/day/10

use strict;
use POSIX;

my @asteroids = ();
my $y = 0;
while (<DATA>) {
	chomp;
	my @a = split //;
	for (my $x = 0; $x < scalar(@a); $x++) {
		if ($a[$x] eq '#') {
			push @asteroids, {'x' => $x, 'y' => $y};
		}
	}
	$y++;
}

my $max_num = 0;
my $max_loc = "";
my %seen = ();
my $total = -1; # we don't want to count the asteroid where we are putting the station
foreach my $a (@asteroids) {
	my $key = "$a->{'x'},$a->{'y'}";
	$seen{$key} = {'r' => {}, 'l' => {}};
	my $num = 0;
	foreach my $b (@asteroids) {
		my $slope;
		my $side = ($b->{'x'} >= $a->{'x'}) ? 'r' : 'l';
		if ($b->{'x'} == $a->{'x'}) {
			if ($b->{'y'} == $a->{'y'}) {
				next;
			} elsif ($b->{'y'} > $a->{'y'}) {
				$slope = "999999";
			} else {
				$slope = "-999999";
			}
		} else {
			# Slope alone is not enough to differentiate since our target might be directly between 2 asteroids.
			# So we will add an arbitrary marker for right vs left since above vs below already differentiated
			$slope = ($b->{'y'}-$a->{'y'})/($b->{'x'}-$a->{'x'});
		}
		if (not exists $seen{$key}{$side}{$slope}) {
			$seen{$key}{$side}{$slope} = {};
			$num++;
		}
		my $md = abs($b->{'y'}-$a->{'y'})+abs($b->{'x'}-$a->{'x'});
		$seen{$key}{$side}{$slope}{$md} = "$b->{'x'},$b->{'y'}";
	}
	if ($num > $max_num) {
		$max_num = $num;
		$max_loc = $key;
	}
	$total++;
}

print "\nBest Location $max_loc can see $max_num (of $total) other asteroids\n";

my $i = 1;
while ($i <= $total) {
	foreach my $k (sort {$a <=> $b} keys %{$seen{$max_loc}{'r'}}) {
		my $closest_dist = 999;
		foreach my $j (keys %{$seen{$max_loc}{'r'}{$k}}) {
			if ($j < $closest_dist) {
				$closest_dist = $j;
			}
		}
		if (exists $seen{$max_loc}{'r'}{$k}{$closest_dist}) {
			print "($i) Asteroid at $seen{$max_loc}{'r'}{$k}{$closest_dist} [slope $k, md $closest_dist] vaporized\n";
			delete $seen{$max_loc}{'r'}{$k}{$closest_dist};
			$i++;
		}
	}
	foreach my $k (sort {$a <=> $b} keys %{$seen{$max_loc}{'l'}}) {
		my $closest_dist = 999;
		foreach my $j (keys %{$seen{$max_loc}{'l'}{$k}}) {
			if ($j < $closest_dist) {
				$closest_dist = $j;
			}
		}
		if (exists $seen{$max_loc}{'l'}{$k}{$closest_dist}) {
			print "($i) Asteroid at $seen{$max_loc}{'l'}{$k}{$closest_dist} [slope $k, md $closest_dist] vaporized\n";
			delete $seen{$max_loc}{'l'}{$k}{$closest_dist};
			$i++;
		}
	}
}



__DATA__
#...##.####.#.......#.##..##.#.
#.##.#..#..#...##..##.##.#.....
#..#####.#......#..#....#.###.#
...#.#.#...#..#.....#..#..#.#..
.#.....##..#...#..#.#...##.....
##.....#..........##..#......##
.##..##.#.#....##..##.......#..
#.##.##....###..#...##...##....
##.#.#............##..#...##..#
###..##.###.....#.##...####....
...##..#...##...##..#.#..#...#.
..#.#.##.#.#.#####.#....####.#.
#......###.##....#...#...#...##
.....#...#.#.#.#....#...#......
#..#.#.#..#....#..#...#..#..##.
#.....#..##.....#...###..#..#.#
.....####.#..#...##..#..#..#..#
..#.....#.#........#.#.##..####
.#.....##..#.##.....#...###....
###.###....#..#..#.....#####...
#..##.##..##.#.#....#.#......#.
.#....#.##..#.#.#.......##.....
##.##...#...#....###.#....#....
.....#.######.#.#..#..#.#.....#
.#..#.##.#....#.##..#.#...##..#
.##.###..#..#..#.###...#####.#.
#...#...........#.....#.......#
#....##.#.#..##...#..####...#..
#.####......#####.....#.##..#..
.#...#....#...##..##.#.#......#
#..###.....##.#.......#.##...##