#!/bin/perl -w
#
# https://adventofcode.com/2017/day/15

use strict;

print "2017 Day 15\n\n";
my $puzzle = do { local $/; <DATA> }; # slurp it

my %gen = ();
map { /Generator (\w+) starts with (\d+)/; $gen{$1} = $2; } split('\n', $puzzle);

my $sample = 4e7;
my $count = judge_gens(\%gen, $sample);
print "P1: The judge has counted $count matches after $sample pairs.\n";

# Reset the generators
map { /Generator (\w+) starts with (\d+)/; $gen{$1} = $2; } split('\n', $puzzle);
$sample = 5e6;
$count = judge_gens_with_align(\%gen, $sample, 4, 8);
print "P2: The judge has counted $count matches after $sample pairs with alignment.\n";

sub judge_gens {
	my $gen_ref = shift;
	my $sample = shift;
	
	my $count = 0;
	foreach my $i (1 .. $sample) {
		$gen_ref->{'A'} = ($gen_ref->{'A'} * 16807) % 2147483647;
		$gen_ref->{'B'} = ($gen_ref->{'B'} * 48271) % 2147483647;
		$count++ if ( ($gen_ref->{'A'} & 0xFFFF) == ($gen_ref->{'B'} & 0xFFFF) );
	}
	return $count;
}

# Even though there is a good deal of redundancy, we are implementing this seperately so as not to slow down part 1
sub judge_gens_with_align {
	my $gen_ref = shift;
	my $sample = shift;
	my $A_mod = shift;
	my $B_mod = shift;
	
	$A_mod = 1 unless (defined $A_mod);
	$B_mod = 1 unless (defined $B_mod);
	
	my $count = 0;
	foreach my $i (1 .. $sample) {
		while (1) { $gen_ref->{'A'} = ($gen_ref->{'A'} * 16807) % 2147483647; last unless ($gen_ref->{'A'} % $A_mod); }
		while (1) { $gen_ref->{'B'} = ($gen_ref->{'B'} * 48271) % 2147483647; last unless ($gen_ref->{'B'} % $B_mod); }
		$count++ if ( ($gen_ref->{'A'} & 0xFFFF) == ($gen_ref->{'B'} & 0xFFFF) );
	}
	return $count;
}

__DATA__
Generator A starts with 679
Generator B starts with 771
