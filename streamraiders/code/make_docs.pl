#!/bin/perl -w
#
# make_docs.pl
#
# processing a large JSON data file from Stream Raiders to create summary web pages

use strict;
#use JSON::Relaxed qw(from_rjson);
use JSON;
use File::Slurp qw(read_file);
#use Scalar::Util qw(looks_like_number);
#use POSIX qw(ceil floor);
#use List::Util qw(min max);
#use Storable;
#use Math::Round;
use Data::Dumper;
#use Imager;
use HTML::Entities;
#use Text::Autoformat;

# Read data from file identified by first cmd line arg
my $DataFile = shift @ARGV;
die "Can't read data file. Make sure to pass filename as argument.\n$!" if (not defined $DataFile or not -e $DataFile);
my $GameData = ParseJsonFile($DataFile);

# Some configs
my $DocBase = "..";
my $HidePower = 1;

my %Units = ();
my %Power = ();
GatherUnitData();

WriteMainIndex();
WriteUnitSummaryViewer();
WriteUnitSummaryCaptain();
WritePowerSummaryViewer();
WritePowerSummaryCaptain();
#WriteCSS();

#print STDOUT Dumper(%Power);

exit;

# ParseJsonFile - Small wrapper to file slurping and JSON parsing.
#    filename
sub ParseJsonFile {
	my $filename = shift;
	my $file_contents = 
	return decode_json read_file($filename, {binmode => ':encoding(UTF-8)'});
}

# AddCommas - Adds appropriate commas to a number as thousands separators
#  This is the `commify` function from O'Reilly's Perl Cookbook by Nathan Torkington and Tom Christiansen
#  See https://www.oreilly.com/library/view/perl-cookbook/1565922433/ch02s18.html
sub AddCommas {
	my $text = reverse $_[0];
    $text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
    return scalar reverse $text;
}

# Wikify: Conversion of a javascript function from Stardew Checkup that adds a wiki link for something.
#   item name
#   page name [optional] - used when the item is just an anchor on another page rather than having its own page
#
sub Wikify {
	my $item = shift;
	my $page = shift;
	my $trimmed = $item;
	$trimmed =~ s/ /_/g;

	if (defined $page) {
		return qq(<a href="http://streamraiders.fandom.com/wiki/$page#$trimmed">$item</a>);
	} else {
		return qq(<a href="http://streamraiders.fandom.com/wiki/$trimmed">$item</a>);
	}
}

# StripHTML: Overly simplistic method of removing HTML tags from a string.
# This is a terrible implementation for general use and some sort of package like HTML::Strip should be used
#  for those cases, however since we are only using it to strip simple wiki links or spans that we ourselves
#  created, we can get away with this non-robust method.
sub StripHTML {
	my $input = shift;
	$input =~ s/\<[^>]*>//g;
	return $input;
}

# GetHeader - creates and returns HTML code for top of pages
#
#   subtitle - string to put in top header and title
#   shortdesc - [optional] short description for social media embeds
#   longdesc - [optional] any additonal info to include in top panel
sub GetHeader {
	my $subtitle = shift;
	my $shortdesc = shift;
	if (not defined $shortdesc or $shortdesc eq '') {
		$shortdesc = "Datamined info for the Stream Raiders game.";
	}
	my $longdesc = shift;
	if (not defined $longdesc) {
		$longdesc = "";
	}
	
	my $output = <<"END_PRINT";
<!DOCTYPE html>
<html>
<head>
<title>Mousey's Stream Raiders Datamine: $subtitle</title>

<meta charset="UTF-8" />
<meta property="og:title" content="Stream Raiders Datamine: $subtitle" />
<meta property="og:description" content="$shortdesc" />
<!-- meta property="og:image" content="https://mouseypounds.github.io/stardew-checkup/og-embed-image.png" / -->
<!-- meta property="twitter:image" content="https://mouseypounds.github.io/stardew-checkup/og-embed-image.png" / -->
<meta name="theme-color" content="#44ffff">
<meta name="author" content="MouseyPounds" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />

<link rel="stylesheet" type="text/css" href="./sr.css" />
<!-- link rel="stylesheet" type="text/css" href="./sr-img.css" / -->
<link rel="icon" type="image/png" href="./StreamCaptainLogoDark.png" />

<!-- Table sorting by https://www.kryogenix.org/code/browser/sorttable/ -->
<!-- script type="text/javascript" src="./sorttable.js"></script -->
<script type="text/javascript" src="./sr_scripts.js"></script>

</head>
<body>
<div class="panel" id="header"><h1>Mousey's Stream Raiders Datamine: $subtitle</h1>
$longdesc
</div>
END_PRINT

	return $output;
}

# GetTOCStart - creates and returns HTML code for beginning of TOC
sub GetTOCStart {
	my $output = <<"END_PRINT";
<div id="TOC">
<h1>Navigation</h1>
<div id="TOC-details">
<ul>
<li><a href="#header">(Top)</a></li>
END_PRINT

	return $output;
}

# GetTOCEnd - creates and returns HTML code for end of TOC
sub GetTOCEnd {
	my $output = <<"END_PRINT";
</ul>
</div>
</div>
END_PRINT

	return $output;
}

# GetFooter - creates and returns HTML code for bottom of pages
sub GetFooter {
	my $output = <<"END_PRINT";
<div id="footer" class="panel">
Stream Raiders Datamine:
<a href="./index.html">Main Index</a> ||
<a href="./captain_units.html">Captain Units</a> || 
<a href="./captain_power.html">Captain Power</a> || 
<a href="./viewer_units.html">Viewer Units</a> || 
<a href="./viewer_power.html">Viewer Power</a>
<br />
Other Stream Raiders resources: <a href="http://www.streamcaptain.com/streamraiders/">Website</a> || 
<a href="https://streamraiders.fandom.com/wiki/Stream_Raiders_Wiki">Wiki</a> || 
<a href="https://discordapp.com/invite/SJF2Eef">Discord</a>
</div>
</body>
</html>
END_PRINT

	return $output;
}

# GatherUnitData - extracts unit info from base game data into some more manageable structures
sub GatherUnitData {
	my @FieldsToCopy_Global = qw(DisplayName Rarity Role WeakAgainstTagsList StrongAgainstTagsList TargetPriorityTagsList TargetingPriorityRange UnitTargetingType TargetTeam);
	my @FieldsToCopy_PerLevel = qw(AttackRate Damage HP Heal Power Range Speed UpgradeCost UpgradeCostGold SpecialAbilityDescription SpecialAbilityRate StartBuffsList);
	my %monsters = ();
	foreach my $k (keys %{$GameData->{'sheets'}{'Units'}}) {
		$k =~ /(\w+\D)\d+$/;
		my $name = $1;
		$name =~ s/^epic//;
		$name =~ s/^captain//;
		$name =~ s/^allies//;
		my $u = $GameData->{'sheets'}{'Units'}{$k};
		
		if (defined $u->{'TagsList'} and $u->{'TagsList'} =~ /monster/i) {
			$monsters{$u->{'DisplayName'}} = 1;
		}
		
		next unless ($u->{'CanBePlaced'});
		
		my $type = $u->{'IsEpic'} ? "Epic" : "Normal";
		$type = "Captain" if ($u->{'PlacementType'} eq 'captain');
		
		if (not exists $Units{$name}) {
			$Units{$name} = {};
			foreach my $f (@FieldsToCopy_Global) {
				$Units{$name}{$f} = $u->{$f};
			}
			$Units{$name}{'_CanHeal'} = 0;
			$Units{$name}{'WeakAgainstTagsList'} = "None" if ($u->{'WeakAgainstTagsList'} eq '');
			$Units{$name}{'StrongAgainstTagsList'} = "None" if ($u->{'StrongAgainstTagsList'} eq '');
			$Units{$name}{'TargetPriorityTagsList'} = "None" if ($u->{'TargetPriorityTagsList'} eq '');
		}

		# Fix Display Name to remove 'Epic '
		$Units{$name}{'DisplayName'} =~ s/Epic //;
		
		# Description only listed for level 30 to have consistent milestone message
		# We don't use StripHTML here because we also want to remove the text between the tags
		my $lvl = $u->{'Level'};
		if ($lvl == 30) {
			$Units{$name}{'Description'} = $u->{'Description'};
			$Units{$name}{'Description'} =~ s| ?<color.*/color>$||i;
		}
		foreach my $f (@FieldsToCopy_PerLevel) {
			$Units{$name}{$type}{$lvl}{$f} = $u->{$f};
		}
		$Units{$name}{'_CanHeal'} = 1 if ($u->{'Heal'} > 0);
		if ($lvl == 1) {
			$Units{$name}{$type}{$lvl}{'UpgradeCost'} = $u->{'UnlockCost'};
			$Units{$name}{$type}{$lvl}{'UpgradeCostGold'} = $u->{'UnlockCostGold'};
		}
		
		# Gather power
		my $p = $Units{$name}{$type}{$lvl}{'Power'};
		if (not exists $Power{'individual'}{$type}{$p}) {
			$Power{'individual'}{$type}{$p} = [];
		}
		push @{$Power{'individual'}{$type}{$p}}, qq[<span class="unit_$name">$Units{$name}{'DisplayName'} (Lvl $lvl)</span>];
		if (not exists $Power{'total'}{$type}{$Units{$name}{'DisplayName'}}) {
			$Power{'total'}{$type}{$Units{$name}{'DisplayName'}} = 0;
		}
		$Power{'total'}{$type}{$Units{$name}{'DisplayName'}} += $p;
	}
	#print STDOUT "Monsters: " . join(", ", (sort keys %monsters)) . "\n";
}

# TranslateBuff - Turns a buff ID into a more human-readable string
sub TranslateBuff {
	my $buffID = shift;
	
	return $buffID;
}

###################################################################################################
# WriteMainIndex - index page generation
sub WriteMainIndex {
	my $FH;
	open $FH, ">$DocBase/index.html" or die "Can't open index.html for writing: $!";
	select $FH;

	print STDOUT "Generating Main Index\n";
	my $longdesc = <<"END_PRINT";
<p>Welcome to my personal collection of datamined info for the Stream Raiders game. Although all datamined info should be taken with a
grain of salt, this is especially true for a game like Stream Raiders which is still in beta and undergoing frequent updates.</p>
<p>Most images are from the Stream Captains external assets share. Data was collected from cached browser files for the web client from a viewer account. The export timestamp for the data used is $GameData->{'exportDate'} PDT.</p>
<p>If you have any suggestions for improvement or bugs to report, please contact me at <span class="username">MouseyPounds#0557</span>
on <a href="https://discordapp.com">Discord</a></p>
<h2>Page Directory</h2>
<ul>
<li><a href="./captain_units.html">Captain Units</a> - Unit stats for troops placed by captains.</li>
<li><a href="./captain_power.html">Captain Power</a> - Power rankings for captain troops (mainly useful for PvP events)</li>
<li><a href="./viewer_units.html">Viewer Units</a> - Unit stats for troops placed by viewers.</li>
<li><a href="./viewer_power.html">Viewer Power</a> - Power rankings for viewer troops (mainly useful for PvP events)</li>
</ul>
END_PRINT

	print GetHeader("Main Index", qq(Datamined info for Stream Raiders game.), $longdesc);
	
	my $out = <<"END_PRINT";
<div class="panel" id="upgrade_calc">
<h2>Unit Upgrade Cost Calculator</h2>
<p>This tool calculates the total upgrade cost for a unit; the level range is specified by the selection menus, and the type of unit
is specified by the radio buttons. The calculated cost will be shown in the small <span class="note">Results</span> table just below
the entry fields, and a detailed breakdown of the individual levels with applicable rows <span class="highlight">highlighted</span>
appears in the table below that.</p>
END_PRINT
	
	# Duplicating this to have different defaults on the two menus
	my $options_start = qq(<option value="unlock_initial">Unlock (Initial)</option><option value="unlock_dupe">Unlock (Duplicate)</option>);
	for (my $i = 1; $i <= 30; $i++) {
		my $checked = ($i == 1) ? qq( selected="selected") : "";
		$options_start .= qq(<option value="$i"$checked>$i</option>);
	}
	my $options_end = qq(<option value="unlock_initial">Unlock (Initial)</option><option value="unlock_dupe">Unlock (Duplicate)</option>);
	for (my $i = 1; $i <= 30; $i++) {
		my $checked = ($i == 30) ? qq( selected="selected") : "";
		$options_end .= qq(<option value="$i"$checked>$i</option>);
	}

	$out .= <<"END_PRINT";
<fieldset id="level_set" class="select_set">
<legend>Level Range</legend>
Current Level: <select id="level_start" name="level_start" class="level_select">$options_start</select>
Target Level: <select id="level_end" name="level_end" class="level_select">$options_end</select>
</fieldset>
<fieldset id="filter_acct_options" class="radio_set">
<legend>Account Type</legend>
<label><input class="filter" type="radio" name="filter_acct" value="0" checked="checked"> Viewer</label><br />
<label><input class="filter" type="radio" name="filter_acct" value="4"> Captain</label>
</fieldset>
<fieldset id="filter_rare_options" class="radio_set">
<legend>Unit Rarity</legend>
<label><input class="filter" type="radio" name="filter_rare" value="0" checked="checked"> Non-Legendary</label><br />
<label><input class="filter" type="radio" name="filter_rare" value="2"> Legendary</label>
</fieldset>
<table class="output">
<thead><tr><th>Results</th>
<th class="cost_0">Gold</th><th class="cost_1">Scrolls</th>
<th class="cost_2">Gold</th><th class="cost_3">Scrolls</th>
<th class="cost_4">Gold</th><th class="cost_5">Scrolls</th>
<th class="cost_6">Gold</th><th class="cost_7">Scrolls</th>
</tr></thead><tbody><tr class="highlight"><td class="result_text" id="result_desc">Placeholder</td>
<td class="num cost_0" id="total_0">0</td><td class="num cost_1" id="total_1">0</td>
<td class="num cost_2" id="total_2">0</td><td class="num cost_3" id="total_3">0</td>
<td class="num cost_4" id="total_4">0</td><td class="num cost_5" id="total_5">0</td>
<td class="num cost_6" id="total_6">0</td><td class="num cost_7" id="total_7">0</td>
</tr></tbody></table>
END_PRINT

	# Breaking this up between tables for some commentary. We are going to use 'archer' as the generic non-legendary
	#  unit and mage for legendary, assuming that costs are similar among all non-legendaries and among all legendaries.
	# Also, it seems that dupe unit costs are always 1000/300 regardless of acct type or unit rarity, so we just repeat.

	$out .= <<"END_PRINT";
<table class="output">
<thead>
<tr><th colspan="4">Detailed Breakdown</th></tr>
<tr><th>From</th><th>To</th>
<th class="cost_0">Gold</th><th class="cost_1">Scrolls</th>
<th class="cost_2">Gold</th><th class="cost_3">Scrolls</th>
<th class="cost_4">Gold</th><th class="cost_5">Scrolls</th>
<th class="cost_6">Gold</th><th class="cost_7">Scrolls</th>
</tr></thead><tbody>
<tr id="unlock_initial">
<td class="num" colspan="2">Unlock (Initial)</td>
<td class="num cost_0">$Units{'archer'}{'Normal'}{'1'}{'UpgradeCostGold'}</td>
<td class="num cost_1">$Units{'archer'}{'Normal'}{'1'}{'UpgradeCost'}</td>
<td class="num cost_2">$Units{'mage'}{'Normal'}{'1'}{'UpgradeCostGold'}</td>
<td class="num cost_3">$Units{'mage'}{'Normal'}{'1'}{'UpgradeCost'}</td>
<td class="num cost_4">$Units{'archer'}{'Captain'}{'1'}{'UpgradeCostGold'}</td>
<td class="num cost_5">$Units{'archer'}{'Captain'}{'1'}{'UpgradeCost'}</td>
<td class="num cost_6">$Units{'mage'}{'Captain'}{'1'}{'UpgradeCostGold'}</td>
<td class="num cost_7">$Units{'mage'}{'Captain'}{'1'}{'UpgradeCost'}</td>
</tr>
<tr id="unlock_dupe">
<td class="num" colspan="2">Unlock (Dupe)</td>
<td class="num cost_0">$GameData->{'sheets'}{'UnitDupeCosts'}{'common1'}{'GoldCost'}</td>
<td class="num cost_1">$GameData->{'sheets'}{'UnitDupeCosts'}{'common1'}{'UnitCurrencyCost'}</td>
<td class="num cost_2">$GameData->{'sheets'}{'UnitDupeCosts'}{'legendary1'}{'GoldCost'}</td>
<td class="num cost_3">$GameData->{'sheets'}{'UnitDupeCosts'}{'legendary1'}{'UnitCurrencyCost'}</td>
<td class="num cost_4">$GameData->{'sheets'}{'UnitDupeCosts'}{'common1'}{'GoldCost'}</td>
<td class="num cost_5">$GameData->{'sheets'}{'UnitDupeCosts'}{'common1'}{'UnitCurrencyCost'}</td>
<td class="num cost_6">$GameData->{'sheets'}{'UnitDupeCosts'}{'legendary1'}{'GoldCost'}</td>
<td class="num cost_7">$GameData->{'sheets'}{'UnitDupeCosts'}{'legendary1'}{'UnitCurrencyCost'}</td>
</tr>
END_PRINT

	for (my $i = 2; $i <= 30; $i++) {
		my $prev = $i - 1;
		$out .= <<"END_PRINT";
<tr id="level_$prev">
<td class="num">$prev</td><td class="num">$i</td>
<td class="num cost_0">$Units{'archer'}{'Normal'}{$i}{'UpgradeCostGold'}</td>
<td class="num cost_1">$Units{'archer'}{'Normal'}{$i}{'UpgradeCost'}</td>
<td class="num cost_2">$Units{'mage'}{'Normal'}{$i}{'UpgradeCostGold'}</td>
<td class="num cost_3">$Units{'mage'}{'Normal'}{$i}{'UpgradeCost'}</td>
<td class="num cost_4">$Units{'archer'}{'Captain'}{$i}{'UpgradeCostGold'}</td>
<td class="num cost_5">$Units{'archer'}{'Captain'}{$i}{'UpgradeCost'}</td>
<td class="num cost_6">$Units{'mage'}{'Captain'}{$i}{'UpgradeCostGold'}</td>
<td class="num cost_7">$Units{'mage'}{'Captain'}{$i}{'UpgradeCost'}</td>
</tr>
END_PRINT
	}
	
	$out .= <<"END_PRINT";
</table></div>
END_PRINT

	print $out;
	print GetFooter();
	close $FH or die "Error closing file";
}

###################################################################################################
# WriteUnitSummaryViewer - handles unit summary page for viewers
sub WriteUnitSummaryViewer {
	my $FH;
	open $FH, ">$DocBase/viewer_units.html" or die "Can't open viewer_units.html for writing: $!";
	select $FH;

	print STDOUT "Generating Viewer Unit Summary\n";
	my @Panel = (	);
	
	foreach my $k (sort {$Units{$a}{'DisplayName'} cmp $Units{$b}{'DisplayName'}} keys %Units) {
		my $entry = { 'key' => $Units{$k}{'DisplayName'}, 'name' => $Units{$k}{'DisplayName'}, 'out' => "" };
		$entry->{'key'} =~ s/ /_/g;
		my $heal_head = "";
		my $norm_span = 5;
		my $epic_span = 4;
		if ($Units{$k}{'_CanHeal'}) {
			$heal_head = "<th>Heal</th>";
			$norm_span++;
			$epic_span++;
		}
		my $atk_spd = 1;
		if ($Units{$k}{'Normal'}{'1'}{'AttackRate'} != 0) {
			$atk_spd = sprintf("%0.02f", 1/$Units{$k}{'Normal'}{'1'}{'AttackRate'});
		}
		my $img = lc $Units{$k}{'DisplayName'};
		$img =~ s/ //g;
		$entry->{'out'} = <<"END_PRINT";
<div>
<h2>$Units{$k}{'DisplayName'}</h2>
<img class="unit" src="./img/${img}_walk.gif" alt="Unit Icon" />
$Units{$k}{'Rarity'} $Units{$k}{'Role'} &mdash; $Units{$k}{'Description'}<br />
Strong Against: $Units{$k}{'StrongAgainstTagsList'}<br />
Weak Against: $Units{$k}{'WeakAgainstTagsList'}<br />
Targets $Units{$k}{'TargetTeam'} $Units{$k}{'UnitTargetingType'} within $Units{$k}{'TargetingPriorityRange'} tiles with priority: $Units{$k}{'TargetPriorityTagsList'}
</div>
<div class="stat_table">
<table class="output">
<thead><tr><th rowspan="2">Lvl</th><th rowspan="2">Spd</th><th rowspan="2">Atk<br />Spd</th><th colspan="$norm_span">Normal</th><th colspan="$epic_span">Epic</th><th colspan="2">Upgrade Cost</th></tr>
<tr><th>HP</th><th>Dam</th><th>Rng</th>$heal_head<th>Pow</th><th>Milestone Desc and Actual Buffs</th>
<th>HP</th><th>Dam</th><th>Rng</th>$heal_head<th>Milestone Desc and Actual Buffs</th>
<th>Gold</th><th>Scrolls</th>
</tr></thead><tbody>
END_PRINT

		foreach my $lvl (1 .. 30) {
			my $heal_norm = "";
			my $heal_epic = "";
			my $row_class = "no_hl";
			#if ($lvl == 5 or $lvl == 10 or $lvl == 20 or $lvl == 30) {
			if ($lvl % 5 == 0) {
				$row_class = "highlight";
			}
			if ($Units{$k}{'_CanHeal'}) {
				$heal_norm = qq(<td class="num">$Units{$k}{'Normal'}{$lvl}{'Heal'}</td>);
				$heal_epic = qq(<td class="num">$Units{$k}{'Epic'}{$lvl}{'Heal'}</td>);
			}
			my $mile_norm = qq(<td class="text">$Units{$k}{'Normal'}{$lvl}{'SpecialAbilityDescription'}<br />);
			$mile_norm .= join("<br />", (map {TranslateBuff($_)} split(/,/, $Units{$k}{'Normal'}{$lvl}{'StartBuffsList'})));
			$mile_norm .= "</td>";
			my $mile_epic = qq(<td class="text">$Units{$k}{'Epic'}{$lvl}{'SpecialAbilityDescription'}<br />);
			$mile_epic .= join("<br />", (map {TranslateBuff($_)} split(/,/, $Units{$k}{'Epic'}{$lvl}{'StartBuffsList'})));
			$mile_epic .= "</td>";
			my $power = $HidePower ? "--" : $Units{$k}{'Normal'}{$lvl}{'Power'};
			$entry->{'out'} .= <<"END_PRINT";
<tr class="$row_class"><td class="num">$lvl</td><td class="num">$Units{$k}{'Normal'}{$lvl}{'Speed'}</td><td class="num">$atk_spd</td>
<td class="num">$Units{$k}{'Normal'}{$lvl}{'HP'}</td><td class="num">$Units{$k}{'Normal'}{$lvl}{'Damage'}</td><td class="num">$Units{$k}{'Normal'}{$lvl}{'Range'}</td>$heal_norm<td class="num">$power</td>$mile_norm
<td class="num">$Units{$k}{'Epic'}{$lvl}{'HP'}</td><td class="num">$Units{$k}{'Epic'}{$lvl}{'Damage'}</td><td class="num">$Units{$k}{'Epic'}{$lvl}{'Range'}</td>$heal_epic$mile_epic
<td class="num">$Units{$k}{'Normal'}{$lvl}{'UpgradeCostGold'}</td><td class="num">$Units{$k}{'Normal'}{$lvl}{'UpgradeCost'}</td>
</tr>
END_PRINT
		
		}
		$entry->{'out'} .= "</tbody></table></div>";
		push @Panel, $entry;
	}
	my $power_desc = $HidePower ? qq(<span class="warn">specific power numbers are currently hidden at request of the Stream Captain team</span>) : 
	qq( as the main user interest for power is PvP placement, it is only shown for non-epic units.
For an overall power summary, see the <a href="./viewer_power.html">Viewer Power page</a>.);

	my $longdesc = <<"END_PRINT";
<p>A summary of unit stats as of $GameData->{'exportDate'} PDT. Some notes on this data:</p>
<ul>
<li><span class="note">Milestone Desc</span> is just the text displayed for the milestone ability; actual milestone data and other unit buffs is still a work-in-progress.</li>
<li>Specialization information is not yet included.</li>
<li>The <span class="note">Rng</span> column is attack range, and the <span class="note">Pow</span> column is unit power; $power_desc</li>
<li>Upgrade costs are the costs to get to that level from the previous level (or to initially unlock for level 1).
A cost calculator is included on the <a href="./index.html#upgrade_calc">Main Index page</a>.</li>
<li>A <span class="note">Heal</span> column is displayed for units which can heal allies.</li>
<li>The ground/air targeting information is for normal units only as epics can always target both.</li>
</ul>
END_PRINT

	print GetHeader("Viewer Units", qq(Stats for viewer units in Stream Raiders.), $longdesc);
	print GetTOCStart();

	# Print the rest of the TOC
	foreach my $p (@Panel) {
		my $text = $p->{'name'};
		$text =~ s/ /&nbsp;/g;
		print qq(<li><a href="#TOC_$p->{'key'}">$text</a></li>);
	}
	print GetTOCEnd();
	
	# Print the Panels
	foreach my $p (@Panel) {
		print <<"END_PRINT";
<div class="panel" id="TOC_$p->{'key'}">
$p->{'out'}
</div>
END_PRINT
	}
		
	print GetFooter();
	close $FH or die "Error closing file";
}

###################################################################################################
# WriteUnitSummaryCaptain - handles unit summary page for captains
sub WriteUnitSummaryCaptain {
	my $FH;
	open $FH, ">$DocBase/captain_units.html" or die "Can't open captain_units.html for writing: $!";
	select $FH;

	print STDOUT "Generating Captain Unit Summary\n";
	my @Panel = (	);
	
	foreach my $k (sort {$Units{$a}{'DisplayName'} cmp $Units{$b}{'DisplayName'}} keys %Units) {
		my $entry = { 'key' => $Units{$k}{'DisplayName'}, 'name' => $Units{$k}{'DisplayName'}, 'out' => "" };
		$entry->{'key'} =~ s/ /_/g;
		my $heal_head = "";
		my $norm_span = 5;
		my $epic_span = 4;
		if ($Units{$k}{'_CanHeal'}) {
			$heal_head = "<th>Heal</th>";
			$norm_span++;
			$epic_span++;
		}
		my $atk_spd = 1;
		if ($Units{$k}{'Captain'}{'1'}{'AttackRate'} != 0) {
			$atk_spd = sprintf("%0.02f", 1/$Units{$k}{'Captain'}{'1'}{'AttackRate'});
		}
		
		$entry->{'out'} = <<"END_PRINT";
$Units{$k}{'Rarity'} $Units{$k}{'Role'} &ndash; $Units{$k}{'Description'}<br />
Strong Against: $Units{$k}{'StrongAgainstTagsList'}<br />
Weak Against: $Units{$k}{'WeakAgainstTagsList'}<br />
Targets $Units{$k}{'TargetTeam'} $Units{$k}{'UnitTargetingType'} within $Units{$k}{'TargetingPriorityRange'} tiles with priority: $Units{$k}{'TargetPriorityTagsList'}
<table class="output">
<thead><tr><th rowspan="2">Lvl</th><th rowspan="2">Spd</th><th rowspan="2">Atk<br />Spd</th><th colspan="$norm_span">Captain</th><th colspan="2">Upgrade Cost</th></tr>
<tr><th>HP</th><th>Dam</th><th>Rng</th>$heal_head<th>Pow</th><th>Milestone Desc</th>
<th>Gold</th><th>Scrolls</th>
</tr></thead><tbody>
END_PRINT

		foreach my $lvl (1 .. 30) {
			my $heal_norm = "";
			my $row_class = "no_hl";
			#if ($lvl == 5 or $lvl == 10 or $lvl == 20 or $lvl == 30) {
			if ($lvl % 5 == 0) {
				$row_class = "highlight";
			}
			if ($Units{$k}{'_CanHeal'}) {
				$heal_norm = qq(<td class="num">$Units{$k}{'Captain'}{$lvl}{'Heal'}</td>);
			}
			my $mile_capt = qq(<td class="text">$Units{$k}{'Captain'}{$lvl}{'SpecialAbilityDescription'}<br />);
			$mile_capt .= join("<br />", (map {TranslateBuff($_)} split(/,/, $Units{$k}{'Captain'}{$lvl}{'StartBuffsList'})));
			$mile_capt .= "</td>";
			my $power = $HidePower ? "--" : $Units{$k}{'Captain'}{$lvl}{'Power'};			
			$entry->{'out'} .= <<"END_PRINT";
<tr class="$row_class"><td class="num">$lvl</td><td class="num">$Units{$k}{'Captain'}{$lvl}{'Speed'}</td><td class="num">$atk_spd</td>
<td class="num">$Units{$k}{'Captain'}{$lvl}{'HP'}</td><td class="num">$Units{$k}{'Captain'}{$lvl}{'Damage'}</td><td class="num">$Units{$k}{'Captain'}{$lvl}{'Range'}</td>$heal_norm<td class="num">$power</td>
$mile_capt
<td>$Units{$k}{'Captain'}{$lvl}{'UpgradeCostGold'}</td><td>$Units{$k}{'Captain'}{$lvl}{'UpgradeCost'}</td>
</tr>
END_PRINT
		
		}
		$entry->{'out'} .= "</tbody></table>";
		push @Panel, $entry;
	}
	my $power_desc = $HidePower ? qq(<span class="warn">specific power numbers are currently hidden at request of the Stream Captain team</span>) : 
	qq(the main user interest for power is PvP placement. Note that anecdotal evidence suggests that the Captain's unit will be limited to 25% of the power cap, so on a given battle the actual power counted may be less than that listed here. For an overall power summary, see the <a href="./captain_power.html">Captain Power page</a>.);

	my $longdesc = <<"END_PRINT";
<p>A summary of unit stats as of $GameData->{'exportDate'} PDT. Some notes on this data:</p>
<ul>
<li><span class="note">Milestone Desc</span> is just the text displayed for the milestone ability; actual milestone data and other unit buffs is still a work-in-progress.</li>
<li>Specialization information is not yet included.</li>
<li>The <span class="note">Rng</span> column is attack range, and the <span class="note">Pow</span> column is unit power; $power_desc</li>
<li>Upgrade costs are the costs to get to that level from the previous level (or to initially unlock for level 1).
A cost calculator is included on the <a href="./index.html#upgrade_calc">Main Index page</a>.</li>
<li>A <span class="note">Heal</span> column is displayed for units which can heal allies.</li>
</ul>
END_PRINT

	print GetHeader("Captain Units", qq(Stats for captain units in Stream Raiders.), $longdesc);
	print GetTOCStart();

	# Print the rest of the TOC
	foreach my $p (@Panel) {
		my $text = $p->{'name'};
		$text =~ s/ /&nbsp;/g;
		print qq(<li><a href="#TOC_$p->{'key'}">$text</a></li>);
	}
	print GetTOCEnd();
	
	# Print the Panels
	foreach my $p (@Panel) {
		print <<"END_PRINT";
<div class="panel" id="TOC_$p->{'key'}">
<h2>$p->{'name'}</h2>
$p->{'out'}
</div>
END_PRINT
	}
		
	print GetFooter();
	close $FH or die "Error closing file";
}

###################################################################################################
# WritePowerSummaryViewer - handles unit power summary page for viewers
sub WritePowerSummaryViewer {
	my $FH;
	open $FH, ">$DocBase/viewer_power.html" or die "Can't open viewer_power.html for writing: $!";
	select $FH;

	print STDOUT "Generating Viewer Power Summary\n";
	
	#This one only has a limited number of panels so they are just hardcoded.
	
	my @Panel = (	); 
	
	# First panel - simplistic rankings
	my $entry = { 'key' => '1_simple', 'name' => 'Overall Power Rankings', 'out' => "" };
	
	my $last_power = -1;
	my @rank = ();
	foreach my $k (sort {$Power{'total'}{'Normal'}{$b} <=> $Power{'total'}{'Normal'}{$a} or 
						$a cmp $b} keys %{$Power{'total'}{'Normal'}}) {
		if ($Power{'total'}{'Normal'}{$k} != $last_power) {
			my $the_power = $HidePower ? "----" : $Power{'total'}{'Normal'}{$k};
			push @rank, "[$the_power] $k";
			$last_power = $Power{'total'}{'Normal'}{$k};
		} else {
			$rank[$#rank] .= ", $k";
		}
	}
	my $intro = $HidePower ? qq(<p class="warn">Specific power numbers are currently hidden at the request of the Stream Captain team.</p>) : "";
	
	$entry->{'out'} = <<"END_PRINT";
$intro
<p>This section is just a simple power ranking of each unit based on the total power for levels 1 through 30 of the unit.
Basically it is a way to quickly see which units the game considers the strongest overall without regard for level
differences.</p>
<ol>
END_PRINT

	foreach my $i (@rank) {
		$entry->{'out'} .= "<li>$i</li>";
	}
	$entry->{'out'} .= "</ol>";
	push @Panel, $entry;
	
	# Next, more detailed level-by-level rankings.
	$entry = { 'key' => '2_detailed', 'name' => 'Per-Level Power Rankings', 'out' => "" };
	
	$entry->{'out'} = <<"END_PRINT";
$intro
<p>This section takes each individual level of each unit and puts them all together into a power ranking which
provides a more detailed view. Note that when trying to compare two specific units (e.g. Archer vs Buster), it may
be easier to just look at the power numbers listed in their respective <a href="./viewer_units.html">unit summaries</a>.</p>
<table class="output">
<thead><tr><th>Power</th><th>Unit(s)</th></tr></thead>
<tbody>
END_PRINT
	
	foreach my $p (sort {$b <=> $a} keys %{$Power{'individual'}{'Normal'}}) {
		# TODO: Future feature: dropdown list of units to highlight all entries for that unit.
		my $the_power = $HidePower ? "--" : $p;
		$entry->{'out'} .= qq(<tr><td class="num">$the_power</td><td class="text">);
		$entry->{'out'} .= join(", ", sort @{$Power{'individual'}{'Normal'}{$p}});
		$entry->{'out'} .= '</td></tr>';
	}
	$entry->{'out'} .= '</tbody></table>';
	push @Panel, $entry;


	my $longdesc = <<"END_PRINT";
<p>A summary of the power rankings of units as of $GameData->{'exportDate'} PDT. The primary use of this data is to help understand
the filling of the power bar in PvP.</p>
END_PRINT

	print GetHeader("Viewer Power", qq(Power rankings for viewer units in Stream Raiders.), $longdesc);
	print GetTOCStart();

	# Print the rest of the TOC
	foreach my $p (@Panel) {
		my $text = $p->{'name'};
		$text =~ s/ /&nbsp;/g;
		print qq(<li><a href="#TOC_$p->{'key'}">$text</a></li>);
	}
	print GetTOCEnd();
	
	# Print the Panels
	foreach my $p (@Panel) {
		print <<"END_PRINT";
<div class="panel" id="TOC_$p->{'key'}">
<h2>$p->{'name'}</h2>
$p->{'out'}
</div>
END_PRINT
	}
		
	print GetFooter();
	close $FH or die "Error closing file";
}

###################################################################################################
# WritePowerSummaryCaptain - handles unit power summary page for viewers
sub WritePowerSummaryCaptain {
	my $FH;
	open $FH, ">$DocBase/captain_power.html" or die "Can't open captain_power.html for writing: $!";
	select $FH;

	print STDOUT "Generating Captain Power Summary\n";
	
	#This one only has a limited number of panels so they are just hardcoded.
	
	my @Panel = (	); 
	
	# First panel - simplistic rankings
	my $entry = { 'key' => '1_simple', 'name' => 'Overall Power Rankings', 'out' => "" };
	
	my $last_power = -1;
	my @rank = ();
	foreach my $k (sort {$Power{'total'}{'Captain'}{$b} <=> $Power{'total'}{'Captain'}{$a} or
						$a cmp $b} keys %{$Power{'total'}{'Captain'}}) {
		if ($Power{'total'}{'Captain'}{$k} != $last_power) {
			my $the_power = $HidePower ? "----" : $Power{'total'}{'Captain'}{$k};
			push @rank, "[$the_power] $k";
			$last_power = $Power{'total'}{'Captain'}{$k};
		} else {
			$rank[$#rank] .= ", $k";
		}
	}
	my $intro = $HidePower ? qq(<p class="warn">Specific power numbers are currently hidden at the request of the Stream Captain team.</p>) : "";
	
	$entry->{'out'} = <<"END_PRINT";
$intro
<p>This section is just a simple power ranking of each unit based on the total power for levels 1 through 30 of the unit.
Basically it is a way to quickly see which units the game considers the strongest overall without regard for level
differences. Note that anecdotal evidence suggests that the Captain's unit will be limited to 25% of the power cap,
so on a given battle the actual power counted may be less than that listed here.</p>
<ol>
END_PRINT

	foreach my $i (@rank) {
		$entry->{'out'} .= "<li>$i</li>";
	}
	$entry->{'out'} .= "</ol>";
	push @Panel, $entry;
	
	# Next, more detailed level-by-level rankings.
	$entry = { 'key' => '2_detailed', 'name' => 'Per-Level Power Rankings', 'out' => "" };
	
	$entry->{'out'} = <<"END_PRINT";
$intro
<p>This section takes each individual level of each unit and puts them all together into a power ranking which
provides a more detailed view. Note that when trying to compare two specific units (e.g. Archer vs Buster), it may
be easier to just look at the power numbers listed in their respective <a href="./captain_units.html">unit summaries</a>.</p>
<table class="output">
<thead><tr><th>Power</th><th>Unit(s)</th></tr></thead>
<tbody>
END_PRINT
	
	foreach my $p (sort {$b <=> $a} keys %{$Power{'individual'}{'Captain'}}) {
		# TODO: Future feature: dropdown list of units to highlight all entries for that unit.
		my $the_power = $HidePower ? "--" : $p;
		$entry->{'out'} .= qq(<tr><td class="num">$the_power</td><td class="text">);
		$entry->{'out'} .= join(", ", sort @{$Power{'individual'}{'Captain'}{$p}});
		$entry->{'out'} .= '</td></tr>';
	}
	$entry->{'out'} .= '</tbody></table>';
	push @Panel, $entry;


	my $longdesc = <<"END_PRINT";
<p>A summary of the power rankings of units as of $GameData->{'exportDate'} PDT. The primary use of this data is to help understand
the filling of the power bar in PvP.</p>
END_PRINT

	print GetHeader("Captain Power", qq(Power rankings for captain units in Stream Raiders.), $longdesc);
	print GetTOCStart();

	# Print the rest of the TOC
	foreach my $p (@Panel) {
		my $text = $p->{'name'};
		$text =~ s/ /&nbsp;/g;
		print qq(<li><a href="#TOC_$p->{'key'}">$text</a></li>);
	}
	print GetTOCEnd();
	
	# Print the Panels
	foreach my $p (@Panel) {
		print <<"END_PRINT";
<div class="panel" id="TOC_$p->{'key'}">
<h2>$p->{'name'}</h2>
$p->{'out'}
</div>
END_PRINT
	}
		
	print GetFooter();
	close $FH or die "Error closing file";
}

###################################################################################################
# WriteCSS - Iterates through the SpriteInfo structure and writes out the appropriate CSS for each ID
sub WriteCSS {
	my $FH;
	open $FH, ">$DocBase/sr-img.css" or die "Can't open sr-img.css for writing: $!";
	select $FH;

	print STDOUT "Generating CSS for image sprites\n";
	# First, the basic classes for each spritesheet
	print <<"END_PRINT";
/* sr-img.css
 * https://mouseypounds.github.io/streamraiders/
 */
img.craftables {
	vertical-align: -2px;
	width: 16px;
	height: 32px;
	background-image:url("./img/ss_craftables.png")
}
END_PRINT

	
	# Everything that was gathered in SpriteInfo
	# foreach my $id (sort keys %$SpriteInfo) {
		# my $x = $SpriteInfo->{$id}{'x'};
		# my $y = $SpriteInfo->{$id}{'y'};
		# print <<"END_PRINT";
# img#$id {
	# background-position: ${x}px ${y}px;
# }
# END_PRINT
	# }
	
	close $FH;
}

__END__ 
