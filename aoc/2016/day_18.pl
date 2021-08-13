#!/bin/perl -w
#
# https://adventofcode.com/2016/day/18

use strict;
use POSIX;

print "2016 Day 18\n\n";
my $puzzle = <DATA>;

my $steps = 40;
my $safe = run_sim($puzzle, $steps);
print "P1 Solution: Number of safe tiles after $steps rows is $safe.\n\n";

$steps = 400000;
$safe = run_sim($puzzle, $steps);
print "P2 Solution: Number of safe tiles after $steps rows is $safe.\n\n";

sub run_sim {
	my $start = shift;
	my $end = shift;
	
	my @current = split('', $start);
	my $count = $start =~ tr/..//;
	my $row = 1;
	
	while ($row < $end) {
		my @next = ();
		for (my $i = 0; $i <= $#current; $i++) {
			my $left = ($i == 0) ? "." : $current[$i-1];
			my $right = ($i == $#current) ? "." : $current[$i+1];
			
			if ($left ne $right) {
				$next[$i] = '^';
			} else {
				$next[$i] = '.';
				$count++;
			}
		}
		$row++;
		@current = @next;
	}
	
	return $count;
}				

__DATA__
^^^^......^...^..^....^^^.^^^.^.^^^^^^..^...^^...^^^.^^....^..^^^.^.^^...^.^...^^.^^^.^^^^.^^.^..^.^