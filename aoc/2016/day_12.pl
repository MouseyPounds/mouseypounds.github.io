#!/bin/perl -w
#
# https://adventofcode.com/2016/day/12
#

use strict;
use POSIX;

use lib '.';
use assembunny;

print "2016 Day 12\n";
my $puzzle = do { local $/; <DATA> }; # slurp it
my @instructions = split("\n", $puzzle);

print "\nPart 1:\n";
(my ($a, $b, $c, $d)) = run_program(\@instructions);
print "P1: After program completion with default starting values, register a is $a.\n";

print "\nPart 2:\n";
my $reg = 'c';
my $val = 1;
($a, $b, $c, $d) = run_program(\@instructions, $reg, $val);
print "P2: After program completion with register $reg initialized to $val, register a is $a.\n";


__DATA__
cpy 1 a
cpy 1 b
cpy 26 d
jnz c 2
jnz 1 5
cpy 7 c
inc d
dec c
jnz c -2
cpy a c
inc a
dec b
jnz b -2
cpy c b
dec d
jnz d -6
cpy 17 c
cpy 18 d
inc a
dec d
jnz d -2
dec c
jnz c -5