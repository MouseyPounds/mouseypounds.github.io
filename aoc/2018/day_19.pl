#!/bin/perl -w
#
# https://adventofcode.com/2018/day/19

use strict;

print "2018 Day 19\n\n";
my $puzzle = do { local $/; <DATA> }; # slurp it
my @lines = split("\n", $puzzle);

my @program = ();
my $ipreg = 0;
for (my $i = 0; $i < scalar(@lines); $i++) {
	my @inst = split /\s+/, $lines[$i];
	if ($inst[0] eq '#ip') {
		$ipreg = $inst[1];
	} else {
		push @program, [@inst];
	}
}

my @reg = run_program(\@program, $ipreg);
print "P1: After running the original program, register 0 contains $reg[0].\n";

# Part 2 would take a really long time to run, so the whole key to this puzzle is to
# investigate what the program is actually doing. Here is a basic skeleton:
# [00] jumps to instruction 17
# [17-25] does some math ending with register 2 containing 905 (part 1 target)
# [26] jumps to instruction 1 for part 1 (start of outer loop), but skipped for part 2
# [27-35] does more math increasing register 2 to 10551305 (part 2 target)
# Outer loop begins (reg0 == 0 in both cases at this point)
# [01] reg1 initialized to 1
#   Inner loop begins
#   [02] reg4 initialized to 1
#   [03-11] multiples reg1*reg4 to see if it == reg2, incrementing reg4 after
#           if equality succeeds, reg1 is added to reg0.
#   Inner loop ends when reg4 > reg2
# [12-15] now reg1 gets incremented and continues looping
# Outer loop ends  when reg1 > reg2
# [16] squares reg3 (ip) which halts the program
# Thus the program finds all factors of the reg2 target number, sums them, and stores in reg0.
# We will now circumvent this process with our own sum of factors calculator.
# We'll rerun part 1 with the new optimized program and then do part 2.

@reg = run_program(\@program, $ipreg, 0, 1);
print "P1: After running optimized program with starting value 0, register 0 contains $reg[0].\n";
@reg = run_program(\@program, $ipreg, 1, 1);
print "P2: After running optimized program with starting value 1, register 0 contains $reg[0].\n";
exit;

sub run_program {
	my $inst = shift;
	my $ir = shift;
	my $reg_0 = shift;
	my $override = shift;
	
	$reg_0 = 0 unless defined $reg_0;
	$override = 0 unless defined $override;
	
	my $ip = 0;
	my @reg = ($reg_0, 0, 0, 0, 0, 0);
	
	while ($ip < scalar(@$inst) and $ip >= 0) {
		$reg[$ir] = $ip;
		
		# This may not be a generic solution if other inputs use a different target register.
		if ($override and $ip == 1) {
			$reg[0] = get_sum_of_factors($reg[2]);
			last;
		}
		
		if ($inst->[$ip][0] eq 'addr') {
			$reg[$inst->[$ip][3]] = $reg[$inst->[$ip][1]] + $reg[$inst->[$ip][2]];
		} elsif ($inst->[$ip][0] eq 'addi') {
			$reg[$inst->[$ip][3]] = $reg[$inst->[$ip][1]] + $inst->[$ip][2];
		} elsif ($inst->[$ip][0] eq 'mulr') {
			$reg[$inst->[$ip][3]] = $reg[$inst->[$ip][1]] * $reg[$inst->[$ip][2]];
		} elsif ($inst->[$ip][0] eq 'muli') {
			$reg[$inst->[$ip][3]] = $reg[$inst->[$ip][1]] * $inst->[$ip][2];
		} elsif ($inst->[$ip][0] eq 'banr') {
			$reg[$inst->[$ip][3]] = $reg[$inst->[$ip][1]] & $reg[$inst->[$ip][2]];
		} elsif ($inst->[$ip][0] eq 'bani') {
			$reg[$inst->[$ip][3]] = $reg[$inst->[$ip][1]] & $inst->[$ip][2];
		} elsif ($inst->[$ip][0] eq 'borr') {
			$reg[$inst->[$ip][3]] = $reg[$inst->[$ip][1]] | $reg[$inst->[$ip][2]];
		} elsif ($inst->[$ip][0] eq 'bori') {
			$reg[$inst->[$ip][3]] = $reg[$inst->[$ip][1]] | $inst->[$ip][2];
		} elsif ($inst->[$ip][0] eq 'setr') {
			$reg[$inst->[$ip][3]] = $reg[$inst->[$ip][1]];
		} elsif ($inst->[$ip][0] eq 'seti') {
			$reg[$inst->[$ip][3]] = $inst->[$ip][1];
		} elsif ($inst->[$ip][0] eq 'gtir') {
			$reg[$inst->[$ip][3]] = ($inst->[$ip][1] > $reg[$inst->[$ip][2]]) ? 1 : 0;
		} elsif ($inst->[$ip][0] eq 'gtri') {
			$reg[$inst->[$ip][3]] = ($reg[$inst->[$ip][1]] > $inst->[$ip][2]) ? 1 : 0;
		} elsif ($inst->[$ip][0] eq 'gtrr') {
			$reg[$inst->[$ip][3]] = ($reg[$inst->[$ip][1]] > $reg[$inst->[$ip][2]]) ? 1 : 0;
		} elsif ($inst->[$ip][0] eq 'eqir') {
			$reg[$inst->[$ip][3]] = ($inst->[$ip][1] == $reg[$inst->[$ip][2]]) ? 1 : 0;
		} elsif ($inst->[$ip][0] eq 'eqri') {
			$reg[$inst->[$ip][3]] = ($reg[$inst->[$ip][1]] == $inst->[$ip][2]) ? 1 : 0;
		} elsif ($inst->[$ip][0] eq 'eqrr') {
			$reg[$inst->[$ip][3]] = ($reg[$inst->[$ip][1]] == $reg[$inst->[$ip][2]]) ? 1 : 0;
		} else {
			die "Unknown opcode $inst->[$ip][0] at program instruction $ip";
		}
		
		#print "[$ip] ", join(" ", @reg), "\n";
		
		$ip = $reg[$ir];
		$ip++;			
	}
	return @reg;
}

sub get_sum_of_factors {
	my $target = shift;
	my $sum = 0;
	
	for (my $i = 1; $i <= sqrt($target); $i++) {
		if ($target % $i == 0) {
			my $other = $target/$i;
			$other = 0 if ($other == $i);
			$sum += $i + $other;
		}
	}
	return $sum;
}

__DATA__
#ip 3
addi 3 16 3
seti 1 5 1
seti 1 4 4
mulr 1 4 5
eqrr 5 2 5
addr 5 3 3
addi 3 1 3
addr 1 0 0
addi 4 1 4
gtrr 4 2 5
addr 3 5 3
seti 2 6 3
addi 1 1 1
gtrr 1 2 5
addr 5 3 3
seti 1 1 3
mulr 3 3 3
addi 2 2 2
mulr 2 2 2
mulr 3 2 2
muli 2 11 2
addi 5 3 5
mulr 5 3 5
addi 5 3 5
addr 2 5 2
addr 3 0 3
seti 0 6 3
setr 3 8 5
mulr 5 3 5
addr 3 5 5
mulr 3 5 5
muli 5 14 5
mulr 5 3 5
addr 2 5 2
seti 0 2 0
seti 0 2 3