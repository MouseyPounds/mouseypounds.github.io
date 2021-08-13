#!/bin/perl -w
#
# https://adventofcode.com/2020/day/23
#
# In the grand tradition of AoC we have a small problem with a small number of iterations for part 1 and then a large
# problem with a larger number of iterations for part 2 that probably fails with whatever simple approach was used earlier.
#
# We will wind up rolling our own "linked list" implementation because the string method we originally used for part 1 was
# completely infeasible and a method using standard arrays and splice still hadn't finished after 2 hours.
# Our linked list will basically just be an array where the cup value is the index and the element value is the next in line.

use strict;
use List::Util qw(any);

print "2020 Day 23\n\n";
my $puzzle = "974618352";
#$puzzle = "389125467";

my $debugging = 0;

my $move_limit = 100;
my $cups = 9;
my $result = play_game($puzzle, $cups, $move_limit);
my $answer = string_list($result, 1, 1);
chop $answer;
print "P1: After $move_limit moves with $cups cups, the order of the labels of the cups following cup 1 is $answer.\n";

$cups = 1e6;
$move_limit = 1e7;
$result = play_game($puzzle, $cups, $move_limit);
my $a1 = $result->[1];
my $a2 = $result->[$a1];
$answer = $a1 * $a2;
print "P2: After $move_limit moves with $cups cups, the labels following cup 1 are $a1 and $a2 with product $answer.\n";

sub play_game {
	my $start = shift;
	my $list_size = shift;
	my $move_limit = shift;
	
	# Note, we make the assumption that the starting string contains all values 1 .. length
	my @cups = ();
	my $curr = substr($start, 0, 1);
	my $dest = $curr;
	foreach (split '', substr($start, 1)) {
		$cups[$dest] = $_;
		$dest = $_;
	}
	if ($list_size > (length $start)) {
		foreach (((length $start) + 1) .. $list_size) {
			$cups[$dest] = $_;
			$dest = $_;
		}
	}
	$cups[$dest] = $curr;
	
	my $move = 0;
	while ($move++ < $move_limit) {
		print "Move $move, cups are (", string_list(\@cups, $curr), ")\n  Current is $curr\n" if $debugging;
		# Pick up the next 3 cups after current cup
		my ($a, $b, $c);
		$a = $cups[$curr];
		$b = $cups[$a];
		$c = $cups[$b];
		$cups[$curr] = $cups[$c];
		print "  Cups ($a, $b, $c) were picked up, leaving (", string_list(\@cups, $curr), ")\n" if $debugging;
		
		# Select destination cup which is next lower valid label from current cup
		$dest = $curr;
		while (1) {
			$dest--;
			$dest = $list_size if ($dest == 0);
			last unless ($dest == $a or $dest == $b or $dest == $c);
		}
		print "  Destination is $dest\n" if $debugging;
		
		# Re-integrate picked up cups behind destination.
		my $old = $cups[$dest];
		$cups[$dest] = $a;
		$cups[$c] = $old;
		
		# Pick new current which is next in line after last current
		$curr = $cups[$curr];
	}
	return \@cups;
}

sub string_list {
	my $list_ref = shift;
	my $curr = shift;
	my $simple = shift;
	
	$simple = 0 unless (defined $simple);
	
	my $str = $simple ? "" : "(";
	my $i = $curr;
	while (1) {
		my $j = $list_ref->[$i];
		$str .= $simple ? $j : "$j,";
		$i = $j;
		last if ($i == $curr);
	}
	chop $str unless $simple;
	$str .= ")" unless $simple;
	return $str;
}