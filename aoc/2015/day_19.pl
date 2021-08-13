#!/bin/perl -w
#
# https://adventofcode.com/2015/day/19
#

use strict;
use POSIX;
use List::Util qw(min);

my $debugging = 0;

my %replacements = ();
my %reverse_rep = (); 
my $blank_line_seen = 0;
my $medicine = "";
while (<DATA>) {
	chomp;
	if ($_ eq '') {
		$blank_line_seen = 1;
	} else {
		if ($blank_line_seen) {
			$medicine = $_;
		} else {
			(my ($input, $output)) = /^(\w+) => (\w+)$/;
			$replacements{$input} = [] unless (defined $replacements{$input});
			push @{$replacements{$input}}, $output;
			# See comments at beginning for part 2 for why this is done
			$reverse_rep{reverse $output} = reverse $input;
		}
	}
}

print "2015 Day 19\n";
my @med_elements = $medicine =~ /([A-Z][a-z]?)/g;
my %results = ();

print "\nPart 1 calibrating...\n";
for (my $i = 0; $i <= $#med_elements; $i++) {
	if (exists $replacements{$med_elements[$i]}) {
		foreach my $rep (@{$replacements{$med_elements[$i]}}) {
			my @copy = @med_elements;
			$copy[$i] = $rep;
			my $new = join('', @copy);
			$results{$new} = 0 unless (defined $results{$new});
			$results{$new}++;
		}
	}
}
print "P1: Machine can make " . scalar(keys %results) . " distinct molecules from the medicine.\n";

print "\nPart 2 manufacturing...\n";
# After the brute-force attempt failed due to deep recursion, we notice that every rule in the given puzzle input has a unique
# output, so we can define a reverse replacement mapping and try to deconstruct the molecule down to 'e' via substitution.
# It turns out that this actually works, but is much easier if we match from right-to-left since doing it left-to-right
# has some ambiguity that could trap us without backtracking. To match right-to-left we need to reverse everything.
# The medicine string is easy enough to do now, but for the rules we added some code to the input processing loop.
my $reversed_molecule = reverse $medicine;
my $match_pattern = join('|', keys %reverse_rep);
my $steps = 0;
while ($reversed_molecule =~ s/($match_pattern)/$reverse_rep{$1}/) {
	$steps++;
}
if ($reversed_molecule eq 'e') {
	print "P2: Minimum number of steps required to make the medicine is $steps\n";
} else {
	print "P2: Failed to calculate required steps.\n";
}

sub dump_hash {
	my $h = shift;
	foreach my $k (keys %$h) {
		print " $k occurs $h->{$k} times\n";
	}
}

# Failed brute-force mentioned above. Works fine for examples, but hits deep recursion limit on actual input.
sub run_machine {
	my $target = shift;		# as a string for easier comparisons
	my $target_len = shift;	# number of elements in target since we are not passing full list
	my $repref = shift;		# ref to hash of replacement rules
	
	my $eleref = shift;		# ref to list of currently assembled elements
	my $steps = shift;		# current step count
	
	$eleref = ['e'] unless (defined $eleref);
	$steps = 0 unless (defined $steps);
	
	# End conditions: matched target or molecule is too long
	return $steps if ($target eq join('', @$eleref));
	return 1e9 if (scalar(@$eleref) > $target_len);

	my $min_steps = 2e9;
	# The recursive part is similar to initial calibration loop.
	for (my $i = 0; $i <= $#$eleref; $i++) {
		if (exists $repref->{$eleref->[$i]}) {
			foreach my $rep (@{$repref->{$eleref->[$i]}}) {
				my @copy = @$eleref;
				splice @copy, $i, 1, split("", $rep);
				my $result = run_machine($target, $target_len, $repref, \@copy, $steps + 1);
				$min_steps = $result if ($result < $min_steps);
			}
		}
	}
	return $min_steps;
}

__DATA__
Al => ThF
Al => ThRnFAr
B => BCa
B => TiB
B => TiRnFAr
Ca => CaCa
Ca => PB
Ca => PRnFAr
Ca => SiRnFYFAr
Ca => SiRnMgAr
Ca => SiTh
F => CaF
F => PMg
F => SiAl
H => CRnAlAr
H => CRnFYFYFAr
H => CRnFYMgAr
H => CRnMgYFAr
H => HCa
H => NRnFYFAr
H => NRnMgAr
H => NTh
H => OB
H => ORnFAr
Mg => BF
Mg => TiMg
N => CRnFAr
N => HSi
O => CRnFYFAr
O => CRnMgAr
O => HP
O => NRnFAr
O => OTi
P => CaP
P => PTi
P => SiRnFAr
Si => CaSi
Th => ThCa
Ti => BP
Ti => TiTi
e => HF
e => NAl
e => OMg

ORnPBPMgArCaCaCaSiThCaCaSiThCaCaPBSiRnFArRnFArCaCaSiThCaCaSiThCaCaCaCaCaCaSiRnFYFArSiRnMgArCaSiRnPTiTiBFYPBFArSiRnCaSiRnTiRnFArSiAlArPTiBPTiRnCaSiAlArCaPTiTiBPMgYFArPTiRnFArSiRnCaCaFArRnCaFArCaSiRnSiRnMgArFYCaSiRnMgArCaCaSiThPRnFArPBCaSiRnMgArCaCaSiThCaSiRnTiMgArFArSiThSiThCaCaSiRnMgArCaCaSiRnFArTiBPTiRnCaSiAlArCaPTiRnFArPBPBCaCaSiThCaPBSiThPRnFArSiThCaSiThCaSiThCaPTiBSiRnFYFArCaCaPRnFArPBCaCaPBSiRnTiRnFArCaPRnFArSiRnCaCaCaSiThCaRnCaFArYCaSiRnFArBCaCaCaSiThFArPBFArCaSiRnFArRnCaCaCaFArSiRnFArTiRnPMgArF