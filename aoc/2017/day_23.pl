#!/bin/perl -w
#
# https://adventofcode.com/2017/day/23

use strict;

print "2017 Day 23\n\n";
my $puzzle = do { local $/; <DATA> }; # slurp it
my @ins = map { [ split(' ') ] } split("\n", $puzzle);

my $result = run_coprocessor(\@ins);
print "P1: The mul instruction was invoked $result times.\n";

# Manual translation of coprocessor instructions. The first line is apparently what is different for different inputs;
# registers b & c are initialized based on this value. The program loops from this initial b to c in steps of 17.
# For each b it loops d = 2 .. b and e = 2 .. b and sets f = 0 if (d*e == b); then h is incremented if (f == 0)
# So basically it is counting all the prime values of b in the appropriate range. That is what we need to calculate.
my $b = $ins[0][2];
my $start = $b * 100 + 100000;
my $c = $start + 17000;
my $h = 0;
for ($b = $start; $b <= $c; $b += 17) {
	for (my $i = 2; $i <= sqrt($b); $i++) {
		if (($b % $i) == 0) {
			$h++;
			last;
		}
	}
}
print "P2: The program is trying to calculate h = $h.\n";

sub run_coprocessor {
	my $ins = shift;

	my $ip = 0;
	my $done = 0;
	my $mul_count = 0;
	my %reg = ();
	map { $reg{$_} = 0 } ('a' .. 'h');
	my ($op, $x, $y);
	
	while(not $done) {
		#print "[$ip]: ", join(' ', @{$ins->[$ip]}), "\n";
		$op = $ins->[$ip][0];
		$x = ((exists $reg{$ins->[$ip][1]}) ? $reg{$ins->[$ip][1]} : $ins->[$ip][1]) if (scalar @{$ins->[$ip]} > 1);
		$y = ((exists $reg{$ins->[$ip][2]}) ? $reg{$ins->[$ip][2]} : $ins->[$ip][2]) if (scalar @{$ins->[$ip]} > 2);
			
		if ($op eq 'set') {
			$reg{$ins->[$ip][1]} = $y;
			$ip++;
		} elsif ($op eq 'sub') {
			$reg{$ins->[$ip][1]} -= $y;
			$ip++;
		} elsif ($op eq 'mul') {
			$reg{$ins->[$ip][1]} *= $y;
			$ip++;
			$mul_count++;
		} elsif ($op eq 'jnz') {
			$ip += ($x != 0) ? $y : 1;
		} else {
			warn "Skipping invalid instruction {$ins->[$ip][0]}\n";
			$ip++;
		}
		$done = 1 if ($ip >= scalar(@$ins));
	}
	return $mul_count;
}

__DATA__
set b 84
set c b
jnz a 2
jnz 1 5
mul b 100
sub b -100000
set c b
sub c -17000
set f 1
set d 2
set e 2
set g d
mul g e
sub g b
jnz g 2
set f 0
sub e -1
set g e
sub g b
jnz g -8
sub d -1
set g d
sub g b
jnz g -13
jnz f 2
sub h -1
set g b
sub g c
jnz g 2
jnz 1 3
sub b -17
jnz 1 -23