#!/bin/perl
#
# https://adventofcode.com/2019/day/7

use Carp;
use POSIX;

use lib '.';
use intcode;


# pre-calculate all possible phase setting sequences
my @pss = ();
perm([], [0..4]);

print "\nDay 07-1 Examples:\n";
my @examples = ("3,15,3,16,1002,16,10,16,1,16,15,15,4,15,99,0,0", "3,23,3,24,1002,24,10,24,1002,23,-1,23,101,5,23,23,1,24,23,23,4,23,99,0,0", "3,31,3,32,1002,32,10,32,1001,31,-2,31,1007,31,0,33,1002,33,7,33,1,33,31,31,1,32,31,31,4,31,99,0,0,0");
foreach my $e (@examples) {
	my $max_signal = 0;
	my $max_pss = "";
	foreach my $p (@pss) {
		#print "PSS Ref is $p (" . join(',', @$p) . ")\n";
		my $signal = amplifier_check($e, $p);
		if ($signal > $max_signal) {
			$max_signal = $signal;
			$max_pss = join(',', @$p);
			#print ">> New Max $signal with pss $max_pss\n";
		}
	}
	print "Max Signal: $max_signal from sequence ($max_pss)\n";
}

print "\nDay 07-1 Solution:\n";
$puzzle = <DATA>;
my $max_signal = 0;
my $max_pss = "";
foreach my $p (@pss) {
	#print "PSS Ref is $p (" . join(',', @$p) . ")\n";
	my $signal = amplifier_check($puzzle, $p);
	if ($signal > $max_signal) {
		$max_signal = $signal;
		$max_pss = join(',', @$p);
		#print ">> New Max $signal with pss $max_pss\n";
	}
}
print "Max Signal: $max_signal from sequence ($max_pss)\n";

@pss = ();
perm([], [5..9]);

select STDOUT;
$| = undef;

print "\nDay 07-2 Examples:\n";
my @examples = ("3,26,1001,26,-4,26,3,27,1002,27,2,27,1,27,26,27,4,27,1001,28,-1,28,1005,28,6,99,0,0,5", "3,52,1001,52,-5,52,3,53,1,52,56,54,1007,54,5,55,1005,55,26,1001,54,-5,54,1105,1,12,1,53,54,53,1008,54,0,55,1001,55,1,55,2,53,55,53,4,53,1001,56,-1,56,1005,56,6,99,0,0,0,0,10");
foreach my $e (@examples) {
	my $max_signal = 0;
	my $max_pss = "";
	foreach my $p (@pss) {
		#print "PSS Ref is $p (" . join(',', @$p) . ")\n";
		my $signal = amplifier_check($e, $p, 1);
		if ($signal > $max_signal) {
			$max_signal = $signal;
			$max_pss = join(',', @$p);
			#print ">> New Max $signal with pss $max_pss\n";
		}
	}
	print "Max Signal: $max_signal from sequence ($max_pss)\n";
}

print "\nDay 07-2 Solution:\n";
$max_signal = 0;
$max_pss = "";
foreach my $p (@pss) {
	#print "PSS Ref is $p (" . join(',', @$p) . ")\n";
	my $signal = amplifier_check($puzzle, $p, 1);
	if ($signal > $max_signal) {
		$max_signal = $signal;
		$max_pss = join(',', @$p);
		#print ">> New Max $signal with pss $max_pss\n";
	}
}
print "Max Signal: $max_signal from sequence ($max_pss)\n";


sub perm {
	my $used = shift;
	my $left = shift;
	
	if (scalar(@$left) == 0) {
		push @pss, $used;
		#print "PERM " . join(',', @$used) . "\n";
		return;
	} else {
		for (my $i = 0; $i < scalar(@$left); $i++) {
			my @new_used = @$used;
			my @new_left = @$left;
			push @new_used, $new_left[$i];
			splice @new_left, $i, 1;
			perm(\@new_used, \@new_left);
		}
	}
}

sub amplifier_check {
	my $program = shift;
	my $pss_ref = shift;
	my $loop = shift;

	$loop = 0 if (not defined $loop);
	
	my $icc = intcode->new($program,1,0,$pss_ref);
	my $i = 0;
	my $r = 0;
	while($icc->num_running_computers() > 0) {
		for ($i = 0; $i < 5; $i++) {
			$icc->send_input($i, $r);
			$r = $icc->get_output(1,1);
		}
		last unless $loop;
	}
	$icc->exit();
	return $r;
}


__DATA__
3,8,1001,8,10,8,105,1,0,0,21,38,55,64,89,114,195,276,357,438,99999,3,9,101,3,9,9,102,3,9,9,1001,9,5,9,4,9,99,3,9,101,2,9,9,1002,9,3,9,101,5,9,9,4,9,99,3,9,101,3,9,9,4,9,99,3,9,1002,9,4,9,101,5,9,9,1002,9,5,9,101,5,9,9,102,3,9,9,4,9,99,3,9,101,3,9,9,1002,9,4,9,101,5,9,9,102,5,9,9,1001,9,5,9,4,9,99,3,9,102,2,9,9,4,9,3,9,101,2,9,9,4,9,3,9,102,2,9,9,4,9,3,9,101,2,9,9,4,9,3,9,102,2,9,9,4,9,3,9,1002,9,2,9,4,9,3,9,101,1,9,9,4,9,3,9,101,1,9,9,4,9,3,9,1001,9,1,9,4,9,3,9,1002,9,2,9,4,9,99,3,9,1002,9,2,9,4,9,3,9,1001,9,1,9,4,9,3,9,102,2,9,9,4,9,3,9,102,2,9,9,4,9,3,9,101,2,9,9,4,9,3,9,1002,9,2,9,4,9,3,9,102,2,9,9,4,9,3,9,101,1,9,9,4,9,3,9,102,2,9,9,4,9,3,9,1002,9,2,9,4,9,99,3,9,101,2,9,9,4,9,3,9,101,2,9,9,4,9,3,9,102,2,9,9,4,9,3,9,102,2,9,9,4,9,3,9,1001,9,1,9,4,9,3,9,102,2,9,9,4,9,3,9,101,2,9,9,4,9,3,9,101,1,9,9,4,9,3,9,1001,9,1,9,4,9,3,9,1001,9,2,9,4,9,99,3,9,1001,9,1,9,4,9,3,9,1002,9,2,9,4,9,3,9,1001,9,2,9,4,9,3,9,101,1,9,9,4,9,3,9,101,1,9,9,4,9,3,9,102,2,9,9,4,9,3,9,1002,9,2,9,4,9,3,9,102,2,9,9,4,9,3,9,1002,9,2,9,4,9,3,9,101,1,9,9,4,9,99,3,9,1002,9,2,9,4,9,3,9,1001,9,1,9,4,9,3,9,101,2,9,9,4,9,3,9,1002,9,2,9,4,9,3,9,101,1,9,9,4,9,3,9,101,2,9,9,4,9,3,9,1001,9,1,9,4,9,3,9,1002,9,2,9,4,9,3,9,102,2,9,9,4,9,3,9,1001,9,1,9,4,9,99