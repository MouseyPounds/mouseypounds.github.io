#!/bin/perl -w
#
# https://adventofcode.com/2020/day/15

use strict;
use POSIX;

print "2020 Day 15\n";
my @puzzle = (0,13,1,16,6,17);

$| = 1;

print "\nPart 1\n";
my $target = 2020;
my $num = get_num(\@puzzle, $target);
print "P1: The ${target}th number spoken will be $num.\n";

print "\nPart 2\n";
$target = 30000000;
$num = get_num(\@puzzle, $target);
print "P2: The ${target}th number spoken will be $num.\n";

sub get_num {
	my $nums = shift;
	my $target = shift;

	my %history = ( 'last' => {}, 'beforelast' => {} );
	my @starter = @$nums;
	
	my $turn = 1;
	my $this_num = -1;
	while ($turn <= $target) {
		my $last_num = $this_num;
		if (scalar(@starter)) {
			$this_num = shift @starter;
		} elsif (exists $history{'beforelast'}{$last_num}) {
			$this_num = $history{'last'}{$last_num} - $history{'beforelast'}{$last_num};
		} else {
			$this_num = 0;
		}
		$history{'beforelast'}{$this_num} = $history{'last'}{$this_num} if (exists $history{'last'}{$this_num});
		$history{'last'}{$this_num} = $turn++;
	}
	return $this_num;
}


__DATA__
