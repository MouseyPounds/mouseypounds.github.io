#!/bin/perl
#
# make_docs.pl
#
# processing JA & CFR data for PPJA Mods to create summary web pages

use strict;
use Scalar::Util qw(looks_like_number);
use POSIX qw(ceil floor);
use List::Util qw(min max);
use Storable;
use Math::Round;
use Data::Dumper;

my $GameData = retrieve("cache_GameData");
my $ModData = retrieve("cache_ModData");
my $ModInfo = retrieve("cache_ModInfo");

my $DocBase = "..";

my $SpriteInfo = {};

CropSummary();
MachineSummary();
WriteCSS();

exit;

# Wikify: Conversion of a javascript function from Stardew Checkup that adds a wiki link for an item.
#   item name
#   page name [optional] - used when the item is just an anchor on another page rather than having its own page
#
sub Wikify {
	my $item = shift;
	my $page = shift;
	my $trimmed = $item;
	$trimmed =~ s/ (White)//;
	$trimmed =~ s/ (Brown)//;
	$trimmed =~ s/L. /Large /;
	$trimmed =~ s/ /_/g;

	# Hardcoded Category redirects
	if ($trimmed =~ /^fruit$/i or $trimmed =~ /^vegetable$/i or $trimmed =~ /^flower$/i) {
		$trimmed .= 's';
	}
	
	if (defined $page) {
		return qq(<a href="http://stardewvalleywiki.com/$page#$trimmed">$item</a>);
	} else {
		return qq(<a href="http://stardewvalleywiki.com/$trimmed">$item</a>);
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

# GetItem receives 1 or 2 inputs and will use the first one that is defined.
# It then tries to resolve an ID into a name if it looks like a vanilla item
sub GetItem {
	my $input = shift;
	if (not defined $input or $input eq "") {
		# first one didn't work, now try second
		$input = shift;
	}
	if (not defined $input or $input eq "") {
		# second didn't work either, give up
		return "Unknown Item";
	}
	my $output = "";
	if (looks_like_number($input)) {
		if ($input < 0) {
			# TODO: This needs better handling, either here or before it gets here
			if ($input == -999) {
				$output = qq(<span class="group">Same as Input</span>);
			} else {
				$output = '<span class="group">Any ' . Wikify(GetCategory($input)) . '</span>';
			}
		}
		elsif (exists $GameData->{'ObjectInformation'}{$input}) {
			my $name = $GameData->{'ObjectInformation'}{$input}{'split'}[0];
			$output = Wikify($name);
		}
	} else {
		# Custom, probably JA, but maybe not. JA takes priority
		if (exists $ModData->{'Objects'}{$input}) {
			# This is a JA item, but we have nothing to add yet.
			$output = $input;
		} else {
			foreach my $k (keys %{$GameData->{'ObjectInformation'}}) {
				if ($GameData->{'ObjectInformation'}{$k}{'split'}[0] eq $input) {
					$output = Wikify($input);
				}
			}
		}
	}
	if ($output eq '') {
		$output = qq(<span class="note">Unknown Item: $input</span>);
	}
	return $output;
}

# GetValue is a companion to GetItem and uses similar arguments & logic
# Normally returns an integer, but if given a category will instead return "varies".
# Also returns -1 if no valid input
sub GetValue {
	my $input = shift;
	if (not defined $input or $input eq "") {
		# first one didn't work, now try second
		$input = shift;
	}
	if (not defined $input or $input eq "") {
		# second didn't work either, give up
		return -1;
	}
	my $output = "";
	if (looks_like_number($input)) {
		if ($input < 0) {
			# For an "Any Milk" or "Any Egg" entry we will use the price of cheapest option
			if ($input == -6) {
				$output = GetValue("Milk");
			} elsif ($input == -5) {
				$output = GetValue("Egg");
			} else {
				$output = "varies";
			}
		}
		elsif (exists $GameData->{'ObjectInformation'}{$input}) {
			$output = $GameData->{'ObjectInformation'}{$input}{'split'}[1];
		}
	} else {
		if (exists $ModData->{'Objects'}{$input}) {
			$output = $ModData->{'Objects'}{$input}{'Price'};
		} else {
			foreach my $k (keys %{$GameData->{'ObjectInformation'}}) {
				if ($GameData->{'ObjectInformation'}{$k}{'split'}[0] eq $input) {
					$output = $GameData->{'ObjectInformation'}{$k}{'split'}[1]
				}
			}
		}
	}
	return $output;
}

sub GetCategory {
	my $input = shift;
	my $output = "";
	# Categories derived from wiki <https://stardewvalleywiki.com/Modding:Object_data#Categories>
	#   but use more descriptive names based on the internal constants
	# Some categories that are unused by vanilla items are ignored.
	my %c = (
		-2 => 'Gem',
		-4 => 'Fish',
		-5 => 'Egg',
		-6 => 'Milk',
		-7 => 'Cooked Dish',
		-8 => 'Crafted Item',
		-9 => 'Large Crafted Item', #unused in vanilla
		-12 => 'Mineral',
		-14 => 'Meat', #unused in vanilla
		-15 => 'Metal Resource',
		-16 => 'Building Resource',
		# -17 is marked as `Object.sellAtPierres` but contains only Sweet Gem Berry and Truffle
		#-17 => 'Item Sold by Pierre',
		-18 => 'Animal Product', #vanilla: wool, duck feather, and rabbit foot
		-19 => 'Fertilizer',
		-20 => 'Trash',
		-21 => 'Bait',
		-22 => 'Fishing Tackle',
		-23 => 'Shell',
		-24 => 'Decor Item',
		-25 => 'Cooking Ingredient', #unused in vanilla
		-26 => 'Artisan Goods',
		-27 => 'Tapper Product',
		-28 => 'Monster Loot',
		-29 => 'Equipment', #unused in vanilla
		-74 => 'Seed',
		-75 => 'Vegetable',
		-79 => 'Fruit',
		-80 => 'Flower',
		-81 => 'Forage',
		-95 => 'Hat', #unused in vanilla
		-96 => 'Ring', #unused in vanilla
		-98 => 'Weapon', #unused in vanilla
		-99 => 'Tool', #unused in vanilla
	);	
	
	if (exists $c{$input}) {
		$output = $c{$input};
	} else {
		$output = "Category $input Item";
	}
	return $output;
}

# GetHeader - creates and returns HTML code for top of pages
#
#   subtitle - string to put in top header and title
#   shortdesc - [optional] short description for social media embeds
#   longdesc - [optional] any additonal info to include in top panel
#   script - [optional] javascript to enable
sub GetHeader {
	my $subtitle = shift;
	my $shortdesc = shift;
	if (not defined $shortdesc or $shortdesc eq '') {
		$shortdesc = "Personal reference for the PPJA family of Stardew Valley mods.";
	}
	my $longdesc = shift;
	if (not defined $longdesc) {
		$longdesc = "";
	}
	my $script = shift;
	if (not defined $script or $script eq '') {
		$script = "";
	} else {
		$script = qq(<script type="text/javascript" src="./$script"></script>);
	}
	
	my $output = <<"END_PRINT";
<!DOCTYPE html>
<html>
<head>
<title>Mousey's PPJA Documentation: $subtitle</title>

<meta charset="UTF-8" />
<meta property="og:title" content="PPJA $subtitle" />
<meta property="og:description" content="$shortdesc" />
<!-- meta property="og:image" content="https://mouseypounds.github.io/stardew-checkup/og-embed-image.png" / -->
<!-- meta property="twitter:image" content="https://mouseypounds.github.io/stardew-checkup/og-embed-image.png" / -->
<meta name="theme-color" content="#ffe0b0">
<meta name="author" content="MouseyPounds" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />

<link rel="stylesheet" type="text/css" href="./ppja-doc.css" />
<link rel="stylesheet" type="text/css" href="./ppja-doc-img.css" />
<!-- link rel="icon" type="image/png" href="./favicon_c.png" / -->

<!-- Table sorting by https://www.kryogenix.org/code/browser/sorttable/ -->
<script type="text/javascript" src="./sorttable.js"></script>
$script

</head>
<body>
<div class="panel" id="header"><h1>Mousey's PPJA Documentation: $subtitle</h1>
$longdesc
</div>
<div id="TOC">
<h1>Navigation</h1>
<div id="TOC-details">
<ul>
<li><a href="#header">(Top)</a></li>
END_PRINT

	return $output;
}

# GetFooter - creates and returns HTML code for bottom of pages
sub GetFooter {
	my $output = <<"END_PRINT";
<div id="footer" class="panel">
PPJA Docs:
<a href="./crops.html">Crop Summary</a> || 
<a href="./machines.html">Machine Summary</a>
<br />
Stardew Apps by MouseyPounds: <a href="https://mouseypounds.github.io/stardew-checkup/">Stardew Checkup</a> ||
<a href="https://mouseypounds.github.io/stardew-predictor/">Stardew Predictor</a> || 
<a href="https://mouseypounds.github.io/stardew-fair-helper/">Stardew Fair Helper</a>
<br />
Other Stardew Valley resources: <a href="http://stardewvalley.net/">Website</a> || 
<a href="http://store.steampowered.com/app/413150/Stardew_Valley/">Steam Page</a> ||
<a href="https://www.gog.com/game/stardew_valley">GOG Page</a> ||
<a href="http://www.stardewvalleywiki.com/">Wiki</a> || 
<a href="http://community.playstarbound.com/index.php?forums/stardew-valley.72/">Forums</a> ||
<a href="https://www.reddit.com/r/StardewValley">Subreddit</a> ||
<a href="https://discordapp.com/invite/StardewValley">Discord</a>
<br />
Stardew Valley was developed by <a href="http://twitter.com/concernedape">ConcernedApe</a> and published by 
<a href="http://blog.chucklefish.org/about/">Chucklefish Games</a>.
</div>
</body>
</html>
END_PRINT

	return $output;
}

sub CropSummary {
	my $FH;
	open $FH, ">$DocBase/crops.html" or die "Can't open crops.html for writing: $!";
	select $FH;
	my $longdesc = <<"END_PRINT";
<p>A summary of growth information including base game crops as well as crops from the following mods:</p>
<ul>
<li><a href="https://www.nexusmods.com/stardewvalley/mods/1741">$ModInfo->{'PPJA.cannabiskit'}{'Name'}</a> version $ModInfo->{'PPJA.cannabiskit'}{'Version'}</li>
<li><a href="https://www.nexusmods.com/stardewvalley/mods/1610">$ModInfo->{'ParadigmNomad.FantasyCrops'}{'Name'}</a> version $ModInfo->{'ParadigmNomad.FantasyCrops'}{'Version'}</li>
<li><a href="https://www.nexusmods.com/stardewvalley/mods/2075">$ModInfo->{'kildarien.farmertoflorist'}{'Name'}</a> version $ModInfo->{'kildarien.farmertoflorist'}{'Version'}</li>
<li><a href="https://www.nexusmods.com/stardewvalley/mods/1721">$ModInfo->{'paradigmnomad.freshmeat'}{'Name'}</a> version $ModInfo->{'paradigmnomad.freshmeat'}{'Version'}</li>
<li><a href="https://www.nexusmods.com/stardewvalley/mods/1598">$ModInfo->{'ppja.fruitsandveggies'}{'Name'}</a> version $ModInfo->{'ppja.fruitsandveggies'}{'Version'}</li>
<li><a href="https://www.nexusmods.com/stardewvalley/mods/2028">$ModInfo->{'mizu.flowers'}{'Name'}</a> version $ModInfo->{'mizu.flowers'}{'Version'}</li>
</ul>
<p>Growth speed option to apply to all crop tables:</p>
<fieldset id="growth_speed_options" class="radio_set">
<label><input type="radio" name="speed" value="0" checked="checked"> No speed modifiers</label><br />
<label><input type="radio" name="speed" value="10"> 10% (Only one of <a href="https://stardewvalleywiki.com/Farming#Farming_Skill">Agriculturist</a> Profession or <a href="https://stardewvalleywiki.com/Speed-Gro">Speed-Gro</a> Fertilizer</label>)</label><br />
<label><input type="radio" name="speed" value="20"> 20% (Both <a href="https://stardewvalleywiki.com/Farming#Farming_Skill">Agriculturist</a> Profession and <a href="https://stardewvalleywiki.com/Speed-Gro">Speed-Gro</a> Fertilizer</label>)</label><br />
<label><input type="radio" name="speed" value="25"> 25% (Only <a href="https://stardewvalleywiki.com/Deluxe_Speed-Gro">Deluxe Speed-Gro</a> Fertilizer)</label><br />
<label><input type="radio" name="speed" value="35"> 35% (Both <a href="https://stardewvalleywiki.com/Farming#Farming_Skill">Agriculturist</a> Profession and <a href="https://stardewvalleywiki.com/Deluxe_Speed-Gro">Deluxe Speed-Gro</a> Fertilizer)</label>
</fieldset>
<input type="hidden" id="last_speed" value="0" />
END_PRINT
	print GetHeader("Crop Growth Summary", qq(PPJA Crop Growth Summary), $longdesc, "crops-form.js");

	# We will organize this by Season so we start with an array that will hold a hash of the table rows keyed by crop name.
	my @Panel = ( 
		{ 'key' => 'Spring', 'row' => {}, },
		{ 'key' => 'Summer', 'row' => {}, },
		{ 'key' => 'Fall', 'row' => {}, },
		{ 'key' => 'Winter', 'row' => {}, },
		);

	# Vanilla crop data
	foreach my $sid (keys %{$GameData->{'Crops'}}) {
		# The keys for the Crops hash are the object ID numbers for the Seeds (hence the var $sid)
		# We will need to extract some info from ObjectInformation as well but don't sanity-check very often since we trust game data
		my $sname = GetItem($sid);
		my $scost = 2*$GameData->{'ObjectInformation'}{$sid}{'split'}[1];
		my @phases = (split(' ', $GameData->{'Crops'}{$sid}{'split'}[0]));
		my $season_str = $GameData->{'Crops'}{$sid}{'split'}[1];
		#my @seasons = (split(' ', $GameData->{'Crops'}{$sid}{'split'}[1]));
		my $sprite_index = $GameData->{'Crops'}{$sid}{'split'}[2];
		my $cid = $GameData->{'Crops'}{$sid}{'split'}[3];
		my $cname = GetItem($cid);
		my $cprice = $GameData->{'ObjectInformation'}{$cid}{'split'}[1];
		my $regrowth = $GameData->{'Crops'}{$sid}{'split'}[4];
		$regrowth = (($regrowth > 0) ? $regrowth : "--");
		my $need_scythe = ($GameData->{'Crops'}{$sid}{'split'}[5] ? "Yes" : "--");
		my @multi_data = (split(' ', $GameData->{'Crops'}{$sid}{'split'}[6]));
		my $num_harvest = pop @multi_data;
		if ($num_harvest eq 'true') {
			my ($min, $max, $inc_per_level, $extra_chance) = @multi_data;
			$num_harvest = $min + $extra_chance;
		} else {
			$num_harvest = 1;
		}
		my $is_trellis = (($GameData->{'Crops'}{$sid}{'split'}[7] eq 'true') ? "Yes" : "--");
		my @color_data = (split(' ', $GameData->{'Crops'}{$sid}{'split'}[8]));
		# This is all hard-coded since it is handled in the exe
		# To make it easier to read we check the name rather than id, so we have to strip it
		my $crop = StripHTML($cname);
		my $seed_vendor = Wikify("Pierre");
		if ($crop eq 'Rhubarb' or $crop eq 'Starfruit' or $crop eq 'Beet' or $crop eq 'Cactus Fruit') {
			$seed_vendor = Wikify("Sandy");
			if ($crop eq 'Cactus Fruit') {
				$scost = 150;
			}
		} elsif ($crop eq 'Coffee Bean') {
			$seed_vendor = Wikify("Traveling Merchant");
			$scost = 2500;
		} elsif ($crop eq 'Ancient Fruit') {
			$seed_vendor = qq(<span class="note">None</span>);
		}
		if ($crop eq 'Garlic' or $crop eq 'Red Cabbage' or $crop eq 'Artichoke') {
			$seed_vendor .= "<br />(Year 2+)";
		}
		
		my $output = <<"END_PRINT";
<tr><td>$cname</td>
<td>$sname</td>
<td>$seed_vendor</td>
<td>$scost</td>
<td>$need_scythe</td>
<td>$is_trellis</td>
<td>$num_harvest</td>
END_PRINT
		foreach my $opt (qw(0 10 20 25 35)) {
			my $growth = CalcGrowth($opt/100, \@phases);
			my $max_harvests = floor(27/$growth);
			if (looks_like_number($regrowth) and $regrowth > -1) {
				if ($growth > 27) {
					$max_harvests = 0;
				} else {
					$max_harvests = 1 + max(0, floor((27-$growth)/$regrowth));
				}
			}
			$output .= <<"END_PRINT";
<td class="col_$opt">$growth</td>
<td class="col_$opt">$regrowth</td>
<td class="col_$opt">$max_harvests</td>
END_PRINT
		}
		$output .= "</tr>";
		foreach my $p (@Panel) {
			my $check = lc $p->{'key'};
			if ($season_str =~ /$check/) {
				$p->{'row'}{StripHTML($cname)} = $output;
			}
		}
	}

	# Mod crop data; uses similar variable names to the vanilla logic
	foreach my $key (keys %{$ModData->{'Crops'}}) {
		# The keys for the Mod Crops hash should be the names of the crops but don't have to be
		my $sname = $ModData->{'Crops'}{$key}{'SeedName'};
		my $scost = $ModData->{'Crops'}{$key}{'SeedPurchasePrice'};
		my @phases = @{$ModData->{'Crops'}{$key}{'Phases'}};
		my $season_str = join(" ", @{$ModData->{'Crops'}{$key}{'Seasons'}});
		#my @seasons = $ModData->{'Crops'}{$key}{'Seasons'};
		#Sprites are the __SS keys
		my $cname = GetItem($ModData->{'Crops'}{$key}{'Product'});
		my $cprice = GetValue($ModData->{'Crops'}{$key}{'Product'});
		my $regrowth = $ModData->{'Crops'}{$key}{'RegrowthPhase'};
		$regrowth = (($regrowth > 0) ? $regrowth : "--");
		my $need_scythe = ($ModData->{'Crops'}{$key}{'HarvestWithScythe'} ? "Yes" : "--");
		my $is_trellis = ($ModData->{'Crops'}{$key}{'TrellisCrop'} ? "Yes" : "--");
		#my @colors = @{$ModData->{'Crops'}{$key}{'Colors'}};
		my $num_harvest = $ModData->{'Crops'}{$key}{'Bonus'}{'MinimumPerHarvest'} + $ModData->{'Crops'}{$key}{'Bonus'}{'ExtraChance'};
		my $seed_vendor = Wikify("Pierre");
		if (exists $ModData->{'Crops'}{$key}{'SeedPurchaseFrom'}) {
			$seed_vendor = Wikify($ModData->{'Crops'}{$key}{'SeedPurchaseFrom'});
		}
		if (exists $ModData->{'Crops'}{$key}{'SeedPurchaseRequirements'} and defined $ModData->{'Crops'}{$key}{'SeedPurchaseRequirements'}) {
			my @req = TranslatePreconditions(@{$ModData->{'Crops'}{$key}{'SeedPurchaseRequirements'}});
			# Note that the order here is not guaranteed. If we start getting crops with multiple different requirements we might have to deal with that
			$seed_vendor .= '<br />' . join('<br />', @req);
		}
		
		my $output = <<"END_PRINT";
<tr><td>$cname</td>
<td>$sname</td>
<td>$seed_vendor</td>
<td>$scost</td>
<td>$need_scythe</td>
<td>$is_trellis</td>
<td>$num_harvest</td>
END_PRINT
		foreach my $opt (qw(0 10 20 25 35)) {
			my $growth = CalcGrowth($opt/100, \@phases);
			my $max_harvests = floor(27/$growth);
			if (looks_like_number($regrowth) and $regrowth > -1) {
				if ($growth > 27) {
					$max_harvests = 0;
				} else {
					$max_harvests = 1 + max(0, floor((27-$growth)/$regrowth));
				}
			}
			$output .= <<"END_PRINT";
<td class="col_$opt">$growth</td>
<td class="col_$opt">$regrowth</td>
<td class="col_$opt">$max_harvests</td>
END_PRINT
		}
		$output .= "</tr>";
		foreach my $p (@Panel) {
			my $check = lc $p->{'key'};
			if ($season_str =~ /$check/) {
				$p->{'row'}{StripHTML($cname)} = $output;
			}
		}
	}

	# Print the rest of the TOC
	foreach my $p (@Panel) {
		print qq(<li><a href="#TOC_$p->{'key'}">$p->{'key'} Crops</a></li>);
	}
	print <<"END_PRINT";
</ul>
</div>
</div>
END_PRINT
	
	# Print the Panels
	foreach my $p (@Panel) {
		print <<"END_PRINT";
<div class="panel" id="TOC_$p->{'key'}">
<h2>$p->{'key'} Crops</h2>

<table class="sortable output">
<thead>
<tr>
<th>Crop Name</th>
<th>Seed Name</th>
<th>Seed Vendor<br />(&amp; Requirements)</th>
<th>Seed<br />Price</th>
<th>Needs<br />Scythe?</th>
<th>Has<br />Trellis?</th>
<th>Average<br />Yield</th>
<th class="col_0">Initial<br />Growth</th>
<th class="col_0">Regrowth</th>
<th class="col_0">Maximum<br />Harvests</th>
<th class="col_10">Initial<br />Growth</th>
<th class="col_10">Regrowth</th>
<th class="col_10">Maximum<br />Harvests</th>
<th class="col_20">Initial<br />Growth</th>
<th class="col_20">Regrowth</th>
<th class="col_20">Maximum<br />Harvests</th>
<th class="col_25">Initial<br />Growth</th>
<th class="col_25">Regrowth</th>
<th class="col_25">Maximum<br />Harvests</th>
<th class="col_35">Initial<br />Growth</th>
<th class="col_35">Regrowth</th>
<th class="col_35">Maximum<br />Harvests</th>
</tr>
</thead>
<tbody>
END_PRINT
		foreach my $k (sort keys %{$p->{'row'}}) {
			print $p->{'row'}{$k};
		}
		print <<"END_PRINT";
</tbody>
</table>
</div>
END_PRINT
	}
	
	print GetFooter();

	close $FH or die "Error closing file";
}

# CalcGrowth - Calculates the number of days it will take for a crop to grow from seed
#
#   factor - the pct reduction factor (e.g. .10 for basic speed-gro or agriculturist)
#   phases_ref - a reference to the array of phase data
sub CalcGrowth() {
	my $factor = shift;
	my $phases_ref = shift;
	my @phases = @$phases_ref;
	my $days = 0;
	my $num_phases = scalar @phases;
	for (my $i = 0; $i < $num_phases; $i++) {
		$days += $phases[$i];
	}
	my $reduction = ceil($factor * $days);
	# The following mimics the game's imprecision errors due to excessive type casting
	# For more on the growth mechanics and this error, see https://stardewvalleywiki.com/Talk:Speed-Gro
	if (($days % 10 == 0 and $factor == 0.10) or ($days % 5 == 0 and $factor == 0.20)) {
		$reduction++;
	}
	my $tries = 0;
	while ($reduction > 0 and $tries < 3) {
		for (my $i = 0; $i <= $num_phases; $i++) {
			if ($i == 0) {
				if ($phases[$i] > 1) {
					$phases[$i]--;
					$reduction--;
					$days--;
				}
			} elsif ($i < $num_phases) {
				if ($phases[$i] > 0) {
					$phases[$i]--;
					$reduction--;
					$days--;
				}
			} else {
				# lost reduction day in final phase
				$reduction--;
			}
			last if ($reduction <= 0);
		}
		$tries++;
	}
	return $days;
}

# TranslatePreconditions - Receives an array of event preconditions and tries to make them human-readable
#  Currently only supports `z`, `y`, and `f` since those are what we have needed to deal with so far.
sub TranslatePreconditions {
	my %seasons = ( 'Spring' => 1, 'Summer' => 2, 'Fall' => 3, 'Winter' => 4 );
	my $changed_seasons = 0;
	my @results = ();
	
	foreach my $arg (@_) {
		if ($arg =~ /^y (\d+)/) {
			push @results, "(Year $1+)";
		} elsif ($arg =~ /^f (\w+) (\d+)/) {
			my $num_hearts = $2/250;
			push @results, "($num_hearts+ Hearts with " . Wikify($1) . ")";
		} elsif ($arg =~ /^z /) {
			my @removal = split(/, ?/, $arg);
			foreach my $r (@removal) {
				$r =~ s/^z //;
				my $s = ucfirst $r;
				delete $seasons{$s} if (exists $seasons{$s});
				$changed_seasons = 1;
			}
		}
	}
	if ($changed_seasons) {
		my $r = '(' . join(', ', (sort {$seasons{$a} <=> $seasons{$b}} (keys %seasons))) . ')';
		push @results, $r;
	}
	return @results;
}

sub MachineSummary {
	my $FH;
	open $FH, ">$DocBase/machines.html" or die "Can't open machines.html for writing: $!";
	select $FH;

	my $longdesc = <<"END_PRINT";
<p>A summary of machines from the following mods:</p>
<ul>
<li><a href="https://www.nexusmods.com/stardewvalley/mods/1926">$ModInfo->{'ppja.avcfr'}{'Name'}</a> version $ModInfo->{'ppja.avcfr'}{'Version'}
including enabling recipes from:
  <ul>
  <li><a href="https://www.nexusmods.com/stardewvalley/mods/1897">$ModInfo->{'Aquilegia.SweetTooth'}{'Name'}</a> version $ModInfo->{'Aquilegia.SweetTooth'}{'Version'} (with <span class="note">Lavender</span> corrected to <span class="note">Herbal Lavender</span>).</li>
  <!-- <li><a href="https://www.nexusmods.com/stardewvalley/mods/1741">$ModInfo->{'PPJA.cannabiskit'}{'Name'}</a> version $ModInfo->{'PPJA.cannabiskit'}{'Version'}</li> -->
  </ul>
</li>
<li><a href="https://www.nexusmods.com/stardewvalley/mods/2075">$ModInfo->{'kildarien.farmertofloristcfr'}{'Name'}</a> version $ModInfo->{'kildarien.farmertofloristcfr'}{'Version'}</li>
</ul>
<p>Inputs related to an entire category (e.g. <span class="group">Any Fruit</span>) accept appropriate mod items too even though this summary links them to
the wiki which only shows base game items. All value and profit calculations assume basic (no-star) <a href="https://stardewvalleywiki.com/Crops#Crop_Quality">quality</a>. Additonally, if a recipe calls for <span class="group">Any Milk</span>, the
value of the small cow <a href="https://stardewvalleywiki.com/Milk">Milk</a> is used, and if a recipe calls for <span class="group">Any Egg</span>,
the value of the small <a href="https://stardewvalleywiki.com/Egg">Egg</a> is used.
</p>

<p>There are two types of profit listed: <span class="note">Profit (Item)</span> is purely based on the difference between the values of the ingredients
and products while <span class="note">Profit (Hr)</span> takes the production time into account and divides the per-item profit by the number of hours the
machine takes. The latter is rounded to two decimal places.
</p>
END_PRINT
	print GetHeader("Machine Summary", qq(PPJA Artisan Valley Machine Summary), $longdesc);

	my %TOC = ();

	# To most easily sort the machines alphabetically, I will save all output in this Panel hash, keyed on machine name
	my %Panel = ();
	foreach my $j (@{$ModData->{'Machines'}}) {
		# These are the individual json files from each machine mod. Since mod names here don't necessarily reflect either the
		#  manifest name or UniqueID, we hardcode the appropriate keys for ModInfo.
		my $extra_info = "";
		if ($j->{name} eq 'Artisan Valley Machine Machines') {
			$extra_info = qq(<p><span class="note">From $ModInfo->{'ppja.avcfr'}{'Name'} version $ModInfo->{'ppja.avcfr'}{'Version'}</span></p>);
		} elsif ($j->{name} eq 'Farmer to Florist Machines Redux') {
			$extra_info = qq(<p><span class="note">From $ModInfo->{'kildarien.farmertofloristcfr'}{'Name'} version $ModInfo->{'kildarien.farmertofloristcfr'}{'Version'}</span></p>);
		} 
		foreach my $m (@{$j->{'machines'}}) {
			# Try to get a unique key for the Panel hash and give up on failure since it really shouldn't happen.
			my $key = $m->{'name'};
			my $tries = 0;
			my $max_tries = 10;
			while (exists $Panel{$key} and $tries < $max_tries) {
				$key = $m->{'name'} . "_$tries";
				$tries++;
			}
			if (exists $Panel{$key}) {
				die "I tried $max_tries iterations of $key and all of them existed. This job sucks. I quit.";
			}
			my $id = "Machine_$m->{'name'}";
			$id =~ s/ /_/g;
			my $anchor = "TOC_$id";
			$TOC{$m->{'name'}} = $anchor;
			if (exists $SpriteInfo->{$id}) {
				warn "Sprite ID {$id} will not be unique";
			}
			$SpriteInfo->{$id} = { 'x' => 0 - 2*$m->{'__SS_X'}, 'y' => 0 - 2*$m->{'__SS_Y'} };
			my $output = <<"END_PRINT";
<div class="panel" id="$anchor">
<div class="container">
<img class="container__image craftables_x2" id="$id" src="img/blank.png" alt="Machine Sprite" />
<div class="container__text">
<h2>$m->{'name'}</h2>
<span class="mach_desc">$m->{'description'}</span><br />
</div>
$extra_info
</div>
<table class="recipe">
<tbody><tr><th>Crafting Recipe</th><td>
END_PRINT

			my @recipe = split(' ', $m->{'crafting'});
			for (my $i = 0; $i < scalar(@recipe); $i += 2) {
				my $num = $recipe[$i+1];
				$output .= GetItem($recipe[$i]) . ($num > 1 ? " ($num)" : "" ) . "<br />";
			}
			
			$output .= <<"END_PRINT";
</td></tbody></table>
<table class="sortable output">
<thead>
<tr><th>Product</th><th>Ingredients</th><th>Time</th><th>Value</th><th>Profit<br />(Item)</th><th>Profit<br />(Hr)</th></tr>
</thead>
<tbody>
END_PRINT
			my $starter = "NO_STARTER";
			if (exists $m->{'starter'}) {
				$starter = GetItem($m->{'starter'}{'name'}, $m->{'starter'}{'index'});
			}
			# Pre-scan production to handle "includes" by duplicating the production object for each additional item.
			my @add = ();
			foreach my $p (@{$m->{'production'}}) {
				# We will assume that the materials array only contains one thing and that there are no other nested
				#  objects which we care about. Thus, a shallow copy of the production object is acceptable.
				if (exists $p->{'include'}) {
					foreach my $p_inc (@{$p->{'include'}}) {
						my %temp = %$p;
						$temp{'materials'} = [];
						$temp{'materials'}[0] = { 'index' => $p_inc };
						push @add, \%temp;
					}
				}
			}
			# We want to sort this thing too, by output first, then by input. This time it's a temp array.
			my @rows = ();
			foreach my $p (@{$m->{'production'}}, @add) {
				my $name = GetItem($p->{'item'}, $p->{'index'});
				my $starter_included = 0;
				my %entry = { 'key1' => '', 'key2' => '', 'out' => '' };
				# key1 is the output name, but we need to strip HTML. Because we created the HTML ourselves we know
				# that a simple regex can do the job rather than needing a more robust general approach.
				$entry{'key1'} = StripHTML($name);
				$entry{'out'} = "<tr><td>$name</td>";
				$entry{'out'} .= "<td>";
				my $i_count = 0;
				my $cost = 0;
				foreach my $i (@{$p->{'materials'}}) {
					$name = GetItem($i->{'name'}, $i->{'index'});
					if ($i_count > 0) {
						$name = "+ $name";
					}
					$i_count++;
					my $stack_size = 1;
					if (exists $i->{'stack'} and $i->{'stack'} > 1) {
						$stack_size = $i->{'stack'};
					}
					if (not $starter_included and $starter eq $name) {
						$stack_size++;
						$starter_included = 1;
					}
					if ($stack_size > 1) {
						$name .= " ($stack_size)";
					}
					$entry{'out'} .= "$name<br />";
					if ($entry{'key2'} eq '') {
						$entry{'key2'} = StripHTML($name);
					}
					$cost += $stack_size * GetValue($i->{'name'}, $i->{'index'});
				}
				if (not $starter_included and $starter ne "NO_STARTER") {
					$entry{'out'} .= "+ $starter<br />";
					$cost += GetValue($m->{'starter'}{'name'}, $m->{'starter'}{'index'});
				}
				if (exists $p->{'exclude'}) {
					$entry{'out'} .= '<span class="group">Except ' . join(', ', (map {GetItem($_)} @{$p->{'exclude'}})) . "</span><br />";
				}
				$entry{'out'} .= "</td>";
				my $time = $p->{'time'};
				if ($time > 1440) { 
					$time = "$time min (~" . nearest(.1, $time/1440) . " days)";
				} elsif ($time == 1440) {
					$time = "$time min (~1 day)";
				} elsif ($time >= 60) {
					my $rem = $time%60;
					my $hr = "hr" . ($time > 119 ? "s" : "");
					if ($rem > 0) {
						$time = sprintf("%d min (%d %s, %d min)", $time, $time/60, $hr, $rem);
					} else {
						$time = sprintf("%d min (%d %s)", $time, $time/60, $hr);
					}
				} else {
					$time = "$time min";
				}
				$entry{'out'} .= "<td>$time</td>";
				my $value = $p->{'price'};
				if (not defined $value or $value eq "") {
					$value = GetValue($p->{'item'}, $p->{'index'});
				} elsif ($value =~ /original/) {
					my $temp = GetValue($p->{'item'}, $p->{'index'});
					if (looks_like_number($temp) and $temp > 0) {
						$value =~ s/original/$temp/g;
					}
				}
				if ($value =~ /input/) {
					# We are trying to determine the main ingredient in order to better determine value & profit
					# Since that ingredient was used for the second sort key, we try to look it up.
					my $ingr_value = GetValue($entry{'key2'});
					if (looks_like_number($ingr_value) and $ingr_value >= 0) {
						$value =~ s/input/$ingr_value/g;
					}
				}
				# Now let's do something a wee bit dangerous and try to evaluate the value equation.
				# We aren't doing any sanity-checking on this, and there is the theoretical possibility somebody stuck
				# some malicious perl code in their machine's output equation. But since this script is only being run
				# on specific Stardew Valley mods from people we trust, we will take that risk.
				my $eq_eval = eval $value;
				#print STDOUT "Tried to eval {$value} and got {$eq_eval}\n";
				if ($eq_eval ne '' and looks_like_number($eq_eval)) {
					$value = floor($eq_eval);
				}
				$entry{'out'} .= "<td>$value</td>";
				my $profit = "";
				if ($value =~ /original/ or $value =~ /input/) {
					# This still looks like an equation
					$profit = qq(<span class="note">Varies</span>);
				} else {
					$profit = $value - $cost;
				}
				$entry{'out'} .= "<td>$profit</td>";
				# reuse profit variable for per-minute version.
				if (looks_like_number($profit)) {
					$profit = nearest(.01,60*$profit/$p->{'time'});
				}
				$entry{'out'} .= "<td>$profit</td>";
				$entry{'out'} .= "</tr>";
				push @rows, \%entry;
			}
			foreach my $e (sort {$a->{'key1'} cmp $b->{'key1'} or $a->{'key2'} cmp $b->{'key2'}} @rows) {
				$output .= $e->{'out'};
			}

			$output .= <<"END_PRINT";
</tbody>
</table>
</div>
END_PRINT
			$Panel{$key} = $output;
		} # end of machine loop
	} # end of "json" loop

	foreach my $p (sort keys %Panel) {
		print qq(<li><a href="#$TOC{$p}">$p</a></li>);
	}

	print <<"END_PRINT";
</ul>
</div>
</div>
END_PRINT

	foreach my $p (sort keys %Panel) {
		print $Panel{$p};
	}

	print GetFooter();

	close $FH or die "Error closing file";
}

sub WriteCSS {
	my $FH;
	open $FH, ">$DocBase/ppja-doc-img.css" or die "Can't open ppja-doc-img.css for writing: $!";
	select $FH;

	print <<"END_PRINT";
/* ppja-doc-img.css
 * https://mouseypounds.github.io/ppja-doc/
 */
img.craftables {
	vertical-align: -2px;
	width: 16px;
	height: 32px;
	background-image:url("./img/ss_craftables.png")
}
img.craftables_x2 {
	vertical-align: -5px;
	width: 32px;
	height: 64px;
	background-image:url("./img/ss_craftables_x2.png")
}
img.crops {
	vertical-align: -2px;
	/* Full sprite is 128px */
	width: 16px;
	height: 32px;
	background-image:url("./img/ss_crops.png")
}
img.crops_x2 {
	vertical-align: -2px;
	width: 32px;
	height: 64px;
	background-image:url("./img/ss_crops_x2.png")
}
img.hats {
	vertical-align: -2px;
	width: 20px;
	height: 20px;
	background-image:url("./img/ss_hats.png")
}
img.hats_x2 {
	vertical-align: -2px;
	width: 40px;
	height: 40px;
	background-image:url("./img/ss_hats_x2.png")
}
img.objects {
	vertical-align: -2px;
	width: 16px;
	height: 16px;
	background-image:url("./img/ss_objects.png")
}
img.objects_x2 {
	vertical-align: -2px;
	width: 32px;
	height: 32px;
	background-image:url("./img/ss_objects_x2.png")
}
img.trees {
	vertical-align: -2px;
	width: 48px;
	height: 80px;
	background-image:url("./img/ss_trees.png")
}
img.trees_x2 {
	vertical-align: -2px;
	width: 96px;
	height: 160px;
	background-image:url("./img/ss_trees_x2.png")
}
END_PRINT

	foreach my $id (keys %$SpriteInfo) {
		my $x = $SpriteInfo->{$id}{'x'};
		my $y = $SpriteInfo->{$id}{'y'};
		print <<"END_PRINT";
img#$id {
	background-position: ${x}px ${y}px;
}
END_PRINT
	}
	
	close $FH;
}

__END__ 

my %options = (
	"Base" => 0.0,
	"SG/Ag" => 0.10,
	"SG+Ag" => 0.20,
	"DSG" => 0.25,
	"DSG+Ag" => 0.35,
);

my %game_data = ( 'crops' => {}, 'obj' => {} , 'cook' => {} );
my %ppja_data = ( 'crops' => {}, 'obj' => {} , 'cook' => {} );


sub read_all_ja($+%) {
	my $base_dir = shift;
	my $hash_ref = shift;
	my $DH;
	my $FH;
	my %count = ();
	my @recipes = ();

	opendir($DH, "$base_dir");
	my @mods = readdir($DH);
	closedir $DH;


	foreach my $m (@mods) {
		if (-d "$base_dir\\$m") {
			$count{$m} = { 'regrow' => 0, 'onetime' => 0 };
			# Parse Objects first
			if (-d "$base_dir\\$m\\Objects") {
				opendir($DH, "$base_dir\\$m\\Objects");
				my @files = readdir($DH);
				closedir $DH;
				foreach my $f (@files) {
					if (-d "$base_dir\\$m\\Objects\\$f") {
						if (-e "$base_dir\\$m\\Objects\\$f\\object.json") {
							map_file my $string, "$base_dir\\$m\\Objects\\$f\\object.json";
							my $c = from_rjson($string);
							my $id = $c->{'Name'};
							my @fields = (
								$c->{'Name'},
								$c->{'Price'}/2,
								$c->{'Edibility'},
								$c->{'Category'}, # This should include a category number too
								$c->{'Name'}, # Display Name
								$c->{'Description'},
								);
							$hash_ref->{'obj'}{$id} = \@fields;

							#print Dumper($c);
							if (defined $c->{'Recipe'}) {
								my $from = 'Pierre';
								my $req = 'no prereqs';
								if (defined $c->{'Recipe'}{'PurchaseFrom'}) {
									$from = $c->{'Recipe'}{'PurchaseFrom'};
								}
								if (ref $c->{'Recipe'}{'PurchaseRequirements'} eq 'ARRAY') {
									$req = join(', ', @{$c->{'Recipe'}{'PurchaseRequirements'}});
								}
								push @recipes, sprintf "%s from %s (%s)\n", $c->{'Name'}, $from, $req;
							}
						}
					}
				}
			}
			# Parse Crops
			if (-d "$base_dir\\$m\\Crops") {
				opendir($DH, "$base_dir\\$m\\Crops");
				my @files = readdir($DH);
				closedir $DH;
				foreach my $f (@files) {
					if (-d "$base_dir\\$m\\Crops\\$f") {
						if (-e "$base_dir\\$m\\Crops\\$f\\crop.json") {
							map_file my $string, "$base_dir\\$m\\Crops\\$f\\crop.json";
							# Seed object
							my $c = from_rjson($string);
							my $id = $c->{'SeedName'};
							# Object Entry
							my @o_fields = (
								$c->{'SeedName'},
								$c->{'SeedPurchasePrice'},
								-300, # Should this be blank instead?
								"Seeds -74", # Should this be blank instead?
								$c->{'SeedName'}, # Display Name
								$c->{'SeedDescription'},
								);
							$hash_ref->{'obj'}{$id} = \@o_fields;
							# Crop Entry
							my $bonus = "false";
							if ($c->{'Bonus'}{'MinimumPerHarvest'} > 1 or $c->{'Bonus'}{'ExtraChance'} > 0) {
								$bonus = "true $c->{'Bonus'}{'MinimumPerHarvest'} $c->{'Bonus'}{'MaximumPerHarvest'} $c->{'Bonus'}{'MaxIncreasePerFarmLevel'} $c->{'Bonus'}{'ExtraChance'}";
							}
							my @c_fields = (
								join(" ", @{$c->{'Phases'}}),
								join(" ", @{$c->{'Seasons'}}),
								0,
								$c->{'Product'},
								$c->{'RegrowthPhase'},
								$c->{'HarvestWithScythe'} ? 1 : 0,
								$bonus,
								$c->{'TrellisCrop'} ? "true" : "false",
								"", # This should eventually match "Colors"
								);
							$hash_ref->{'crops'}{$id} = \@c_fields;
							if ($c->{'RegrowthPhase'} == -1) {
								$count{$m}{'onetime'}++;
							} else {
								$count{$m}{'regrow'}++;
							} 
						}
					}
				}
			}
		}
	}
	print "Mod Crop Summary\n";
	print "                   Mod Name                      Regrow  OneTime  Total\n";
	print "  ---------------------------------------------  ------  -------  -----\n";
	foreach my $k (%count) {
		next unless ($k =~ /JA/);
		printf "  %45s  %6d  %7d  %6d\n", $k, $count{$k}{'regrow'}, $count{$k}{'onetime'}, $count{$k}{'regrow'}+$count{$k}{'onetime'};
	}
	print "\n";
	print "Recipe Summary\n";
	print join("", sort @recipes);
}
	
read_yaml("Game\\Crops.yaml", $game_data{'crops'});
read_yaml("Game\\ObjectInformation.yaml", $game_data{'obj'});
# Make some changes for things that have hardcoded price changes
# Strawberry Seeds set to 100g & Rare seeds set to 1000g
# Currently leaving Coffee Bean (433) at 15g; consider changing to 2500g
$game_data{'obj'}{745}[1] = 100;
$game_data{'obj'}{347}[1] = 1000;


print "Vanilla crop total growth times\n";

read_all_ja("PPJA", %ppja_data);

print "\nPPJA crop total growth times\n";
foreach my $k (sort {$a cmp $b} keys %{$ppja_data{'crops'}}) {
	my $base = 0;
	my $out = "";
	foreach my $op (sort {$options{$a} <=> $options{$b}} keys %options) {
		my $all_phases = $ppja_data{'crops'}{$k}[0];
		my @phases = (split(' ', $all_phases));
		$base = calc_reduction($options{$op}, \@phases);
		my $cost = 2*$ppja_data{'obj'}{$k}[1];
		my $sell = 0;
		if (looks_like_number($ppja_data{'crops'}{$k}[3])) {
			$sell = $game_data{'obj'}{$ppja_data{'crops'}{$k}[3]}[1];
		} else {
			$sell = $ppja_data{'obj'}{$ppja_data{'crops'}{$k}[3]}[1];
		}
		my @bonus = (split(' ', $ppja_data{'crops'}{$k}[6]));
		my $harvest = 1;
		if ($bonus[0] eq 'true') {
			$harvest = $bonus[1]+$bonus[4];
		}
		my $income = $sell*$harvest;
		my $profit = sprintf("%d   g(raw)",$income - $cost);
		my $regrowth = "  ";
		if ($ppja_data{'crops'}{$k}[4] > -1) {
			$regrowth = sprintf("+%d",$ppja_data{'crops'}{$k}[4]);
			$profit = sprintf("%.1f g/day ",$income/($ppja_data{'crops'}{$k}[4]));
		}
		my $trellis = ($ppja_data{'crops'}{$k}[7] eq "true")? "t": " ";
		$out .= sprintf(" | %s (%d%%): %2d%2s%s %13s",$op,100*$options{$op},$base,$regrowth,$trellis,$profit);
	}
	printf("%28s $out\n", $k);
}

#print Dumper(\%ppja_data);
