#!/bin/perl -w
#
# https://adventofcode.com/2020/day/17

use strict;

print "2020 Day 17\n";

my $puzzle = do { local $/; <DATA> }; # slurp it
my @lines = split("\n", $puzzle);

my $cycles = 6;
my $dim = 3;
my $count = run_sim(\@lines, $cycles, $dim);
print "P1: Number of active cells for sim of $cycles cycles in $dim dimensions is $count.\n";

$dim = 4;
$count = run_sim(\@lines, $cycles, $dim);
print "P2: Number of active cells for sim of $cycles cycles in $dim dimensions is $count.\n";

sub run_sim {
	my $initial = shift;
	my $cycles = shift;
	my $dim = shift;
	
	$cycles = 1 unless (defined $cycles);
	$dim = 3 unless (defined $dim);

	my $width = length $initial->[0];
	my $height = scalar(@$initial);
	my ($x, $y, $z, $w, $adj);
	my %grid = ();
	
	# pre-initialize grid to empty. x & y go one further in each direction.
	for ($y = -1; $y <= $height; $y++) {
		for ($x =-1; $x <= $width; $x++) {
			for ($z = -1; $z <= 1; $z++) {
				if ($dim > 3) {
					for ($w = -1; $w <= 1; $w++) {
						$grid{"$x,$y,$z,$w"} = '.';
					}
				} else {
					$grid{"$x,$y,$z"} = '.';
				}
			}
		}
	}
	for ($y = 0; $y < $height; $y++) {
		for ($x = 0; $x < $width; $x++) {
			if ($dim > 3) {
				$grid{"$x,$y,0,0"} = substr($initial->[$y], $x, 1);
			} else {
				$grid{"$x,$y,0"} = substr($initial->[$y], $x, 1);
			}
		}
	}
	for (my $c = 1; $c <= $cycles; $c++) {
		my @to_active = ();
		my @to_inactive = ();
		
		for ($y = -1 - $c; $y <= $height + $c; $y++) {
			for ($x = -1 - $c; $x <= $width + $c; $x++) {
				for ($z = -1 - $c; $z <= 1 + $c; $z++) {
					if ($dim > 3) {
						for ($w = -1 - $c; $w <= 1 + $c; $w++) {
							$adj = count_active(\%grid, $x,$y,$z,$w);
							push @to_active, "$x,$y,$z,$w" if ((not exists $grid{"$x,$y,$z,$w"} or $grid{"$x,$y,$z,$w"} eq '.') and $adj == 3);
							push @to_inactive, "$x,$y,$z,$w" if ((exists $grid{"$x,$y,$z,$w"} and $grid{"$x,$y,$z,$w"} eq '#') and ($adj < 2 or $adj > 3));
						}
					} else {
						$adj = count_active(\%grid, $x,$y,$z);
						push @to_active, "$x,$y,$z" if ((not exists $grid{"$x,$y,$z"} or $grid{"$x,$y,$z"} eq '.') and $adj == 3);
						push @to_inactive, "$x,$y,$z" if ((exists $grid{"$x,$y,$z"} and $grid{"$x,$y,$z"} eq '#') and ($adj < 2 or $adj > 3));
					}
				}
			}
		}
		foreach my $tile (@to_active) { $grid{$tile} = '#'; }
		foreach my $tile (@to_inactive) { $grid{$tile} = '.'; }
	}
	return count_active(\%grid);
}

# Counts active neighbors if the 3 (0r 4) coordinate arguments are given and all active cells if not.
sub count_active {
	my $gridref = shift;
	my $x0 = shift;
	my $y0 = shift;
	my $z0 = shift;
	my $w0 = shift;
	my $count = 0;
	
	if (defined $x0 and defined $y0 and defined $z0) {
		for (my $y = $y0 - 1; $y <= $y0 + 1; $y++) {
			for (my $x = $x0 - 1; $x <= $x0 + 1; $x++) {
				for (my $z = $z0 - 1; $z <= $z0 + 1; $z++) {
					if (defined $w0) {
						for (my $w = $w0 - 1; $w <= $w0 + 1; $w++) {
							next if ($x == $x0 and $y == $y0 and $z == $z0 and $w == $w0);
							$count++ if (exists $gridref->{"$x,$y,$z,$w"} and $gridref->{"$x,$y,$z,$w"} eq '#');
						}
					} else {
						next if ($x == $x0 and $y == $y0 and $z == $z0);
						$count++ if (exists $gridref->{"$x,$y,$z"} and $gridref->{"$x,$y,$z"} eq '#');
					}
				}
			}
		}
	} else {
		foreach my $tile (keys %$gridref) {
			$count++ if ($gridref->{"$tile"} eq '#');
		}
	}
	return $count;
}
	
__DATA__
##.#...#
#..##...
....#..#
....####
#.#....#
###.#.#.
.#.#.#..
.#.....#