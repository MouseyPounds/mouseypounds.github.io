#!/bin/perl -w
#
# https://adventofcode.com/2019/day/19
#

use strict;
use POSIX;

use lib '.';
use intcode;

print "\nDay 19:\n";
my $puzzle = <DATA>;

my $ship_size = 100;
my $count_limit = 50;

# In part 2, we are told that the beam starts small and widens as it travels. We have also seen that it is basically cone-shaped
# This leads to some optimizations:
# - Rather than keeping data for the entire map, we will only keep track of the start & end locations per level;
# - When parsing a particular line, we will now stop as soon as the beam is gone, and start the next line at same
#   x-coord where the previous line's beam started.
# - We also use a comparison based on similar triangles to guess how far forward to skip after completing part 1. That saves
#   quite a bit of time, but it might still take a few minutes on old systems.
print "Gathering data\n";
my $map = {};
my $count = 0;
my $p2_done = 0;
my $p1_done = 0;
my $x = 0;
my $y = 0;
my $in_beam = 0;
my $line = "";
my $p2_x = 0;
my $p2_y = 0;
my $last_width = 0;

while (not $p2_done and $y < 10000) {
	my $icc = intcode->new($puzzle,1,0,);
	$icc->send_input(0, $x, $y);
	my $result = $icc->get_output();
	$icc->exit();
	if ($result) {
		# Computer sensed beam
		if (not $in_beam) {
			# This must be beginning of beam
			$map->{$y}{'start'} = $x;
			$in_beam = 1;
		}
		$count++ if (not $p1_done);
		$x++;
	} else {
		# Computer did not sense beam
		if ($in_beam) {
			# Passed through beam and are on other side. Beam ended in the grid location before this.
			$map->{$y}{'end'} = $x-1;
			$in_beam = 0;
			$last_width = $x - $map->{$y}{'start'};
			# Check if ship fits by analyzing location 99 rows above us, if it exists.
			if ($last_width >= $ship_size) {
				$p2_x = $map->{$y}{'start'};
				$p2_y = $y - $ship_size + 1;
				if (exists $map->{$p2_y} and $p2_x >= $map->{$p2_y}{'start'} and ($p2_x + $ship_size - 1) <= $map->{$p2_y}{'end'}) {
					$p2_done = 1;
					last;
				}
			}
			# Search moves to next row and resets x to start of beam
			$y++;
			$x -= $last_width;
			# If we are done our p1 count, we want to jump quite far ahead since we won't see 100-length beams
			# for quite a while. We will try to guess how far based on a formula derived from similiar triangles
			# It does pretty well, pushing us down to y=900 on our input (actual p2 solution is 661, 984)
			if (not $p1_done and $y >= $count_limit) {
				print "P1: Found $count locations affected by beam in $count_limit x $count_limit area\n";
				$p1_done = 1;
				$map->{'p1_done'} = $count;
				#my $target_width = $ship_size + POSIX::floor($last_width / $y * $ship_size);
				#$y = POSIX::floor($target_width * $y / $last_width);
				# find largest current square
				my $sq;
				for ($sq = $last_width; $sq > 0; $sq--) {
					last if ($map->{$y-1}{'start'} + $sq -1 <= $map->{$y-$sq}{'end'});
				}
				$y = POSIX::floor($ship_size / $sq * ($y-$sq));
				print "P2: Currently a ship of $sq x $sq would fit in the beam; skipping to y=$y to find room for our ship.\n";
			}
		} else {
			# Probably still before beam, however some early rows don't show a beam at all so we need failsafe
			if ($y < 10 and $x > 9) {
				$map->{$y}{'start'} = -1;
				$map->{$y}{'end'} = -1;
				$y++;
				$x = 0;
			} else {
				$x++;
			}
		}
	}
}

print "P2: Ship will fit in a $ship_size x $ship_size area starting at ($p2_x, $p2_y) - value: " . (10000 * $p2_x + $p2_y) . "\n";

__DATA__
109,424,203,1,21102,1,11,0,1105,1,282,21101,18,0,0,1106,0,259,2101,0,1,221,203,1,21102,1,31,0,1106,0,282,21101,0,38,0,1106,0,259,21002,23,1,2,22102,1,1,3,21101,0,1,1,21102,57,1,0,1106,0,303,2102,1,1,222,21002,221,1,3,21002,221,1,2,21101,0,259,1,21101,0,80,0,1105,1,225,21101,123,0,2,21101,91,0,0,1105,1,303,1201,1,0,223,20101,0,222,4,21101,259,0,3,21102,225,1,2,21101,0,225,1,21102,118,1,0,1105,1,225,21001,222,0,3,21102,58,1,2,21101,133,0,0,1105,1,303,21202,1,-1,1,22001,223,1,1,21102,1,148,0,1106,0,259,1201,1,0,223,20101,0,221,4,21002,222,1,3,21101,20,0,2,1001,132,-2,224,1002,224,2,224,1001,224,3,224,1002,132,-1,132,1,224,132,224,21001,224,1,1,21101,195,0,0,105,1,109,20207,1,223,2,20102,1,23,1,21101,-1,0,3,21102,214,1,0,1105,1,303,22101,1,1,1,204,1,99,0,0,0,0,109,5,2101,0,-4,249,22102,1,-3,1,22102,1,-2,2,22101,0,-1,3,21101,250,0,0,1105,1,225,21202,1,1,-4,109,-5,2105,1,0,109,3,22107,0,-2,-1,21202,-1,2,-1,21201,-1,-1,-1,22202,-1,-2,-2,109,-3,2106,0,0,109,3,21207,-2,0,-1,1206,-1,294,104,0,99,21201,-2,0,-2,109,-3,2106,0,0,109,5,22207,-3,-4,-1,1206,-1,346,22201,-4,-3,-4,21202,-3,-1,-1,22201,-4,-1,2,21202,2,-1,-1,22201,-4,-1,1,22102,1,-2,3,21102,1,343,0,1105,1,303,1105,1,415,22207,-2,-3,-1,1206,-1,387,22201,-3,-2,-3,21202,-2,-1,-1,22201,-3,-1,3,21202,3,-1,-1,22201,-3,-1,2,21201,-4,0,1,21102,1,384,0,1106,0,303,1105,1,415,21202,-4,-1,-4,22201,-4,-3,-4,22202,-3,-2,-2,22202,-2,-4,-4,22202,-3,-2,-3,21202,-4,-1,-2,22201,-3,-2,1,21201,1,0,-4,109,-5,2105,1,0