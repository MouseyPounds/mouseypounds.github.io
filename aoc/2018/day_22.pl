#!/bin/perl -w
#
# https://adventofcode.com/2018/day/22

use strict;
use List::PriorityQueue;

print "2018 Day 22\n\n";
my $puzzle = do { local $/; <DATA> }; # slurp it
(my ($depth, @target)) = $puzzle =~ /(\d+)/g;

my %map = ();
my %cache = ( 'geo' => {}, 'ero' => {} );
my @terrain_name = qw(rocky wet narrow);

#$depth = 510;
#@target = (10,10);
# my @examples = ( [0,0], [1,0], [0,1], [1,1], [10,10] );
# foreach my $e (@examples) {
	# print "Example [$e->[0], $e->[1]]: Geo = ", get_geologic_index($e->[0], $e->[1]),
		# " Ero = ", get_erosion_level($e->[0], $e->[1]), " Type = ",
		# get_terrain_type($e->[0], $e->[1]), " (",
		# $terrain_name[get_terrain_type($e->[0], $e->[1])], ")\n";
# }

print "P1: The risk level of this area is ", get_risk_level(), "\n";

#print_map("Before Search");

my $dist = get_shortest_path();
print "P2: The shortest path to the target takes $dist minutes.\n";

#print_map("After Search",1);

# BFS search
# We need to keep track of what tool is equipped when we visit a square; this is the 'e'
# key in the queue entry and the 3rd coordinate in the keys of the visited hash.
# The value mapping is 0=neither, 1=torch, 2=climbing gear.
sub get_shortest_path {
	my %visited = ();
	my $queue = new List::PriorityQueue;
	$queue->insert({'x'=>0, 'y'=>0, 'e'=>1, 'd'=>0}, 0);
	my $dist = 0;

	while (my $p = $queue->pop()) {
		my $tool = $p->{'e'};
		my $terr = get_terrain_type($p->{'x'},$p->{'y'});
		$dist = $p->{'d'} + 1;
		next if (exists $visited{"$p->{'x'},$p->{'y'},$tool"});
		$visited{"$p->{'x'},$p->{'y'},$tool"} = undef;

		#print "BFS: At $p->{'x'},$p->{'y'} (terr $terr) with tool $p->{'e'}, dist $p->{'d'}\n";
		if ( (not exists $map{"$p->{'x'},$p->{'y'}"}{'d'}) or ($p->{'d'} < $map{"$p->{'x'},$p->{'y'}"}{'d'}) ) {
			$map{"$p->{'x'},$p->{'y'}"}{'d'} = $p->{'d'};
		}

		if ($p->{'x'} == $target[0] and $p->{'y'} == $target[1] and $p->{'e'} == 1) {
			return $p->{'d'};
		}
		
		foreach my $offset (-1, 1) {
			my $tx = $p->{'x'} + $offset;
			if ($tx >= 0) {
				my $ts = tool_switch($tx,$p->{'y'},$terr,$tool);
				if ($ts == $tool) {
					# No tool switch, can just queue next square
					if (not exists $visited{"$tx,$p->{'y'},$ts"}) {
						$queue->insert({'x'=>$tx, 'y'=>$p->{'y'}, 'e'=>$ts, 'd'=>$dist}, $dist);
					}
				} else {
					# Tool switch needed to reach further tiles, do it now before moving.
					if (not exists $visited{"$p->{'x'},$p->{'y'},$ts"}) {
						$queue->insert({'x'=>$p->{'x'}, 'y'=>$p->{'y'}, 'e'=>$ts, 'd'=>$dist+6}, $dist+6);
					}
				}				 
			}
			my $ty = $p->{'y'} + $offset;
			if ($ty >= 0) {
				my $ts = tool_switch($p->{'x'},$ty,$terr,$tool);
				if ($ts == $tool) {
					# No tool switch, can just queue next square
					if (not exists $visited{"$p->{'x'},$ty,$ts"}) {
						$queue->insert({'x'=>$p->{'x'}, 'y'=>$ty, 'e'=>$ts, 'd'=>$dist}, $dist);
					}
				} else {
					# Tool switch needed to reach further tiles, do it now before moving.
					if (not exists $visited{"$p->{'x'},$p->{'y'},$ts"}) {
						$queue->insert({'x'=>$p->{'x'}, 'y'=>$p->{'y'}, 'e'=>$ts, 'd'=>$dist+6}, $dist+6);
					}
				}				 
			}
		}
	}
	return -1;
}

sub tool_switch {
	(my ($x, $y, $old_t, $tool)) = @_;
	my $new_t = get_terrain_type($x, $y);

	# We don't verify that the currently equipped tool is valid for the current location;
	# if we are moving between similar terrain types, we just keep current tool.
	return $tool if ($old_t == $new_t);
	if ($old_t == 0 ) {
		return ($new_t == 1) ? 2 : 1;
	} elsif ($old_t == 1) {
		return ($new_t == 0) ? 2 : 0;
	} elsif ($old_t == 2) {
		return ($new_t == 0) ? 1 : 0;
	}	
}

sub get_risk_level {
	my $result = 0;
	for (my $y = 0; $y <= $target[1]; $y++) {
		for (my $x = 0; $x <= $target[0]; $x++) {
			$result += get_terrain_type($x, $y);
		}
	}
	return $result;
}

sub get_geologic_index {
	(my ($x, $y)) = @_;
	return $map{"$x,$y"}{'g'} if (exists $map{"$x,$y"}{'g'});
	my $result = 0;
	if ($x == 0 and $y == 0) {
		$result = 0;
	} elsif ($x == $target[0] and $y == $target[1]) {
		$result = 0;
	} elsif ($y == 0) {
		$result = 16807 * $x;
	} elsif ($x == 0) {
		$result = 48271 * $y;
	} else {
		$result = get_erosion_level($x-1, $y) * get_erosion_level($x, $y-1);
	}
	$map{"$x,$y"}{'g'} = $result;
	return $result;
}

sub get_erosion_level {
	(my ($x, $y)) = @_;
	return $map{"$x,$y"}{'e'} if (exists $map{"$x,$y"}{'e'});
	my $result = (get_geologic_index($x, $y) + $depth) % 20183;
	$map{"$x,$y"}{'e'} = $result;
	return $result;
}

sub get_terrain_type {
	(my ($x, $y)) = @_;
	return $map{"$x,$y"}{'t'} if (exists $map{"$x,$y"}{'t'});
	my $result = get_erosion_level($x, $y) % 3;
	$map{"$x,$y"}{'t'} = $result;
	return $result;
}

sub print_map {
	my $title = shift;
	my $use_dist = shift;
	
	$title = "Map" unless defined $title;
	print "\n$title\n";
	
	$use_dist = 0 unless defined $use_dist;
	
	my @c = qw(. = |);
	
	for (my $y = 0; $y <= $target[1] + 10; $y++) {
		my $line = "";
		for (my $x = 0; $x <= $target[0] + 10; $x++) {
			my $char = '?';
			$char = $c[$map{"$x,$y"}{'t'}] if (exists $map{"$x,$y"}{'t'});
			$char = '*' if ($x == $target[0] and $y == $target[1]);
			if ($use_dist) {
				my $d = 0;
				$d = $map{"$x,$y"}{'d'} if (exists $map{"$x,$y"}{'d'});
				$char = sprintf("$char%03d$char ", $d);
			}
			$line .= $char;
		}
		print "$line\n";
	}
}

__DATA__
depth: 9465
target: 13,704