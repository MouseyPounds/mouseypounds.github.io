#!/bin/perl -w
#
# https://adventofcode.com/2015/day/17
#

use strict;
use POSIX;
use List::Util qw(min);

my $puzzle = do { local $/; <DATA> }; # slurp it
my @nums = split("\n", $puzzle);

print "2015 Day 17\n";

my $target = 150;
my %container_counts = ();
my $count = count_to($target, \@nums, \%container_counts);
print "P1: There are $count combinations which hold exactly $target liters.\n";

my $min_containers = min(keys %container_counts);
print "P2: The minimum number of containers is $min_containers which can happen $container_counts{$min_containers} ways.\n";

sub count_to {
	my $target = shift;
	my $inputs = shift;
	my $containers = shift;
	my $current = shift;
	my $depth = shift;

	$current = 0 unless (defined $current);
	$depth = 0 unless (defined $depth);
	
	my $target_count = 0;

	# End conditions: hit it, overshot, or out of numbers
	if ($current == $target) {
		$containers->{$depth} = 0 unless (defined $containers->{$depth});
		$containers->{$depth}++;
		return 1;
	}
	return 0 if ($current > $target);
	return 0 if (scalar(@$inputs) == 0);
	
	# Continuing with two possibilities -- skip or include this number
	my @new_inputs = @$inputs;
	my $this_input = shift @new_inputs;
	$target_count += count_to($target, \@new_inputs, $containers, $current, $depth);
	$target_count += count_to($target, \@new_inputs, $containers, $current + $this_input, $depth + 1);

	return $target_count;
}

__DATA__
33
14
18
20
45
35
16
35
1
13
18
13
50
44
48
6
24
41
30
42