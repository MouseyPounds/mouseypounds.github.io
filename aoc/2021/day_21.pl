#!/bin/perl -w
#
# https://adventofcode.com/2021/day/21
#

use strict;

print "2021 Day 21\n";
my $input = do { local $/; <DATA> }; # slurp it
my %player = ();
foreach my $line (split("\n", $input)) {
	my @n = $line =~ /(\d+)/g;
	$player{$n[0]} = { 'pos' => $n[1], 'score' => 0 };
}
my %dirac = ( "$player{1}{'pos'},$player{1}{'score'},$player{2}{'pos'},$player{2}{'score'}" => 1 );

my $turn = 0;
my $die = 0;
my $rolls = 0;
LOOP: while (1) {
	$turn++;
	foreach my $p (1 .. 2) {
		my $roll = roll_dice($turn, \$die); $rolls += 3;
		$player{$p}{'pos'} = ($player{$p}{'pos'} + $roll) % 10;
		$player{$p}{'pos'} = 10 if ($player{$p}{'pos'} == 0);
		$player{$p}{'score'} += $player{$p}{'pos'};
		#print "Turn $turn, Player $p rolled $roll and moved to $player{$p}{'pos'}; score is now $player{$p}{'score'}\n";
		
		if ($player{$p}{'score'} >= 1000) {
			my $score = $rolls * ( $p == 1 ? $player{2}{'score'} : $player{1}{'score'} );
			print "Player $p wins on turn $turn with $rolls total dice rolls! Game score is $score\n";
			last LOOP;
		}
	}
}

# With Dirac dice, every roll triple has 27 different possibilities with 7 unique sums
my %rolls = ( 3=>1, 4=>3, 5=>6, 6=>7, 7=>6, 8=>3, 9=>1 );
#my %rolls = ( 6=>7 );
my %wins = ( 1=>0, 2=>0 );
LOOP: while (scalar(keys %dirac)) {
	my @add = ();
	#print "=============================\nNew turn with ", scalar(keys %dirac), " game states\n";
	foreach my $d (keys %dirac) {
		my $count = delete $dirac{$d};
		my @n = split(',', $d);
		# Player 1 first
		foreach my $r (keys %rolls) {
			my $pos = ($n[0] + $r) % 10;
			$pos = 10 if ($pos == 0);
			my $score = $n[1] + $pos;
			if ($score >= 21) {
				$wins{1} += $count*$rolls{$r};
			} else {
				# Now Player 2
				foreach my $r2 (keys %rolls) {
					my $pos2 = ($n[2] + $r2) % 10;
					$pos2 = 10 if ($pos2 == 0);
					my $score2 = $n[3] + $pos2;
					if ($score2 >= 21) {
						$wins{2} += $count*$rolls{$r}*$rolls{$r2};
					} else {
						push @add, { 'k' => "$pos,$score,$pos2,$score2", 'v' => $count*$rolls{$r}*$rolls{$r2} };
					}
				}
			}
		}
	}
	foreach my $new (@add) {
		$dirac{$new->{'k'}} = 0 if (not exists $dirac{$new->{'k'}});
		$dirac{$new->{'k'}} += $new->{'v'};
		#print "New game state $new->{'k'} ($dirac{$new->{'k'}})\n";
	}
}
print "Part 2: Player 1 won $wins{1} and Player 2 won $wins{2}\n";

sub roll_dice {
	my $turn = shift;
	my $die_pos = shift;
	my $roll = 0;
	
	#print "Rolling on turn $turn; starting die is $$die_pos...";
	foreach my $d (0 .. 2) {
		$$die_pos++;
		$$die_pos -= 100 if ($$die_pos > 100);
		$roll += $$die_pos;
	}
	#print "rolled $roll\n";
	return $roll;
}

# mine is 3 7
__DATA__
Player 1 starting position: 3
Player 2 starting position: 7