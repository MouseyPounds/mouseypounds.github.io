#!/bin/perl -w
#
# https://adventofcode.com/2021/day/14
#
# We can't actually keep and manipulate a copy of the polymer string because part 2 will punish us.
# The chosen approach is to just keep a count of each element pair in the string and update at each step.
# For example with the rule SV -> C and n current SV pairs, we would remove n pairs of SV and add
# n pairs each of SC and CV for the updated counts.

use strict;
use List::Util qw(max min);

print "2021 Day 14\n";
my $input = do { local $/; <DATA> }; # slurp it
my @lines = split("\n", $input);
my %pairs = ();
my %rules = ();
for (my $i = 2; $i <= $#lines; $i++) {
	(my ($k, $v)) = $lines[$i] =~ /(\w+)/g;
	$rules{$k} = "$v";
	$pairs{$k} = 0;
}
for (my $i = 0; $i < (-1 + length $lines[0]); $i++) {
	$pairs{substr($lines[0],$i,2)}++;
}

my $max_step = 40;
for (my $i = 1; $i <= $max_step; $i++) {
	my %next_pairs = %pairs;
	foreach my $k (keys %pairs) {
		next if ($pairs{$k} == 0);
		$next_pairs{substr($k,0,1) . $rules{$k}} += $pairs{$k};
		$next_pairs{$rules{$k} . substr($k,1,1)} += $pairs{$k};
		$next_pairs{$k} -= $pairs{$k};
	}
	%pairs = %next_pairs;
	if ($i == 10) {
		print "Part 1: After $i steps, difference between most common and least common elements is ", count_letters(\%pairs, $lines[0]), "\n";
	}
}
print "Part 2: After $max_step steps, difference between most common and least common elements is ", count_letters(\%pairs, $lines[0]), "\n";

# We now have to translate our counts of element pairs into counts of individual elements. Note that
# %pairs is double-counting all individual letters except that the very first and last letters are 1 short.
# So we add an extra for those specific two letters and then divide all counts in half.
sub count_letters {
	my $p = shift;
	my $start = shift;
	
	my %letters = ();
	foreach my $k (keys %$p) {
		$letters{substr($k,0,1)} = 0 unless exists $letters{substr($k,0,1)};
		$letters{substr($k,0,1)} += $p->{$k};
		$letters{substr($k,1,1)} = 0 unless exists $letters{substr($k,1,1)};
		$letters{substr($k,1,1)} += $p->{$k};
	}
	$letters{substr($start,1,1)}++;
	$letters{substr($start,-1,1)}++;
	foreach my $k (keys %letters) {
		$letters{$k} /= 2;
	}
	return (max(values %letters) - min(values %letters));
}

__DATA__
VNVVKSNNFPBBBVSCVBBC

SV -> C
SF -> P
BP -> V
HC -> B
PK -> B
NF -> C
SN -> N
PF -> S
ON -> S
FC -> C
PN -> P
SC -> B
KS -> V
OS -> S
NC -> C
VH -> N
OH -> C
BB -> H
KV -> V
HP -> S
CP -> H
SO -> F
KK -> N
OO -> C
SH -> O
PB -> S
KP -> H
OC -> K
BN -> F
HH -> S
CH -> B
PC -> V
SB -> N
KO -> H
BH -> B
SK -> K
KF -> S
NH -> O
HN -> V
VN -> F
BC -> V
VP -> C
KN -> H
PV -> S
HB -> V
VV -> O
PO -> B
FN -> H
PP -> B
BF -> S
CB -> S
NK -> F
NO -> B
CC -> S
OF -> C
HS -> H
SP -> C
VB -> V
BK -> S
CO -> O
NS -> K
PH -> O
BV -> B
CK -> F
VC -> S
HK -> B
BO -> K
HV -> F
KC -> V
CN -> H
FS -> V
VS -> N
CF -> K
VO -> F
FH -> H
NB -> N
PS -> P
OK -> N
CV -> O
CS -> K
HO -> C
KB -> P
NN -> V
KH -> C
OB -> V
BS -> O
FB -> H
FF -> K
HF -> P
FO -> F
VF -> F
OP -> S
VK -> K
OV -> N
FK -> H
FP -> H
NV -> H
NP -> N
SS -> C
FV -> N