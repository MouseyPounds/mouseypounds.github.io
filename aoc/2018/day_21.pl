#!/bin/perl -w
#
# https://adventofcode.com/2018/day/21

use strict;

print "2018 Day 21\n\n";
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

my @reg = run_program(\@program, $ipreg, 1);
print "P1: The value for register 0 with least instructions is $reg[0].\n";
@reg = run_program(\@program, $ipreg, 2);
print "P1: The value for register 0 with most instructions is $reg[0].\n";

# Examining the instruction set, the only time register 0 comes into
# play is the `eqrr 3 0 1` instruction. If reg3 == reg0, this will set
# reg1 to 1 and the next instruction will then put the ip out of bounds
# and halt the program. So to answer part 1, we need to know what value
# register 3 has when it first hits this instruction.

# For part 2 we tried just watching that same instruction and then keeping
# track of the reg3 values there until we see a duplicate. This works, but
# takes forever, so once again it looks like reimplimenting the logic of the
# program natively is the better option.

sub run_program {
	my $inst = shift;
	my $ir = shift;
	my $override = shift;
	
	$override = 0 unless defined $override;
	
	my $ip = 0;
	my @reg = (0, 0, 0, 0, 0, 0);
	my %seen = ();
	my $last = 0;
	
	while ($ip < scalar(@$inst) and $ip >= 0) {
		$reg[$ir] = $ip;
		
		# This may not be a generic solution if other inputs use a different target register.
		if ($ip == 28) {
			if ($override == 1) {
				$reg[0] = $reg[3];
				last;
			} elsif ($override == 2) {
				if (defined $seen{$reg[3]}) {
					$reg[0] = $last;
					last;
				} else {
					$last = $reg[3];
					$seen{$reg[3]} = 1;
				}
			}
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
			$reg[$inst->[$ip][3]] = 0 + $reg[$inst->[$ip][1]] & $reg[$inst->[$ip][2]];
		} elsif ($inst->[$ip][0] eq 'bani') {
			$reg[$inst->[$ip][3]] = 0 + $reg[$inst->[$ip][1]] & $inst->[$ip][2];
		} elsif ($inst->[$ip][0] eq 'borr') {
			$reg[$inst->[$ip][3]] = 0 + $reg[$inst->[$ip][1]] | $reg[$inst->[$ip][2]];
		} elsif ($inst->[$ip][0] eq 'bori') {
			$reg[$inst->[$ip][3]] = 0 + $reg[$inst->[$ip][1]] | $inst->[$ip][2];
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
		
		#print "[$ip] [", join(" ", @reg), "]\n";
		
		$ip = $reg[$ir];
		$ip++;			
	}
	return @reg;
}



__DATA__
#ip 4
seti 123 0 3
bani 3 456 3
eqri 3 72 3
addr 3 4 4
seti 0 0 4
seti 0 5 3
bori 3 65536 2
seti 10736359 9 3
bani 2 255 1
addr 3 1 3
bani 3 16777215 3
muli 3 65899 3
bani 3 16777215 3
gtir 256 2 1
addr 1 4 4
addi 4 1 4
seti 27 2 4
seti 0 3 1
addi 1 1 5
muli 5 256 5
gtrr 5 2 5
addr 5 4 4
addi 4 1 4
seti 25 8 4
addi 1 1 1
seti 17 6 4
setr 1 5 2
seti 7 7 4
eqrr 3 0 1
addr 1 4 4
seti 5 1 4