#!/bin/perl -w
#
# https://adventofcode.com/2020/day/13

use strict;
use POSIX;
use List::Util qw(max min);

$| = 1; # unbuffered output
my $debugging = 0;

print "2020 Day 13\n";
my $puzzle = do { local $/; <DATA> }; # slurp it
my @lines = split("\n", $puzzle);
my $target_time = $lines[0];
my @bus_ids = split(',', $lines[1]);

print "\nPart 1\n";
my $earliest_time = 1e15;
my $earliest_bus = 0;
my %bus_id_to_index = ();
for (my $i=0; $i<=$#bus_ids; $i++) {
	next if ($bus_ids[$i] eq 'x');
	my $arrival = $bus_ids[$i] * POSIX::ceil($target_time/$bus_ids[$i]);
	$bus_id_to_index{$bus_ids[$i]} = $i;
	if ($arrival < $earliest_time) {
		$earliest_time = $arrival;
		$earliest_bus = $bus_ids[$i];
	}
}
my $time_diff = $earliest_time - $target_time;
my $p1_solution = $time_diff * $earliest_bus;
print "P1: The earliest bus after $target_time is bus number $earliest_bus which arrives $time_diff minutes later.\n";
print "    Solution value is $earliest_bus * $time_diff = $p1_solution.\n";

print "\nPart 2 (math)\n";
# Math approach. This is pretty much a textbook Chinese Remainder Theorem problem. Because we need a multiplicative inverse
# for modular arithmetic as part of the algorithm, we'll enable bignum for this part. One potential snag is that we have to
# remember that the remainders (@a) are the negatives of the indices which is why we subtract from 0 when initializing @a.
# Variables are named similar to the brief explanation on <https://mathworld.wolfram.com/ChineseRemainderTheorem.html>
{
	use bignum;
	
	my @m = keys %bus_id_to_index;
	my @a = map { (0 - $bus_id_to_index{$_}) % $_ } @m;
	my $big_m = 1; map { $big_m *= $_ } @m;
	my $x = 0;
	for (my $i = 0; $i <= $#m; $i++) {
		my $M_over_m = 1;
		for (my $j = 0; $j <= $#m; $j++) {
			$M_over_m *= $m[$j] unless ($i == $j);
		}
		my $b = $M_over_m->copy()->bmodinv($m[$i]);
		$x += $a[$i] * $b * $M_over_m;
	}
	$x %= $big_m;
	print "P2: Applying the Chinese Remainder Theorem, we find the correct timestamp is $x.\n";
}

print "\nPart 2 (search)\n";
# Programmatic approach. Buses are sorted descending by ID and the time increment starts off with the highest ID at a time
# value that works for that bus. As we search, we grab the next highest ID to do our checks and once we find it, we multiply
# the increment by that ID (which works because inspection tells us all the IDs are primes.) This converges pretty quickly,
# although we have to take care to apply the modulus to the check value as well as the timestamp.
my @buses_left = sort {$b <=> $a} keys %bus_id_to_index;
my $next_bus = shift @buses_left;
my $next_check = ($next_bus - $bus_id_to_index{$next_bus}) % $next_bus;
my $time = $next_bus - $bus_id_to_index{$next_bus};
my $increment = 1;
while (1) {
	print "$time +$increment\r";
	if ($time % $next_bus == $next_check) {
		$increment *= $next_bus;
		print "Found correct offset for bus $next_bus at $time; increasing increment to $increment\n" if $debugging;
		last unless (scalar(@buses_left));
		$next_bus = shift @buses_left;
		$next_check = ($next_bus - $bus_id_to_index{$next_bus}) % $next_bus;
	}
	$time += $increment;
}
print "P2: Search concluded; the correct timestamp is $time\n";

__DATA__
1014511
17,x,x,x,x,x,x,41,x,x,x,x,x,x,x,x,x,643,x,x,x,x,x,x,x,23,x,x,x,x,13,x,x,x,x,x,x,x,x,x,x,x,x,x,x,x,29,x,433,x,x,x,x,x,37,x,x,x,x,x,x,x,x,x,x,x,x,19