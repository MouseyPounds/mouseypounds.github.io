#!/bin/perl -w
#
# https://adventofcode.com/2018/day/16

use strict;
use List::Util qw(sum);
use Data::Dumper;

print "2018 Day 16\n\n";
my $puzzle = do { local $/; <DATA> }; # slurp it
my @lines = split("\n", $puzzle);

my @samples = ();
my @program = ();
for (my $i = 0; $i < scalar(@lines);) {
	if ($lines[$i] =~ /Before/) {
		# Still in test phase
		my @before = $lines[$i] =~ /(\d+)/g;
		my @inst = $lines[$i+1] =~ /(\d+)/g;
		my @after = $lines[$i+2] =~ /(\d+)/g;
		
		push @samples, { 'b' => [@before], 'i' => [@inst], 'a' => [@after] };
		$i +=4;
	} else {
		# Now in program phase, skip blank lines
		my @inst = $lines[$i] =~ /(\d+)/g;
		if (scalar(@inst)) {
			push @program, [@inst];
		}
		$i++;
	}
}

my $p1_count = 0;
for (my $i = 0; $i < scalar(@samples); $i++) {
	my @matches = test_instruction($samples[$i]{'b'}, $samples[$i]{'i'}, $samples[$i]{'a'});
	$p1_count++ if (scalar(@matches) >= 3);
}
print "P1: Opcode testing found $p1_count out of ", scalar(@samples), " samples which behave like 3+ opcodes\n";

my %opcodes = ();
my %left = map {$_ => 1} (0 .. 15);
while (scalar(keys %left)) {
	my $start = scalar(keys %left);
	for (my $i = 0; $i < scalar(@samples); $i++) {
		next if (exists $opcodes{$samples[$i]{'i'}[0]});
		my @matches = test_instruction($samples[$i]{'b'}, $samples[$i]{'i'}, $samples[$i]{'a'}, \%opcodes);
		if (scalar(@matches) == 1) {
			$opcodes{$samples[$i]{'i'}[0]} = $matches[0];
			$opcodes{$matches[0]} = $samples[$i]{'i'}[0];
			delete $left{$samples[$i]{'i'}[0]};
		}
	}
	if (scalar(keys %left) == $start) {
		print "Opcode search failed to find any new matches\n";
		last;
	}
}

my @reg = run_program(\@program, \%opcodes);
print "P2: After running the program, register 0 contains $reg[0].\n";

sub run_program {
	my $inst = shift;
	my $opcodes = shift;

	my $ip = 0;
	my @reg = (0, 0, 0, 0);
	
	while ($ip < scalar(@$inst)) {
		if ($inst->[$ip][0] == $opcodes->{'addr'}) {
			$reg[$inst->[$ip][3]] = $reg[$inst->[$ip][1]] + $reg[$inst->[$ip][2]];
		} elsif ($inst->[$ip][0] == $opcodes->{'addi'}) {
			$reg[$inst->[$ip][3]] = $reg[$inst->[$ip][1]] + $inst->[$ip][2];
		} elsif ($inst->[$ip][0] == $opcodes->{'mulr'}) {
			$reg[$inst->[$ip][3]] = $reg[$inst->[$ip][1]] * $reg[$inst->[$ip][2]];
		} elsif ($inst->[$ip][0] == $opcodes->{'muli'}) {
			$reg[$inst->[$ip][3]] = $reg[$inst->[$ip][1]] * $inst->[$ip][2];
		} elsif ($inst->[$ip][0] == $opcodes->{'banr'}) {
			$reg[$inst->[$ip][3]] = $reg[$inst->[$ip][1]] & $reg[$inst->[$ip][2]];
		} elsif ($inst->[$ip][0] == $opcodes->{'bani'}) {
			$reg[$inst->[$ip][3]] = $reg[$inst->[$ip][1]] & $inst->[$ip][2];
		} elsif ($inst->[$ip][0] == $opcodes->{'borr'}) {
			$reg[$inst->[$ip][3]] = $reg[$inst->[$ip][1]] | $reg[$inst->[$ip][2]];
		} elsif ($inst->[$ip][0] == $opcodes->{'bori'}) {
			$reg[$inst->[$ip][3]] = $reg[$inst->[$ip][1]] | $inst->[$ip][2];
		} elsif ($inst->[$ip][0] == $opcodes->{'setr'}) {
			$reg[$inst->[$ip][3]] = $reg[$inst->[$ip][1]];
		} elsif ($inst->[$ip][0] == $opcodes->{'seti'}) {
			$reg[$inst->[$ip][3]] = $inst->[$ip][1];
		} elsif ($inst->[$ip][0] == $opcodes->{'gtir'}) {
			$reg[$inst->[$ip][3]] = ($inst->[$ip][1] > $reg[$inst->[$ip][2]]) ? 1 : 0;
		} elsif ($inst->[$ip][0] == $opcodes->{'gtri'}) {
			$reg[$inst->[$ip][3]] = ($reg[$inst->[$ip][1]] > $inst->[$ip][2]) ? 1 : 0;
		} elsif ($inst->[$ip][0] == $opcodes->{'gtrr'}) {
			$reg[$inst->[$ip][3]] = ($reg[$inst->[$ip][1]] > $reg[$inst->[$ip][2]]) ? 1 : 0;
		} elsif ($inst->[$ip][0] == $opcodes->{'eqir'}) {
			$reg[$inst->[$ip][3]] = ($inst->[$ip][1] == $reg[$inst->[$ip][2]]) ? 1 : 0;
		} elsif ($inst->[$ip][0] == $opcodes->{'eqri'}) {
			$reg[$inst->[$ip][3]] = ($reg[$inst->[$ip][1]] == $inst->[$ip][2]) ? 1 : 0;
		} elsif ($inst->[$ip][0] == $opcodes->{'eqrr'}) {
			$reg[$inst->[$ip][3]] = ($reg[$inst->[$ip][1]] == $reg[$inst->[$ip][2]]) ? 1 : 0;
		} else {
			die "Unknown opcode $inst->[$ip][0] at program instruction $ip";
		}
		$ip++;
	}
	return @reg;
}

sub test_instruction {
	my $before = shift;
	my $inst = shift;	#opcode	A B C
	my $after = shift;
	my $opcodes = shift;
	
	my @matches = ();
	my $op;
	
	$op = 'addr';
	if (not defined $opcodes or (not exists $opcodes->{$inst->[0]} and not exists $opcodes->{$op})) {
		push @matches, $op if (check($before, $after, $inst->[3], $before->[$inst->[1]] + $before->[$inst->[2]]));
	}
	$op = 'addi';
	if (not defined $opcodes or (not exists $opcodes->{$inst->[0]} and not exists $opcodes->{$op})) {
		push @matches, $op if (check($before, $after, $inst->[3], $before->[$inst->[1]] + $inst->[2]));
	}
	$op = 'mulr';
	if (not defined $opcodes or (not exists $opcodes->{$inst->[0]} and not exists $opcodes->{$op})) {
		push @matches, $op if (check($before, $after, $inst->[3], $before->[$inst->[1]] * $before->[$inst->[2]]));
	}
	$op = 'muli';
	if (not defined $opcodes or (not exists $opcodes->{$inst->[0]} and not exists $opcodes->{$op})) {
		push @matches, $op if (check($before, $after, $inst->[3], $before->[$inst->[1]] * $inst->[2]));
	}
	$op = 'banr';
	if (not defined $opcodes or (not exists $opcodes->{$inst->[0]} and not exists $opcodes->{$op})) {
		push @matches, $op if (check($before, $after, $inst->[3], $before->[$inst->[1]] & $before->[$inst->[2]]));
	}
	$op = 'bani';
	if (not defined $opcodes or (not exists $opcodes->{$inst->[0]} and not exists $opcodes->{$op})) {
		push @matches, $op if (check($before, $after, $inst->[3], $before->[$inst->[1]] & $inst->[2]));
	}
	$op = 'borr';
	if (not defined $opcodes or (not exists $opcodes->{$inst->[0]} and not exists $opcodes->{$op})) {
		push @matches, $op if (check($before, $after, $inst->[3], $before->[$inst->[1]] | $before->[$inst->[2]]));
	}
	$op = 'bori';
	if (not defined $opcodes or (not exists $opcodes->{$inst->[0]} and not exists $opcodes->{$op})) {
		push @matches, $op if (check($before, $after, $inst->[3], $before->[$inst->[1]] | $inst->[2]));
	}
	$op = 'setr';
	if (not defined $opcodes or (not exists $opcodes->{$inst->[0]} and not exists $opcodes->{$op})) {
		push @matches, $op if (check($before, $after, $inst->[3], $before->[$inst->[1]]));
	}
	$op = 'seti';
	if (not defined $opcodes or (not exists $opcodes->{$inst->[0]} and not exists $opcodes->{$op})) {
		push @matches, $op if (check($before, $after, $inst->[3], $inst->[1]));
	}
	$op = 'gtir';
	if (not defined $opcodes or (not exists $opcodes->{$inst->[0]} and not exists $opcodes->{$op})) {
		push @matches, $op if (check($before, $after, $inst->[3], ($inst->[1] > $before->[$inst->[2]]) ? 1 : 0));
	}
	$op = 'gtri';
	if (not defined $opcodes or (not exists $opcodes->{$inst->[0]} and not exists $opcodes->{$op})) {
		push @matches, $op if (check($before, $after, $inst->[3], ($before->[$inst->[1]] > $inst->[2]) ? 1 : 0));
	}
	$op = 'gtrr';
	if (not defined $opcodes or (not exists $opcodes->{$inst->[0]} and not exists $opcodes->{$op})) {
		push @matches, $op if (check($before, $after, $inst->[3], ($before->[$inst->[1]] > $before->[$inst->[2]]) ? 1 : 0));
	}
	$op = 'eqir';
	if (not defined $opcodes or (not exists $opcodes->{$inst->[0]} and not exists $opcodes->{$op})) {
		push @matches, $op if (check($before, $after, $inst->[3], ($inst->[1] == $before->[$inst->[2]]) ? 1 : 0));
	}
	$op = 'eqri';
	if (not defined $opcodes or (not exists $opcodes->{$inst->[0]} and not exists $opcodes->{$op})) {
		push @matches, $op if (check($before, $after, $inst->[3], ($before->[$inst->[1]] == $inst->[2]) ? 1 : 0));
	}
	$op = 'eqrr';
	if (not defined $opcodes or (not exists $opcodes->{$inst->[0]} and not exists $opcodes->{$op})) {
		push @matches, $op if (check($before, $after, $inst->[3], ($before->[$inst->[1]] == $before->[$inst->[2]]) ? 1 : 0));
	}
	return @matches;
}

sub check {
	my $before = shift;
	my $after = shift;
	my $reg_C_addr = shift;
	my $reg_C_val = shift;

	my @reg = ($before->[0], $before->[1], $before->[2], $before->[3]);
	$reg[$reg_C_addr] = $reg_C_val;
	
	return ($reg[0] == $after->[0] and $reg[1] == $after->[1] and $reg[2] == $after->[2] and $reg[3] == $after->[3]);
}
__DATA__
Before: [2, 3, 2, 2]
15 3 2 2
After:  [2, 3, 4, 2]

Before: [3, 2, 2, 1]
3 1 0 1
After:  [3, 1, 2, 1]

Before: [3, 3, 2, 1]
5 3 2 1
After:  [3, 3, 2, 1]

Before: [0, 1, 2, 2]
10 1 0 1
After:  [0, 1, 2, 2]

Before: [0, 1, 2, 1]
8 0 0 3
After:  [0, 1, 2, 0]

Before: [2, 3, 0, 3]
11 0 3 3
After:  [2, 3, 0, 0]

Before: [2, 3, 1, 0]
0 0 2 3
After:  [2, 3, 1, 4]

Before: [2, 0, 1, 1]
7 2 1 2
After:  [2, 0, 1, 1]

Before: [1, 3, 3, 1]
6 0 2 0
After:  [2, 3, 3, 1]

Before: [1, 2, 2, 1]
5 3 2 3
After:  [1, 2, 2, 3]

Before: [1, 0, 1, 2]
13 1 0 3
After:  [1, 0, 1, 1]

Before: [1, 2, 3, 0]
6 1 3 1
After:  [1, 6, 3, 0]

Before: [1, 0, 0, 3]
11 0 3 0
After:  [0, 0, 0, 3]

Before: [0, 3, 2, 1]
5 3 2 2
After:  [0, 3, 3, 1]

Before: [2, 0, 0, 0]
2 3 0 3
After:  [2, 0, 0, 2]

Before: [1, 0, 2, 1]
15 2 2 0
After:  [4, 0, 2, 1]

Before: [0, 1, 2, 3]
4 3 2 3
After:  [0, 1, 2, 5]

Before: [1, 0, 0, 2]
13 1 0 0
After:  [1, 0, 0, 2]

Before: [3, 1, 2, 1]
5 3 2 0
After:  [3, 1, 2, 1]

Before: [1, 1, 3, 0]
12 0 2 2
After:  [1, 1, 3, 0]

Before: [1, 0, 2, 1]
13 1 0 2
After:  [1, 0, 1, 1]

Before: [2, 2, 3, 1]
6 2 3 2
After:  [2, 2, 9, 1]

Before: [2, 1, 2, 3]
4 1 1 0
After:  [2, 1, 2, 3]

Before: [1, 1, 0, 1]
6 3 2 1
After:  [1, 2, 0, 1]

Before: [3, 2, 2, 3]
3 1 0 3
After:  [3, 2, 2, 1]

Before: [0, 1, 2, 2]
8 0 0 3
After:  [0, 1, 2, 0]

Before: [3, 0, 1, 0]
2 1 0 0
After:  [3, 0, 1, 0]

Before: [3, 2, 3, 3]
3 1 0 0
After:  [1, 2, 3, 3]

Before: [0, 1, 0, 3]
12 0 3 2
After:  [0, 1, 3, 3]

Before: [0, 1, 2, 1]
10 1 0 0
After:  [1, 1, 2, 1]

Before: [2, 1, 1, 2]
12 2 3 3
After:  [2, 1, 1, 3]

Before: [1, 0, 2, 2]
7 0 1 3
After:  [1, 0, 2, 1]

Before: [2, 1, 3, 2]
5 3 1 1
After:  [2, 3, 3, 2]

Before: [1, 0, 3, 2]
13 1 0 3
After:  [1, 0, 3, 1]

Before: [3, 2, 2, 0]
3 1 0 2
After:  [3, 2, 1, 0]

Before: [2, 3, 3, 3]
11 0 3 3
After:  [2, 3, 3, 0]

Before: [0, 1, 3, 3]
10 1 0 2
After:  [0, 1, 1, 3]

Before: [1, 1, 3, 3]
4 0 3 1
After:  [1, 4, 3, 3]

Before: [1, 0, 1, 0]
7 0 1 1
After:  [1, 1, 1, 0]

Before: [3, 0, 1, 3]
14 1 2 1
After:  [3, 1, 1, 3]

Before: [1, 1, 1, 2]
4 0 1 3
After:  [1, 1, 1, 2]

Before: [0, 1, 2, 1]
15 2 2 3
After:  [0, 1, 2, 4]

Before: [0, 3, 3, 3]
8 0 0 2
After:  [0, 3, 0, 3]

Before: [0, 0, 1, 2]
1 0 1 0
After:  [1, 0, 1, 2]

Before: [3, 1, 1, 1]
4 3 1 2
After:  [3, 1, 2, 1]

Before: [3, 2, 3, 2]
3 1 0 2
After:  [3, 2, 1, 2]

Before: [1, 1, 3, 2]
12 0 3 3
After:  [1, 1, 3, 3]

Before: [1, 2, 2, 2]
15 1 2 2
After:  [1, 2, 4, 2]

Before: [2, 0, 1, 2]
14 1 2 3
After:  [2, 0, 1, 1]

Before: [1, 0, 2, 3]
7 0 1 3
After:  [1, 0, 2, 1]

Before: [1, 0, 2, 2]
2 2 0 2
After:  [1, 0, 3, 2]

Before: [1, 0, 0, 0]
13 1 0 3
After:  [1, 0, 0, 1]

Before: [1, 0, 1, 0]
7 0 1 0
After:  [1, 0, 1, 0]

Before: [3, 0, 0, 1]
2 2 0 0
After:  [3, 0, 0, 1]

Before: [0, 2, 3, 0]
8 0 0 3
After:  [0, 2, 3, 0]

Before: [0, 1, 1, 0]
4 1 2 0
After:  [2, 1, 1, 0]

Before: [0, 2, 3, 0]
0 1 2 1
After:  [0, 4, 3, 0]

Before: [3, 2, 1, 3]
3 1 0 0
After:  [1, 2, 1, 3]

Before: [0, 2, 3, 0]
2 3 1 3
After:  [0, 2, 3, 2]

Before: [3, 2, 0, 2]
0 1 2 3
After:  [3, 2, 0, 4]

Before: [0, 0, 1, 3]
8 0 0 2
After:  [0, 0, 0, 3]

Before: [1, 0, 1, 0]
7 2 1 0
After:  [1, 0, 1, 0]

Before: [1, 3, 1, 2]
12 2 3 0
After:  [3, 3, 1, 2]

Before: [2, 3, 3, 1]
5 3 2 1
After:  [2, 3, 3, 1]

Before: [2, 3, 1, 0]
0 0 2 1
After:  [2, 4, 1, 0]

Before: [1, 2, 2, 1]
15 2 2 3
After:  [1, 2, 2, 4]

Before: [1, 1, 1, 3]
11 0 3 3
After:  [1, 1, 1, 0]

Before: [3, 2, 3, 1]
5 3 2 0
After:  [3, 2, 3, 1]

Before: [2, 2, 1, 2]
0 3 2 1
After:  [2, 4, 1, 2]

Before: [1, 1, 3, 3]
12 1 3 3
After:  [1, 1, 3, 3]

Before: [3, 0, 3, 2]
4 0 2 3
After:  [3, 0, 3, 6]

Before: [3, 2, 2, 2]
3 1 0 3
After:  [3, 2, 2, 1]

Before: [2, 1, 3, 2]
0 0 2 3
After:  [2, 1, 3, 4]

Before: [0, 3, 1, 1]
8 0 0 2
After:  [0, 3, 0, 1]

Before: [1, 0, 0, 1]
13 1 0 3
After:  [1, 0, 0, 1]

Before: [3, 0, 2, 2]
15 2 2 1
After:  [3, 4, 2, 2]

Before: [0, 0, 1, 1]
7 3 1 0
After:  [1, 0, 1, 1]

Before: [2, 2, 2, 3]
4 1 3 1
After:  [2, 5, 2, 3]

Before: [1, 0, 2, 1]
13 1 0 1
After:  [1, 1, 2, 1]

Before: [0, 0, 1, 1]
14 1 2 3
After:  [0, 0, 1, 1]

Before: [2, 3, 1, 3]
4 1 3 1
After:  [2, 6, 1, 3]

Before: [2, 2, 3, 2]
0 0 2 0
After:  [4, 2, 3, 2]

Before: [1, 0, 3, 3]
11 0 3 2
After:  [1, 0, 0, 3]

Before: [3, 3, 2, 1]
5 3 2 2
After:  [3, 3, 3, 1]

Before: [2, 3, 2, 1]
5 3 2 0
After:  [3, 3, 2, 1]

Before: [3, 2, 3, 1]
3 1 0 1
After:  [3, 1, 3, 1]

Before: [1, 1, 2, 0]
15 2 2 0
After:  [4, 1, 2, 0]

Before: [0, 1, 0, 3]
10 1 0 3
After:  [0, 1, 0, 1]

Before: [3, 0, 1, 2]
0 3 2 2
After:  [3, 0, 4, 2]

Before: [1, 2, 1, 3]
9 1 0 1
After:  [1, 1, 1, 3]

Before: [2, 0, 3, 3]
11 0 3 0
After:  [0, 0, 3, 3]

Before: [0, 0, 1, 3]
1 0 1 1
After:  [0, 1, 1, 3]

Before: [1, 3, 3, 3]
4 1 3 0
After:  [6, 3, 3, 3]

Before: [1, 2, 2, 2]
15 3 2 0
After:  [4, 2, 2, 2]

Before: [2, 0, 0, 1]
14 1 3 0
After:  [1, 0, 0, 1]

Before: [0, 0, 0, 3]
1 0 1 0
After:  [1, 0, 0, 3]

Before: [1, 2, 3, 3]
12 0 3 0
After:  [3, 2, 3, 3]

Before: [1, 0, 2, 3]
13 1 0 1
After:  [1, 1, 2, 3]

Before: [2, 1, 3, 3]
2 1 0 2
After:  [2, 1, 3, 3]

Before: [0, 1, 1, 0]
10 1 0 0
After:  [1, 1, 1, 0]

Before: [1, 0, 2, 1]
7 0 1 3
After:  [1, 0, 2, 1]

Before: [0, 1, 0, 2]
8 0 0 0
After:  [0, 1, 0, 2]

Before: [3, 0, 0, 1]
14 1 3 1
After:  [3, 1, 0, 1]

Before: [2, 1, 1, 1]
12 0 1 3
After:  [2, 1, 1, 3]

Before: [0, 0, 3, 1]
8 0 0 1
After:  [0, 0, 3, 1]

Before: [3, 2, 2, 1]
3 1 0 0
After:  [1, 2, 2, 1]

Before: [2, 1, 2, 3]
11 0 3 3
After:  [2, 1, 2, 0]

Before: [3, 2, 2, 0]
3 1 0 0
After:  [1, 2, 2, 0]

Before: [1, 2, 0, 3]
12 2 3 2
After:  [1, 2, 3, 3]

Before: [1, 2, 1, 2]
12 0 3 0
After:  [3, 2, 1, 2]

Before: [1, 0, 3, 0]
7 0 1 0
After:  [1, 0, 3, 0]

Before: [3, 2, 2, 2]
3 1 0 2
After:  [3, 2, 1, 2]

Before: [0, 1, 3, 1]
5 3 2 2
After:  [0, 1, 3, 1]

Before: [1, 3, 1, 1]
2 2 1 3
After:  [1, 3, 1, 3]

Before: [0, 0, 3, 1]
14 1 3 1
After:  [0, 1, 3, 1]

Before: [3, 2, 1, 1]
3 1 0 3
After:  [3, 2, 1, 1]

Before: [1, 0, 3, 1]
13 1 0 2
After:  [1, 0, 1, 1]

Before: [2, 2, 1, 0]
0 0 2 2
After:  [2, 2, 4, 0]

Before: [0, 0, 1, 1]
14 1 2 0
After:  [1, 0, 1, 1]

Before: [3, 0, 0, 1]
7 3 1 1
After:  [3, 1, 0, 1]

Before: [0, 2, 3, 3]
8 0 0 0
After:  [0, 2, 3, 3]

Before: [3, 2, 2, 0]
15 1 2 0
After:  [4, 2, 2, 0]

Before: [3, 2, 0, 1]
3 1 0 3
After:  [3, 2, 0, 1]

Before: [3, 0, 1, 3]
14 1 2 0
After:  [1, 0, 1, 3]

Before: [2, 0, 2, 3]
11 0 3 2
After:  [2, 0, 0, 3]

Before: [2, 1, 1, 2]
0 3 2 2
After:  [2, 1, 4, 2]

Before: [2, 0, 1, 2]
14 1 2 0
After:  [1, 0, 1, 2]

Before: [1, 2, 0, 0]
9 1 0 2
After:  [1, 2, 1, 0]

Before: [1, 2, 3, 1]
9 1 0 0
After:  [1, 2, 3, 1]

Before: [0, 3, 3, 2]
2 0 1 3
After:  [0, 3, 3, 3]

Before: [1, 3, 1, 3]
11 0 3 0
After:  [0, 3, 1, 3]

Before: [3, 2, 3, 0]
3 1 0 2
After:  [3, 2, 1, 0]

Before: [2, 3, 2, 3]
4 1 3 1
After:  [2, 6, 2, 3]

Before: [2, 1, 3, 3]
12 0 1 2
After:  [2, 1, 3, 3]

Before: [1, 0, 1, 2]
13 1 0 1
After:  [1, 1, 1, 2]

Before: [0, 0, 0, 1]
8 0 0 2
After:  [0, 0, 0, 1]

Before: [1, 0, 3, 0]
13 1 0 0
After:  [1, 0, 3, 0]

Before: [2, 1, 2, 1]
5 3 2 1
After:  [2, 3, 2, 1]

Before: [1, 0, 3, 2]
7 0 1 3
After:  [1, 0, 3, 1]

Before: [0, 3, 2, 3]
8 0 0 1
After:  [0, 0, 2, 3]

Before: [0, 0, 1, 1]
1 0 1 0
After:  [1, 0, 1, 1]

Before: [0, 0, 1, 0]
1 0 1 0
After:  [1, 0, 1, 0]

Before: [3, 2, 3, 3]
3 1 0 2
After:  [3, 2, 1, 3]

Before: [2, 1, 3, 3]
4 1 1 1
After:  [2, 2, 3, 3]

Before: [3, 1, 3, 2]
6 0 3 3
After:  [3, 1, 3, 9]

Before: [0, 1, 0, 1]
10 1 0 0
After:  [1, 1, 0, 1]

Before: [2, 1, 0, 2]
5 3 1 1
After:  [2, 3, 0, 2]

Before: [0, 3, 0, 1]
8 0 0 3
After:  [0, 3, 0, 0]

Before: [0, 1, 3, 3]
10 1 0 1
After:  [0, 1, 3, 3]

Before: [3, 2, 2, 3]
3 1 0 2
After:  [3, 2, 1, 3]

Before: [2, 1, 0, 1]
2 1 0 3
After:  [2, 1, 0, 3]

Before: [1, 2, 3, 3]
9 1 0 1
After:  [1, 1, 3, 3]

Before: [0, 1, 1, 1]
10 1 0 0
After:  [1, 1, 1, 1]

Before: [3, 0, 2, 3]
12 1 3 0
After:  [3, 0, 2, 3]

Before: [0, 1, 0, 3]
10 1 0 2
After:  [0, 1, 1, 3]

Before: [1, 0, 1, 0]
13 1 0 2
After:  [1, 0, 1, 0]

Before: [0, 0, 2, 1]
8 0 0 0
After:  [0, 0, 2, 1]

Before: [1, 1, 2, 3]
11 0 3 0
After:  [0, 1, 2, 3]

Before: [1, 1, 0, 2]
5 3 1 2
After:  [1, 1, 3, 2]

Before: [0, 3, 2, 1]
5 3 2 1
After:  [0, 3, 2, 1]

Before: [2, 2, 1, 3]
4 0 3 2
After:  [2, 2, 5, 3]

Before: [0, 1, 3, 1]
10 1 0 3
After:  [0, 1, 3, 1]

Before: [0, 1, 0, 2]
10 1 0 3
After:  [0, 1, 0, 1]

Before: [2, 0, 2, 1]
14 1 3 2
After:  [2, 0, 1, 1]

Before: [2, 1, 0, 3]
11 0 3 0
After:  [0, 1, 0, 3]

Before: [2, 2, 2, 1]
15 2 2 0
After:  [4, 2, 2, 1]

Before: [0, 2, 1, 2]
0 1 2 0
After:  [4, 2, 1, 2]

Before: [1, 0, 2, 1]
14 1 3 2
After:  [1, 0, 1, 1]

Before: [1, 0, 2, 1]
13 1 0 0
After:  [1, 0, 2, 1]

Before: [2, 3, 1, 3]
2 0 2 1
After:  [2, 3, 1, 3]

Before: [0, 3, 0, 2]
2 0 3 2
After:  [0, 3, 2, 2]

Before: [1, 2, 1, 3]
12 2 3 1
After:  [1, 3, 1, 3]

Before: [1, 0, 2, 1]
13 1 0 3
After:  [1, 0, 2, 1]

Before: [1, 0, 2, 2]
7 0 1 1
After:  [1, 1, 2, 2]

Before: [1, 0, 1, 1]
13 1 0 1
After:  [1, 1, 1, 1]

Before: [1, 1, 2, 1]
12 0 2 3
After:  [1, 1, 2, 3]

Before: [1, 1, 0, 3]
4 3 3 1
After:  [1, 6, 0, 3]

Before: [1, 3, 3, 3]
11 0 3 0
After:  [0, 3, 3, 3]

Before: [0, 2, 2, 1]
15 2 2 1
After:  [0, 4, 2, 1]

Before: [2, 1, 2, 3]
11 0 3 0
After:  [0, 1, 2, 3]

Before: [2, 2, 1, 3]
4 3 3 3
After:  [2, 2, 1, 6]

Before: [3, 2, 2, 2]
15 2 2 0
After:  [4, 2, 2, 2]

Before: [1, 1, 3, 3]
4 2 3 0
After:  [6, 1, 3, 3]

Before: [0, 2, 3, 1]
0 1 2 0
After:  [4, 2, 3, 1]

Before: [0, 2, 0, 2]
0 3 2 2
After:  [0, 2, 4, 2]

Before: [1, 0, 0, 2]
13 1 0 3
After:  [1, 0, 0, 1]

Before: [3, 1, 1, 2]
5 3 1 0
After:  [3, 1, 1, 2]

Before: [2, 2, 1, 1]
2 2 0 2
After:  [2, 2, 3, 1]

Before: [1, 3, 0, 3]
11 0 3 3
After:  [1, 3, 0, 0]

Before: [1, 1, 3, 2]
5 3 1 2
After:  [1, 1, 3, 2]

Before: [0, 2, 0, 1]
2 0 3 1
After:  [0, 1, 0, 1]

Before: [0, 0, 3, 0]
2 0 2 1
After:  [0, 3, 3, 0]

Before: [3, 0, 3, 1]
14 1 3 1
After:  [3, 1, 3, 1]

Before: [0, 3, 2, 0]
8 0 0 0
After:  [0, 3, 2, 0]

Before: [0, 3, 2, 3]
8 0 0 2
After:  [0, 3, 0, 3]

Before: [0, 1, 3, 3]
10 1 0 3
After:  [0, 1, 3, 1]

Before: [0, 0, 0, 0]
1 0 1 3
After:  [0, 0, 0, 1]

Before: [0, 1, 3, 1]
10 1 0 1
After:  [0, 1, 3, 1]

Before: [0, 0, 2, 1]
14 1 3 0
After:  [1, 0, 2, 1]

Before: [2, 2, 1, 0]
2 1 2 1
After:  [2, 3, 1, 0]

Before: [1, 0, 0, 3]
11 0 3 1
After:  [1, 0, 0, 3]

Before: [0, 1, 3, 0]
10 1 0 1
After:  [0, 1, 3, 0]

Before: [3, 3, 1, 1]
2 2 1 0
After:  [3, 3, 1, 1]

Before: [0, 2, 1, 0]
2 2 1 0
After:  [3, 2, 1, 0]

Before: [2, 1, 2, 3]
12 1 3 1
After:  [2, 3, 2, 3]

Before: [0, 0, 1, 2]
8 0 0 0
After:  [0, 0, 1, 2]

Before: [2, 3, 2, 0]
6 2 3 1
After:  [2, 6, 2, 0]

Before: [3, 0, 2, 1]
5 3 2 1
After:  [3, 3, 2, 1]

Before: [2, 1, 1, 3]
2 2 0 1
After:  [2, 3, 1, 3]

Before: [2, 2, 0, 0]
2 3 0 2
After:  [2, 2, 2, 0]

Before: [3, 2, 3, 0]
3 1 0 3
After:  [3, 2, 3, 1]

Before: [0, 1, 3, 2]
10 1 0 2
After:  [0, 1, 1, 2]

Before: [1, 2, 3, 0]
2 0 1 2
After:  [1, 2, 3, 0]

Before: [1, 3, 2, 3]
11 0 3 2
After:  [1, 3, 0, 3]

Before: [0, 0, 2, 1]
15 2 2 1
After:  [0, 4, 2, 1]

Before: [3, 2, 0, 0]
3 1 0 1
After:  [3, 1, 0, 0]

Before: [1, 0, 0, 1]
14 1 3 1
After:  [1, 1, 0, 1]

Before: [2, 0, 1, 3]
7 2 1 2
After:  [2, 0, 1, 3]

Before: [1, 0, 0, 0]
13 1 0 2
After:  [1, 0, 1, 0]

Before: [1, 0, 1, 1]
13 1 0 2
After:  [1, 0, 1, 1]

Before: [1, 0, 2, 0]
13 1 0 2
After:  [1, 0, 1, 0]

Before: [3, 1, 1, 2]
12 1 3 3
After:  [3, 1, 1, 3]

Before: [0, 1, 1, 0]
12 0 1 0
After:  [1, 1, 1, 0]

Before: [1, 0, 3, 2]
13 1 0 0
After:  [1, 0, 3, 2]

Before: [2, 2, 1, 3]
11 0 3 1
After:  [2, 0, 1, 3]

Before: [0, 0, 2, 3]
1 0 1 0
After:  [1, 0, 2, 3]

Before: [1, 2, 0, 3]
11 0 3 2
After:  [1, 2, 0, 3]

Before: [1, 0, 3, 1]
7 3 1 0
After:  [1, 0, 3, 1]

Before: [1, 0, 0, 1]
13 1 0 1
After:  [1, 1, 0, 1]

Before: [1, 2, 3, 0]
9 1 0 2
After:  [1, 2, 1, 0]

Before: [1, 1, 3, 3]
11 0 3 2
After:  [1, 1, 0, 3]

Before: [2, 3, 2, 3]
11 0 3 1
After:  [2, 0, 2, 3]

Before: [0, 1, 2, 2]
10 1 0 2
After:  [0, 1, 1, 2]

Before: [2, 0, 1, 2]
2 0 2 2
After:  [2, 0, 3, 2]

Before: [1, 2, 1, 1]
9 1 0 1
After:  [1, 1, 1, 1]

Before: [0, 0, 2, 0]
12 1 2 0
After:  [2, 0, 2, 0]

Before: [3, 1, 1, 1]
6 0 3 3
After:  [3, 1, 1, 9]

Before: [1, 1, 2, 0]
2 2 0 2
After:  [1, 1, 3, 0]

Before: [0, 0, 1, 3]
8 0 0 1
After:  [0, 0, 1, 3]

Before: [2, 1, 2, 2]
15 3 2 0
After:  [4, 1, 2, 2]

Before: [3, 1, 0, 2]
12 1 3 1
After:  [3, 3, 0, 2]

Before: [0, 0, 1, 1]
14 1 2 1
After:  [0, 1, 1, 1]

Before: [1, 2, 3, 3]
2 1 0 2
After:  [1, 2, 3, 3]

Before: [0, 3, 2, 3]
15 2 2 0
After:  [4, 3, 2, 3]

Before: [2, 0, 0, 2]
2 1 3 0
After:  [2, 0, 0, 2]

Before: [2, 2, 1, 0]
6 0 3 2
After:  [2, 2, 6, 0]

Before: [0, 1, 1, 2]
5 3 1 0
After:  [3, 1, 1, 2]

Before: [2, 3, 3, 3]
4 1 3 3
After:  [2, 3, 3, 6]

Before: [0, 1, 1, 0]
10 1 0 3
After:  [0, 1, 1, 1]

Before: [0, 0, 2, 1]
14 1 3 2
After:  [0, 0, 1, 1]

Before: [2, 0, 1, 2]
0 0 2 0
After:  [4, 0, 1, 2]

Before: [3, 2, 1, 0]
3 1 0 0
After:  [1, 2, 1, 0]

Before: [0, 1, 2, 0]
10 1 0 1
After:  [0, 1, 2, 0]

Before: [1, 1, 3, 3]
12 1 2 1
After:  [1, 3, 3, 3]

Before: [2, 0, 2, 0]
15 2 2 3
After:  [2, 0, 2, 4]

Before: [1, 2, 3, 1]
5 3 2 2
After:  [1, 2, 3, 1]

Before: [1, 0, 3, 1]
14 1 3 2
After:  [1, 0, 1, 1]

Before: [1, 2, 3, 2]
0 3 2 0
After:  [4, 2, 3, 2]

Before: [0, 1, 2, 2]
10 1 0 3
After:  [0, 1, 2, 1]

Before: [1, 2, 0, 2]
9 1 0 3
After:  [1, 2, 0, 1]

Before: [3, 2, 2, 2]
3 1 0 1
After:  [3, 1, 2, 2]

Before: [3, 3, 2, 2]
15 3 2 1
After:  [3, 4, 2, 2]

Before: [2, 0, 2, 3]
11 0 3 0
After:  [0, 0, 2, 3]

Before: [0, 0, 2, 3]
1 0 1 3
After:  [0, 0, 2, 1]

Before: [2, 0, 2, 1]
7 3 1 2
After:  [2, 0, 1, 1]

Before: [0, 0, 2, 0]
1 0 1 2
After:  [0, 0, 1, 0]

Before: [2, 2, 0, 3]
11 0 3 1
After:  [2, 0, 0, 3]

Before: [1, 0, 1, 0]
14 1 2 3
After:  [1, 0, 1, 1]

Before: [0, 0, 1, 3]
7 2 1 3
After:  [0, 0, 1, 1]

Before: [3, 2, 1, 3]
4 1 3 1
After:  [3, 5, 1, 3]

Before: [1, 0, 2, 3]
11 0 3 0
After:  [0, 0, 2, 3]

Before: [1, 0, 0, 0]
13 1 0 1
After:  [1, 1, 0, 0]

Before: [1, 2, 0, 3]
0 1 2 0
After:  [4, 2, 0, 3]

Before: [3, 3, 3, 0]
6 2 3 1
After:  [3, 9, 3, 0]

Before: [1, 1, 2, 1]
15 2 2 2
After:  [1, 1, 4, 1]

Before: [2, 1, 0, 0]
6 1 2 3
After:  [2, 1, 0, 2]

Before: [2, 0, 0, 3]
11 0 3 1
After:  [2, 0, 0, 3]

Before: [0, 3, 1, 3]
12 2 3 0
After:  [3, 3, 1, 3]

Before: [2, 0, 1, 1]
7 2 1 1
After:  [2, 1, 1, 1]

Before: [1, 2, 2, 3]
9 1 0 3
After:  [1, 2, 2, 1]

Before: [3, 0, 2, 0]
6 2 3 3
After:  [3, 0, 2, 6]

Before: [3, 0, 0, 2]
2 2 0 0
After:  [3, 0, 0, 2]

Before: [3, 2, 0, 2]
3 1 0 2
After:  [3, 2, 1, 2]

Before: [0, 1, 1, 0]
10 1 0 2
After:  [0, 1, 1, 0]

Before: [0, 0, 0, 2]
1 0 1 0
After:  [1, 0, 0, 2]

Before: [0, 2, 1, 1]
2 2 1 1
After:  [0, 3, 1, 1]

Before: [0, 0, 3, 1]
8 0 0 3
After:  [0, 0, 3, 0]

Before: [0, 1, 2, 0]
10 1 0 3
After:  [0, 1, 2, 1]

Before: [3, 2, 1, 0]
3 1 0 1
After:  [3, 1, 1, 0]

Before: [3, 3, 0, 1]
6 0 3 1
After:  [3, 9, 0, 1]

Before: [0, 1, 3, 1]
2 0 2 0
After:  [3, 1, 3, 1]

Before: [2, 3, 1, 1]
6 1 3 2
After:  [2, 3, 9, 1]

Before: [1, 0, 3, 3]
2 1 2 3
After:  [1, 0, 3, 3]

Before: [1, 1, 2, 3]
11 0 3 3
After:  [1, 1, 2, 0]

Before: [3, 3, 3, 2]
4 2 2 0
After:  [6, 3, 3, 2]

Before: [3, 1, 0, 0]
2 1 0 1
After:  [3, 3, 0, 0]

Before: [2, 0, 2, 2]
15 2 2 1
After:  [2, 4, 2, 2]

Before: [0, 1, 3, 2]
8 0 0 2
After:  [0, 1, 0, 2]

Before: [1, 2, 2, 0]
9 1 0 3
After:  [1, 2, 2, 1]

Before: [1, 3, 2, 1]
6 1 3 0
After:  [9, 3, 2, 1]

Before: [0, 1, 0, 1]
10 1 0 2
After:  [0, 1, 1, 1]

Before: [3, 0, 1, 1]
7 3 1 1
After:  [3, 1, 1, 1]

Before: [0, 3, 1, 0]
8 0 0 3
After:  [0, 3, 1, 0]

Before: [0, 1, 2, 1]
10 1 0 3
After:  [0, 1, 2, 1]

Before: [0, 1, 1, 3]
10 1 0 3
After:  [0, 1, 1, 1]

Before: [3, 0, 1, 3]
7 2 1 1
After:  [3, 1, 1, 3]

Before: [3, 2, 1, 3]
3 1 0 1
After:  [3, 1, 1, 3]

Before: [0, 1, 0, 0]
10 1 0 3
After:  [0, 1, 0, 1]

Before: [1, 3, 2, 1]
5 3 2 2
After:  [1, 3, 3, 1]

Before: [2, 2, 2, 1]
5 3 2 2
After:  [2, 2, 3, 1]

Before: [2, 0, 2, 1]
15 2 2 1
After:  [2, 4, 2, 1]

Before: [3, 2, 2, 2]
6 0 3 1
After:  [3, 9, 2, 2]

Before: [2, 3, 3, 3]
4 2 2 2
After:  [2, 3, 6, 3]

Before: [0, 0, 3, 2]
1 0 1 1
After:  [0, 1, 3, 2]

Before: [3, 3, 3, 2]
0 3 2 0
After:  [4, 3, 3, 2]

Before: [0, 1, 2, 3]
8 0 0 2
After:  [0, 1, 0, 3]

Before: [1, 2, 1, 3]
0 1 2 0
After:  [4, 2, 1, 3]

Before: [0, 0, 1, 0]
8 0 0 1
After:  [0, 0, 1, 0]

Before: [0, 0, 2, 1]
1 0 1 2
After:  [0, 0, 1, 1]

Before: [1, 0, 1, 1]
13 1 0 0
After:  [1, 0, 1, 1]

Before: [0, 3, 2, 0]
8 0 0 2
After:  [0, 3, 0, 0]

Before: [2, 0, 1, 0]
7 2 1 2
After:  [2, 0, 1, 0]

Before: [0, 1, 3, 0]
10 1 0 0
After:  [1, 1, 3, 0]

Before: [2, 0, 1, 3]
14 1 2 1
After:  [2, 1, 1, 3]

Before: [0, 0, 1, 3]
1 0 1 0
After:  [1, 0, 1, 3]

Before: [0, 1, 3, 1]
10 1 0 2
After:  [0, 1, 1, 1]

Before: [0, 0, 1, 3]
14 1 2 1
After:  [0, 1, 1, 3]

Before: [0, 0, 0, 0]
1 0 1 2
After:  [0, 0, 1, 0]

Before: [0, 1, 3, 2]
10 1 0 1
After:  [0, 1, 3, 2]

Before: [3, 3, 3, 1]
5 3 2 3
After:  [3, 3, 3, 3]

Before: [0, 0, 0, 0]
8 0 0 3
After:  [0, 0, 0, 0]

Before: [0, 1, 2, 3]
8 0 0 3
After:  [0, 1, 2, 0]

Before: [1, 3, 1, 2]
0 3 2 3
After:  [1, 3, 1, 4]

Before: [0, 0, 1, 1]
8 0 0 0
After:  [0, 0, 1, 1]

Before: [0, 0, 3, 1]
1 0 1 1
After:  [0, 1, 3, 1]

Before: [2, 3, 1, 1]
4 3 2 3
After:  [2, 3, 1, 2]

Before: [1, 2, 2, 0]
9 1 0 0
After:  [1, 2, 2, 0]

Before: [3, 3, 0, 0]
6 0 3 2
After:  [3, 3, 9, 0]

Before: [1, 0, 1, 2]
14 1 2 1
After:  [1, 1, 1, 2]

Before: [3, 2, 3, 1]
3 1 0 0
After:  [1, 2, 3, 1]

Before: [0, 1, 0, 0]
10 1 0 2
After:  [0, 1, 1, 0]

Before: [1, 2, 3, 2]
9 1 0 1
After:  [1, 1, 3, 2]

Before: [0, 1, 1, 3]
4 1 3 2
After:  [0, 1, 4, 3]

Before: [3, 0, 1, 2]
14 1 2 0
After:  [1, 0, 1, 2]

Before: [3, 2, 1, 1]
3 1 0 2
After:  [3, 2, 1, 1]

Before: [1, 2, 3, 3]
0 1 2 0
After:  [4, 2, 3, 3]

Before: [3, 1, 1, 3]
12 2 3 0
After:  [3, 1, 1, 3]

Before: [3, 0, 1, 0]
7 2 1 1
After:  [3, 1, 1, 0]

Before: [1, 0, 3, 2]
0 3 2 0
After:  [4, 0, 3, 2]

Before: [0, 2, 3, 3]
0 1 2 2
After:  [0, 2, 4, 3]

Before: [0, 1, 3, 1]
4 2 1 2
After:  [0, 1, 4, 1]

Before: [1, 0, 3, 3]
13 1 0 3
After:  [1, 0, 3, 1]

Before: [3, 1, 3, 0]
4 1 1 1
After:  [3, 2, 3, 0]

Before: [1, 2, 0, 3]
9 1 0 2
After:  [1, 2, 1, 3]

Before: [0, 2, 2, 3]
4 3 2 1
After:  [0, 5, 2, 3]

Before: [1, 1, 1, 1]
4 0 2 3
After:  [1, 1, 1, 2]

Before: [1, 1, 2, 3]
11 0 3 1
After:  [1, 0, 2, 3]

Before: [2, 0, 1, 1]
7 3 1 1
After:  [2, 1, 1, 1]

Before: [2, 3, 0, 0]
2 2 1 3
After:  [2, 3, 0, 3]

Before: [1, 0, 1, 1]
7 0 1 0
After:  [1, 0, 1, 1]

Before: [1, 0, 0, 0]
7 0 1 2
After:  [1, 0, 1, 0]

Before: [1, 0, 3, 0]
12 0 2 1
After:  [1, 3, 3, 0]

Before: [1, 2, 3, 2]
9 1 0 2
After:  [1, 2, 1, 2]

Before: [1, 2, 3, 0]
9 1 0 0
After:  [1, 2, 3, 0]

Before: [2, 2, 1, 3]
0 0 2 2
After:  [2, 2, 4, 3]

Before: [2, 1, 1, 3]
6 3 2 0
After:  [6, 1, 1, 3]

Before: [2, 1, 2, 0]
15 2 2 3
After:  [2, 1, 2, 4]

Before: [0, 0, 0, 0]
1 0 1 0
After:  [1, 0, 0, 0]

Before: [1, 0, 2, 1]
12 1 2 3
After:  [1, 0, 2, 2]

Before: [0, 0, 1, 3]
14 1 2 3
After:  [0, 0, 1, 1]

Before: [1, 1, 0, 3]
11 0 3 1
After:  [1, 0, 0, 3]

Before: [0, 2, 2, 0]
8 0 0 1
After:  [0, 0, 2, 0]

Before: [3, 1, 2, 0]
6 2 3 3
After:  [3, 1, 2, 6]

Before: [1, 2, 0, 0]
2 3 1 2
After:  [1, 2, 2, 0]

Before: [2, 1, 0, 3]
4 3 3 2
After:  [2, 1, 6, 3]

Before: [3, 2, 0, 0]
3 1 0 0
After:  [1, 2, 0, 0]

Before: [3, 0, 1, 1]
14 1 3 1
After:  [3, 1, 1, 1]

Before: [3, 1, 1, 1]
6 0 3 2
After:  [3, 1, 9, 1]

Before: [0, 0, 1, 1]
1 0 1 1
After:  [0, 1, 1, 1]

Before: [2, 1, 3, 3]
0 0 2 2
After:  [2, 1, 4, 3]

Before: [0, 2, 2, 1]
8 0 0 2
After:  [0, 2, 0, 1]

Before: [1, 0, 2, 2]
15 3 2 3
After:  [1, 0, 2, 4]

Before: [0, 1, 3, 1]
2 0 3 0
After:  [1, 1, 3, 1]

Before: [2, 0, 3, 1]
5 3 2 2
After:  [2, 0, 3, 1]

Before: [3, 2, 0, 3]
3 1 0 1
After:  [3, 1, 0, 3]

Before: [1, 3, 3, 3]
11 0 3 2
After:  [1, 3, 0, 3]

Before: [0, 1, 1, 2]
10 1 0 0
After:  [1, 1, 1, 2]

Before: [3, 2, 1, 2]
2 1 2 3
After:  [3, 2, 1, 3]

Before: [1, 0, 0, 1]
13 1 0 2
After:  [1, 0, 1, 1]

Before: [1, 0, 2, 3]
13 1 0 3
After:  [1, 0, 2, 1]

Before: [0, 0, 0, 2]
1 0 1 2
After:  [0, 0, 1, 2]

Before: [2, 1, 0, 2]
5 3 1 2
After:  [2, 1, 3, 2]

Before: [1, 0, 0, 3]
13 1 0 2
After:  [1, 0, 1, 3]

Before: [2, 1, 3, 2]
5 3 1 2
After:  [2, 1, 3, 2]

Before: [1, 2, 3, 0]
2 3 1 3
After:  [1, 2, 3, 2]

Before: [1, 2, 2, 1]
9 1 0 0
After:  [1, 2, 2, 1]

Before: [0, 0, 3, 3]
1 0 1 1
After:  [0, 1, 3, 3]

Before: [3, 2, 2, 3]
4 1 3 0
After:  [5, 2, 2, 3]

Before: [3, 2, 1, 2]
3 1 0 0
After:  [1, 2, 1, 2]

Before: [2, 1, 3, 1]
6 3 2 3
After:  [2, 1, 3, 2]

Before: [3, 1, 2, 3]
15 2 2 2
After:  [3, 1, 4, 3]

Before: [2, 0, 3, 3]
11 0 3 1
After:  [2, 0, 3, 3]

Before: [0, 0, 2, 2]
1 0 1 0
After:  [1, 0, 2, 2]

Before: [3, 2, 2, 1]
15 2 2 3
After:  [3, 2, 2, 4]

Before: [3, 3, 1, 2]
6 0 3 3
After:  [3, 3, 1, 9]

Before: [2, 1, 0, 2]
12 0 1 3
After:  [2, 1, 0, 3]

Before: [2, 1, 1, 2]
12 0 1 3
After:  [2, 1, 1, 3]

Before: [0, 2, 1, 3]
12 2 3 1
After:  [0, 3, 1, 3]

Before: [3, 1, 1, 3]
4 1 3 3
After:  [3, 1, 1, 4]

Before: [0, 0, 3, 0]
1 0 1 0
After:  [1, 0, 3, 0]

Before: [1, 0, 0, 3]
13 1 0 1
After:  [1, 1, 0, 3]

Before: [3, 0, 1, 0]
14 1 2 0
After:  [1, 0, 1, 0]

Before: [3, 2, 0, 1]
3 1 0 1
After:  [3, 1, 0, 1]

Before: [3, 1, 3, 2]
12 1 2 1
After:  [3, 3, 3, 2]

Before: [2, 0, 0, 1]
7 3 1 3
After:  [2, 0, 0, 1]

Before: [3, 3, 3, 1]
5 3 2 1
After:  [3, 3, 3, 1]

Before: [0, 0, 3, 0]
8 0 0 2
After:  [0, 0, 0, 0]

Before: [1, 3, 1, 1]
6 1 2 2
After:  [1, 3, 6, 1]

Before: [1, 2, 2, 0]
9 1 0 2
After:  [1, 2, 1, 0]

Before: [0, 2, 3, 1]
6 1 3 2
After:  [0, 2, 6, 1]

Before: [0, 0, 1, 2]
14 1 2 0
After:  [1, 0, 1, 2]

Before: [2, 1, 3, 1]
0 0 2 0
After:  [4, 1, 3, 1]

Before: [1, 2, 0, 3]
9 1 0 0
After:  [1, 2, 0, 3]

Before: [1, 3, 0, 3]
11 0 3 2
After:  [1, 3, 0, 3]

Before: [2, 2, 0, 3]
11 0 3 2
After:  [2, 2, 0, 3]

Before: [3, 2, 3, 1]
3 1 0 2
After:  [3, 2, 1, 1]

Before: [1, 0, 1, 3]
13 1 0 3
After:  [1, 0, 1, 1]

Before: [1, 0, 1, 0]
13 1 0 1
After:  [1, 1, 1, 0]

Before: [1, 3, 1, 3]
11 0 3 3
After:  [1, 3, 1, 0]

Before: [0, 1, 1, 2]
8 0 0 1
After:  [0, 0, 1, 2]

Before: [2, 2, 0, 2]
0 3 2 3
After:  [2, 2, 0, 4]

Before: [0, 1, 1, 2]
8 0 0 2
After:  [0, 1, 0, 2]

Before: [1, 2, 3, 3]
2 1 0 1
After:  [1, 3, 3, 3]

Before: [1, 0, 1, 1]
7 0 1 3
After:  [1, 0, 1, 1]

Before: [2, 1, 3, 1]
5 3 2 1
After:  [2, 3, 3, 1]

Before: [0, 2, 3, 3]
8 0 0 2
After:  [0, 2, 0, 3]

Before: [3, 0, 0, 3]
2 2 0 3
After:  [3, 0, 0, 3]

Before: [1, 0, 3, 3]
12 0 2 1
After:  [1, 3, 3, 3]

Before: [3, 2, 0, 2]
3 1 0 1
After:  [3, 1, 0, 2]

Before: [3, 1, 2, 1]
4 0 2 0
After:  [5, 1, 2, 1]

Before: [0, 1, 0, 3]
10 1 0 0
After:  [1, 1, 0, 3]

Before: [1, 2, 0, 1]
2 0 1 2
After:  [1, 2, 3, 1]

Before: [1, 3, 0, 3]
11 0 3 0
After:  [0, 3, 0, 3]

Before: [1, 0, 0, 2]
0 3 2 2
After:  [1, 0, 4, 2]

Before: [0, 1, 0, 1]
10 1 0 3
After:  [0, 1, 0, 1]

Before: [1, 0, 1, 3]
13 1 0 1
After:  [1, 1, 1, 3]

Before: [1, 2, 0, 1]
9 1 0 1
After:  [1, 1, 0, 1]

Before: [2, 2, 3, 2]
0 1 2 2
After:  [2, 2, 4, 2]

Before: [0, 0, 1, 3]
14 1 2 2
After:  [0, 0, 1, 3]

Before: [0, 1, 0, 2]
8 0 0 2
After:  [0, 1, 0, 2]

Before: [2, 2, 3, 1]
5 3 2 0
After:  [3, 2, 3, 1]

Before: [1, 0, 0, 3]
13 1 0 3
After:  [1, 0, 0, 1]

Before: [1, 1, 0, 3]
11 0 3 2
After:  [1, 1, 0, 3]

Before: [0, 0, 3, 2]
2 0 2 2
After:  [0, 0, 3, 2]

Before: [1, 2, 2, 2]
9 1 0 0
After:  [1, 2, 2, 2]

Before: [3, 2, 3, 1]
3 1 0 3
After:  [3, 2, 3, 1]

Before: [1, 2, 3, 1]
9 1 0 2
After:  [1, 2, 1, 1]

Before: [0, 1, 0, 1]
8 0 0 3
After:  [0, 1, 0, 0]

Before: [2, 2, 2, 3]
15 2 2 0
After:  [4, 2, 2, 3]

Before: [0, 1, 2, 2]
10 1 0 0
After:  [1, 1, 2, 2]

Before: [1, 1, 2, 1]
5 3 2 3
After:  [1, 1, 2, 3]

Before: [2, 0, 0, 1]
14 1 3 1
After:  [2, 1, 0, 1]

Before: [3, 0, 2, 0]
12 3 2 0
After:  [2, 0, 2, 0]

Before: [0, 0, 3, 3]
12 1 3 3
After:  [0, 0, 3, 3]

Before: [3, 0, 1, 1]
14 1 3 0
After:  [1, 0, 1, 1]

Before: [1, 1, 3, 1]
4 2 1 2
After:  [1, 1, 4, 1]

Before: [0, 2, 0, 0]
0 1 2 0
After:  [4, 2, 0, 0]

Before: [0, 2, 2, 1]
5 3 2 0
After:  [3, 2, 2, 1]

Before: [3, 2, 0, 0]
3 1 0 3
After:  [3, 2, 0, 1]

Before: [3, 2, 0, 2]
3 1 0 0
After:  [1, 2, 0, 2]

Before: [0, 2, 3, 3]
0 1 2 1
After:  [0, 4, 3, 3]

Before: [2, 3, 1, 3]
2 0 2 0
After:  [3, 3, 1, 3]

Before: [1, 2, 0, 2]
9 1 0 0
After:  [1, 2, 0, 2]

Before: [0, 1, 0, 0]
10 1 0 0
After:  [1, 1, 0, 0]

Before: [2, 0, 3, 1]
7 3 1 1
After:  [2, 1, 3, 1]

Before: [3, 2, 3, 2]
3 1 0 1
After:  [3, 1, 3, 2]

Before: [1, 2, 3, 3]
4 3 2 1
After:  [1, 6, 3, 3]

Before: [0, 3, 2, 0]
15 2 2 2
After:  [0, 3, 4, 0]

Before: [0, 3, 3, 2]
0 3 2 3
After:  [0, 3, 3, 4]

Before: [0, 1, 2, 0]
10 1 0 2
After:  [0, 1, 1, 0]

Before: [3, 2, 0, 0]
6 1 3 1
After:  [3, 6, 0, 0]

Before: [0, 1, 1, 3]
10 1 0 0
After:  [1, 1, 1, 3]

Before: [3, 0, 3, 3]
4 3 2 1
After:  [3, 6, 3, 3]

Before: [1, 0, 0, 3]
11 0 3 3
After:  [1, 0, 0, 0]

Before: [1, 0, 3, 2]
13 1 0 1
After:  [1, 1, 3, 2]

Before: [1, 0, 3, 2]
6 2 3 1
After:  [1, 9, 3, 2]

Before: [1, 0, 3, 0]
6 0 2 2
After:  [1, 0, 2, 0]

Before: [1, 2, 1, 0]
9 1 0 3
After:  [1, 2, 1, 1]

Before: [0, 0, 3, 2]
1 0 1 3
After:  [0, 0, 3, 1]

Before: [1, 0, 1, 3]
13 1 0 2
After:  [1, 0, 1, 3]

Before: [0, 2, 2, 2]
15 1 2 3
After:  [0, 2, 2, 4]

Before: [0, 1, 3, 2]
10 1 0 0
After:  [1, 1, 3, 2]

Before: [1, 0, 3, 0]
13 1 0 3
After:  [1, 0, 3, 1]

Before: [0, 1, 1, 2]
10 1 0 3
After:  [0, 1, 1, 1]

Before: [1, 2, 1, 3]
9 1 0 2
After:  [1, 2, 1, 3]

Before: [1, 3, 2, 2]
6 3 3 3
After:  [1, 3, 2, 6]

Before: [2, 1, 2, 3]
15 2 2 1
After:  [2, 4, 2, 3]

Before: [3, 2, 3, 1]
6 2 3 3
After:  [3, 2, 3, 9]

Before: [3, 0, 1, 1]
14 1 2 3
After:  [3, 0, 1, 1]

Before: [1, 1, 3, 2]
12 0 3 2
After:  [1, 1, 3, 2]

Before: [1, 2, 2, 0]
15 2 2 2
After:  [1, 2, 4, 0]

Before: [0, 1, 3, 0]
8 0 0 0
After:  [0, 1, 3, 0]

Before: [0, 0, 0, 3]
1 0 1 1
After:  [0, 1, 0, 3]

Before: [0, 0, 0, 3]
1 0 1 2
After:  [0, 0, 1, 3]

Before: [3, 2, 0, 3]
3 1 0 3
After:  [3, 2, 0, 1]

Before: [2, 1, 2, 0]
12 2 1 3
After:  [2, 1, 2, 3]

Before: [0, 2, 1, 0]
2 3 1 2
After:  [0, 2, 2, 0]

Before: [0, 0, 1, 0]
1 0 1 1
After:  [0, 1, 1, 0]

Before: [3, 2, 3, 1]
5 3 2 2
After:  [3, 2, 3, 1]

Before: [2, 2, 0, 3]
11 0 3 3
After:  [2, 2, 0, 0]

Before: [3, 2, 0, 0]
3 1 0 2
After:  [3, 2, 1, 0]

Before: [1, 0, 2, 0]
13 1 0 1
After:  [1, 1, 2, 0]

Before: [0, 3, 0, 0]
2 0 1 3
After:  [0, 3, 0, 3]

Before: [0, 1, 1, 2]
10 1 0 1
After:  [0, 1, 1, 2]

Before: [0, 0, 0, 2]
1 0 1 1
After:  [0, 1, 0, 2]

Before: [0, 1, 1, 2]
12 0 1 2
After:  [0, 1, 1, 2]

Before: [0, 0, 3, 0]
1 0 1 2
After:  [0, 0, 1, 0]

Before: [0, 1, 2, 1]
10 1 0 1
After:  [0, 1, 2, 1]

Before: [0, 1, 3, 1]
4 2 2 1
After:  [0, 6, 3, 1]

Before: [0, 1, 2, 3]
12 1 2 2
After:  [0, 1, 3, 3]

Before: [1, 0, 1, 1]
14 1 3 2
After:  [1, 0, 1, 1]

Before: [1, 0, 1, 3]
13 1 0 0
After:  [1, 0, 1, 3]

Before: [1, 1, 3, 1]
5 3 2 1
After:  [1, 3, 3, 1]

Before: [1, 2, 2, 3]
9 1 0 0
After:  [1, 2, 2, 3]

Before: [0, 0, 2, 1]
14 1 3 3
After:  [0, 0, 2, 1]

Before: [0, 3, 2, 0]
8 0 0 1
After:  [0, 0, 2, 0]

Before: [1, 0, 3, 1]
12 0 2 2
After:  [1, 0, 3, 1]

Before: [3, 0, 1, 2]
0 3 2 3
After:  [3, 0, 1, 4]

Before: [0, 2, 2, 2]
15 1 2 2
After:  [0, 2, 4, 2]

Before: [0, 1, 1, 1]
10 1 0 1
After:  [0, 1, 1, 1]

Before: [1, 0, 0, 2]
13 1 0 2
After:  [1, 0, 1, 2]

Before: [0, 0, 1, 1]
14 1 3 0
After:  [1, 0, 1, 1]

Before: [3, 2, 0, 1]
3 1 0 0
After:  [1, 2, 0, 1]

Before: [0, 0, 2, 0]
1 0 1 1
After:  [0, 1, 2, 0]

Before: [0, 2, 0, 2]
2 0 3 0
After:  [2, 2, 0, 2]

Before: [0, 0, 1, 2]
14 1 2 2
After:  [0, 0, 1, 2]

Before: [1, 1, 0, 1]
4 1 1 1
After:  [1, 2, 0, 1]

Before: [0, 1, 2, 1]
5 3 2 2
After:  [0, 1, 3, 1]

Before: [0, 3, 1, 3]
8 0 0 3
After:  [0, 3, 1, 0]

Before: [0, 0, 2, 1]
7 3 1 3
After:  [0, 0, 2, 1]

Before: [0, 1, 1, 2]
0 3 2 0
After:  [4, 1, 1, 2]

Before: [1, 2, 2, 2]
9 1 0 1
After:  [1, 1, 2, 2]

Before: [2, 3, 1, 2]
0 3 2 1
After:  [2, 4, 1, 2]

Before: [2, 0, 2, 2]
15 3 2 0
After:  [4, 0, 2, 2]

Before: [1, 2, 1, 3]
9 1 0 3
After:  [1, 2, 1, 1]

Before: [3, 2, 2, 3]
15 1 2 1
After:  [3, 4, 2, 3]

Before: [1, 0, 2, 2]
13 1 0 3
After:  [1, 0, 2, 1]

Before: [3, 0, 1, 0]
7 2 1 2
After:  [3, 0, 1, 0]

Before: [0, 2, 2, 3]
8 0 0 0
After:  [0, 2, 2, 3]

Before: [2, 0, 1, 3]
14 1 2 3
After:  [2, 0, 1, 1]

Before: [0, 1, 1, 1]
4 1 1 2
After:  [0, 1, 2, 1]

Before: [1, 0, 1, 3]
11 0 3 3
After:  [1, 0, 1, 0]

Before: [1, 3, 2, 1]
5 3 2 0
After:  [3, 3, 2, 1]

Before: [1, 0, 2, 1]
15 2 2 2
After:  [1, 0, 4, 1]

Before: [3, 2, 2, 3]
3 1 0 1
After:  [3, 1, 2, 3]

Before: [0, 1, 2, 3]
10 1 0 0
After:  [1, 1, 2, 3]

Before: [2, 0, 0, 1]
14 1 3 2
After:  [2, 0, 1, 1]

Before: [0, 1, 2, 3]
4 1 3 0
After:  [4, 1, 2, 3]

Before: [3, 2, 0, 2]
0 1 2 1
After:  [3, 4, 0, 2]

Before: [1, 0, 2, 3]
12 0 2 2
After:  [1, 0, 3, 3]

Before: [3, 2, 1, 0]
3 1 0 3
After:  [3, 2, 1, 1]

Before: [1, 1, 3, 1]
6 0 2 2
After:  [1, 1, 2, 1]

Before: [2, 0, 3, 0]
0 0 2 0
After:  [4, 0, 3, 0]

Before: [0, 0, 3, 3]
8 0 0 0
After:  [0, 0, 3, 3]

Before: [0, 0, 0, 1]
14 1 3 3
After:  [0, 0, 0, 1]

Before: [1, 0, 2, 2]
13 1 0 0
After:  [1, 0, 2, 2]

Before: [0, 0, 2, 2]
15 2 2 1
After:  [0, 4, 2, 2]

Before: [2, 2, 3, 2]
0 3 2 2
After:  [2, 2, 4, 2]

Before: [1, 2, 0, 0]
9 1 0 3
After:  [1, 2, 0, 1]

Before: [3, 2, 1, 3]
3 1 0 3
After:  [3, 2, 1, 1]

Before: [0, 0, 3, 1]
1 0 1 2
After:  [0, 0, 1, 1]

Before: [1, 0, 1, 1]
4 3 2 1
After:  [1, 2, 1, 1]

Before: [0, 1, 2, 3]
10 1 0 2
After:  [0, 1, 1, 3]

Before: [1, 1, 3, 2]
12 1 3 1
After:  [1, 3, 3, 2]

Before: [0, 0, 0, 3]
8 0 0 0
After:  [0, 0, 0, 3]

Before: [0, 2, 0, 0]
8 0 0 2
After:  [0, 2, 0, 0]

Before: [1, 0, 1, 0]
13 1 0 3
After:  [1, 0, 1, 1]

Before: [1, 0, 2, 2]
7 0 1 2
After:  [1, 0, 1, 2]

Before: [3, 0, 2, 3]
15 2 2 2
After:  [3, 0, 4, 3]

Before: [3, 2, 3, 3]
3 1 0 3
After:  [3, 2, 3, 1]

Before: [3, 2, 1, 2]
3 1 0 1
After:  [3, 1, 1, 2]

Before: [0, 0, 3, 2]
1 0 1 0
After:  [1, 0, 3, 2]

Before: [1, 2, 0, 1]
9 1 0 3
After:  [1, 2, 0, 1]

Before: [2, 0, 2, 3]
11 0 3 1
After:  [2, 0, 2, 3]

Before: [1, 1, 1, 2]
5 3 1 1
After:  [1, 3, 1, 2]

Before: [3, 2, 2, 1]
3 1 0 2
After:  [3, 2, 1, 1]

Before: [0, 2, 2, 2]
15 3 2 2
After:  [0, 2, 4, 2]

Before: [0, 2, 2, 3]
8 0 0 1
After:  [0, 0, 2, 3]

Before: [3, 2, 2, 3]
3 1 0 0
After:  [1, 2, 2, 3]

Before: [2, 2, 1, 3]
4 3 3 2
After:  [2, 2, 6, 3]

Before: [2, 3, 1, 2]
12 2 3 1
After:  [2, 3, 1, 2]

Before: [3, 0, 1, 1]
14 1 2 2
After:  [3, 0, 1, 1]

Before: [1, 1, 3, 0]
4 2 1 1
After:  [1, 4, 3, 0]

Before: [0, 0, 0, 1]
14 1 3 0
After:  [1, 0, 0, 1]

Before: [1, 1, 3, 0]
4 1 1 0
After:  [2, 1, 3, 0]

Before: [0, 1, 0, 0]
10 1 0 1
After:  [0, 1, 0, 0]

Before: [3, 2, 3, 2]
3 1 0 3
After:  [3, 2, 3, 1]

Before: [2, 0, 3, 2]
2 1 0 3
After:  [2, 0, 3, 2]

Before: [1, 2, 3, 3]
11 0 3 2
After:  [1, 2, 0, 3]

Before: [1, 2, 0, 3]
9 1 0 1
After:  [1, 1, 0, 3]

Before: [3, 2, 0, 3]
4 3 3 1
After:  [3, 6, 0, 3]

Before: [2, 3, 1, 0]
2 3 0 3
After:  [2, 3, 1, 2]

Before: [0, 1, 2, 3]
8 0 0 1
After:  [0, 0, 2, 3]

Before: [2, 3, 3, 3]
4 3 2 1
After:  [2, 6, 3, 3]

Before: [0, 0, 2, 0]
8 0 0 1
After:  [0, 0, 2, 0]

Before: [1, 0, 0, 2]
13 1 0 1
After:  [1, 1, 0, 2]

Before: [1, 0, 2, 3]
11 0 3 3
After:  [1, 0, 2, 0]

Before: [1, 2, 1, 3]
9 1 0 0
After:  [1, 2, 1, 3]

Before: [2, 0, 0, 3]
11 0 3 2
After:  [2, 0, 0, 3]

Before: [1, 0, 0, 0]
13 1 0 0
After:  [1, 0, 0, 0]

Before: [0, 2, 1, 3]
0 1 2 1
After:  [0, 4, 1, 3]

Before: [0, 3, 1, 2]
6 3 3 2
After:  [0, 3, 6, 2]

Before: [1, 2, 0, 0]
9 1 0 0
After:  [1, 2, 0, 0]

Before: [1, 0, 3, 0]
13 1 0 1
After:  [1, 1, 3, 0]

Before: [0, 0, 1, 3]
1 0 1 3
After:  [0, 0, 1, 1]

Before: [0, 2, 1, 1]
8 0 0 0
After:  [0, 2, 1, 1]

Before: [3, 0, 1, 1]
14 1 3 2
After:  [3, 0, 1, 1]

Before: [3, 2, 0, 3]
3 1 0 0
After:  [1, 2, 0, 3]

Before: [1, 2, 1, 0]
9 1 0 1
After:  [1, 1, 1, 0]

Before: [1, 2, 3, 0]
0 1 2 2
After:  [1, 2, 4, 0]

Before: [1, 2, 2, 2]
9 1 0 2
After:  [1, 2, 1, 2]

Before: [0, 1, 3, 1]
10 1 0 0
After:  [1, 1, 3, 1]

Before: [0, 2, 2, 0]
2 0 1 0
After:  [2, 2, 2, 0]

Before: [0, 0, 2, 2]
1 0 1 2
After:  [0, 0, 1, 2]

Before: [1, 2, 3, 0]
9 1 0 3
After:  [1, 2, 3, 1]

Before: [0, 0, 2, 0]
1 0 1 3
After:  [0, 0, 2, 1]

Before: [0, 3, 2, 0]
8 0 0 3
After:  [0, 3, 2, 0]

Before: [0, 0, 1, 2]
1 0 1 3
After:  [0, 0, 1, 1]

Before: [3, 2, 3, 0]
3 1 0 1
After:  [3, 1, 3, 0]

Before: [1, 0, 3, 1]
5 3 2 2
After:  [1, 0, 3, 1]

Before: [1, 0, 1, 0]
14 1 2 2
After:  [1, 0, 1, 0]

Before: [2, 3, 3, 3]
11 0 3 2
After:  [2, 3, 0, 3]

Before: [1, 2, 1, 0]
2 3 1 2
After:  [1, 2, 2, 0]

Before: [0, 2, 3, 2]
0 3 2 2
After:  [0, 2, 4, 2]

Before: [0, 3, 3, 0]
6 2 3 0
After:  [9, 3, 3, 0]

Before: [1, 0, 1, 1]
14 1 3 3
After:  [1, 0, 1, 1]

Before: [0, 1, 0, 3]
10 1 0 1
After:  [0, 1, 0, 3]

Before: [3, 0, 1, 2]
14 1 2 2
After:  [3, 0, 1, 2]

Before: [1, 3, 2, 3]
4 3 3 0
After:  [6, 3, 2, 3]

Before: [2, 3, 2, 2]
15 3 2 3
After:  [2, 3, 2, 4]

Before: [2, 0, 1, 1]
14 1 2 1
After:  [2, 1, 1, 1]

Before: [3, 2, 1, 1]
3 1 0 1
After:  [3, 1, 1, 1]

Before: [1, 2, 3, 3]
4 3 2 0
After:  [6, 2, 3, 3]

Before: [1, 0, 1, 1]
7 3 1 0
After:  [1, 0, 1, 1]

Before: [1, 3, 3, 1]
5 3 2 3
After:  [1, 3, 3, 3]

Before: [2, 0, 3, 1]
14 1 3 1
After:  [2, 1, 3, 1]

Before: [1, 0, 3, 3]
11 0 3 3
After:  [1, 0, 3, 0]

Before: [2, 0, 2, 1]
14 1 3 3
After:  [2, 0, 2, 1]

Before: [0, 0, 0, 0]
8 0 0 0
After:  [0, 0, 0, 0]

Before: [3, 1, 2, 1]
5 3 2 2
After:  [3, 1, 3, 1]

Before: [0, 2, 3, 0]
8 0 0 1
After:  [0, 0, 3, 0]

Before: [2, 1, 1, 3]
4 3 3 3
After:  [2, 1, 1, 6]

Before: [2, 1, 0, 2]
0 3 2 0
After:  [4, 1, 0, 2]

Before: [0, 0, 2, 3]
1 0 1 1
After:  [0, 1, 2, 3]

Before: [2, 1, 2, 3]
15 2 2 0
After:  [4, 1, 2, 3]

Before: [1, 2, 1, 0]
9 1 0 2
After:  [1, 2, 1, 0]

Before: [1, 2, 1, 2]
9 1 0 0
After:  [1, 2, 1, 2]

Before: [1, 0, 3, 3]
13 1 0 1
After:  [1, 1, 3, 3]

Before: [0, 1, 1, 2]
8 0 0 3
After:  [0, 1, 1, 0]

Before: [1, 0, 3, 3]
13 1 0 2
After:  [1, 0, 1, 3]

Before: [0, 1, 2, 1]
5 3 2 0
After:  [3, 1, 2, 1]

Before: [1, 3, 2, 1]
6 2 3 2
After:  [1, 3, 6, 1]

Before: [3, 2, 2, 1]
3 1 0 3
After:  [3, 2, 2, 1]

Before: [2, 0, 1, 1]
14 1 2 3
After:  [2, 0, 1, 1]

Before: [2, 1, 0, 2]
2 1 0 2
After:  [2, 1, 3, 2]

Before: [0, 2, 1, 0]
2 1 2 0
After:  [3, 2, 1, 0]

Before: [3, 2, 2, 0]
4 0 2 0
After:  [5, 2, 2, 0]

Before: [1, 0, 1, 3]
7 0 1 3
After:  [1, 0, 1, 1]

Before: [0, 2, 1, 2]
2 0 2 0
After:  [1, 2, 1, 2]

Before: [3, 0, 2, 3]
12 1 2 0
After:  [2, 0, 2, 3]

Before: [2, 2, 1, 0]
2 0 2 2
After:  [2, 2, 3, 0]

Before: [3, 1, 2, 2]
15 3 2 0
After:  [4, 1, 2, 2]

Before: [0, 3, 2, 2]
15 3 2 2
After:  [0, 3, 4, 2]

Before: [1, 0, 3, 2]
13 1 0 2
After:  [1, 0, 1, 2]

Before: [1, 1, 0, 2]
0 3 2 1
After:  [1, 4, 0, 2]

Before: [0, 1, 0, 2]
10 1 0 0
After:  [1, 1, 0, 2]

Before: [3, 1, 2, 1]
5 3 2 3
After:  [3, 1, 2, 3]

Before: [3, 1, 3, 3]
4 2 2 0
After:  [6, 1, 3, 3]

Before: [3, 3, 1, 0]
6 1 3 2
After:  [3, 3, 9, 0]

Before: [2, 1, 1, 3]
4 3 1 3
After:  [2, 1, 1, 4]

Before: [0, 0, 2, 3]
8 0 0 1
After:  [0, 0, 2, 3]

Before: [1, 3, 2, 3]
11 0 3 1
After:  [1, 0, 2, 3]

Before: [2, 2, 1, 0]
0 0 2 3
After:  [2, 2, 1, 4]

Before: [1, 0, 2, 1]
14 1 3 3
After:  [1, 0, 2, 1]

Before: [0, 1, 2, 2]
5 3 1 3
After:  [0, 1, 2, 3]

Before: [1, 0, 2, 3]
7 0 1 1
After:  [1, 1, 2, 3]

Before: [2, 2, 1, 3]
11 0 3 3
After:  [2, 2, 1, 0]

Before: [0, 1, 2, 3]
10 1 0 3
After:  [0, 1, 2, 1]

Before: [1, 0, 0, 3]
7 0 1 0
After:  [1, 0, 0, 3]

Before: [0, 1, 0, 3]
8 0 0 0
After:  [0, 1, 0, 3]

Before: [2, 1, 0, 0]
2 1 0 2
After:  [2, 1, 3, 0]

Before: [0, 0, 3, 1]
1 0 1 3
After:  [0, 0, 3, 1]

Before: [1, 0, 0, 1]
14 1 3 3
After:  [1, 0, 0, 1]

Before: [2, 0, 1, 2]
2 1 3 2
After:  [2, 0, 2, 2]

Before: [1, 0, 2, 2]
2 1 3 0
After:  [2, 0, 2, 2]

Before: [3, 2, 0, 1]
3 1 0 2
After:  [3, 2, 1, 1]

Before: [1, 0, 2, 3]
11 0 3 2
After:  [1, 0, 0, 3]

Before: [2, 2, 1, 2]
12 2 3 0
After:  [3, 2, 1, 2]

Before: [2, 0, 1, 3]
11 0 3 2
After:  [2, 0, 0, 3]

Before: [2, 0, 3, 1]
14 1 3 3
After:  [2, 0, 3, 1]

Before: [1, 2, 3, 0]
9 1 0 1
After:  [1, 1, 3, 0]

Before: [0, 0, 2, 2]
15 2 2 0
After:  [4, 0, 2, 2]

Before: [0, 1, 0, 2]
10 1 0 1
After:  [0, 1, 0, 2]

Before: [0, 1, 0, 3]
12 0 1 2
After:  [0, 1, 1, 3]

Before: [2, 1, 0, 3]
11 0 3 2
After:  [2, 1, 0, 3]

Before: [2, 3, 0, 3]
6 3 2 1
After:  [2, 6, 0, 3]

Before: [0, 0, 2, 3]
15 2 2 2
After:  [0, 0, 4, 3]

Before: [3, 2, 1, 1]
3 1 0 0
After:  [1, 2, 1, 1]

Before: [0, 2, 2, 0]
15 2 2 2
After:  [0, 2, 4, 0]

Before: [0, 3, 0, 1]
2 2 1 1
After:  [0, 3, 0, 1]

Before: [0, 3, 0, 1]
8 0 0 0
After:  [0, 3, 0, 1]

Before: [2, 1, 1, 3]
11 0 3 0
After:  [0, 1, 1, 3]

Before: [1, 0, 3, 1]
14 1 3 3
After:  [1, 0, 3, 1]

Before: [1, 1, 2, 3]
4 0 3 3
After:  [1, 1, 2, 4]

Before: [2, 0, 2, 1]
15 0 2 0
After:  [4, 0, 2, 1]

Before: [1, 0, 3, 2]
12 0 2 3
After:  [1, 0, 3, 3]

Before: [3, 2, 2, 2]
6 0 3 3
After:  [3, 2, 2, 9]

Before: [1, 0, 1, 2]
13 1 0 0
After:  [1, 0, 1, 2]

Before: [2, 3, 1, 3]
4 3 3 2
After:  [2, 3, 6, 3]

Before: [3, 0, 3, 1]
7 3 1 1
After:  [3, 1, 3, 1]

Before: [1, 0, 3, 1]
13 1 0 1
After:  [1, 1, 3, 1]

Before: [0, 0, 1, 2]
1 0 1 1
After:  [0, 1, 1, 2]

Before: [1, 0, 0, 3]
13 1 0 0
After:  [1, 0, 0, 3]

Before: [0, 1, 3, 2]
10 1 0 3
After:  [0, 1, 3, 1]

Before: [3, 0, 0, 3]
6 3 2 2
After:  [3, 0, 6, 3]

Before: [2, 2, 0, 2]
6 0 3 3
After:  [2, 2, 0, 6]

Before: [1, 2, 1, 3]
2 1 2 2
After:  [1, 2, 3, 3]

Before: [3, 0, 1, 3]
14 1 2 3
After:  [3, 0, 1, 1]

Before: [2, 1, 0, 2]
5 3 1 0
After:  [3, 1, 0, 2]

Before: [1, 0, 2, 3]
11 0 3 1
After:  [1, 0, 2, 3]

Before: [0, 3, 1, 1]
6 1 3 2
After:  [0, 3, 9, 1]

Before: [1, 1, 0, 3]
11 0 3 3
After:  [1, 1, 0, 0]

Before: [3, 2, 0, 2]
3 1 0 3
After:  [3, 2, 0, 1]

Before: [1, 0, 1, 2]
7 2 1 3
After:  [1, 0, 1, 1]

Before: [2, 0, 1, 0]
14 1 2 2
After:  [2, 0, 1, 0]

Before: [1, 0, 3, 3]
13 1 0 0
After:  [1, 0, 3, 3]

Before: [1, 2, 0, 3]
11 0 3 1
After:  [1, 0, 0, 3]

Before: [0, 1, 1, 1]
10 1 0 2
After:  [0, 1, 1, 1]

Before: [1, 0, 1, 0]
13 1 0 0
After:  [1, 0, 1, 0]

Before: [1, 1, 0, 1]
4 0 1 1
After:  [1, 2, 0, 1]

Before: [0, 0, 3, 2]
0 3 2 0
After:  [4, 0, 3, 2]

Before: [0, 3, 2, 3]
15 2 2 2
After:  [0, 3, 4, 3]

Before: [0, 1, 0, 0]
8 0 0 0
After:  [0, 1, 0, 0]

Before: [2, 0, 2, 3]
12 1 3 3
After:  [2, 0, 2, 3]

Before: [2, 0, 3, 2]
0 3 2 2
After:  [2, 0, 4, 2]

Before: [0, 0, 1, 2]
7 2 1 2
After:  [0, 0, 1, 2]

Before: [3, 1, 0, 2]
5 3 1 2
After:  [3, 1, 3, 2]

Before: [0, 0, 3, 2]
1 0 1 2
After:  [0, 0, 1, 2]

Before: [1, 1, 1, 2]
5 3 1 0
After:  [3, 1, 1, 2]

Before: [3, 2, 1, 0]
6 0 3 0
After:  [9, 2, 1, 0]

Before: [0, 0, 0, 1]
8 0 0 3
After:  [0, 0, 0, 0]

Before: [2, 0, 1, 2]
14 1 2 1
After:  [2, 1, 1, 2]

Before: [1, 0, 2, 0]
13 1 0 3
After:  [1, 0, 2, 1]

Before: [0, 0, 3, 3]
1 0 1 2
After:  [0, 0, 1, 3]

Before: [0, 2, 2, 1]
5 3 2 2
After:  [0, 2, 3, 1]

Before: [3, 1, 0, 1]
4 3 1 3
After:  [3, 1, 0, 2]

Before: [2, 2, 2, 1]
15 0 2 3
After:  [2, 2, 2, 4]

Before: [0, 1, 1, 0]
4 1 1 3
After:  [0, 1, 1, 2]

Before: [2, 2, 3, 3]
0 1 2 0
After:  [4, 2, 3, 3]

Before: [1, 0, 1, 2]
14 1 2 3
After:  [1, 0, 1, 1]

Before: [3, 3, 1, 1]
6 1 3 1
After:  [3, 9, 1, 1]

Before: [1, 2, 2, 1]
15 1 2 1
After:  [1, 4, 2, 1]

Before: [1, 1, 2, 3]
4 3 2 1
After:  [1, 5, 2, 3]

Before: [1, 0, 2, 3]
13 1 0 0
After:  [1, 0, 2, 3]

Before: [0, 1, 0, 2]
8 0 0 1
After:  [0, 0, 0, 2]

Before: [0, 1, 2, 1]
10 1 0 2
After:  [0, 1, 1, 1]

Before: [3, 0, 3, 1]
7 3 1 2
After:  [3, 0, 1, 1]

Before: [2, 2, 3, 3]
11 0 3 2
After:  [2, 2, 0, 3]

Before: [3, 0, 1, 0]
14 1 2 3
After:  [3, 0, 1, 1]

Before: [0, 0, 1, 2]
12 2 3 0
After:  [3, 0, 1, 2]

Before: [0, 0, 1, 1]
1 0 1 2
After:  [0, 0, 1, 1]

Before: [1, 2, 0, 3]
9 1 0 3
After:  [1, 2, 0, 1]

Before: [0, 1, 3, 0]
10 1 0 3
After:  [0, 1, 3, 1]

Before: [2, 2, 1, 3]
2 2 0 2
After:  [2, 2, 3, 3]

Before: [0, 3, 3, 0]
8 0 0 0
After:  [0, 3, 3, 0]

Before: [1, 2, 0, 1]
9 1 0 2
After:  [1, 2, 1, 1]

Before: [0, 1, 1, 3]
10 1 0 1
After:  [0, 1, 1, 3]

Before: [2, 1, 1, 3]
11 0 3 3
After:  [2, 1, 1, 0]

Before: [3, 0, 1, 1]
7 3 1 3
After:  [3, 0, 1, 1]

Before: [1, 0, 2, 2]
13 1 0 2
After:  [1, 0, 1, 2]

Before: [3, 2, 1, 2]
6 0 3 0
After:  [9, 2, 1, 2]

Before: [0, 2, 3, 0]
2 0 1 3
After:  [0, 2, 3, 2]

Before: [2, 2, 1, 2]
6 3 3 1
After:  [2, 6, 1, 2]

Before: [0, 1, 1, 2]
5 3 1 1
After:  [0, 3, 1, 2]

Before: [1, 2, 2, 1]
6 1 3 3
After:  [1, 2, 2, 6]

Before: [1, 2, 0, 2]
9 1 0 1
After:  [1, 1, 0, 2]

Before: [1, 0, 3, 1]
4 2 2 2
After:  [1, 0, 6, 1]

Before: [1, 0, 2, 2]
13 1 0 1
After:  [1, 1, 2, 2]

Before: [0, 1, 2, 3]
10 1 0 1
After:  [0, 1, 2, 3]

Before: [1, 2, 0, 2]
9 1 0 2
After:  [1, 2, 1, 2]

Before: [3, 2, 2, 2]
15 3 2 2
After:  [3, 2, 4, 2]

Before: [3, 2, 0, 3]
3 1 0 2
After:  [3, 2, 1, 3]

Before: [2, 1, 3, 1]
5 3 2 2
After:  [2, 1, 3, 1]

Before: [1, 0, 3, 1]
13 1 0 0
After:  [1, 0, 3, 1]

Before: [1, 0, 2, 0]
13 1 0 0
After:  [1, 0, 2, 0]

Before: [0, 0, 1, 3]
7 2 1 1
After:  [0, 1, 1, 3]

Before: [1, 0, 3, 0]
13 1 0 2
After:  [1, 0, 1, 0]

Before: [0, 2, 1, 0]
8 0 0 1
After:  [0, 0, 1, 0]

Before: [0, 0, 1, 2]
0 3 2 2
After:  [0, 0, 4, 2]

Before: [0, 0, 3, 3]
1 0 1 3
After:  [0, 0, 3, 1]

Before: [2, 3, 0, 2]
6 1 2 2
After:  [2, 3, 6, 2]

Before: [3, 1, 2, 2]
4 0 2 1
After:  [3, 5, 2, 2]

Before: [3, 2, 3, 0]
2 3 1 1
After:  [3, 2, 3, 0]

Before: [1, 0, 2, 1]
7 0 1 1
After:  [1, 1, 2, 1]

Before: [0, 0, 2, 1]
6 2 3 1
After:  [0, 6, 2, 1]



5 0 2 3
5 1 3 1
5 3 2 2
14 3 2 2
6 2 3 2
4 0 2 0
5 2 3 3
5 0 0 2
14 2 3 3
6 3 3 3
4 3 0 0
10 0 3 2
5 2 1 3
6 1 0 0
0 0 2 0
5 2 0 1
1 0 3 1
6 1 3 1
4 2 1 2
10 2 1 1
5 3 3 0
6 3 0 2
0 2 0 2
6 3 0 3
0 3 1 3
13 2 0 2
6 2 2 2
4 1 2 1
5 0 1 3
5 3 3 2
5 1 2 0
14 3 2 0
6 0 1 0
4 1 0 1
10 1 3 0
6 0 0 1
0 1 1 1
5 2 3 2
5 3 2 3
6 3 1 3
4 3 0 0
10 0 0 1
5 2 1 0
5 3 0 2
5 3 1 3
8 3 0 0
6 0 1 0
4 1 0 1
10 1 3 2
5 1 2 1
6 2 0 0
0 0 2 0
5 2 2 3
1 0 3 1
6 1 2 1
4 1 2 2
10 2 3 3
6 1 0 0
0 0 1 0
5 3 0 2
5 0 3 1
6 0 2 1
6 1 2 1
6 1 2 1
4 3 1 3
10 3 0 0
5 1 2 2
5 0 3 1
6 1 0 3
0 3 0 3
5 3 1 1
6 1 2 1
4 1 0 0
10 0 1 3
5 3 1 1
5 0 1 0
7 1 2 0
6 0 3 0
4 3 0 3
6 0 0 0
0 0 1 0
5 2 0 2
0 0 1 1
6 1 2 1
4 3 1 3
10 3 0 1
5 1 1 3
5 2 2 0
9 0 3 3
6 3 3 3
4 1 3 1
5 2 1 3
1 0 3 0
6 0 3 0
4 0 1 1
10 1 2 0
5 3 1 1
5 0 3 3
6 2 0 2
0 2 0 2
7 1 2 1
6 1 1 1
6 1 3 1
4 1 0 0
10 0 0 1
5 1 2 0
5 3 3 3
5 2 3 3
6 3 3 3
4 3 1 1
10 1 3 2
5 3 1 3
5 3 3 0
5 2 3 1
8 0 1 0
6 0 1 0
4 2 0 2
10 2 1 3
5 0 2 2
6 0 0 0
0 0 3 0
5 1 0 1
13 2 0 2
6 2 2 2
6 2 2 2
4 2 3 3
10 3 1 0
5 0 0 2
6 3 0 3
0 3 1 3
5 3 1 1
6 3 2 2
6 2 2 2
4 0 2 0
10 0 0 3
5 2 2 1
5 1 0 2
5 3 3 0
5 2 0 1
6 1 3 1
4 3 1 3
10 3 3 1
5 2 1 2
5 1 3 0
5 2 0 3
10 0 2 2
6 2 1 2
4 1 2 1
5 2 3 2
6 0 0 3
0 3 0 3
5 0 1 0
11 3 2 2
6 2 2 2
4 1 2 1
10 1 3 0
6 2 0 1
0 1 1 1
5 3 2 3
6 0 0 2
0 2 0 2
7 3 2 2
6 2 1 2
6 2 2 2
4 0 2 0
5 3 0 1
5 0 1 2
6 3 0 3
0 3 1 3
4 3 3 3
6 3 2 3
4 3 0 0
10 0 3 3
5 3 3 2
5 3 2 0
5 2 1 1
2 1 0 1
6 1 1 1
6 1 1 1
4 1 3 3
10 3 2 0
6 2 0 2
0 2 1 2
6 1 0 3
0 3 3 3
5 1 1 1
7 3 2 2
6 2 1 2
6 2 3 2
4 0 2 0
10 0 2 2
5 2 2 3
5 0 2 1
5 2 3 0
1 0 3 1
6 1 1 1
4 2 1 2
10 2 1 0
6 2 0 2
0 2 2 2
5 3 2 1
3 2 1 2
6 2 2 2
4 2 0 0
10 0 2 3
5 1 0 1
5 3 1 2
5 2 1 0
2 0 2 0
6 0 2 0
6 0 3 0
4 3 0 3
10 3 3 0
5 2 1 1
5 2 0 2
5 0 3 3
11 3 2 2
6 2 1 2
4 0 2 0
10 0 0 1
5 0 1 2
5 3 0 0
13 2 0 0
6 0 3 0
4 1 0 1
6 2 0 2
0 2 2 2
5 1 0 0
5 3 1 3
10 0 2 2
6 2 2 2
4 1 2 1
5 3 1 2
5 0 1 3
6 2 0 0
0 0 2 0
13 0 2 2
6 2 2 2
4 1 2 1
10 1 1 3
6 3 0 1
0 1 0 1
6 0 0 0
0 0 1 0
5 2 0 2
10 0 2 0
6 0 2 0
4 0 3 3
10 3 0 1
5 2 0 3
5 3 1 0
5 0 1 2
14 2 3 0
6 0 2 0
4 1 0 1
10 1 3 0
5 3 1 2
6 3 0 1
0 1 1 1
15 1 3 1
6 1 1 1
6 1 3 1
4 1 0 0
10 0 1 3
5 3 1 1
5 2 1 0
13 0 2 1
6 1 1 1
4 1 3 3
10 3 0 1
5 1 1 3
13 0 2 0
6 0 3 0
4 1 0 1
10 1 3 0
5 3 3 1
5 0 2 3
5 2 1 2
11 3 2 1
6 1 3 1
6 1 3 1
4 1 0 0
10 0 2 3
5 3 3 1
5 0 2 0
5 0 3 2
7 1 2 2
6 2 3 2
4 2 3 3
10 3 1 1
5 3 1 0
6 2 0 3
0 3 2 3
5 0 1 2
14 2 3 3
6 3 2 3
4 1 3 1
10 1 2 3
5 1 0 1
5 1 1 2
7 0 2 1
6 1 3 1
4 1 3 3
10 3 2 1
6 2 0 3
0 3 2 3
5 0 2 2
5 2 0 0
1 0 3 0
6 0 1 0
4 1 0 1
6 2 0 2
0 2 3 2
5 2 2 0
1 0 3 0
6 0 2 0
6 0 3 0
4 1 0 1
10 1 2 2
5 2 3 0
5 1 3 1
1 0 3 3
6 3 3 3
4 2 3 2
10 2 0 1
5 2 2 2
5 0 1 3
12 2 3 0
6 0 2 0
4 1 0 1
10 1 1 0
5 3 0 2
5 3 1 1
14 3 2 1
6 1 3 1
6 1 1 1
4 1 0 0
10 0 1 1
6 2 0 2
0 2 1 2
5 2 2 0
5 2 1 3
1 0 3 2
6 2 1 2
4 1 2 1
10 1 2 2
5 3 0 0
5 1 1 3
5 0 3 1
4 3 3 0
6 0 1 0
4 2 0 2
10 2 0 3
5 3 2 0
5 3 3 1
5 0 1 2
13 2 0 1
6 1 2 1
4 3 1 3
5 3 1 2
5 2 3 1
2 1 2 2
6 2 3 2
4 3 2 3
10 3 2 0
5 0 0 2
5 1 0 3
5 3 1 1
7 1 2 2
6 2 2 2
4 0 2 0
5 2 3 1
5 2 0 2
5 0 0 3
11 3 2 1
6 1 3 1
4 1 0 0
5 1 0 1
11 3 2 2
6 2 1 2
6 2 2 2
4 2 0 0
5 0 1 1
5 1 3 2
5 3 0 3
7 3 2 1
6 1 1 1
4 1 0 0
10 0 0 2
5 1 0 3
5 1 2 1
5 2 3 0
9 0 3 3
6 3 2 3
4 3 2 2
10 2 2 3
5 1 1 0
5 0 3 2
5 3 1 1
0 0 1 2
6 2 3 2
6 2 1 2
4 3 2 3
10 3 0 1
5 3 3 2
6 3 0 3
0 3 0 3
5 2 0 0
14 3 2 2
6 2 1 2
4 1 2 1
10 1 2 3
5 3 2 1
5 1 1 0
6 2 0 2
0 2 2 2
10 0 2 1
6 1 1 1
4 1 3 3
10 3 0 2
5 0 1 3
5 2 3 0
6 1 0 1
0 1 3 1
12 0 3 1
6 1 2 1
4 2 1 2
10 2 1 0
5 1 1 3
5 0 3 2
5 3 3 1
6 3 2 1
6 1 2 1
4 1 0 0
10 0 1 1
5 0 1 3
6 2 0 2
0 2 2 2
5 0 0 0
11 3 2 0
6 0 1 0
6 0 2 0
4 1 0 1
5 0 3 2
5 3 1 3
5 3 2 0
5 2 0 2
6 2 2 2
4 2 1 1
6 1 0 0
0 0 2 0
5 1 1 3
5 2 1 2
15 3 0 2
6 2 1 2
4 1 2 1
10 1 1 3
5 3 1 1
6 3 0 2
0 2 2 2
3 0 1 2
6 2 3 2
4 2 3 3
10 3 1 1
5 3 0 3
5 3 0 2
13 0 2 0
6 0 3 0
4 0 1 1
10 1 1 2
5 1 1 0
6 2 0 3
0 3 2 3
6 1 0 1
0 1 0 1
15 0 3 0
6 0 3 0
6 0 3 0
4 2 0 2
5 1 2 3
6 1 0 1
0 1 1 1
5 2 2 0
15 1 0 3
6 3 1 3
6 3 2 3
4 3 2 2
10 2 3 1
5 3 2 2
5 2 1 3
2 0 2 0
6 0 2 0
4 0 1 1
10 1 3 2
6 2 0 0
0 0 2 0
5 2 3 1
5 3 1 3
8 3 1 3
6 3 3 3
4 2 3 2
5 1 2 1
5 1 3 3
9 0 3 1
6 1 3 1
6 1 3 1
4 2 1 2
10 2 3 3
5 3 1 2
5 2 3 1
5 3 0 0
2 1 0 2
6 2 3 2
4 2 3 3
10 3 3 2
5 2 1 0
5 3 3 3
5 1 1 1
15 1 0 0
6 0 2 0
4 2 0 2
10 2 2 3
5 0 0 1
5 0 0 2
5 1 0 0
0 0 1 2
6 2 3 2
4 2 3 3
10 3 2 1
6 3 0 2
0 2 3 2
5 0 0 3
5 3 0 0
14 3 2 3
6 3 2 3
4 3 1 1
10 1 3 3
5 0 2 1
5 0 3 2
13 2 0 1
6 1 3 1
6 1 2 1
4 3 1 3
10 3 1 2
5 2 0 0
6 3 0 1
0 1 3 1
5 1 0 3
3 0 1 1
6 1 3 1
6 1 1 1
4 1 2 2
5 3 0 1
5 0 3 3
3 0 1 3
6 3 2 3
4 2 3 2
10 2 1 1
5 3 0 2
5 1 2 0
5 2 1 3
15 0 3 0
6 0 1 0
6 0 2 0
4 1 0 1
10 1 3 2
5 3 2 1
5 1 3 3
5 1 3 0
4 3 3 3
6 3 2 3
4 3 2 2
10 2 0 1
6 0 0 2
0 2 1 2
5 1 0 3
6 3 0 0
0 0 2 0
15 3 0 2
6 2 2 2
4 1 2 1
10 1 2 3
5 2 3 2
5 3 0 0
5 2 1 1
2 1 0 0
6 0 2 0
4 0 3 3
10 3 1 1
5 1 0 2
5 3 0 0
5 1 0 3
7 0 2 0
6 0 2 0
4 1 0 1
5 2 1 0
5 2 1 3
5 3 3 2
13 0 2 2
6 2 3 2
4 1 2 1
10 1 1 0
5 2 0 2
5 0 0 3
5 1 0 1
11 3 2 3
6 3 3 3
4 0 3 0
10 0 2 1
5 1 2 0
5 1 3 3
10 0 2 0
6 0 1 0
4 0 1 1
10 1 0 0
5 1 3 1
5 3 1 2
5 2 1 3
6 1 2 1
6 1 1 1
6 1 3 1
4 1 0 0
10 0 2 1
5 0 0 3
5 1 2 0
5 2 1 2
10 0 2 0
6 0 3 0
4 0 1 1
10 1 3 2
5 0 2 1
6 1 0 3
0 3 1 3
5 2 2 0
15 3 0 0
6 0 2 0
6 0 3 0
4 0 2 2
5 2 2 1
5 1 1 0
4 3 0 0
6 0 2 0
4 0 2 2
10 2 3 1
6 0 0 2
0 2 2 2
5 1 2 0
10 0 2 3
6 3 1 3
6 3 2 3
4 3 1 1
10 1 2 2
5 3 1 1
5 2 1 0
5 3 3 3
8 3 0 1
6 1 3 1
4 1 2 2
10 2 2 1
6 1 0 2
0 2 0 2
5 2 1 3
14 2 3 3
6 3 1 3
4 3 1 1
10 1 3 3
5 2 3 1
5 3 3 2
13 0 2 0
6 0 2 0
6 0 1 0
4 3 0 3
10 3 2 1
5 2 0 2
5 3 2 0
5 1 2 3
3 2 0 2
6 2 2 2
4 1 2 1
10 1 3 2
5 0 2 1
5 2 1 0
9 0 3 3
6 3 1 3
6 3 2 3
4 2 3 2
10 2 3 0
5 3 1 3
5 3 1 1
5 2 3 2
3 2 1 3
6 3 2 3
4 3 0 0
10 0 3 2
6 3 0 1
0 1 1 1
5 1 0 3
5 3 1 0
4 3 3 3
6 3 2 3
4 3 2 2
10 2 1 3
5 2 3 0
6 2 0 1
0 1 2 1
5 3 0 2
2 0 2 0
6 0 1 0
4 3 0 3
10 3 0 1
6 3 0 0
0 0 2 0
5 2 2 3
5 0 0 2
1 0 3 3
6 3 1 3
6 3 3 3
4 1 3 1
10 1 3 3
5 1 2 0
6 2 0 2
0 2 2 2
5 3 2 1
10 0 2 0
6 0 2 0
4 0 3 3
10 3 1 2
6 3 0 0
0 0 1 0
5 0 2 3
5 2 3 1
12 1 3 3
6 3 1 3
6 3 2 3
4 3 2 2
10 2 0 3
5 3 3 2
5 2 1 0
5 3 3 1
3 0 1 2
6 2 1 2
4 2 3 3
10 3 0 1
6 3 0 0
0 0 3 0
6 2 0 3
0 3 1 3
6 0 0 2
0 2 3 2
6 3 2 0
6 0 2 0
4 0 1 1
5 2 3 0
6 2 0 2
0 2 1 2
6 2 0 3
0 3 2 3
12 0 3 3
6 3 2 3
4 1 3 1
10 1 1 0
5 3 0 1
5 3 0 2
5 2 2 3
8 1 3 1
6 1 3 1
6 1 3 1
4 1 0 0
10 0 1 2
5 1 1 1
6 3 0 3
0 3 1 3
5 2 3 0
15 3 0 3
6 3 3 3
6 3 2 3
4 2 3 2
10 2 0 1
6 1 0 3
0 3 3 3
5 3 2 0
5 2 3 2
3 2 0 2
6 2 2 2
6 2 3 2
4 1 2 1
5 2 0 2
5 0 0 3
3 2 0 3
6 3 3 3
4 3 1 1
10 1 0 0
5 3 2 2
5 3 0 3
6 0 0 1
0 1 2 1
2 1 2 2
6 2 1 2
4 0 2 0
5 2 1 2
6 1 0 3
0 3 0 3
6 0 0 1
0 1 0 1
11 3 2 2
6 2 3 2
4 0 2 0
10 0 3 3
5 3 0 2
5 1 2 1
5 1 1 0
6 0 2 1
6 1 1 1
6 1 1 1
4 3 1 3
10 3 3 1
5 0 3 2
5 2 1 0
5 1 3 3
9 0 3 3
6 3 1 3
4 1 3 1
10 1 1 3
6 2 0 1
0 1 1 1
5 3 3 2
13 0 2 1
6 1 1 1
4 1 3 3
5 1 2 1
5 2 2 2
5 1 3 0
10 0 2 2
6 2 1 2
4 2 3 3
5 3 2 0
5 1 3 2
5 3 0 1
7 0 2 2
6 2 1 2
4 2 3 3
10 3 2 1
5 0 3 3
6 3 0 2
0 2 2 2
6 2 0 0
0 0 1 0
10 0 2 2
6 2 1 2
4 1 2 1
5 2 0 2
5 2 0 0
5 2 3 3
12 2 3 0
6 0 3 0
4 1 0 1
5 0 2 0
5 0 2 2
5 1 0 3
6 3 2 3
6 3 2 3
6 3 2 3
4 1 3 1
10 1 3 3
5 3 2 1
5 2 1 0
6 0 0 2
0 2 3 2
3 0 1 1
6 1 2 1
4 1 3 3
10 3 3 1
5 1 1 2
5 3 3 0
6 3 0 3
0 3 2 3
8 0 3 2
6 2 1 2
6 2 2 2
4 1 2 1
10 1 3 0
5 1 0 3
6 0 0 1
0 1 2 1
5 2 2 2
4 3 3 3
6 3 2 3
4 0 3 0
10 0 1 2
6 3 0 1
0 1 3 1
5 2 1 0
5 1 1 3
15 3 0 1
6 1 3 1
6 1 3 1
4 2 1 2
10 2 3 1
5 2 0 2
5 2 0 3
6 3 0 0
0 0 1 0
4 0 0 3
6 3 1 3
4 1 3 1
5 3 3 0
5 2 1 3
5 0 1 2
14 2 3 2
6 2 2 2
4 1 2 1
10 1 1 2
5 2 1 1
5 2 0 0
12 1 3 0
6 0 1 0
4 0 2 2
5 2 2 0
1 0 3 3
6 3 1 3
4 3 2 2
10 2 2 3
5 1 2 0
6 3 0 1
0 1 0 1
5 0 3 2
6 0 2 2
6 2 2 2
4 2 3 3
10 3 1 1
6 1 0 2
0 2 3 2
5 0 3 3
14 3 2 3
6 3 2 3
6 3 1 3
4 3 1 1
10 1 2 0
6 0 0 3
0 3 3 3
6 0 0 2
0 2 0 2
5 3 0 1
5 2 1 3
6 3 1 3
4 0 3 0
10 0 0 2
5 1 1 3
5 0 2 1
5 0 0 0
0 3 1 3
6 3 1 3
4 2 3 2
10 2 0 1
6 2 0 3
0 3 2 3
6 0 0 2
0 2 3 2
5 2 0 0
1 0 3 2
6 2 1 2
4 2 1 1
10 1 3 2
5 2 1 1
5 1 0 3
5 1 3 0
4 3 0 3
6 3 2 3
4 2 3 2
10 2 2 0
5 3 0 2
5 0 0 3
5 1 0 1
5 2 3 2
6 2 1 2
4 2 0 0
5 1 2 3
5 3 1 2
6 1 2 1
6 1 1 1
4 1 0 0
6 3 0 1
0 1 0 1
6 3 2 3
6 3 2 3
6 3 3 3
4 0 3 0
10 0 0 1
5 2 2 3
5 3 3 0
5 2 0 3
6 3 3 3
4 3 1 1
10 1 0 2
5 1 0 1
5 1 1 3
5 2 1 0
4 1 3 3
6 3 1 3
4 2 3 2
6 3 0 3
0 3 2 3
6 3 0 1
0 1 3 1
1 0 3 0
6 0 1 0
4 0 2 2
10 2 2 3
5 1 3 1
6 1 0 0
0 0 1 0
6 3 0 2
0 2 3 2
6 1 2 2
6 2 3 2
4 3 2 3
5 2 1 2
5 3 3 1
5 0 0 0
3 2 1 0
6 0 2 0
4 0 3 3
10 3 0 1
5 2 2 3
5 2 2 0
5 0 1 2
14 2 3 2
6 2 2 2
6 2 3 2
4 2 1 1
10 1 1 3
5 0 0 1
5 2 0 2
5 3 0 0
3 2 0 0
6 0 2 0
6 0 1 0
4 0 3 3
10 3 1 1
5 0 2 3
5 1 2 0
11 3 2 2
6 2 3 2
4 2 1 1
10 1 3 2
5 3 1 1
5 2 3 0
5 2 2 3
8 1 0 3
6 3 2 3
6 3 2 3
4 3 2 2
5 3 0 3
8 1 0 0
6 0 3 0
4 0 2 2
10 2 3 1
5 0 3 3
6 1 0 0
0 0 1 0
5 2 1 2
10 0 2 3
6 3 3 3
4 1 3 1
5 2 1 0
5 0 1 3
11 3 2 3
6 3 2 3
4 3 1 1
10 1 1 0