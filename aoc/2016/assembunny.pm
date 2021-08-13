#!/bin/perl -w
#
# assembunny.pm
#
# Utility module required for a few AoC 2016 puzzles.
# Only partially implements the day 25 'out' instruction as it will terminate early once the output hits a specific length.
# We somewhat arbitrarily chose 16 for this length based on the day 25 puzzle, but there's a variable for it.

package assembunny;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(run_program);

use strict;
use Carp;
use POSIX;

my $output_cutoff = 16;

# No constructor, just this single function that expects an array ref for the instruction set and
# an optional pair of scalars: string 'a', 'b', 'c', or 'd' indicating a register and an integer
# value to place in that register. All other registers will be initialized to zero.
# Will return a list containing the values in all 4 registers (again in alphabetical order followed by the "output".

my %toggle = ('inc' => 'dec', 'dec' => 'inc', 'tgl' => 'inc', 'jnz' => 'cpy', 'cpy' => 'jnz', 'add' => 'dec', 'mul' => 'dec');

sub run_program {
	my $input = shift;
	my $reg_char = shift;
	my $reg_val = shift;
	
	$reg_char = 'a' unless (defined $reg_char);
	$reg_val = 0 unless (defined $reg_val);
	my %reg = ( 'a' => 0, 'b' => 0, 'c' => 0, 'd' => 0 );
	$reg{$reg_char} = $reg_val;
	my $output = "";

	my $ip = 0;	# instruction pointer

	# Re-parse the input converting from an array of strings into a multi-dimensional array.
	my @ins = map { [ split(' ') ] } @$input; 
	optimize(\@ins);
	
	while ($ip < scalar(@ins)) {
		# Op arguments are basically the same for every function -- if it's a number use it directly,
		# but if it's a letter, fetch the value from that register.
		my $a = ((exists $reg{$ins[$ip][1]}) ? $reg{$ins[$ip][1]} : $ins[$ip][1]) if (scalar @{$ins[$ip]} > 1);
		my $b = ((exists $reg{$ins[$ip][2]}) ? $reg{$ins[$ip][2]} : $ins[$ip][2]) if (scalar @{$ins[$ip]} > 2);
		
		if ($ins[$ip][0] eq 'cpy') {
			$reg{$ins[$ip][2]} = $a;
			$ip++;
		} elsif ($ins[$ip][0] eq 'inc') {
			$reg{$ins[$ip][1]} += 1 if (exists $reg{$ins[$ip][1]});
			$ip++;
		} elsif ($ins[$ip][0] eq 'dec') {
			$reg{$ins[$ip][1]} -= 1 if (exists $reg{$ins[$ip][1]});
			$ip++;
		} elsif ($ins[$ip][0] eq 'jnz') {
			$ip += ($a != 0) ? $b : 1;
		} elsif ($ins[$ip][0] eq 'tgl') {
			my $loc = $ip + $a;
			if ($loc > 0 and $loc <= $#ins) {
				if (exists $toggle{$ins[$loc][0]}) {
					$ins[$loc][0] = $toggle{$ins[$loc][0]};
				} else {
					$ins[$loc][0] = (scalar @{$ins[$loc]} > 2) ? 'jnz' : 'inc';
				}
			}
			$ip++;
			optimize(\@ins);
		} elsif ($ins[$ip][0] eq 'out') {
			$output .= $a;
			last if ($output_cutoff <= length $output);
			$ip++;
		# the rest of these are not actually part of the spec, but necessary for optimizations
		} elsif ($ins[$ip][0] eq 'nop') {
			$ip++;
		} elsif ($ins[$ip][0] eq 'add') {
			$reg{$ins[$ip][1]} += $b;
			$reg{$ins[$ip][2]} = 0;
			$ip += 3;		
		} elsif ($ins[$ip][0] eq 'mul') {
			my $m = (exists $reg{$ins[$ip][3]}) ? $reg{$ins[$ip][3]} : $ins[$ip][3];
			$reg{$ins[$ip][1]} += $a * $m;
			$reg{$ins[$ip][3]} = 0;
			$reg{$ins[$ip][4]} = 0;
			$ip += 5;		
		} else {
			carp "Skipping invalid instruction {$ins[$ip][0]}\n";
			$ip++;
		}
	}
	
	return ($reg{'a'}, $reg{'b'}, $reg{'c'}, $reg{'d'}, $output);
}

sub optimize {
	my $ins = shift;
	# Optimizations. 
	# This was originally pulled into its own function so that it could be called again following a tgl,
	# but we are concerned about that backfiring so we only actualy call it before executing any instructions.
	# 1) In day 12 we see the following pattern several times: inc a, dec b, jnz b -2
	#    This runs the "inc a" instruction b times, so basically is doing a += b and zeroing b
	#    We implement this with an 'add a b' instruction.
	# 2) Day 23 extended that pattern to: cpy b c, inc a, dec c, jnz c -2, dec d, jnz d -5
	#    This one does "a += b" d times so is equivalent to a += b * d with c and d zeroed.
	#    We will call this "mul a b d c" since all 4 registers are involved.
	# Since these are different lengths and the multiplication contains the addition algorithm,
	# we'll just run through the code twice, doing the mult first.
	for (my $i = 0; $i < $#$ins - 5; $i++) {
		if ($ins->[$i][0] eq 'cpy' and $ins->[$i+1][0] eq 'inc' and $ins->[$i+2][0] eq 'dec' and $ins->[$i+3][0] eq 'jnz' and
			$ins->[$i+4][0] eq 'dec' and $ins->[$i+5][0] eq 'jnz' and $ins->[$i][2] eq $ins->[$i+2][1] and
			$ins->[$i][2] eq $ins->[$i+3][1] and $ins->[$i+4][1] eq $ins->[$i+5][1] and
			$ins->[$i+3][2] == -2 and $ins->[$i+5][2] == -5) {
			$ins->[$i][0] = 'nop';
			$ins->[$i+1][0] = 'mul';
			push @{$ins->[$i+1]}, $ins->[$i][1], $ins->[$i+4][1], $ins->[$i][2];
			$ins->[$i+2][0] = 'nop';
			$ins->[$i+3][0] = 'nop';
			$ins->[$i+4][0] = 'nop';
			$ins->[$i+5][0] = 'nop';
		}
	}
	for (my $i = 0; $i < $#$ins - 1; $i++) {
		if ($ins->[$i][0] eq 'inc' and $ins->[$i+1][0] eq 'dec' and $ins->[$i+2][0] eq 'jnz' and
			$ins->[$i+1][1] eq $ins->[$i+2][1] and $ins->[$i+2][2] == -2) {
			$ins->[$i][0] = 'add';
			push @{$ins->[$i]}, $ins->[$i+1][1];
			$ins->[$i+1][0] = 'nop';
			$ins->[$i+2][0] = 'nop';
		}
	}
}

1;
