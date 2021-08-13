#!/bin/perl -w
#
# https://adventofcode.com/2016/day/13

use strict;
use POSIX;

my $debugging = 0;

$| = 1;

print "2016 Day 13\n\n";
my $puzzle = 1364;
my $end_x = 31;
my $end_y = 39;
my $max_moves = 50;

(my ($min_length, $paths)) = do_BFS($puzzle, $end_x, $end_y, $max_moves);
print "P1 Solution: Shortest path to $end_x, $end_y found with distance $min_length.\n";
print "P2 Solution: Number of accessible tiles within distance $max_moves is $paths.\n";

# Note that the $end_x, $end_y condition and the $max_moves conditions are completely
# separate and we don't end the BFS until after both are found.
sub do_BFS {
	my $puzzle = shift;
	my $end_x = shift;
	my $end_y = shift;
	my $max_moves = shift;

	my $x = 1;
	my $y = 1;
	my $dist = 0;
	my %grid = ( "$x,$y" => '.' );
	my %visited = ( "$x,$y" => 1 );
	my @queue = ( {'x'=>$x, 'y'=>$y, 'd'=>$dist} );

	my $moves_to_end = 0;
	my $paths_to_max = 0;
	
	while (my $p = shift @queue) {
		$moves_to_end = $p->{'d'} if ($p->{'x'} == $end_x and $p->{'y'} == $end_y);
		$paths_to_max = count_open(\%grid) if ($dist == $max_moves);
		last if ($moves_to_end and $paths_to_max);
		$dist = $p->{'d'} + 1;
		foreach my $offset (-1, 1) {
			my $tx = $p->{'x'} + $offset;
			if (not exists $visited{"$tx,$p->{'y'}"} and is_open(\%grid, $tx, $p->{'y'})) {
				push @queue, {'x'=>$tx, 'y'=>$p->{'y'}, 'd'=>$dist};
				$visited{"$tx,$p->{'y'}"} = 1;
			}
			my $ty = $p->{'y'} + $offset;
			if (not exists $visited{"$p->{'x'},$ty"} and is_open(\%grid, $p->{'x'}, $ty)) {
				push @queue, {'x'=>$p->{'x'}, 'y'=>$ty, 'd'=>$dist};
				$visited{"$p->{'x'},$ty"} = 1;
			}
		}
	}
	#print_map(\%grid);
	return $moves_to_end, $paths_to_max;
}

sub count_open {
	my $gridref = shift;
	my $c = 0;
	map { $c++ if $gridref->{$_} eq '.' } (keys %$gridref);
	return $c;
}
	
sub is_open {
	my $gridref = shift;
	my $x = shift;
	my $y = shift;
	return 0 if ($x < 0 or $y < 0);
	if (exists $gridref->{"$x,$y"}) {
		return ($gridref->{"$x,$y"} eq '.') ? 1 : 0;
	} else {
		my $n = $x*$x + 3*$x + 2*$x*$y + $y + $y*$y + $puzzle;
		my $bits = (unpack 'B32', (pack 'N', $n));
		my $ones = $bits =~ tr/1/x/;
		if ($ones % 2) {
			$gridref->{"$x,$y"} = '#';
			return 0;
		} else {
			$gridref->{"$x,$y"} = '.';
			return 1;
		}
	}
}

sub print_map {
	my $g = shift;
	print "\n   0123456789012345678901234567890123456789\n";
	for (my $y = 0; $y < 40; $y++) {
		my $line = sprintf "%2d ", $y;
		for (my $x = 0; $x < 40; $x++) {
			if (exists $g->{"$x,$y"}) {
				$line .= $g->{"$x,$y"};
			} else {
				$line .= "?";
			}
		}
		print "$line\n";
	}
	print "\n";
}

__DATA__
