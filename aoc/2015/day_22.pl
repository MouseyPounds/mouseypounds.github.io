#!/bin/perl -w
#
# https://adventofcode.com/2015/day/22
#

use strict;
use POSIX;
use List::Util qw(max min);
use Storable qw(dclone);

my $debugging = 0;

$| = 1;

print "2015 Day 22\n";
my %boss = ();
while (<DATA>) {
	chomp;
	(my ($stat, $val)) = split(': ');
	$boss{$stat} = $val;
}

my %player = (
	"Hit Points" => 50,
	"Mana" => 500,
	"Spells" => {
		"Magic Missile" => { 'Cost' => 53, 'Damage' => 4, 'Heal' => 0, 'HasEffect' => 0 },
		"Drain" => { 'Cost' => 73, 'Damage' => 2, 'Heal' => 2, 'HasEffect' => 0 },
		"Shield" => { 'Cost' => 113, 'Damage' => 0, 'Heal' => 0, 'HasEffect' => 1 },
		"Poison" => { 'Cost' => 173, 'Damage' => 0, 'Heal' => 0, 'HasEffect' => 1 },
		"Recharge" => { 'Cost' => 229, 'Damage' => 0, 'Heal' => 0, 'HasEffect' => 1 },
	},
	"Effects" => {
		"Shield" => { 'Turns' => 6, 'Damage' => 0, 'Armor' => 7, 'Mana' => 0 },
		"Poison" => { 'Turns' => 6, 'Damage' => 3, 'Armor' => 0, 'Mana' => 0 },
		"Recharge" => { 'Turns' => 5, 'Damage' => 0, 'Armor' => 0, 'Mana' => 101 },
	},
);

print "\nPart 1 (normal mode):\n";
my $results = sim_battle(\%player, \%boss);
print "P1: Lowest mana spent on a win was $results->{'best_win'}\n";

print "\nPart 2 (hard mode):\n";
$results = sim_battle(\%player, \%boss, 1);
print "P2: Lowest mana spent on a win was $results->{'best_win'}\n";

# When a battle is decided, the result is given as the amount of mana spent.
# We will gather these values into a pair of arrays and then return a reference to the hash containing them.
sub sim_battle {
	my $p = shift;
	my $b = shift;
	my $hm= shift;
	my $status = shift;
	my $results = shift;
	
	$hm = 0 unless (defined $hm);
	$results = { 'win' => 0, 'loss' => 0, 'best_win' => 9e5 } unless (defined $results);
	
	unless (defined $status) {
		$status = {
			'PlayerHP' => $p->{'Hit Points'},
			'PlayerMana' => $p->{'Mana'},
			'PlayerArmor' => 0,
			'BossHP' => $b->{'Hit Points'},
			'Turn' => 0,
			'ActiveEffects' => {},
			'PlayerActions' => [],
			'ManaSpent' => 0,
		};
	}
	
	# If there is an action queued, do it. There should always be unless this is the very first turn.
	if (scalar(@{$status->{'PlayerActions'}})) {
		# Beginning of Player turn
		$status->{'Turn'}++;
		printf "[%6d] Battling on turn %3d  \r", $results->{'best_win'}, $status->{'Turn'};
		dump_status($status, "Start of Player Turn") if $debugging;
		if ($hm) {
			$status->{'PlayerHP'}--;
			return add_result('loss', $results, $status->{'ManaSpent'}, "hardmode damage loss") if ($status->{'PlayerHP'} <= 0);
		}
		return add_result('win', $results, $status->{'ManaSpent'}, "DoT spell effect") if (apply_effects($p, $status));
		my $action = shift @{$status->{'PlayerActions'}};
		return add_result('loss', $results, $status->{'ManaSpent'}, "overspending mana") 
			if ($status->{'PlayerMana'} < $p->{'Spells'}{$action}{'Cost'});
		$status->{'PlayerMana'} -= $p->{'Spells'}{$action}{'Cost'};
		$status->{'ManaSpent'} += $p->{'Spells'}{$action}{'Cost'};
		$status->{'BossHP'} -= $p->{'Spells'}{$action}{'Damage'};
		return add_result('win', $results, $status->{'ManaSpent'}, "direct damage") if ($status->{'BossHP'} <= 0);
		$status->{'PlayerHP'} += $p->{'Spells'}{$action}{'Heal'};
		if ($p->{'Spells'}{$action}{'HasEffect'}) {
			$status->{'ActiveEffects'}{$action} = $p->{'Effects'}{$action}{'Turns'};
			$status->{'PlayerArmor'} += $p->{'Effects'}{$action}{'Armor'};
		}
		dump_status($status, "Player casts $action") if $debugging;
		# Beginning of Boss turn
		$status->{'Turn'}++;
		dump_status($status, "Start of Boss Turn") if $debugging;
		return add_result('win', $results, $status->{'ManaSpent'}, "DoT spell effect") if (apply_effects($p, $status));
		my $damage = max(1, $b->{'Damage'} - $status->{'PlayerArmor'});
		$status->{'PlayerHP'} -= $damage;
		dump_status($status, "Boss attacks for $damage") if $debugging;
		return add_result('loss', $results, $status->{'ManaSpent'}, "direct damage") if ($status->{'PlayerHP'} <= 0);
	}
	# Now we get ready for the next set of turns. Since we are doing this recursively we need to deep copy the status
	# If there is still an action queued, we must be in debug testing so just follow through.
	if (scalar(@{$status->{'PlayerActions'}})) {
		my %new_status = %{dclone($status)};
		sim_battle($p, $b, $hm, \%new_status, $results);
	} else {
	# Otherwise, we iterate over all player spells. We will avoid casting anything that will still have an active effect,
	# but we don't worry about mana cost since overspending will be handled as a loss in the main turn processing.
	# We also only continue if we can get a better win.
		if ($status->{'ManaSpent'} < $results->{'best_win'}) {
			foreach my $s (keys %{$p->{'Spells'}}) {
				next if (exists $status->{'ActiveEffects'}{$s} and $status->{'ActiveEffects'}{$s} > 1);
				my %new_status = %{dclone($status)};
				push @{$new_status{'PlayerActions'}}, $s;
				sim_battle($p, $b, $hm, \%new_status, $results);
			}
		}
	}
	return $results;
}

sub apply_effects {
	my $p = shift; # needed for effect definitions
	my $status = shift;
	
	foreach my $k (keys %{$status->{'ActiveEffects'}}) {
		$status->{'BossHP'} -= $p->{'Effects'}{$k}{'Damage'};
		$status->{'PlayerMana'} += $p->{'Effects'}{$k}{'Mana'};
		$status->{'ActiveEffects'}{$k}--;
		if ($status->{'ActiveEffects'}{$k} <= 0) {
			$status->{'PlayerArmor'} -= $p->{'Effects'}{$k}{'Armor'};
			delete $status->{'ActiveEffects'}{$k};
		}
	}
	return ($status->{'BossHP'} <= 0);
}

# Wrapper for winning and losing which shortens the main battle loop a little.
sub add_result {
	my $decision = shift;
	my $results = shift;
	my $mana = shift;
	my $desc = shift;

	print "Battle ended in $decision ($mana mana) due to $desc.\n" if $debugging;
	$results->{$decision}++;
	$results->{'best_win'} = $mana if ($decision eq 'win' and $mana < $results->{'best_win'});
	
	return $results;
}

sub dump_status {
	my $status = shift;
	my $desc = shift;
	
	print "[$status->{'Turn'}] $desc\n";
	print "- Player $status->{'PlayerHP'} hp / $status->{'PlayerMana'} mp ($status->{'PlayerArmor'} def); Boss $status->{'BossHP'} hp\n";
	print "- Active Effects: (" . join(', ', map {"$_ ($status->{'ActiveEffects'}{$_})"} keys %{$status->{'ActiveEffects'}}) . ")\n";
	print "\n";
}

__DATA__
Hit Points: 55
Damage: 8