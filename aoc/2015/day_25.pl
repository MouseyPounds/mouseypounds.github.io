#!/bin/perl -w
#
# https://adventofcode.com/2015/day/25
#

use strict;
use POSIX;
use List::Util qw(max);

my $debugging = 0;

$| = 1;

print "2015 Day 24\n";
my $puzzle = do { local $/; <DATA> }; # slurp it
(my ($row, $col)) = $puzzle =~ /row (\d+), column (\d+)/;

print "\nPart 1:\n";
my $code = 20151125;
my $code_found = 0;
my $i = 1;
print "Generating codes...\r";
until ($code_found) {
	$i++;
	for (my $j = 1; $j <= $i; $j++) {
		$code *= 252533;
		$code %= 33554393;
		my $r = $i + 1 - $j;
		if ($r == $row and $j == $col) { $code_found = 1; last; }
	}
}
print "P1: Code at Row $row, Column $col is: $code\n";

__DATA__
To continue, please consult the code grid in the manual.  Enter the code at row 2981, column 3075.
