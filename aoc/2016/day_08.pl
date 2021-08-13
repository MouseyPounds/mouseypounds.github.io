#!/bin/perl -w
#
# https://adventofcode.com/2016/day/8

use strict;
use POSIX;

$| = 1;

print "2016 Day 8\n\n";
my $puzzle = do { local $/; <DATA> }; # slurp it
my @list = split("\n", $puzzle);

my $voltage = read_screen(\@list);
print "\nP1: The number of pixels lit on the screen should be $voltage.\n";

sub read_screen {
	my $ins = shift;

	my $width = 50;
	my $height = 6;
	my $screen = init_screen($width, $height);
	for (my $i = 0; $i <= $#$ins; $i++) {
		if ($ins->[$i] =~ /rect (\d+)x(\d+)/) {
			for (my $y = 0; $y < $2; $y++) {
				for (my $x = 0; $x < $1; $x++) {
					$screen->[$y][$x] = '#';
				}
			}
		} elsif ($ins->[$i] =~ /rotate column x=(\d+) by (\d+)/) {
			my @temp = ();
			for (my $y = 0; $y < $height; $y++) { $temp[$y] = $screen->[($y-$2)%$height][$1]; }
			for (my $y = 0; $y < $height; $y++) { $screen->[$y][$1] = $temp[$y]; }
		} elsif ($ins->[$i] =~ /rotate row y=(\d+) by (\d+)/) {
			my @temp = ();
			for (my $x = 0; $x < $width; $x++) { $temp[$x] = $screen->[$1][($x-$2)%$width]; }
			for (my $x = 0; $x < $width; $x++) { $screen->[$1][$x] = $temp[$x]; }
		} else {
			warn "Skipping unknown instruction: $ins->[$i]\n";
		}
	}
	
	print_screen($screen, "message for P2");
	return count_voltage($screen);
}

sub init_screen {
	my $width = shift;
	my $height = shift;
	
	my @screen = ();
	for (my $y = 0; $y < $height; $y++ ) {
		$screen[$y] = [];
		for (my $x = 0; $x < $width; $x++ ) {
			$screen[$y][$x] = ".";
		}
	}
	return \@screen;
}

sub count_voltage {
	my $screen = shift;
	my $voltage = 0;
	
	for (my $y = 0; $y <= $#$screen; $y++ ) {
		for (my $x = 0; $x <= $#{$screen->[$y]}; $x++ ) {
			$voltage++ if ($screen->[$y][$x] eq '#');
		}
	}
	return $voltage;
}

sub print_screen {
	my $screen = shift;
	my $desc = shift; $desc = "" unless (defined $desc);
	
	print "Screen dump: $desc\n";
	for (my $y = 0; $y <= $#$screen; $y++ ) {
		my $line = "";
		for (my $x = 0; $x <= $#{$screen->[$y]}; $x++ ) {
			$line .= $screen->[$y][$x];
		}
		print "$line\n";
	}
}

__DATA__
rect 1x1
rotate row y=0 by 5
rect 1x1
rotate row y=0 by 6
rect 1x1
rotate row y=0 by 5
rect 1x1
rotate row y=0 by 2
rect 1x1
rotate row y=0 by 5
rect 2x1
rotate row y=0 by 2
rect 1x1
rotate row y=0 by 4
rect 1x1
rotate row y=0 by 3
rect 2x1
rotate row y=0 by 7
rect 3x1
rotate row y=0 by 3
rect 1x1
rotate row y=0 by 3
rect 1x2
rotate row y=1 by 13
rotate column x=0 by 1
rect 2x1
rotate row y=0 by 5
rotate column x=0 by 1
rect 3x1
rotate row y=0 by 18
rotate column x=13 by 1
rotate column x=7 by 2
rotate column x=2 by 3
rotate column x=0 by 1
rect 17x1
rotate row y=3 by 13
rotate row y=1 by 37
rotate row y=0 by 11
rotate column x=7 by 1
rotate column x=6 by 1
rotate column x=4 by 1
rotate column x=0 by 1
rect 10x1
rotate row y=2 by 37
rotate column x=19 by 2
rotate column x=9 by 2
rotate row y=3 by 5
rotate row y=2 by 1
rotate row y=1 by 4
rotate row y=0 by 4
rect 1x4
rotate column x=25 by 3
rotate row y=3 by 5
rotate row y=2 by 2
rotate row y=1 by 1
rotate row y=0 by 1
rect 1x5
rotate row y=2 by 10
rotate column x=39 by 1
rotate column x=35 by 1
rotate column x=29 by 1
rotate column x=19 by 1
rotate column x=7 by 2
rotate row y=4 by 22
rotate row y=3 by 5
rotate row y=1 by 21
rotate row y=0 by 10
rotate column x=2 by 2
rotate column x=0 by 2
rect 4x2
rotate column x=46 by 2
rotate column x=44 by 2
rotate column x=42 by 1
rotate column x=41 by 1
rotate column x=40 by 2
rotate column x=38 by 2
rotate column x=37 by 3
rotate column x=35 by 1
rotate column x=33 by 2
rotate column x=32 by 1
rotate column x=31 by 2
rotate column x=30 by 1
rotate column x=28 by 1
rotate column x=27 by 3
rotate column x=26 by 1
rotate column x=23 by 2
rotate column x=22 by 1
rotate column x=21 by 1
rotate column x=20 by 1
rotate column x=19 by 1
rotate column x=18 by 2
rotate column x=16 by 2
rotate column x=15 by 1
rotate column x=13 by 1
rotate column x=12 by 1
rotate column x=11 by 1
rotate column x=10 by 1
rotate column x=7 by 1
rotate column x=6 by 1
rotate column x=5 by 1
rotate column x=3 by 2
rotate column x=2 by 1
rotate column x=1 by 1
rotate column x=0 by 1
rect 49x1
rotate row y=2 by 34
rotate column x=44 by 1
rotate column x=40 by 2
rotate column x=39 by 1
rotate column x=35 by 4
rotate column x=34 by 1
rotate column x=30 by 4
rotate column x=29 by 1
rotate column x=24 by 1
rotate column x=15 by 4
rotate column x=14 by 1
rotate column x=13 by 3
rotate column x=10 by 4
rotate column x=9 by 1
rotate column x=5 by 4
rotate column x=4 by 3
rotate row y=5 by 20
rotate row y=4 by 20
rotate row y=3 by 48
rotate row y=2 by 20
rotate row y=1 by 41
rotate column x=47 by 5
rotate column x=46 by 5
rotate column x=45 by 4
rotate column x=43 by 5
rotate column x=41 by 5
rotate column x=33 by 1
rotate column x=32 by 3
rotate column x=23 by 5
rotate column x=22 by 1
rotate column x=21 by 2
rotate column x=18 by 2
rotate column x=17 by 3
rotate column x=16 by 2
rotate column x=13 by 5
rotate column x=12 by 5
rotate column x=11 by 5
rotate column x=3 by 5
rotate column x=2 by 5
rotate column x=1 by 5