#!/bin/perl -w
#
# https://adventofcode.com/2019/day/18
#

use strict;

use POSIX;

my $tracing = 0;
$| = 1;

print "\nDay 18: Part 1\n";
my %grid = ( );
my $x = 0;
my $y = 0;
my $start_x = 0;
my $start_y = 0;
my $width = 0;
my $height = 0;
# keys will be a bitmask in order of them being found
my %keys = ();
my @keys_by_quadrant = (0,0,0,0);
my $exp = 0;
while (<DATA>) {
	chomp;
	my @tiles = split '';
	for ($x = 0; $x <= $#tiles; $x++) {
		$grid{"$x,$y"} = $tiles[$x];
		if ($tiles[$x] =~ /[a-z]/) {
			$keys{$tiles[$x]} = 2**$exp;
			# Note assumption of a square map and robots starting in center
			if ($x <= scalar(@tiles)/2) {
				if ($y <= scalar(@tiles)/2) {
					$keys_by_quadrant[0] += 2**$exp;
				} else {
					$keys_by_quadrant[1] += 2**$exp;
				}
			} else {
				if ($y <= scalar(@tiles)/2) {
					$keys_by_quadrant[2] += 2**$exp;
				} else {
					$keys_by_quadrant[3] += 2**$exp;
				}
			}
			$exp++;
		} elsif ($tiles[$x] eq '@') {
			$start_x = $x;
			$start_y = $y;
			$grid{"$x,$y"} = '.';
		}
	}
	$y++;
}
$width = $x;
$height = $y;
my $allkeys = 2**$exp-1;
print "Map is $width x $height with " . scalar(keys %keys) . " total keys (bitmask $allkeys)\n";

# Part 1
my $dist = BFS($start_x, $start_y, 0);
print "P1 Solution: Shortest path found with distance $dist\n";

# Questionable Logic for Part 2. Running separate BFS for each quadrant where keys from other quadrants are assumed collected.
# This actually works (and is quite fast) but the assumptions it makes aren't really warranted by the problem description.
# Start by fixing the center area
print "\nDay 18: Part 2\n";
my $robot = 0;
my @start_pos = ();
for ($x = $start_x - 1; $x <= $start_x + 1; $x++) {
	for ($y = $start_y - 1; $y <= $start_y + 1; $y++) {
		if ($x == $start_x or $y == $start_y) {
			$grid{"$x,$y"} = '#';
		} else {
			$grid{"$x,$y"} = '.';
			$start_pos[$robot] = {'x' => $x, 'y' => $y};
			$robot++;
		}
	}
}

$dist = 0;
foreach my $r (0 .. 3) {
	my $d = BFS($start_pos[$r]{'x'}, $start_pos[$r]{'y'}, $allkeys^$keys_by_quadrant[$r]);
	$dist += $d;
	print "Robot $r finished in $d steps (total now $dist)\n";
}
print "Total distance of all 4 robots: $dist\n";

sub BFS {
	my $x = shift;
	my $y = shift;
	my $ignore_doors = shift;
	my $result = 0;
	
	print "BFS initiated starting at $x, $y with initial key mask $ignore_doors\n";
	
	# BFS search for shortest path -- tiles are marked visited by a combination of keys found & tile coords
	my $dist = 0;
	my @queue = ( { 'x' => $x, 'y' => $y, 'd' => $dist, 'k' => $ignore_doors } );
	my %visited = ( "$x,$y:0" => 1 );
	while (my $p = shift @queue) {
		print "Traversing maze [$dist]\r";
		if ($p->{'k'} == $allkeys) {
			$result = $p->{'d'};
			last;
		}
		$dist = $p->{'d'} + 1;
		foreach my $offset ([-1,0], [1,0], [0,-1], [0,1]) {
			$x = $p->{'x'} + $offset->[0];
			$y = $p->{'y'} + $offset->[1];
			my $k = $p->{'k'};
			
			if (exists $grid{"$x,$y"} and $grid{"$x,$y"} eq '.' and not exists $visited{"$x,$y:$k"}) {
				push @queue, {'x'=>$x, 'y'=>$y, 'd'=>$dist, 'k'=>$k};
				$visited{"$x,$y:$k"} = 1;
			} elsif (exists $grid{"$x,$y"} and $grid{"$x,$y"} =~ /[a-z]/) {
				$k |= $keys{$grid{"$x,$y"}};
				if (not exists $visited{"$x,$y:$k"}) {
					push @queue, {'x'=>$x, 'y'=>$y, 'd'=>$dist, 'k'=>$k};
					$visited{"$x,$y:$k"} = 1;
				}
			} elsif (exists $grid{"$x,$y"} and $grid{"$x,$y"} =~ /[A-Z]/ and ($k & $keys{lc $grid{"$x,$y"}})) {
				if (not exists $visited{"$x,$y:$k"}) {
					push @queue, {'x'=>$x, 'y'=>$y, 'd'=>$dist, 'k'=>$k};
					$visited{"$x,$y:$k"} = 1;
				}
			}
		}
	}

	return $result;
}
	

__DATA__
#################################################################################
#...#.......#.....#.......#...#.........#.......#.......#..q............#...#...#
#.#.#.#.###.###.#.#.#####.#.#.#.#######.#####.#.###.###Y###.#######.#####I#.#.#.#
#.#.#.#...#.....#.#.....#.#.#...#...#...#.....#.....#.#.....#.......#...#.#...#.#
#.#.#####.#######.#####.#.#.#####.#.#.#.#.#####.#####.###.#######.###N#.#.#####.#
#.#....f#.....#.#.#.#...#.#...#...#...#.#...#...#...#...#.#.....#.#...#.#...#...#
#.#####.###.#.#.#.#.#.###.#####.###########.#####.#.#.###.#.###.###.###.###.#.###
#.....#...#.#.#.#...#...#.....#.#.......#...#...#.#.#.....#.#.#.......#.....#.F.#
#####.###.###.#.###.###.#####.#.#.#####.#.###.#.#.#.#######.#.#############.###.#
#...#.#.#.#...#.....#.....#...#.#...#...#...#.#.#.#.......#.#.....#.......#.#a..#
#.#.#.#.#.#.###.#####.#####.###.#.###.#.#.#.#.#.#.#######.#.#.#.###.#####.###.###
#.#...#.#...#.#...#...#.....#...#.#...#.#.#...#.#.....#...#.#.#...#.....#.....#.#
#.#####.#####.#.###.###.#######.#.#.###.#######.#.#####.#.#.#####.#####.#######.#
#...#.........#.#...#.#.......#...#.#.#.#.....#...#...#.#.#...........#.#.......#
###.#########.#.#.###.#######.#.###.#.#.#.###.#####.#.#.###########.###.#.#####.#
#...#.....#...#.#.......#...#.#.#...#.#.#.#.....#...#...#...#.......#...#...#...#
#.#.#.###.#.###.#######.#.###.#.#.###.#.#.#####.#.#####.#.#.#.#######.#####.#####
#.#.#...#.#.....#.#.......#...#.#.#.#...#...#.....#.....#.#.......#...#...#.....#
#.#####.#.###.###.#.#######.#####.#.#.###.#.#########.###.#########.###.#.#####.#
#.......#...#.....#.#.......#.....#...#.#.#.....#...#.#.#...#.....#.#...#.......#
#.#######.#.#######.#.#########.###.###.#.#####.#.#.#.#.###.#.###.#.#.#.#######.#
#...#...#.#.......#.#.#...L...#.#.#...#.#...#.#...#.#.....#.#.#.#.#.#.#...#...#.#
#.###.#.#####.###.#.#######.#.#.#.###.#.###.#.#####.#####.#.###.#.#.#####.#.#.###
#.#...#.....#...#.#.......#.#...#.......#.#.......#...#...#.#...#...#.....#.#...#
#.#.#######.###.#.#######.#.###########.#.#######.###.#.###.#.#.#####.#.###.###.#
#.#.#.#.....#...#...#.....#.........#...#.#...#.....#.#...#.#.#.....#.#.#...#.#.#
###.#.#.#########.###.###########.#.###.#.#.#.#.#####.###.#.#####.#.#.###.###.#.#
#...#...J.#.......#...#.........#.#...#.#...#...#.....#.#.#.#.....#...#...#s..#.#
#.#######.#.#####S#.#######.###.#.###.###.#######.#####.#.#.#.#####.###.#####.#.#
#.#.....#...#...#.#.#.....#.#.#.#...#...#...#.#...#.......#.#...#...#...#.....#.#
#.#T###.#####.#.###.###.#.#.#.#.#.#####.###.#.#.#########.#.###.#####.###.#####.#
#.#.#...#.....#.#...#...#...#...#.#...#.#.#.#.#.#.......#.#...#.......#.....#..w#
#.#.#.###.#####.#.###.#######.#####.#.#.#.#.#.#.#.#####.#####.#.###########.#.#.#
#...#.#.B.#...#.#.#.#...#.#...#.....#.#.#.#.#.#.#.#r..#.....#.#.#...#.......#.#.#
#.###.#.###.#.#.#.#.#.#.#.#.###.#####.#.#.#.#.#.#.#.#######.#.#.#.#.#.###.###.#.#
#...#.#...#.#.#...#...#.#.#.#.......#...#.#...#...#.......#.#.#.#.#.#.#...#...#.#
###.#.###.###.#########.#.#.#.#####.#####.###.#####.#####.#.#.#.#.#.#.#####.###.#
#...#...#...#.....W...#.#.#.#c#...#.....#...#.....#.#.....#...#...#...#...#...#.#
#.###.#####.###.#####.#.#.#.###.#.#####.#.#.#####.###.###.#############.#.###.#.#
#o..#...........#.......#.......#.........#...........#.................#.....#.#
#######################################.@.#######################################
#...#.....#...#.........#.............#...........#.....#............j....#...#.#
#.#.#P###.###.#.###.###.#.###.#######.#.#.#####.###.#.#.###.#.###.#######.#.#.#.#
#.#...#.#...#.#.#.#...#.#...#.#.....#.#.#.#...#.....#.#...#.#.#...#..t..#...#...#
#G#####.###.#.#.#.###.#.#.###.#.#.#.#.#.#.###.#######.###C###.#.###.###.###.#####
#.#...#...#.#.#.....#.#.#.#...#.#.#.#.#.#...#.....#...#.#...#.#.#...#...#...#...#
#.#.###.#.#.#.#####.#.#.###.#####.###.#.###.#.#####.###.###.#.###.###.#######.#.#
#.#.....#.#.#...#...#.#...#.....#...#.#.#.....#...#.#.....#.#.......#.#.......#.#
#.#######.#.#.###.###.###.#####.###.#.#.#.#####.#.#.#.#####.#.#####.#.#.#######.#
#.......#...#...#.#.#.#.#.....#...#...#.#...#...#.#.#.....#.#.#...#.#...#.......#
#.#####.#.#####.#.#.#.#.#####.###.#.###.#.###.###.#.#####.#.###.#.#######.#####.#
#.#...#.#.....#...#.#.#.....#.....#.#...#.#...#.#.#.....#...#...#.........#.....#
#.#.#.#.#####.#.###.#.#####.#######.#.#.#.#.###.#.#.###.#.###.#############.#####
#...#.#.#.....#.....#.....#...#.....#.#.#.#.#.....#.#.#.#.#...#...#.O.#...#b..#.#
#####.#.###.###.#########.###.#.#####.#.#.#.#.#####.#.#.#.#.###.#.###.#.#.###.#.#
#...#.#...#...#.#.........#...#...#...#.#.#.#...#.....#.#...#...#..d#.#.#...#.#.#
#.###.###.###.#.#.#########.#.###.#.###.###.###.#######.###.#.#####.#.#.#.###.#.#
#.#.X.#.#.#...#.#...#.#.....#...#.#...#.#...#.....#.....#...#.#...#.#...#...#...#
#.#.###.#.#.###.###.#.#.###.###.#.#.#.#.#.#.#####.#.#####.###.###.#.#######.###.#
#.......#.#.#.#...#.#...#.#.#...#.#.#.#.#.#.#...#.#.#...#...#...#k#.......#...#.#
#.#####.#.#.#.#.###.###.#.#.#####.#.#.###.###.#.#.#.#.#.#######.#.#######.#.#.#.#
#.#...#.#.#.#...#...#.#...#.#...#.#.#...#.#...#.#...#.#.....U.#.#.....#...#.#...#
#.#.#.###.#.#.###.#.#.###.#.#.#.#.#####.#.#.###.###.#.#########.#.#####.#########
#.#.#.....#.#.#...#.#.#...#...#...#...#.#.....#...#.#...#......h#.......#.......#
#.#.#######.###.###.#.#######.#####.#.#.#########.#.###.###.#####.#######.#####.#
#.#.#...#.....#.#...#u......#...#...#.R.#.......#.#.#...#...#...#........x#...#.#
#.#.#.#.#####.#.#.#########.###.#.#.###.#.#####.#.###.###.###.#Z###########.#.#.#
#.#...#...#.#...#...#...#.E.#.#.#.#.#...#...#...#...#.#.......#.#.....#....g#.#.#
#K#######.#.#####.###.#.#.###.#.#.#.#.#####.#.#####.#.#####.###.#.###.###.#####.#
#.#z....#.#.......#..v#.#...#.#.#.#.#...#...#.....#.#.#..e#...#.#...#...#.......#
#.#.###.#.#########.###.###.#.#.#.#.###.#.#######.#.#.#.#.###.#.#.#####.#.#######
#.#.#...#.......#...#.#.....#.#.#.#.#...#...#.......#...#...#.#...#...M.#.......#
#.###H#.#######.#.###.#######.#.###.#.###.#.###############V#######.###########.#
#...#.#.#.....#.#.....#.........#...#l#.#.#...#.........Q.#.........#.......#...#
###.#.###.#.###.#####.#.#####.###.###.#.#####.#.#######.#############.#####.#.###
#.#.#.....#.#.....#.#.#.#...#...#.#.....#.....#.#...#...#.......#.........#.#..p#
#.#.#######.#.###.#.#.###.#.###.#.#####.#.###.#.###.#.###.###.#.#.#######.#.###.#
#.#...D.....#.#.....#m....#.#...#...#.#.#y#...#.#...#n..#...#i#.#.#.......#.#...#
#.#########.#.#############.#.#####.#.#.#.#####.#.#.###.###.#.###.#.#########.###
#...........#...............#.......#...#.........#...#.....#.....#.......A.....#
#################################################################################