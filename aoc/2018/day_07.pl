#!/bin/perl -w
#
# https://adventofcode.com/2018/day/7
#
# This needs to be cleaned up and possibly merged into 1 function.

use strict;
use List::Util qw(max);

print "2018 Day 7\n\n";
my $puzzle = do { local $/; <DATA> }; # slurp it
my @lines = split(/\n/, $puzzle);

my %parent = ();
my %child = ();
my %left = ();
foreach (@lines) {
	(my ($a, $b)) = /[Ss]tep (\w+)/g;
	$parent{$b}{$a} = "";
	$child{$a}{$b} = "";
	$left{$a} = "";
	$left{$b} = "";
}

my $order = "";
while (scalar(%left)) {
	foreach my $p (sort keys %left) {
		if (not exists $parent{$p}) {
			$order .= $p;
			foreach my $c (keys %{$child{$p}}) {
				delete $child{$p}{$c};
				delete $parent{$c}{$p};
				delete $parent{$c} if (scalar keys %{$parent{$c}} == 0);
			}
			delete $child{$p};
			delete $left{$p};
			last;
		}
	}
}
print "P1: The order of instructions is $order\n";

#resetting
%parent = ();
%child = ();
%left = ();
my @worker = ([' ', 0], [' ', 0], [' ', 0], [' ', 0], [' ', 0]);
foreach (@lines) {
	(my ($a, $b)) = /[Ss]tep (\w+)/g;
	$parent{$b}{$a} = "";
	$child{$a}{$b} = "";
	$left{$a} = "";
	$left{$b} = "";
}
my $elapsed = 0;
while (scalar(%left)) {
	foreach my $p (sort keys %left) {
		if (not exists $parent{$p}) {
			print "Step $p is ready\n";
			my $time = 61 + (ord($p) - ord('A'));
			my $who = get_free_worker(\@worker);
			if ($who > -1) {
				$worker[$who] = [$p, $time];
				print "  Worker $who started working on $p\n";
				delete $left{$p};
			}
		}
	}
	$elapsed++;
	print "Time now $elapsed\n";
	foreach my $w (@worker) {
		$w->[1]--;
		if ($w->[1] <= 0 and $w->[0] ne ' ') {
			my $p = $w->[0];
			print "  Worker finished $p\n";
			foreach my $c (keys %{$child{$p}}) {
				delete $child{$p}{$c};
				delete $parent{$c}{$p};
				if (scalar keys %{$parent{$c}} == 0) {
					delete $parent{$c};
				}
			}
			delete $child{$p};
			$w = [' ', 0];
		}
	}
}
my $remaining = 0;
foreach my $w (@worker) {
	$remaining = $w->[1] if ($w->[1] > $remaining);
}
$elapsed += $remaining;
print "\nP2: With 5 workers it will take $elapsed seconds to complete the assembly\n";
# 893 correct

sub get_free_worker {
	my $worker = shift;
	
	for (my $i = 0; $i <= $#$worker; $i++) {
		return $i if ($worker->[$i][1] <= 0);
	}
	return -1;
}

__DATA__
Step Y must be finished before step L can begin.
Step N must be finished before step D can begin.
Step Z must be finished before step A can begin.
Step F must be finished before step L can begin.
Step H must be finished before step G can begin.
Step I must be finished before step S can begin.
Step M must be finished before step U can begin.
Step R must be finished before step J can begin.
Step T must be finished before step D can begin.
Step U must be finished before step D can begin.
Step O must be finished before step X can begin.
Step B must be finished before step D can begin.
Step X must be finished before step V can begin.
Step J must be finished before step V can begin.
Step D must be finished before step A can begin.
Step K must be finished before step P can begin.
Step Q must be finished before step C can begin.
Step S must be finished before step E can begin.
Step A must be finished before step V can begin.
Step G must be finished before step L can begin.
Step C must be finished before step W can begin.
Step P must be finished before step W can begin.
Step V must be finished before step W can begin.
Step E must be finished before step W can begin.
Step W must be finished before step L can begin.
Step P must be finished before step E can begin.
Step T must be finished before step K can begin.
Step A must be finished before step G can begin.
Step G must be finished before step P can begin.
Step N must be finished before step S can begin.
Step R must be finished before step D can begin.
Step M must be finished before step G can begin.
Step Z must be finished before step L can begin.
Step M must be finished before step T can begin.
Step S must be finished before step L can begin.
Step S must be finished before step W can begin.
Step O must be finished before step J can begin.
Step Z must be finished before step D can begin.
Step A must be finished before step C can begin.
Step P must be finished before step V can begin.
Step A must be finished before step P can begin.
Step B must be finished before step C can begin.
Step R must be finished before step S can begin.
Step X must be finished before step S can begin.
Step T must be finished before step P can begin.
Step Y must be finished before step E can begin.
Step G must be finished before step E can begin.
Step Y must be finished before step K can begin.
Step J must be finished before step P can begin.
Step I must be finished before step Q can begin.
Step E must be finished before step L can begin.
Step X must be finished before step J can begin.
Step T must be finished before step X can begin.
Step M must be finished before step O can begin.
Step K must be finished before step A can begin.
Step D must be finished before step W can begin.
Step H must be finished before step C can begin.
Step F must be finished before step R can begin.
Step B must be finished before step Q can begin.
Step M must be finished before step Q can begin.
Step D must be finished before step S can begin.
Step Y must be finished before step I can begin.
Step M must be finished before step K can begin.
Step S must be finished before step G can begin.
Step X must be finished before step L can begin.
Step D must be finished before step V can begin.
Step B must be finished before step X can begin.
Step C must be finished before step L can begin.
Step V must be finished before step L can begin.
Step Z must be finished before step Q can begin.
Step Z must be finished before step H can begin.
Step M must be finished before step S can begin.
Step O must be finished before step C can begin.
Step B must be finished before step A can begin.
Step U must be finished before step V can begin.
Step U must be finished before step A can begin.
Step X must be finished before step G can begin.
Step K must be finished before step C can begin.
Step T must be finished before step S can begin.
Step K must be finished before step G can begin.
Step U must be finished before step B can begin.
Step A must be finished before step E can begin.
Step F must be finished before step V can begin.
Step Q must be finished before step A can begin.
Step F must be finished before step Q can begin.
Step J must be finished before step L can begin.
Step O must be finished before step E can begin.
Step O must be finished before step Q can begin.
Step I must be finished before step K can begin.
Step I must be finished before step P can begin.
Step J must be finished before step D can begin.
Step Q must be finished before step P can begin.
Step S must be finished before step C can begin.
Step U must be finished before step P can begin.
Step S must be finished before step P can begin.
Step O must be finished before step B can begin.
Step Z must be finished before step F can begin.
Step R must be finished before step V can begin.
Step D must be finished before step L can begin.
Step Y must be finished before step T can begin.
Step G must be finished before step C can begin.