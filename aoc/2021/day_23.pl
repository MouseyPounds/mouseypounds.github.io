#!/bin/perl -w
#
# https://adventofcode.com/2021/day/23
#

use strict;
use List::PriorityQueue;
use List::Util qw(all);

print "2021 Day 23\n";
my $input = do { local $/; <DATA> }; # slurp it
my @line = split("\n", $input);

# Because of all the ways movement is restricted in this game, we are mostly hardcoding
# the board and only parsing the starting positions. Lots of assumptions are made about
# the layout of the board such as the hallway always being on the second line with
# 1-wide walls and there always being 4 rooms. While initial parsing handles the room
# locations fairly generally, the gameplay loop expects them to be exactly under indices
# 2,4,6,8 of the hallway.
my %move_cost = ('A' => 1, 'B' => 10, 'C' => 100, 'D' => 1000);
my %initial_state = ('h' => [split('',substr($line[1],1,-1))], 'A' => [], 'B' => [], 'C' => [], 'D' => [], 's' => 0);
foreach (@line) {
	my @amphipod = /([ABCD])/g;
	if (scalar(@amphipod)) {
		push @{$initial_state{chr(ord('A') + $_)}}, $amphipod[$_] for (0..3);
	}
}

my $result = play_game(\%initial_state, \%move_cost);
print "Part 1: The lowest cost solution is $result\n";

splice (@{$initial_state{'A'}}, 1, 0, "D", "D"); 
splice (@{$initial_state{'B'}}, 1, 0, "C", "B"); 
splice (@{$initial_state{'C'}}, 1, 0, "B", "A"); 
splice (@{$initial_state{'D'}}, 1, 0, "A", "C"); 
$result = play_game(\%initial_state, \%move_cost);
print "Part 2: The lowest cost solution is $result\n";

# Playing the game involves checking the current state for a victory condition and then
# queueing all valid moves from this state if not. We use a priority queue weighted on
# the score of the current state so that once we find a victory we know it is the best.
# This array-based implementation is faster than a previous string-based one, but it
# still takes a good minute to complete both parts on our old system.
sub play_game {
	my $s = shift;
	my $mc = shift;
	
	my %room_loc = ( 'A' => 2, 'B' => 4, 'C' => 6, 'D' => 8 );
	my %forbidden = map { $_ => 1 } values(%room_loc);

	my $queue = new List::PriorityQueue;
	$queue->insert({'h' => $s->{'h'}, 'A' => $s->{'A'}, 'B' => $s->{'B'}, 'C' => $s->{'C'}, 'D' => $s->{'D'}, 's' => $s->{'s'}}, $s->{'s'});
	my %seen = ( );
	while ($s = $queue->pop()) {
		my $key = join('', @{$s->{'h'}}). join('', @{$s->{'A'}}). join('', @{$s->{'B'}}). join('', @{$s->{'C'}}). join('', @{$s->{'D'}});
		next if (exists $seen{$key} and $seen{$key} <= $s->{'s'});
		$seen{$key} = $s->{'s'};
		
		if (all {$_ eq 'A'} @{$s->{'A'}} and all {$_ eq 'B'} @{$s->{'B'}} and all {$_ eq 'C'} @{$s->{'C'}} and all {$_ eq 'D'} @{$s->{'D'}}) {
			return $s->{'s'};
		} else {
			# Try all moves from hallway -> room
			for (my $i=0; $i <= $#{$s->{'h'}}; $i++) {
				my $c = $s->{'h'}[$i];
				if ($c ne '.' and all { $_ eq '.' or $_ eq $c } @{$s->{$c}}) {
					my $dir = $room_loc{$c} <=> $i;
					my $cost = $mc->{$c};
					for (my $j = $i+$dir; $j != $room_loc{$c}; $j += $dir) {
						if ($s->{'h'}[$j] ne '.') {
							# path not clear so bail out and use -1 cost as a flag
							$cost = -1; last;
						}
						$cost += $mc->{$c};
					}
					if ($cost > -1) {
						for (my $j = 0; $j <= scalar(@{$s->{$c}}); $j++) {
							if ($j == scalar(@{$s->{$c}}) or $s->{$c}[$j] ne '.') {
								# We are outside the bounds of the room or we are at the first settled amphipod
								# Either way the current one should settle in the previous spot
								my $next = copy_state($s);
								$next->{'h'}[$i] = '.';
								$next->{$c}[$j-1] = $c;
								$next->{'s'} += $cost;
								$queue->insert($next, $next->{'s'});
								last;
							} else {
								$cost += $mc->{$c};
							}
						}
					}
				}
			}
			# Try all moves from room -> hallway
			foreach my $r ('A' .. 'D') {
				next if (all { $_ eq '.' or $_ eq $r } @{$s->{$r}});
				my ($depth, $c);
				for ($depth = 0; $depth <= $#{$s->{$r}}; $depth++) {
					$c = $s->{$r}[$depth];
					last if ($c ne '.');
				}
				my $base_cost = ($depth+1)*($mc->{$c});
				# Try to go left
				my $cost = $base_cost;
				for (my $i = $room_loc{$r}-1; $i >= 0; $i--) {
					my $occupant = $s->{'h'}[$i];
					last if ($occupant ne '.');
					$cost += $mc->{$c};
					if (not exists($forbidden{$i})) {
						my $next = copy_state($s);
						$next->{'h'}[$i] = $c;
						$next->{$r}[$depth] = '.';
						$next->{'s'} += $cost;
						$queue->insert($next, $next->{'s'});
					}
				}
				# Try to go right
				$cost = $base_cost;
				for (my $i = $room_loc{$r}+1; $i <= $#{$s->{'h'}}; $i++) {
					my $occupant = $s->{'h'}[$i];
					last if ($occupant ne '.');
					$cost += $mc->{$c};
					if (not exists($forbidden{$i})) {
						my $next = copy_state($s);
						$next->{'h'}[$i] = $c;
						$next->{$r}[$depth] = '.';
						$next->{'s'} += $cost;
						$queue->insert($next, $next->{'s'});
					}
				}
			}
		}
	}
	return -1;
}

sub copy_state {
	my $s = shift;
	return {
		'h' => [@{$s->{'h'}}],
		'A' => [@{$s->{'A'}}],
		'B' => [@{$s->{'B'}}],
		'C' => [@{$s->{'C'}}],
		'D' => [@{$s->{'D'}}],
		's' => $s->{'s'}
		};
}

__DATA__
#############
#...........#
###C#B#A#D###
  #B#C#D#A#
  #########