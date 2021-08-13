#!/bin/perl
#
# https://adventofcode.com/2019/day/2

use Carp;
use POSIX;

use lib '.';
use intcode;


my @examples = ( "1,9,10,3,2,3,11,0,99,30,40,50", "1,0,0,0,99", "2,3,0,3,99", "2,4,4,5,99,0", "1,1,1,4,99,5,6,0,99" );

print "Day 02 Examples\n";
foreach my $e (@examples) {
	my $icc = intcode->new($e,1,1);
	my $r = $icc->get_output();
	print "$e -> $r\n";
	$icc->exit();
}
my $puzzle = <DATA>;

my @input = split(',', $puzzle);
$input[1]= 12;
$input[2] = 2;
my $icc = intcode->new(\@input,1,1);
my $r = $icc->get_output();
my @result = split(',', $r);
$icc->exit();

print "\nSolution 02-1: $result[0]\n";

print "\nStarting search for 02-2\n";
my $found = 0;
my $start_noun = 0; # 0 nornally, 80 for quick result for later intcode testing
my $start_verb = 0; # 0 normally, 50 for quick result for later intcode testing
OUTER: for (my $noun = $start_noun; $noun < 100; $noun++) {
	for (my $verb = $start_verb; $verb < 100; $verb++) {
		@input = split(',', $puzzle);
		$input[1]= $noun;
		$input[2] = $verb;
		$icc = intcode->new(\@input,1,1);
		$r = $icc->get_output();
		@result = split(',', $r);
		print "[N:$noun V:$verb] $result[0]     \r";
		if ($result[0] == 19690720) {
			print "\nSolution 02-2 found at " . ($noun*100+$verb) . "\n";
			$found = 1;
		}
		$icc->exit();
		last OUTER if ($found);
	}
}

print "\nNo solution 02-2 found.\n" if (not $found);
__DATA__
1,0,0,3,1,1,2,3,1,3,4,3,1,5,0,3,2,1,6,19,1,5,19,23,1,23,6,27,1,5,27,31,1,31,6,35,1,9,35,39,2,10,39,43,1,43,6,47,2,6,47,51,1,5,51,55,1,55,13,59,1,59,10,63,2,10,63,67,1,9,67,71,2,6,71,75,1,5,75,79,2,79,13,83,1,83,5,87,1,87,9,91,1,5,91,95,1,5,95,99,1,99,13,103,1,10,103,107,1,107,9,111,1,6,111,115,2,115,13,119,1,10,119,123,2,123,6,127,1,5,127,131,1,5,131,135,1,135,6,139,2,139,10,143,2,143,9,147,1,147,6,151,1,151,13,155,2,155,9,159,1,6,159,163,1,5,163,167,1,5,167,171,1,10,171,175,1,13,175,179,1,179,2,183,1,9,183,0,99,2,14,0,0