#!/bin/perl -w
#
# https://adventofcode.com/2015/day/9
#

use strict;
use POSIX;

my $debugging = 0;

my %trips = ();
while (<DATA>) {
	chomp;
	my ($a, $b, $dist) = /^(\w.*) to (\w.*) = (\d+)$/;

	$trips{$a} = [] unless (exists $trips{$a});
	$trips{$b} = [] unless (exists $trips{$b});
	push @{$trips{$a}}, { 'to' => $b, 'dist' => $dist };
	push @{$trips{$b}}, { 'to' => $a, 'dist' => $dist };
}

print "2015 Day 9\n";

my @routes;
my @cities = (keys %trips);
permute_list(\@routes, \@cities);
my $max_dist = 0;
my $max_route;
my $min_dist = 1e9;
my $min_route;
ROUTE: foreach my $r (@routes) {
	my $total_dist = 0;
	# Walk through this route, adding up the distance
	for (my $i = 0; $i < $#$r; $i++) {
		my $hop = 0;
		# Find how far to get from current location to next, if possible at all
		for (my $j = 0; $j <= $#{$trips{$r->[$i]}}; $j++) {
			if ($trips{$r->[$i]}[$j]{'to'} eq $r->[$i+1]) {
				$hop = $trips{$r->[$i]}[$j]{'dist'};
				last;
			}
		}
		if ($hop > 0) {
			$total_dist += $hop;
		} else {
			# Couldn't make this hop, so route is invalid.
			next ROUTE;
		}
	}
	if ($total_dist < $min_dist) {
		$min_dist = $total_dist;
		$min_route = $r;
	}
	if ($total_dist > $max_dist) {
		$max_dist = $total_dist ;
		$max_route = $r;
	}
}

print "\nP1: The shortest distance is $min_dist for the route\n  " . join(" -> ", @$min_route) . "\n";
print "\nP2: The longest distance is $max_dist for the route\n  " . join(" -> ", @$max_route) . "\n";

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
AlphaCentauri to Snowdin = 66
AlphaCentauri to Tambi = 28
AlphaCentauri to Faerun = 60
AlphaCentauri to Norrath = 34
AlphaCentauri to Straylight = 34
AlphaCentauri to Tristram = 3
AlphaCentauri to Arbre = 108
Snowdin to Tambi = 22
Snowdin to Faerun = 12
Snowdin to Norrath = 91
Snowdin to Straylight = 121
Snowdin to Tristram = 111
Snowdin to Arbre = 71
Tambi to Faerun = 39
Tambi to Norrath = 113
Tambi to Straylight = 130
Tambi to Tristram = 35
Tambi to Arbre = 40
Faerun to Norrath = 63
Faerun to Straylight = 21
Faerun to Tristram = 57
Faerun to Arbre = 83
Norrath to Straylight = 9
Norrath to Tristram = 50
Norrath to Arbre = 60
Straylight to Tristram = 27
Straylight to Arbre = 81
Tristram to Arbre = 90