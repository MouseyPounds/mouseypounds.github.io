#!/bin/perl -w
#
# https://adventofcode.com/2018/day/11

use strict;
use List::Util qw(max);
use POSIX qw(floor);

print "2018 Day 11\n\n";
my $puzzle = do { local $/; <DATA> }; # slurp it

# Power Examples
#print "(3,5,8) -> ", get_power(3,5,8), "\n";
#print "(122,79,57) -> ", get_power(122,79,57), "\n";
#print "(217,196,39) -> ", get_power(217,196,39), "\n";
#print "(101,153,71) -> ", get_power(101,153,71), "\n";

# Grid Examples
#my $serial = 18;
#my $serial = 42;
my $serial = $puzzle;

my $max = -99999;
my $tx = 0;
my $ty = 0;
my %power = ();
for (my $x = 1; $x < 299; $x++) {
	for (my $y = 1; $y < 299; $y++) {
		my $power = 0;
		for (my $xx = $x; $xx <= $x + 2; $xx++) {
			for (my $yy = $y; $yy <= $y + 2; $yy++) {
				if (not exists $power{"$xx,$yy"}) {
					$power{"$xx,$yy"} = get_power($xx, $yy, $serial);
				}
				$power += $power{"$xx,$yy"};
			}
		}
		if ($power > $max) {
			$max = $power;
			$tx = $x;
			$ty = $y;
		}
	}
}
print "P1: The top-left fuel cell of the 3x3 square with the largest total power ($max) is $tx,$ty\n";

my $ts = 0;
$max = -99999;
# Note: size should loop to <= 300 but that will take forever and we know from experience it doesn't need to go that far.
for (my $size = 1; $size <= 20; $size++) {
	for (my $x = 1; $x <= 301 - $size; $x++) {
		for (my $y = 1; $y <= 301 - $size; $y++) {
			my $power = 0;
			for (my $xx = $x; $xx <= $x + $size - 1; $xx++) {
				for (my $yy = $y; $yy <= $y + $size - 1; $yy++) {
					if (not exists $power{"$xx,$yy"}) {
						$power{"$xx,$yy"} = get_power($xx, $yy, $serial);
					}
					$power += $power{"$xx,$yy"};
				}
			}
			if ($power > $max) {
				$max = $power;
				$tx = $x;
				$ty = $y;
				$ts = $size;
			}
		}
	}
}
print "P2: The identifier of the square with the largest total power ($max) is $tx,$ty,$ts\n";

exit;

sub get_power {
	my $x = shift;
	my $y = shift;
	my $serial = shift;

	my $rackID = $x + 10;
	my $power = $rackID * $y + $serial;
	$power *= $rackID;
	
	if ($power < 100) {
		$power = 0;
	} else {
		$power = floor(($power % 1000)/100);
	}
	return $power - 5;
}

__DATA__
2187