#!/bin/perl -w
#
# https://adventofcode.com/2015/day/15
#

use strict;
use POSIX;
use List::Util qw(max min);

my $debugging = 0;

my %ingredients = ();
my %properties = ();
while (<DATA>) {
	chomp;
	my ($ingr, $properties) = split(': ');
	my @prop = split(', ', $properties);
	foreach my $p (@prop) {
		(my ($name, $amt)) = $p =~ /(\w+) (-?\d+)/;
		$ingredients{$ingr}{$name} = $amt;
		$properties{$name} = 1;
	}
}

print "2015 Day 15\n";

my $total_tsp = 100;
my @amounts = ();
my @names = sort (keys %ingredients);
permute_amounts(\@amounts, $total_tsp, scalar(keys %ingredients));
print "Permutations complete\n";

my $max_score = 0;
my $max_score_p2 = 0;
my $max_amt;
my $max_amt_p2;
foreach my $a (@amounts) {
	my $score = 1;
	my $valid_p2 = 0;
	foreach my $p (keys %properties) {
		my $this_score = 0;
		for (my $i = 0; $i <= $#names; $i++) {
			$this_score += $a->[$i] * $ingredients{$names[$i]}{$p};
		}
		if ($p eq 'calories') {
			$valid_p2 = 1 if ($this_score == 500);
		} else {
			$this_score = 0 if ($this_score < 0);
			$score *= $this_score;
		}
	}
	print "Calculating score [$max_score] / [$max_score_p2]\r";
	if ($score > $max_score) {
		$max_score = $score;
		$max_amt = $a;
	}
	if ($valid_p2 and $score > $max_score_p2) {
		$max_score_p2 = $score;
		$max_amt_p2 = $a;
	}
}

print "P1: Highest score is $max_score for a cookie with ingredients: \n";
for (my $i = 0; $i <= $#names; $i++) {
	print "    * $max_amt->[$i] tsp of $names[$i]\n";
}
print "P2: Highest score is $max_score_p2 for a 500-calorie cookie with ingredients: \n";
for (my $i = 0; $i <= $#names; $i++) {
	print "    * $max_amt_p2->[$i] tsp of $names[$i]\n";
}

sub permute_amounts {
	my $results = shift;	# Array Ref -- 2d array of all permutations
	my $n = shift;	# How many values to choose from
	my $r = shift;	# How many values left to pick
	my $current = shift;
	
	$current = [] unless (defined $current);

	printf "Permuting %3d, %d\r", $n, $r;
	if ($r == 0) {
		push @$results, $current;
		return;
	} else {
		for (my $i = 0; $i <= $n; $i++) {
			my @new_current = @$current;
			push @new_current, $i;
			permute_amounts($results, $n - $i, $r - 1, \@new_current);
		}
	}
}

__DATA__
Sprinkles: capacity 5, durability -1, flavor 0, texture 0, calories 5
PeanutButter: capacity -1, durability 3, flavor 0, texture 0, calories 1
Frosting: capacity 0, durability -1, flavor 4, texture 0, calories 6
Sugar: capacity -1, durability 0, flavor 0, texture 2, calories 8