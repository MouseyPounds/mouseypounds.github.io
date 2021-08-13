#!/bin/perl -w
#
# https://adventofcode.com/2019/day/24
#

use strict;

use Carp;
use POSIX;

$| = 1;

my $puzzle = do { local $/; <DATA> };
my @lines = split("\n", $puzzle);

my $level = 0;
my %grid = ( $level => {} );
my $y = 0;
my $x = 0;
my $width = 0;
my $height = 0;
for ($y = 0; $y <= $#lines; $y++) {
	my @line = split ('', $lines[$y]);
	for ($x = 0; $x <= $#line; $x++) {
		$grid{$level}{"$x,$y"} = $line[$x];
	}
}
$width = $x;
$height = $y;

print "\nDay 24 (puzzle grid is $width x $height)\n";
my %seen = ();
while (1) {
	my $bd = calculate_biodiversity();
	print "Running ... ($bd)\r";
	if (exists $seen{$bd}) {
		print "P1: Found repeat layout with biodiversity $bd\n";
		last;
	} else {
		$seen{$bd} = 1;
	}
	# update board
	my %to_bug = ();
	my %to_space = ();
	for (my $y = 0; $y < $height; $y++) {
		for (my $x = 0; $x < $width; $x++) {
			my $north = (exists $grid{$level}{"$x,".($y-1)} and $grid{$level}{"$x,".($y-1)} eq '#') ? 1 : 0;
			my $south = (exists $grid{$level}{"$x,".($y+1)} and $grid{$level}{"$x,".($y+1)} eq '#') ? 1 : 0;
			my $west = (exists $grid{$level}{($x-1).",$y"} and $grid{$level}{($x-1).",$y"} eq '#') ? 1 : 0;
			my $east = (exists $grid{$level}{($x+1).",$y"} and $grid{$level}{($x+1).",$y"} eq '#') ? 1 : 0;
			my $adjacent = $north + $south + $east + $west;
			if (($grid{$level}{"$x,$y"} eq '#' and $adjacent != 1)) {
				$to_space{"$level:$x,$y"} = 1;
			} elsif ($grid{$level}{"$x,$y"} eq '.' and ($adjacent == 1 or $adjacent == 2)) {
				$to_bug{"$level:$x,$y"} = 1;
			}
		}
	}
	foreach my $k (keys %to_space) {
		my ($lvl, $key) = split(':', $k);
		$grid{$lvl}{$key} = '.';
	}
	foreach my $k (keys %to_bug) {
		my ($lvl, $key) = split(':', $k);
		$grid{$lvl}{$key} = '#';
	}
}

# reset data for part 2
$y = 0;
$x = 0;
$level = 0;
%grid = ( $level => {} );
for ($y = 0; $y <= $#lines; $y++) {
	my @line = split ('', $lines[$y]);
	for ($x = 0; $x <= $#line; $x++) {
		$grid{$level}{"$x,$y"} = $line[$x];
	}
}
# need to init level above & below as well
foreach my $lvl (-1, 1) {
	$grid{$lvl} = {};
	for (my $xx = 0; $xx < $width; $xx++) {
		for (my $yy = 0; $yy < $height; $yy++) {
			$grid{$lvl}{"$xx,$yy"} = '.';
		}
	}
}


# We are going to try to keep this somewhat generic, using $width & $height instead of a hardcoded 5x5 grid,
# but it should be noted that this logic only makes sense if these values are odd.
my $middle_y = ($height - 1)/2;
my $middle_x = ($width - 1)/2;
my $min;
my $max_time = 200;
for ($min = 1; $min <= $max_time; $min++) {
	print "Running ... ($min)\r";
	# update board
	my %to_bug = ();
	my %to_space = ();
	my %init_levels = ();
	foreach $level (keys %grid) {
		for (my $y = 0; $y < $height; $y++) {
			for (my $x = 0; $x < $width; $x++) {
				next if ($x == $middle_x and $y == $middle_y);
				my $north = 0;
				if ($y == 0) {
					if (not exists $grid{$level - 1}) {
						$init_levels{$level - 1} = 1;
					} else {
						$north = ($grid{$level - 1}{"$middle_x," . ($middle_y - 1)} eq '#') ? 1 : 0;
					}
				} elsif ($y == $middle_y + 1 and $x == $middle_x) {
					if (not exists $grid{$level + 1}) {
						$init_levels{$level + 1} = 1;
					} else {
						for (my $xx = 0; $xx < $width; $xx++) {
							$north += ($grid{$level + 1}{"$xx," . ($height - 1)} eq '#') ? 1 : 0;
						}
					}
				} else {
					$north = ($grid{$level}{"$x,".($y-1)} eq '#') ? 1 : 0;
				}
				my $south = 0;
				if ($y == $height - 1) {
					if (not exists $grid{$level - 1}) {
						$init_levels{$level -1} = 1;
					} else {
						$south = ($grid{$level - 1}{"$middle_x," . ($middle_y + 1)} eq '#') ? 1 : 0;
					}
				} elsif ($y == $middle_y - 1 and $x == $middle_x) {
					if (not exists $grid{$level + 1}) {
						$init_levels{$level + 1} = 1;
					} else {
						for (my $xx = 0; $xx < $width; $xx++) {
							$south += ($grid{$level + 1}{"$xx,0"} eq '#') ? 1 : 0;
						}
					}
				} else {
					$south = ($grid{$level}{"$x,".($y+1)} eq '#') ? 1 : 0;
				}
				my $west = 0;
				if ($x == 0) {
					if (not exists $grid{$level - 1}) {
						$init_levels{$level - 1} = 1;
					} else {
						$west = ($grid{$level - 1}{($middle_x - 1) . ",$middle_y"} eq '#') ? 1 : 0;
					}
				} elsif ($x == $middle_x + 1 and $y == $middle_y) {
					if (not exists $grid{$level + 1}) {
						$init_levels{$level + 1} = 1;
					} else {
						for (my $yy = 0; $yy < $height; $yy++) {
							$west += ($grid{$level + 1}{($width - 1) . ",$yy"} eq '#') ? 1 : 0;
						}
					}
				} else {
					$west = ($grid{$level}{($x-1).",$y"} eq '#') ? 1 : 0;
				}
				my $east = 0;
				if ($x == $width - 1) {
					if (not exists $grid{$level - 1}) {
						$init_levels{$level - 1} = 1;
					} else {
						$east = ($grid{$level - 1}{($middle_x + 1) . ",$middle_y"} eq '#') ? 1 : 0;
					}
				} elsif ($x == $middle_x - 1 and $y == $middle_y) {
					if (not exists $grid{$level + 1}) {
						$init_levels{$level + 1} = 1;
					} else {
						for (my $yy = 0; $yy < $height; $yy++) {
							$east += ($grid{$level + 1}{"0,$yy"} eq '#') ? 1 : 0;
						}
					}
				} else {
					$east = ($grid{$level}{($x+1).",$y"} eq '#') ? 1 : 0;
				}
				my $adjacent = $north + $south + $east + $west;
				if (($grid{$level}{"$x,$y"} eq '#' and $adjacent != 1)) {
					$to_space{"$level:$x,$y"} = 1;
				} elsif ($grid{$level}{"$x,$y"} eq '.' and ($adjacent == 1 or $adjacent == 2)) {
					$to_bug{"$level:$x,$y"} = 1;
				}
			}
		}
	}
	foreach my $k (keys %init_levels) {
		$grid{$k} = {};
		for (my $xx = 0; $xx < $width; $xx++) {
			for (my $yy = 0; $yy < $height; $yy++) {
				$grid{$k}{"$xx,$yy"} = '.';
			}
		}
	}
	foreach my $k (keys %to_space) {
		my ($lvl, $key) = split(':', $k);
		$grid{$lvl}{$key} = '.';
	}
	foreach my $k (keys %to_bug) {
		my ($lvl, $key) = split(':', $k);
		$grid{$lvl}{$key} = '#';
	}
}

print "P2: After " . ($min-1) . " minutes there are " . count_bugs() . " total bugs\n";
#print_grids();

sub calculate_biodiversity {
	my $lvl = shift;
	$lvl = 0 if (not defined $lvl);
	my $bd = 0;
	my $exp = 0;
	for (my $y = 0; $y < $height; $y++) {
		for (my $x = 0; $x < $width; $x++) {
			if ($grid{$lvl}{"$x,$y"} eq '#') {
				$bd += 2**$exp;
			}
			$exp++;
		}
	}
	return $bd;
}

sub count_bugs {
	my $bugs = 0;
	foreach my $lvl (keys %grid) {
		for (my $y = 0; $y < $height; $y++) {
			for (my $x = 0; $x < $width; $x++) {
				if ($grid{$lvl}{"$x,$y"} eq '#') {
					$bugs++
				}
			}
		}
	}
	return $bugs;
}

sub print_grids {
	foreach my $lvl (sort {$a <=> $b } keys %grid) {
		print "\nLevel $lvl\n";
		for (my $y = 0; $y < $height; $y++) {
			for (my $x = 0; $x < $width; $x++) {
				print $grid{$lvl}{"$x,$y"};
			}
			print "\n";
		}
	}
}
__DATA__
.###.
##...
...##
.#.#.
#.#.#