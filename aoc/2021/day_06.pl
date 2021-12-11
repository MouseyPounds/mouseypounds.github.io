#!/bin/perl -w
#
# https://adventofcode.com/2021/day/6

use strict;
use List::Util qw(sum);

print "2021 Day 6\n";
my $input = do { local $/; <DATA> }; # slurp it
#$input = "3,4,3,1,2";
my $p1_days = 80;
my $p2_days = 256;

my %fish_count; @fish_count{0..6} = (0) x 7;
foreach my $i (split(',', $input)) {
	$fish_count{$i}++;
}

my %newborn = ();
for (my $day = 1; $day <= $p2_days; $day++) {
	my $f = $day % 7 - 1; $f += 7 if ($f < 0);
	$newborn{$day + 2} = $fish_count{$f} if (exists $fish_count{$f});
	$fish_count{$f} += delete $newborn{$day} if (exists $newborn{$day});
	
	if ($day == $p1_days or $day == $p2_days) {
		my $total_fish = sum(values %fish_count, values %newborn);
		print "After $day days there are $total_fish fish.\n";
	}
}
	
__DATA__
1,3,1,5,5,1,1,1,5,1,1,1,3,1,1,4,3,1,1,2,2,4,2,1,3,3,2,4,4,4,1,3,1,1,4,3,1,5,5,1,1,3,4,2,1,5,3,4,5,5,2,5,5,1,5,5,2,1,5,1,1,2,1,1,1,4,4,1,3,3,1,5,4,4,3,4,3,3,1,1,3,4,1,5,5,2,5,2,2,4,1,2,5,2,1,2,5,4,1,1,1,1,1,4,1,1,3,1,5,2,5,1,3,1,5,3,3,2,2,1,5,1,1,1,2,1,1,2,1,1,2,1,5,3,5,2,5,2,2,2,1,1,1,5,5,2,2,1,1,3,4,1,1,3,1,3,5,1,4,1,4,1,3,1,4,1,1,1,1,2,1,4,5,4,5,5,2,1,3,1,4,2,5,1,1,3,5,2,1,2,2,5,1,2,2,4,5,2,1,1,1,1,2,2,3,1,5,5,5,3,2,4,2,4,1,5,3,1,4,4,2,4,2,2,4,4,4,4,1,3,4,3,2,1,3,5,3,1,5,5,4,1,5,1,2,4,2,5,4,1,3,3,1,4,1,3,3,3,1,3,1,1,1,1,4,1,2,3,1,3,3,5,2,3,1,1,1,5,5,4,1,2,3,1,3,1,1,4,1,3,2,2,1,1,1,3,4,3,1,3