#!/bin/perl -w
#
# https://adventofcode.com/2016/day/1

use strict;
use POSIX;

my $x = 0;
my $y = 0;
my @dir = qw(N E S W);
my $d = 0;

my ($x2, $y2);

my %visited = ();
my $found = 0;

print "2016 Day 1\n";
while (<DATA>) {
	chomp;
	my @a = split(/,/);
	for (my $i = 0; $i < scalar(@a); $i++) {
		$a[$i] =~ /\s?(\w)(\d+)/;
		my $turn = $1;
		my $dist = $2;

		if ($turn eq 'R') {
			$d++;
		} else {
			$d--;
		}
		if ($d > 3) {$d -= 4;}
		if ($d < 0) {$d += 4;}
		
		if ($dir[$d] eq 'N') {
			for (my $j = 0; $j < $dist; $j++) {
				$y++;
				addloc($x,$y);
			}
		} elsif ($dir[$d] eq 'S') {
			for (my $j = 0; $j < $dist; $j++) {
				$y--;
				addloc($x,$y);
			}
		} elsif ($dir[$d] eq 'E') {
			for (my $j = 0; $j < $dist; $j++) {
				$x++;
				addloc($x,$y);
			}
		} elsif ($dir[$d] eq 'W') {
			for (my $j = 0; $j < $dist; $j++) {
				$x--;
				addloc($x,$y);
			}
		} 
	}
}

sub addloc {
	my $x = shift;
	my $y = shift;
	my $loc = "$x,$y";
	if (not exists $visited{$loc}) {
		$visited{$loc} = 1;
	} else {
		if (not $found) {
			$found = 1;
			$x2 = $x;
			$y2 = $y;
		}
	}
}

print "Final location $x, $y with taxi distance " . (abs($x)+abs($y)) . " blocks away\n";
print "Part 2 location $x2, $y2 with taxi distance " . (abs($x2)+abs($y2)) . " blocks away\n";

__DATA__
L5, R1, R4, L5, L4, R3, R1, L1, R4, R5, L1, L3, R4, L2, L4, R2, L4, L1, R3, R1, R1, L1, R1, L5, R5, R2, L5, R2, R1, L2, L4, L4, R191, R2, R5, R1, L1, L2, R5, L2, L3, R4, L1, L1, R1, R50, L1, R1, R76, R5, R4, R2, L5, L3, L5, R2, R1, L1, R2, L3, R4, R2, L1, L1, R4, L1, L1, R185, R1, L5, L4, L5, L3, R2, R3, R1, L5, R1, L3, L2, L2, R5, L1, L1, L3, R1, R4, L2, L1, L1, L3, L4, R5, L2, R3, R5, R1, L4, R5, L3, R3, R3, R1, R1, R5, R2, L2, R5, L5, L4, R4, R3, R5, R1, L3, R1, L2, L2, R3, R4, L1, R4, L1, R4, R3, L1, L4, L1, L5, L2, R2, L1, R1, L5, L3, R4, L1, R5, L5, L5, L1, L3, R1, R5, L2, L4, L5, L1, L1, L2, R5, R5, L4, R3, L2, L1, L3, L4, L5, L5, L2, R4, R3, L5, R4, R2, R1, L5