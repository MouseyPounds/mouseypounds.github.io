#!/bin/perl -w
#
# https://adventofcode.com/2017/day/18
#
# Because of the need for the computers to talk to each other we implemted this in a threaded module similar to the AoC 2019
# intcode module. Thus this script does very little. Part 2 output includes both send counts even though we only need ID 1.

use strict;

use lib ".";
use duet;

print "2017 Day 18\n\n";
my $puzzle = do { local $/; <DATA> }; # slurp it

my $comp = duet->new($puzzle, 1);
my $freq = $comp->get_output();
$comp->exit();
print "P1: The recovered frequency is $freq\n\n";

$comp = duet->new($puzzle, 2);
my @counts = $comp->get_output(2);
$comp->exit();
foreach my $c (sort @counts) {
	(my ($id, $num)) = split(':', $c);
	print "P2: Computer ID $id sent $num messages.\n";
}

__DATA__
set i 31
set a 1
mul p 17
jgz p p
mul a 2
add i -1
jgz i -2
add a -1
set i 127
set p 622
mul p 8505
mod p a
mul p 129749
add p 12345
mod p a
set b p
mod b 10000
snd b
add i -1
jgz i -9
jgz a 3
rcv b
jgz b -1
set f 0
set i 126
rcv a
rcv b
set p a
mul p -1
add p b
jgz p 4
snd a
set a b
jgz 1 3
snd b
set f 1
add i -1
jgz i -11
snd a
jgz f -16
jgz a -19