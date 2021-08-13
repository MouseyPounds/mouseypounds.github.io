#!/bin/perl -w
#
# https://adventofcode.com/2016/day/23
#

use strict;
use POSIX;

use lib '.';
use assembunny;

print "2016 Day 23\n";
my $puzzle = do { local $/; <DATA> }; # slurp it
my @instructions = split("\n", $puzzle);

print "\nPart 1:\n";
my $reg = 'a';
my $val = 7;
(my ($a, $b, $c, $d)) = run_program(\@instructions, $reg, $val);
print "P1: After program completion with register $reg initialized to $val, register a is $a.\n";

print "\nPart 2:\n";
$val = 12;
($a, $b, $c, $d) = run_program(\@instructions, $reg, $val);
print "P2: After program completion with register $reg initialized to $val, register a is $a.\n";


__DATA__
cpy a b
dec b
cpy a d
cpy 0 a
cpy b c
inc a
dec c
jnz c -2
dec d
jnz d -5
dec b
cpy b c
cpy c d
dec d
inc c
jnz d -2
tgl c
cpy -16 c
jnz 1 c
cpy 87 c
jnz 97 d
inc a
inc d
jnz d -2
inc c
jnz c -5