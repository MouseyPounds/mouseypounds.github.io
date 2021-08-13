#!/bin/perl -w
#
# https://adventofcode.com/2017/day/14

use strict;

use lib ".";
use knothash;

print "2017 Day 14\n\n";
my $puzzle = "amgozmfv";

my $grid_size = 128;
my @grid = ();
my $used_count = 0;
my %unvisited = (); 
foreach my $g (0 .. $grid_size - 1) {
	my $kh = get_hash(sprintf("%s-%d", $puzzle, $g));
	my $bitstring = join('', map { sprintf("%04b", hex($_)) } split('', $kh) );
	$used_count += $bitstring =~ tr/1/1/;
	push @grid, [split('', $bitstring)];
	map { $unvisited{"$g,$_"} = "" } ( 0 .. $grid_size - 1);
}
print "P1: There are $used_count used blocks on the disk.\n";

# For part 2 we will use a hash of block positions to keep track of everywhere we've searched.
# The process is to keep grabbing an unseen block and if it is used, use a BFS-type algorithm to map the region.
my $regions = 0;
while (scalar(keys %unvisited)) {
	(my ($x,$y)) = split(',', (%unvisited)[0]);
	if ($grid[$y][$x]) {
		$regions++;
		traverse_region(\@grid, \%unvisited, $x, $y);
	} else {
		delete $unvisited{"$x,$y"};
	}
}
print "P2: There are $regions seperate regions on the disk.\n";

sub traverse_region {
	my $grid_ref = shift;
	my $unv_ref = shift;
	my $x = shift;
	my $y = shift;
	
	my @offset = ( [-1,0], [1,0], [0,-1], [0,1] );
	my @queue = ( { 'x' => $x, 'y' => $y } );
	while (my $p = shift @queue) {
		next unless exists ($unv_ref->{"$p->{'x'},$p->{'y'}"});
		if ($grid_ref->[$p->{'y'}][$p->{'x'}]) {
			foreach my $off (@offset) {
				my $xx = $p->{'x'} + $off->[0];
				my $yy = $p->{'y'} + $off->[1];
				push @queue, { 'x' => $xx, 'y' => $yy } if (exists $unv_ref->{"$xx,$yy"});
			}
		}
		delete $unv_ref->{"$p->{'x'},$p->{'y'}"};
	}
}
__DATA__
