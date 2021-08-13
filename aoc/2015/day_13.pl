#!/bin/perl -w
#
# https://adventofcode.com/2015/day/13
#

use strict;
use POSIX;

my $debugging = 0;

my %relations = ();
while (<DATA>) {
	chomp;
	my ($a, $change, $value, $b) = /^(\w.*) would (\w+) (\d+) happiness units by sitting next to (\w.*)\.$/;

	$relations{$a} = {} unless (exists $relations{$a});
	$value = -$value if ($change eq 'lose');
	$relations{$a}{$b} = $value;
}

print "2015 Day 13\n";

my @arrangements = ();
my @people = (keys %relations);
permute_list(\@arrangements, \@people);

print "\nP1: " . find_max_happy(\@arrangements, \%relations);

foreach my $p (@people) {
	$relations{$p}{'me'} = 0;
	$relations{'me'}{$p} = 0;
}
print "\nP2: " . find_max_happy(\@arrangements, \%relations, 1);

sub find_max_happy {
	my $arrangements = shift;
	my $relations = shift;
	my $add_me = shift;
	
	$add_me = 0 unless (defined $add_me);
	
	my $max_happy = 0;
	my $max_arr;
	my $min_happy = 1e9;
	my $min_arr;
	ARR: foreach my $a (@$arrangements) {
		if ($add_me) {
			push @$a, "me";
		}
		my $total_happy = 0;
		# Walk through this arrangement, adding up the happiness
		for (my $i = 0; $i <= $#$a; $i++) {
			my $next = ($i == $#$a) ? 0 : $i + 1;
			my $prev = ($i == 0) ? $#$a : $i - 1;
			
			$total_happy += $relations->{$a->[$i]}{$a->[$next]};
			$total_happy += $relations->{$a->[$i]}{$a->[$prev]};
		}
		if ($total_happy < $min_happy) {
			$min_happy = $total_happy;
			$min_arr = $a;
		}
		if ($total_happy > $max_happy) {
			$max_happy = $total_happy ;
			$max_arr = $a;
		}
	}

	return "The most happiness is $max_happy for the arrangement\n  " . join(" <-> ", @$max_arr) . "\n";
}

sub permute_list {
	my $results = shift;	# Array Ref -- 2d array of all permutations
	my $left = shift;		# Array Ref -- Initially the list of things to permute; gradually empties
	my $used = shift;		# Array Ref -- Initially empty and okay if missing; gradually fills
	
	$used = [] unless (defined $used);
	
	if (scalar(@$left) == 0) {
		push @$results, $used;
		return;
	} else {
		for (my $i = 0; $i < scalar(@$left); $i++) {
			my @new_used = @$used;
			my @new_left = @$left;
			push @new_used, $new_left[$i];
			splice @new_left, $i, 1;
			permute_list($results, \@new_left, \@new_used);
		}
	}
}

__DATA__
Alice would gain 2 happiness units by sitting next to Bob.
Alice would gain 26 happiness units by sitting next to Carol.
Alice would lose 82 happiness units by sitting next to David.
Alice would lose 75 happiness units by sitting next to Eric.
Alice would gain 42 happiness units by sitting next to Frank.
Alice would gain 38 happiness units by sitting next to George.
Alice would gain 39 happiness units by sitting next to Mallory.
Bob would gain 40 happiness units by sitting next to Alice.
Bob would lose 61 happiness units by sitting next to Carol.
Bob would lose 15 happiness units by sitting next to David.
Bob would gain 63 happiness units by sitting next to Eric.
Bob would gain 41 happiness units by sitting next to Frank.
Bob would gain 30 happiness units by sitting next to George.
Bob would gain 87 happiness units by sitting next to Mallory.
Carol would lose 35 happiness units by sitting next to Alice.
Carol would lose 99 happiness units by sitting next to Bob.
Carol would lose 51 happiness units by sitting next to David.
Carol would gain 95 happiness units by sitting next to Eric.
Carol would gain 90 happiness units by sitting next to Frank.
Carol would lose 16 happiness units by sitting next to George.
Carol would gain 94 happiness units by sitting next to Mallory.
David would gain 36 happiness units by sitting next to Alice.
David would lose 18 happiness units by sitting next to Bob.
David would lose 65 happiness units by sitting next to Carol.
David would lose 18 happiness units by sitting next to Eric.
David would lose 22 happiness units by sitting next to Frank.
David would gain 2 happiness units by sitting next to George.
David would gain 42 happiness units by sitting next to Mallory.
Eric would lose 65 happiness units by sitting next to Alice.
Eric would gain 24 happiness units by sitting next to Bob.
Eric would gain 100 happiness units by sitting next to Carol.
Eric would gain 51 happiness units by sitting next to David.
Eric would gain 21 happiness units by sitting next to Frank.
Eric would gain 55 happiness units by sitting next to George.
Eric would lose 44 happiness units by sitting next to Mallory.
Frank would lose 48 happiness units by sitting next to Alice.
Frank would gain 91 happiness units by sitting next to Bob.
Frank would gain 8 happiness units by sitting next to Carol.
Frank would lose 66 happiness units by sitting next to David.
Frank would gain 97 happiness units by sitting next to Eric.
Frank would lose 9 happiness units by sitting next to George.
Frank would lose 92 happiness units by sitting next to Mallory.
George would lose 44 happiness units by sitting next to Alice.
George would lose 25 happiness units by sitting next to Bob.
George would gain 17 happiness units by sitting next to Carol.
George would gain 92 happiness units by sitting next to David.
George would lose 92 happiness units by sitting next to Eric.
George would gain 18 happiness units by sitting next to Frank.
George would gain 97 happiness units by sitting next to Mallory.
Mallory would gain 92 happiness units by sitting next to Alice.
Mallory would lose 96 happiness units by sitting next to Bob.
Mallory would lose 51 happiness units by sitting next to Carol.
Mallory would lose 81 happiness units by sitting next to David.
Mallory would gain 31 happiness units by sitting next to Eric.
Mallory would lose 73 happiness units by sitting next to Frank.
Mallory would lose 89 happiness units by sitting next to George.