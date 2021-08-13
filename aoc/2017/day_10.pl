#!/bin/perl -w
#
# https://adventofcode.com/2017/day/10
#
# This is now super-tiny since the knothash algorithms were pulled into their own module due to use in later puzzles.

use strict;

use lib ".";
use knothash;

print "2017 Day 10\n\n";
my $puzzle = do { local $/; <DATA> }; # slurp it

my @list = 0 .. 255;
my @twist = split(',', $puzzle);
my $skip = 0;
my $pos = 0;
knothash::do_round(\@list, \@twist, \$skip, \$pos);
print "P1: The product of the first two elements in the final list is ", ($list[0] * $list[1]) . ".\n";

my $knot = get_hash($puzzle);
print "P2: The knot hash is $knot.\n";

__DATA__
129,154,49,198,200,133,97,254,41,6,2,1,255,0,191,108