#!/bin/perl -w
#
# https://adventofcode.com/2015/day/14
#

use strict;
use POSIX;

my $debugging = 0;

my %reindeer = ();
while (<DATA>) {
	chomp;
	my ($deer, $speed, $time, $rest) = /^(\w+) can fly (\d+) km.s for (\d+) seconds?, but then must rest for (\d+) seconds?\.$/;

	$reindeer{$deer} = { 'speed' => $speed, 'time' => $time, 'rest' => $rest, };
}

print "2015 Day 14\n";

my $race_length = 2503;
run_race(\%reindeer, $race_length);
my ($winner, $amt) = get_leader(\%reindeer, 'dist');
print "\nP1: after $race_length seconds, the winning reindeer is $winner at a distance of $amt km.\n";

($winner, $amt) = get_leader(\%reindeer, 'score');
print "\nP2: after $race_length seconds, the winning reindeer is $winner with a score of $amt points.\n";

sub setup_race {
	my $racers = shift;
	foreach my $r (keys %$racers) {
		$racers->{$r}{'is_running'} = 1;
		$racers->{$r}{'time_left'} = $racers->{$r}{'time'};
		$racers->{$r}{'dist'} = 0;
		$racers->{$r}{'score'} = 0;
	}
}

sub run_race {
	my $racers = shift;
	my $race_length = shift;
	
	setup_race($racers);
	
	my $max_dist = 0;
	for (my $timer = 1; $timer <= $race_length; $timer++) {
		foreach my $r (keys %$racers) {
			if ($racers->{$r}{'is_running'}) {
				$racers->{$r}{'dist'} += $racers->{$r}{'speed'};
				$max_dist = $racers->{$r}{'dist'} if ($racers->{$r}{'dist'} > $max_dist);
			}
			$racers->{$r}{'time_left'}--;
			if ($racers->{$r}{'time_left'} <= 0) {
				$racers->{$r}{'is_running'} = abs($racers->{$r}{'is_running'} - 1);
				$racers->{$r}{'time_left'} = $racers->{$r}{'is_running'} ? $racers->{$r}{'time'} : $racers->{$r}{'rest'};
			}
		}
		foreach my $r (keys %$racers) {	$racers->{$r}{'score'}++ if ($racers->{$r}{'dist'} == $max_dist); }
	}
}

# This does not account for ties
sub get_leader {
	my $racers = shift;
	my $stat = shift;

	my $max = 0;
	my $leader = "";
	foreach my $r (keys %$racers) {
		if ($racers->{$r}{$stat} > $max) {
			$max = $racers->{$r}{$stat};
			$leader = $r;
		}
	}
	return ($leader, $racers->{$leader}{$stat});
}

__DATA__
Vixen can fly 8 km/s for 8 seconds, but then must rest for 53 seconds.
Blitzen can fly 13 km/s for 4 seconds, but then must rest for 49 seconds.
Rudolph can fly 20 km/s for 7 seconds, but then must rest for 132 seconds.
Cupid can fly 12 km/s for 4 seconds, but then must rest for 43 seconds.
Donner can fly 9 km/s for 5 seconds, but then must rest for 38 seconds.
Dasher can fly 10 km/s for 4 seconds, but then must rest for 37 seconds.
Comet can fly 3 km/s for 37 seconds, but then must rest for 76 seconds.
Prancer can fly 9 km/s for 12 seconds, but then must rest for 97 seconds.
Dancer can fly 37 km/s for 1 seconds, but then must rest for 36 seconds.