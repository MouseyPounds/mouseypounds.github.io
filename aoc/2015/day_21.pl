#!/bin/perl -w
#
# https://adventofcode.com/2015/day/21
#

use strict;
use POSIX;
use List::Util qw(max);

my $debugging = 0;

$| = 1;

print "2015 Day 21\n";
my %boss = ();
while (<DATA>) {
	chomp;
	(my ($stat, $val)) = split(': ');
	$boss{$stat} = $val;
}

# Hardcoding shop data and adding placeholders for optional gear
my %shop = (
	"Weapons" => [
		{ 'Name' => "Dagger", 'Cost' => 8, 'Damage' => 4, 'Armor' => 0 },
		{ 'Name' => "Shortsword", 'Cost' => 10, 'Damage' => 5, 'Armor' => 0 },
		{ 'Name' => "Warhammer", 'Cost' => 25, 'Damage' => 6, 'Armor' => 0 },
		{ 'Name' => "Longsword", 'Cost' => 40, 'Damage' => 7, 'Armor' => 0 },
		{ 'Name' => "Greataxe", 'Cost' => 74, 'Damage' => 8, 'Armor' => 0 },
	],
	"Armor" => [
		{ 'Name' => "None", 'Cost' => 0, 'Damage' => 0, 'Armor' => 0 },
		{ 'Name' => "Leather", 'Cost' => 13, 'Damage' => 0, 'Armor' => 1 },
		{ 'Name' => "Chainmail", 'Cost' => 31, 'Damage' => 0, 'Armor' => 2 },
		{ 'Name' => "Splintmail", 'Cost' => 53, 'Damage' => 0, 'Armor' => 3 },
		{ 'Name' => "Bandedmail", 'Cost' => 75, 'Damage' => 0, 'Armor' => 4 },
		{ 'Name' => "Platemail", 'Cost' => 102, 'Damage' => 0, 'Armor' => 5 },
	],
	"Rings" => [
		{ 'Name' => "None", 'Cost' => 0, 'Damage' => 0, 'Armor' => 0 },
		{ 'Name' => "None", 'Cost' => 0, 'Damage' => 0, 'Armor' => 0 },
		{ 'Name' => "Damage +1", 'Cost' => 25, 'Damage' => 1, 'Armor' => 0 },
		{ 'Name' => "Damage +2", 'Cost' => 50, 'Damage' => 2, 'Armor' => 0 },
		{ 'Name' => "Damage +3", 'Cost' => 100, 'Damage' => 3, 'Armor' => 0 },
		{ 'Name' => "Defense +1", 'Cost' => 20, 'Damage' => 0, 'Armor' => 1 },
		{ 'Name' => "Defense +2", 'Cost' => 40, 'Damage' => 0, 'Armor' => 2 },
		{ 'Name' => "Defense +3", 'Cost' => 80, 'Damage' => 0, 'Armor' => 3 },
	],
);	
my %player = (
	"Hit Points" => 100,
	"Damage" => 0,
	"Armor" => 0,
	"Spent" => 0,
);

my $min_spent = 1e9;
my $win_gear = "";
my $max_spent = 0;
my $loss_gear = "";
my $win = 0;
my $loss = 0;
for (my $w = 0; $w <= $#{$shop{'Weapons'}}; $w++) {
	for (my $a = 0; $a <= $#{$shop{'Armor'}}; $a++) {
		for (my $r = 0; $r < $#{$shop{'Rings'}}; $r++) {
			for (my $r2 = $r + 1; $r2 <= $#{$shop{'Rings'}}; $r2++) {
				$player{"Damage"} = $shop{'Weapons'}[$w]{'Damage'} + $shop{'Rings'}[$r]{'Damage'} + $shop{'Rings'}[$r2]{'Damage'};
				$player{"Armor"} = $shop{'Armor'}[$a]{'Armor'} + $shop{'Rings'}[$r]{'Armor'} + $shop{'Rings'}[$r2]{'Armor'};
				$player{"Spent"} = $shop{'Weapons'}[$w]{'Cost'} + $shop{'Armor'}[$a]{'Cost'} + $shop{'Rings'}[$r]{'Cost'} + $shop{'Rings'}[$r2]{'Cost'};
				if (sim_battle(\%player, \%boss)) {
					if ($player{"Spent"} < $min_spent) {
						$min_spent = $player{"Spent"};
						$win_gear = "$shop{'Weapons'}[$w]{'Name'}, $shop{'Armor'}[$a]{'Name'}, $shop{'Rings'}[$r]{'Name'}, $shop{'Rings'}[$r2]{'Name'}";
					}
					$win++;
				} else {
					if ($player{"Spent"} > $max_spent) {
						$max_spent = $player{"Spent"};
						$loss_gear = "$shop{'Weapons'}[$w]{'Name'}, $shop{'Armor'}[$a]{'Name'}, $shop{'Rings'}[$r]{'Name'}, $shop{'Rings'}[$r2]{'Name'}";
					}
					$loss++;
				}
			}
		}
	}
}
print "\nPlayer won $win and lost $loss.\n";
print "P1: Lowest gold spent on a win was $min_spent for: $win_gear\n";
print "P2: Highest gold spent on a loss was $max_spent for: $loss_gear\n";


sub sim_battle {
	my $p = shift;
	my $b = shift;
	
	# Because we are going to sim this over and over, we are using a secondary HP stat
	$p->{'HP'} = $p->{'Hit Points'};
	$b->{'HP'} = $b->{'Hit Points'};

	my $turn = 1;
	print "Battle begins! Player ($p->{'HP'}/$p->{'Damage'}/$p->{'Armor'}) vs Boss ($b->{'HP'}/$b->{'Damage'}/$b->{'Armor'})\n" if $debugging;
	while ($p->{'HP'} > 0 and $b->{'HP'} > 0) {
		if ($turn % 2 == 1) {
			$b->{'HP'} -= max(1, $p->{'Damage'} - $b->{'Armor'});
		} else {
			$p->{'HP'} -= max(1, $b->{'Damage'} - $p->{'Armor'});
		}
		print "[$turn] Player ($p->{'HP'}) vs Boss ($b->{'HP'})\n" if $debugging;
		$turn++;
	}
	return ($p->{'HP'} > 0);
}

__DATA__
Hit Points: 109
Damage: 8
Armor: 2