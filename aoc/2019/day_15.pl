#!/bin/perl -w
#
# https://adventofcode.com/2019/day/15
#
# Originally tried a bunch of stuff to traverse the map such as keeping track of how often tiles were visited and prioritizing
# unseen tiles for next move including failsafes to randomly change direction if the same tile was hit too many times. After
# several attempts it became evident that the map was basically a maze so the logic was redone to follow a wall-hugger algorithm
# of simply turning clockwise if a tile was open and counter-clockwise if we hit a wall.

use strict;

use POSIX;

use lib '.';
use intcode;

print "\nDay 15:\n";
my $puzzle = <DATA>;

$| = 1;

my %grid = ( '0,0' => 'S' );
my $max_x = 0;
my $max_y = 0;
my $min_x = 0;
my $min_y = 0;
my $x = 0;
my $y = 0;
my @dirs = qw(X N S W E);
my %cw = ( 1=>4, 2=>3, 3=>1, 4=>2 );
my %ccw = ( 4=>1, 3=>2, 1=>3, 2=>4 );
my @next = ([0,1],[0,-1],[-1,0],[1,0]);
my $d = 1;
my $found_oxygen = 0;
my $back_home = 0;
my $move_limit = 5000; # full map takes ~3200 moves
my $moves = 0;
my $ox = 0;
my $oy = 0;

my $icc = intcode->new($puzzle,1,0,[$d]);
while (not $found_oxygen or not $back_home) {
	my $status = $icc->get_output();
	my $next_move = $cw{$d};

	if ($status == 0) {
		# wall in direction $d, bot unmoved
		my $tx = $x;
		my $ty = $y;
		if ($d == 1) {
			$ty++;
		} elsif ($d == 2) {
			$ty--;
		} elsif ($d == 4) {
			$tx++;
		} elsif ($d == 3) {
			$tx--;
		} 
		update_grid($tx,$ty,"#");
		$next_move = $ccw{$d};
	} else {
		# bot moved
		if ($d == 1) {
			$y++;
		} elsif ($d == 2) {
			$y--;
		} elsif ($d == 4) {
			$x++;
		} elsif ($d == 3) {
			$x--;
		}
		if ($status == 1) {
			update_grid($x,$y," ");
		} elsif ($status == 2) {
			update_grid($x,$y,"O");
			$found_oxygen = 1;
			$ox = $x;
			$oy = $y;
			print "Oxygen located at $ox, $oy after $moves moves\n";
		} else {
			warn "Unknown status: $status";
		}
	}
	
	if ($found_oxygen and $x == 0 and $y == 0) {
		print "Back home after $moves moves\n";
		$back_home = 1;
	}
	
	# Periodically print the map
	$moves++;
	if ($moves % $move_limit == 0) {
		print "Map dump after $moves moves\n";
		print_map($x, $y);
	}
	$icc->send_input(0, $next_move);
	$d = $next_move;
}
$icc->exit();
print "Final map (S = Starting Position, O = Oxygen System)\n";
print_map(-99,-99);

# Using a breadth-first search to find distance. Note that when we add tiles to the search we just check that the grid
#  is not a known wall (#) which accounts for both empty spaces and the marked oxygen location.
#
# Initially we did the search starting at the origin point and ending at the oxygen system; but because of p2 we reversed
# that logic and perform the full BFS without exiting once the shortest path was found allowing us to do both part 1 & 2
# simultaneously
my %visited = ();
my @queue = ();
push @queue, {'x'=>$ox, 'y'=>$oy, 'd'=>0};
$visited{"$ox,$oy"} = 1;
my $dist = 0;

print "Traversing map via BFS...\n";
while (my $p = shift @queue) {
	if ($p->{'x'} == 0 and $p->{'y'} == 0) {
		print "P1 Solution: Shortest path to oxygen found with distance $p->{'d'}\n";
	}
	$dist = $p->{'d'} + 1;
	foreach my $offset (-1, 1) {
		my $tx = $p->{'x'} + $offset;
		if (exists $grid{"$tx,$p->{'y'}"} and $grid{"$tx,$p->{'y'}"} ne '#' and not exists $visited{"$tx,$p->{'y'}"}) {
			push @queue, {'x'=>$tx, 'y'=>$p->{'y'}, 'd'=>$dist};
			$visited{"$tx,$p->{'y'}"} = 1;
		}
		my $ty = $p->{'y'} + $offset;
		if (exists $grid{"$p->{'x'},$ty"} and $grid{"$p->{'x'},$ty"} ne '#' and not exists $visited{"$p->{'x'},$ty"}) {
			push @queue, {'x'=>$p->{'x'}, 'y'=>$ty, 'd'=>$dist};
			$visited{"$p->{'x'},$ty"} = 1;
		}
	}
}
$dist--;
print "P2 Solution: Oxygen replenishment complete after $dist minutes\n";

exit;

sub print_map {
	my $dx = shift;
	my $dy = shift;
	print "\n";
	for (my $y = $max_y; $y >= $min_y; $y--) {
		my $line = "";
		for (my $x = $min_x; $x <= $max_x; $x++) {
			if ($x == 0 and $y == 0) {
				$line .= "S";
			} elsif ($dx == $x and $dy == $y) {
				$line .= "D";
			} elsif (exists $grid{"$x,$y"}) {
				$line .= $grid{"$x,$y"};
			} else {
				$line .= "?";
			}
		}
		print "$line\n";
	}
	print "\n";
}

sub update_grid {
	my $x = shift;
	my $y = shift;
	my $char = shift;
	
	$grid{"$x,$y"} = $char;
	if ($x > $max_x) {
		$max_x = $x;
	} elsif ($x < $min_x) {
		$min_x = $x;
	} 
	if ($y > $max_y) {
		$max_y = $y;
	} elsif ($y < $min_y) {
		$min_y = $y;
	}
}

__END__
3,1033,1008,1033,1,1032,1005,1032,31,1008,1033,2,1032,1005,1032,58,1008,1033,3,1032,1005,1032,81,1008,1033,4,1032,1005,1032,104,99,1002,1034,1,1039,102,1,1036,1041,1001,1035,-1,1040,1008,1038,0,1043,102,-1,1043,1032,1,1037,1032,1042,1105,1,124,1002,1034,1,1039,101,0,1036,1041,1001,1035,1,1040,1008,1038,0,1043,1,1037,1038,1042,1106,0,124,1001,1034,-1,1039,1008,1036,0,1041,101,0,1035,1040,1001,1038,0,1043,1001,1037,0,1042,1105,1,124,1001,1034,1,1039,1008,1036,0,1041,1002,1035,1,1040,102,1,1038,1043,101,0,1037,1042,1006,1039,217,1006,1040,217,1008,1039,40,1032,1005,1032,217,1008,1040,40,1032,1005,1032,217,1008,1039,37,1032,1006,1032,165,1008,1040,37,1032,1006,1032,165,1102,1,2,1044,1106,0,224,2,1041,1043,1032,1006,1032,179,1101,1,0,1044,1105,1,224,1,1041,1043,1032,1006,1032,217,1,1042,1043,1032,1001,1032,-1,1032,1002,1032,39,1032,1,1032,1039,1032,101,-1,1032,1032,101,252,1032,211,1007,0,73,1044,1105,1,224,1102,1,0,1044,1105,1,224,1006,1044,247,1002,1039,1,1034,1001,1040,0,1035,101,0,1041,1036,101,0,1043,1038,101,0,1042,1037,4,1044,1105,1,0,58,87,52,69,28,16,88,43,75,16,91,2,94,51,62,80,96,46,64,98,72,8,54,71,47,84,88,44,81,7,90,13,80,42,62,68,85,27,34,2,13,89,87,79,63,76,9,82,58,60,93,63,78,79,43,32,84,25,34,80,87,15,89,96,1,50,75,25,67,82,27,3,89,48,99,33,36,77,86,62,99,19,86,92,6,56,24,96,2,79,9,3,84,41,94,79,76,91,66,50,82,88,85,13,88,18,93,79,12,98,46,75,52,99,95,11,16,25,17,77,55,87,17,74,76,81,41,77,80,92,46,20,99,22,16,41,90,64,89,53,3,61,88,97,14,2,33,79,62,79,90,80,77,71,45,40,51,62,67,82,42,27,97,17,72,77,12,38,97,85,85,35,92,82,3,84,96,40,27,93,96,18,45,98,16,49,82,52,90,43,81,10,88,94,15,42,77,67,84,88,51,35,84,20,99,7,9,79,65,86,39,93,52,98,11,19,83,75,92,27,72,77,77,78,99,18,53,35,75,14,23,90,15,83,15,98,74,14,75,67,98,93,64,97,97,58,77,88,28,19,1,82,96,69,92,34,1,90,45,79,27,25,85,59,89,88,13,91,93,38,95,55,24,61,79,56,63,61,80,10,76,84,24,80,41,83,37,86,81,93,53,33,75,78,6,81,66,84,98,3,37,84,48,89,88,70,93,96,17,94,38,82,39,74,65,90,9,77,55,53,78,10,98,27,96,11,18,86,54,98,53,86,66,19,93,52,99,44,85,79,19,7,53,86,13,90,46,33,86,19,52,79,60,92,94,97,4,99,83,67,84,58,10,96,5,91,75,47,74,93,68,76,74,50,45,99,15,85,13,99,96,30,99,84,59,81,51,64,74,9,27,2,99,34,49,76,61,28,87,56,84,81,32,6,88,48,57,89,43,76,77,15,80,91,45,9,6,52,93,84,77,17,82,32,67,97,92,74,54,46,99,80,5,83,74,85,64,89,36,41,77,47,94,24,86,45,23,99,59,90,43,61,95,98,91,90,33,91,15,19,88,49,54,86,75,42,67,43,54,97,10,10,42,85,10,11,60,76,17,90,43,80,80,34,90,85,71,70,40,80,97,31,55,80,3,58,99,31,31,99,31,90,90,57,29,85,76,22,14,77,76,87,21,88,77,85,33,81,77,94,57,56,18,83,54,90,90,2,89,87,36,13,85,36,85,70,96,20,85,82,43,34,97,93,27,40,44,80,97,2,81,16,44,12,91,35,90,24,49,75,71,96,5,29,65,80,87,35,51,92,43,94,30,84,88,10,99,4,71,76,65,77,71,1,89,90,58,28,77,42,57,81,87,13,16,72,74,32,98,83,8,75,79,10,96,11,92,34,84,13,1,77,78,71,21,63,78,37,98,86,53,84,75,1,60,75,66,86,22,78,32,31,78,97,97,89,23,88,78,4,75,59,99,65,13,85,70,74,77,83,39,62,76,81,33,98,87,25,41,90,48,42,33,24,94,86,15,94,89,21,23,81,29,36,99,93,60,20,90,19,66,52,90,80,97,95,21,86,45,80,78,7,37,80,84,22,6,97,79,34,87,27,43,52,97,84,72,9,89,93,2,75,82,60,92,12,87,89,59,74,64,90,38,71,89,12,26,81,6,53,78,96,8,81,91,69,68,89,76,79,50,77,19,83,14,75,26,76,34,78,1,83,70,80,39,99,62,95,89,99,6,79,93,80,10,83,50,79,80,92,41,78,20,86,9,84,53,87,13,74,0,0,21,21,1,10,1,0,0,0,0,0,0