#!/bin/perl -w
#
# https://adventofcode.com/2019/day/16
#

use strict;

use Carp;
use POSIX;

$| = 1;

print "\nDay 16:\n";
my $puzzle = <DATA>;
my @input = split '', $puzzle;

# Setup the repeating pattern multipliers as per instructions
my @multipliers = ();
for (my $i = 1; $i <= $#input+1; $i++) {
	my @base = ( (0) x $i, (1) x $i, (0) x $i, (-1) x $i );
	my $m = 1 + POSIX::ceil(scalar(@input) / ($i * 4));
	my @row = (@base) x $m;
	shift @row;
	splice @row, scalar(@input);
	$multipliers[$i-1] = \@row;
}

# Optimizations in play
# 1) second loop should start at $i because all the multipliers before that are zeroes
# 2) we don't actually need to do any multiplications since a multiplier of 1 is just an addition and -1 is just a subtraction
my $phases = 100;
my @output = ();

for (my $p = 0; $p < $phases; $p++) {
	print "Computing FFT phase $p\r";
	for (my $i = 0; $i <= $#input; $i++) {
		my $sum = 0;
		for (my $j = $i; $j <= $#input; $j++) {
			if ($multipliers[$i][$j] != 0) {
				$sum += ($multipliers[$i][$j] == 1) ? $input[$j] : -$input[$j];
			}
		}
		$output[$i] = abs($sum) % 10;
	}
	@input = @output;
}
print "Finished computing $phases phases of FFT\n";
print "Final result for p1 is " . join('', @input[0..7]) . "\n";

# For p2 there is are more optimizations which can be done. Input has exploded from 650 to 6,500,000 values but the offset
# for our data is 5,978,017. Since this is more than halfway through the data set, everything before it is a zero and
# everything after it is a positive one. Although it doesn't really matter we are confident all input from AoC is setup this way.
# Thus our algorithm is basically output[n] = sum of last n values, and by iterating backwards we just make a cumulative sum and
# each step is a single addition + modulo (without abs since we know it's positive.)
@input = split '', $puzzle;
my $size = scalar(@input)*10000 - substr($puzzle,0,7);
@output = (@input) x POSIX::ceil($size/scalar(@input));
splice @output, 0, -$size;
@input = @output;
for (my $p = 0; $p < $phases; $p++) {
	print "Computing FFT phase $p\r";
	$output[$#input] = $input[$#input];
	for (my $i = $#input-1; $i >= 0; $i--) {
		$output[$i] = ($output[$i+1]+$input[$i]) % 10;
	}
	@input = @output;
}
print "Finished computing $phases phases of FFT\n";
print "Final result for p2 is " . join('', @input[0..7]) . "\n";

__DATA__
59780176309114213563411626026169666104817684921893071067383638084250265421019328368225128428386936441394524895942728601425760032014955705443784868243628812602566362770025248002047665862182359972049066337062474501456044845186075662674133860649155136761608960499705430799727618774927266451344390608561172248303976122250556049804603801229800955311861516221350410859443914220073199362772401326473021912965036313026340226279842955200981164839607677446008052286512958337184508094828519352406975784409736797004839330203116319228217356639104735058156971535587602857072841795273789293961554043997424706355960679467792876567163751777958148340336385972649515437