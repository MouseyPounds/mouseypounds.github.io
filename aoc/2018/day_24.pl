#!/bin/perl -w
#
# https://adventofcode.com/2018/day/24

use strict;
use POSIX;
use List::Util qw(max);

my $debugging = 0;

print "2018 Day 24\n\n";
my $puzzle = do { local $/; <DATA> }; # slurp it
my @lines = split("\n", $puzzle);

my (%army, %count);
(my ($winner, $left, $boost)) = run_sim();
print "P1: The winning team was $winner with $left remaining units.\n";

($winner, $left, $boost) = run_sim(1);
print "P2: With a boost of $boost, the winning team was $winner with $left remaining units.\n";
exit;

sub run_sim {
	my $boost = shift;
	$boost = 0 unless defined $boost;
	# If there is no boost, we assume we are in part 1 and just run the battle once.
	# If there is a boost, we assume we are in part 2 and continue running battles with increasingly bigger boosts until immune wins.

	while (1) {
		# Initialization
		%army = ( );
		%count = ( 'immune' => 0, 'infected' => 0 );
		my $team = "";
		my $id = 0;
		foreach (@lines) {
			if (/^(I\w+)/) {
				$team = lc $1;
			} elsif (/^(\d+) units .* (\d+) hit points(.*) with .* (\d+) (\w+) damage at initiative (\d+)/) {
				my $entry = { 'units' => $1, 'hp' => $2, 'att_dam' => $4, 'att_type' => $5, 'init' => $6, 'team' => $team };
				$entry->{'att_dam'} += $boost if ($boost and $team eq 'immune');
				$entry->{'power'} = $entry->{'units'} * $entry->{'att_dam'};
				if (length($3) > 1) {
					foreach my $e (split(';', $3)) {
						$e =~ /(\w+) to ([^\)]+)/;
						my $key = $1;
						my @types = split(/,\s*/, $2);
						$entry->{$key} = { map { $_ => undef } @types };
					}
				}
				$army{$id++} = $entry;
				$count{$team}++;
			}
		}

		until ($count{'immune'} == 0 or $count{'infection'} == 0) {
			# Target Selection
			my %picked = ();
			my %attacks = ();
			my @order = sort { $army{$b}{'power'} <=> $army{$a}{'power'} or
				$army{$b}{'init'} <=> $army{$a}{'init'} } keys(%army);
			print "\nTarget selection order: ", join(', ', @order), "\n" if $debugging;
			foreach my $att (@order) {
				print "- Army $att with $army{$att}{'units'} units and $army{$att}{'power'} power" if $debugging;
				my @targets = sort { damage_vs($att, $b) <=> damage_vs($att, $a) or
					$army{$b}{'power'} <=> $army{$a}{'power'} or 
					$army{$b}{'init'} <=> $army{$a}{'init'} }
					grep { $army{$_}{'team'} ne $army{$att}{'team'} } keys(%army);
				foreach my $def (@targets) {
					if ((not exists $picked{$def}) and (damage_vs($att, $def) > 0)) {
						$picked{$def} = undef;
						$attacks{$att} = $def;
						print " will attack army $def" if $debugging;
						last;
					}
				}
				print "\n" if $debugging;
			}
			# Combat
			my $total_damage_done = 0;
			@order = sort { $army{$b}{'init'} <=> $army{$a}{'init'} } keys(%army);
			print "Combat order: ", join(', ', @order), "\n" if $debugging;
			foreach my $att (@order) {
				print "- Army $att (init $army{$att}{'init'})" if $debugging;
				if (exists $attacks{$att}) {
					my $def = $attacks{$att};
					my $damage = POSIX::floor( damage_vs($att,$def) / $army{$def}{'hp'} );
					$total_damage_done += $damage;
					$army{$def}{'units'} = max(0, $army{$def}{'units'} - $damage);
					$army{$def}{'power'} = $army{$def}{'units'} * $army{$def}{'att_dam'};
					print " does $damage damage to army $def, leaving them with $army{$def}{'units'} units and $army{$def}{'power'} power.\n" if $debugging;
				} else {
					print " had no target to attack.\n" if $debugging;
				}
			}
			# Cleanup
			# Failsafe for stalemates: kill all remaining immune system units if nobody did any damage
			foreach my $a (keys %army) {
				if ($army{$a}{'units'} <= 0) {
					print "Army $a was destroyed in battle.\n" if $debugging;
					$count{$army{$a}{'team'}}--;
					delete $army{$a};
				} elsif ($total_damage_done == 0 and $army{$a}{'team'} eq 'immune') {
					print "Stalemate detected, removing army $a.\n" if $debugging;
					$count{$army{$a}{'team'}}--;
					delete $army{$a};				
				}
			}
		}
		my $winner = '';
		my $left = 0;
		foreach my $a (keys %army) {
			$left += $army{$a}{'units'};
			$winner = $army{$a}{'team'};
		}
		return ($winner, $left, $boost) if ( ($winner eq 'immune') or not $boost);
		$boost++;
	}
}

sub damage_vs {
	(my ($att, $def)) = @_;
	my $r = 0;
	unless (exists $army{$def}{'immune'}{$army{$att}{'att_type'}}) {
		if (exists $army{$def}{'weak'}{$army{$att}{'att_type'}}) {
			$r = $army{$att}{'power'}*2;
		} else {
			$r = $army{$att}{'power'};
		}
	}
	return $r;
}

# Example Input
# Immune System:
# 17 units each with 5390 hit points (weak to radiation, bludgeoning) with an attack that does 4507 fire damage at initiative 2
# 989 units each with 1274 hit points (immune to fire; weak to bludgeoning, slashing) with an attack that does 25 slashing damage at initiative 3

# Infection:
# 801 units each with 4706 hit points (weak to radiation) with an attack that does 116 bludgeoning damage at initiative 1
# 4485 units each with 2961 hit points (immune to radiation; weak to fire, cold) with an attack that does 12 slashing damage at initiative 4
__DATA__
Immune System:
1193 units each with 4200 hit points (immune to slashing, radiation, fire) with an attack that does 33 bludgeoning damage at initiative 2
151 units each with 9047 hit points (immune to slashing, cold; weak to fire) with an attack that does 525 slashing damage at initiative 1
218 units each with 4056 hit points (weak to radiation; immune to fire, slashing) with an attack that does 176 fire damage at initiative 9
5066 units each with 4687 hit points (weak to slashing, fire) with an attack that does 8 slashing damage at initiative 8
2023 units each with 5427 hit points (weak to slashing) with an attack that does 22 slashing damage at initiative 3
3427 units each with 5532 hit points (weak to slashing) with an attack that does 15 cold damage at initiative 13
1524 units each with 8584 hit points (immune to fire) with an attack that does 49 fire damage at initiative 7
82 units each with 2975 hit points (weak to cold, fire) with an attack that does 359 bludgeoning damage at initiative 5
5628 units each with 9925 hit points (weak to fire; immune to cold) with an attack that does 17 radiation damage at initiative 11
1410 units each with 9872 hit points (weak to cold; immune to fire) with an attack that does 60 slashing damage at initiative 10

Infection:
5184 units each with 12832 hit points (weak to fire, cold) with an attack that does 4 fire damage at initiative 20
2267 units each with 13159 hit points (weak to fire; immune to bludgeoning) with an attack that does 10 fire damage at initiative 4
3927 units each with 50031 hit points (weak to slashing, cold; immune to fire, radiation) with an attack that does 23 cold damage at initiative 17
9435 units each with 23735 hit points (immune to cold) with an attack that does 4 cold damage at initiative 12
3263 units each with 26487 hit points (weak to fire) with an attack that does 11 fire damage at initiative 14
222 units each with 15916 hit points (weak to fire) with an attack that does 135 fire damage at initiative 18
972 units each with 45332 hit points (weak to bludgeoning, slashing) with an attack that does 86 cold damage at initiative 19
1456 units each with 39583 hit points (immune to radiation; weak to cold, fire) with an attack that does 53 bludgeoning damage at initiative 16
2813 units each with 28251 hit points with an attack that does 17 cold damage at initiative 15
1179 units each with 42431 hit points (immune to fire, slashing) with an attack that does 55 fire damage at initiative 6
