#!/bin/perl -w
#
# https://adventofcode.com/2016/day/11
#
# We found this quite challenging. While we pretty much immediately decided to use a BFS, it was difficult coming up with a 
# compact state summary and duplicate check. Determining the list of possible next moves was also somewhat tricky.

use strict;
use POSIX;
use Storable qw(dclone);
use Math::Combinatorics;

$| = 1;

print "2016 Day 11\n\n";
my $puzzle = do { local $/; <DATA> }; # slurp it
my @list = split("\n", $puzzle);

my $steps = solve_puzzle(\@list);
print "P1: Minimum steps needed to get everything to 4th floor is $steps\n";

push @list, "The first floor contains a elerium generator, a elerium-compatible microchip, a dilithium generator, and a dilithium-compatible microchip.";
$steps = solve_puzzle(\@list);
print "P2: After adding new items, the minimum steps needed to get everything to 4th floor is $steps\n";


sub solve_puzzle {
	my $loc = shift;
	
	my %floors = ( 'first' => 1, 'second' => 2, 'third' => 3, 'fourth' => 4);
	my %state = ( );
	
	for (my $i = 0; $i <= $#$loc; $i++) {
		(my ($f, $stuff)) = $loc->[$i] =~ /^The (\w+) floor contains (.*)/;
		my $floor = $floors{$f};
		next if ($stuff =~ /nothing relevant/);
		my @things = $stuff =~ /a (\w*(?:\-compatible)? (?:microchip|generator))/g;
		foreach my $t (@things) {
			(my ($element, $type)) = $t =~ /^(\w{2}).*\s(\w+)$/;
			$state{$element} = [0,0] unless (exists $state{$element});
			# Microchips are index 0 and Generators are index 1
			if ($type =~ /^m/) { $state{$element}[0] = $floor; } else { $state{$element}[1] = $floor; };
		}
	}
	return BFS_solve(\%state);;
}

sub BFS_solve {
	my $state = shift;
	
	my $moves = 0;
	my $elevator = 1;
	my $visit_key = gen_key($state, 1);
	my %visited = ( $visit_key => 1 );
	my @queue = ( { 'e' => $elevator, 'm' => $moves, 's' => $state } );
	
	while (my $q = shift @queue) {
		if ( are_we_done($q->{'s'}) ) {
			$moves = $q->{'m'};
			last;
		}
		
		$moves = $q->{'m'} + 1;
		my @elevator_next = ();
		push @elevator_next, ($q->{'e'} + 1) if ($q->{'e'} < 4);
		push @elevator_next, ($q->{'e'} - 1) if ($q->{'e'} > 1);
		foreach my $e (@elevator_next) {
			my @possible_moves = ();
			# First, check possible single moves
			foreach my $k (keys %$state) {
				foreach my $i (0, 1) {
					if ($q->{'s'}{$k}[$i] == $q->{'e'}) {
						my $next_state = dclone($q->{'s'});
						$next_state->{$k}[$i] = $e;
						if (is_valid_state($next_state)) {
							$visit_key = gen_key($next_state, $e);
							if (not exists $visited{$visit_key}) {
								push @queue, { 'e' => $e, 'm' => $moves, 's' => $next_state };
								$visited{$visit_key} = 1;
							}
						}
						push @possible_moves, "$k:$i";
					}
				}
			}
			# Now possible double moves
			my @combo = combine(2, @possible_moves);
			foreach my $c (@combo) {
				my $next_state = dclone($q->{'s'});
				foreach my $ci (0, 1) {
					(my ($k, $i)) = split(':', $c->[$ci]);
					$next_state->{$k}[$i] = $e;
				}
				if (is_valid_state($next_state)) {
					$visit_key = gen_key($next_state, $e);
					if (not exists $visited{$visit_key}) {
						push @queue, { 'e' => $e, 'm' => $moves, 's' => $next_state };
						$visited{$visit_key} = 1;
					}
				}
			}
		}
	}
	
	return $moves;
}

sub is_valid_state {
	my $state = shift;
	foreach my $k (keys %$state) {
		if ($state->{$k}[0] ne $state->{$k}[1]) {
			foreach my $j (keys %$state) {
				return 0 if ($state->{$k}[0] == $state->{$j}[1]);
			}
		}
	}
	return 1;
}	

sub are_we_done {
	my $state = shift;
	foreach my $k (keys %$state) {
		return 0 if ($state->{$k}[0] < 4 or $state->{$k}[1] < 4);
	}
	return 1;
}

sub gen_key {
	my $state = shift;
	my $elevator = shift;

	return "$elevator:" . join("|", map { "$state->{$_}[0],$state->{$_}[1]" } 
		(sort {$state->{$b}[0] <=> $state->{$a}[0] or $state->{$b}[1] <=> $state->{$a}[1]} keys %$state));
}

__DATA__
The first floor contains a thulium generator, a thulium-compatible microchip, a plutonium generator, and a strontium generator.
The second floor contains a plutonium-compatible microchip and a strontium-compatible microchip.
The third floor contains a promethium generator, a promethium-compatible microchip, a ruthenium generator, and a ruthenium-compatible microchip.
The fourth floor contains nothing relevant.