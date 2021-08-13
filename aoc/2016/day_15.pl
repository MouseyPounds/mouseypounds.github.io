#!/bin/perl -w
#
# https://adventofcode.com/2016/day/15
#
# Note, this is pretty much a Chinese Remainder Theorem problem with m = disc_size and a = (0 - disc_num - disc_start)
# But we are going to do it algorithmically by noting that once we are in synch with the first disc, any time increment
# equal to its disc size will keep it aligned, and the increments will multiply as we go. This all works nicely because
# the discs all have prime number sizes (not stated in problem but noticed in input.)

use strict;
use POSIX;

print "2016 Day 15\n";
my $puzzle = do { local $/; <DATA> }; # slurp it
my @lines = split("\n", $puzzle);

my $time = play_game(\@lines);
print "\nP1 solution: The earliest time that will allow a capsule to fall through is $time.\n";
print "(This means waiting for " . convert_seconds($time) . ".)\n";

push @lines, "Disc #7 has 11 positions; at time=0, it is at position 0.";
$time = play_game(\@lines);
print "\nP2 solution: The earliest time that will allow a capsule to fall through is $time.\n";
print "(This means waiting for " . convert_seconds($time) . ".)\n";


sub play_game {
	my $disc = shift;
	
	my $time = 0;
	my $increment = 1;
	for (my $i = 0; $i <= $#$disc; $i++) {
		(my ($id, $size, $time_offset, $start_pos)) = $disc->[$i] =~ 
			/Disc #(\d+) has (\d+) positions; at time=(\d+), it is at position (\d+)./;
		$time += $increment while ( ($start_pos + $time + $id - $time_offset) % $size );
		$increment *= $size;
	}
	return $time;
}

# simplistic conversion because we were curious how long this results actually represent
sub convert_seconds {
	my $sec = shift;
	my @units = qw(sec min hr d wk);
	my @n = (1, 60, 60, 24, 7);
	
	my @out = ();
	for (my $i = $#n; $i >= 0; $i--) {
		my $div = 1; 
		map { $div *= $n[$_] } (0 .. $i);
		my $q = POSIX::floor($sec/$div);
		push @out, sprintf("%d %s", $q, $units[$i]) if $q;
		$sec -= $q*$div;
	}
	return join(", ", @out);
}

__DATA__
Disc #1 has 17 positions; at time=0, it is at position 1.
Disc #2 has 7 positions; at time=0, it is at position 0.
Disc #3 has 19 positions; at time=0, it is at position 2.
Disc #4 has 5 positions; at time=0, it is at position 0.
Disc #5 has 3 positions; at time=0, it is at position 0.
Disc #6 has 13 positions; at time=0, it is at position 5.