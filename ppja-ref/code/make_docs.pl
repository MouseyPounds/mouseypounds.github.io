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
use Imager;

my $GameData = retrieve("../local/cache_GameData");
my $ModData = retrieve("../local/cache_ModData");
my $ModInfo = retrieve("../local/cache_ModInfo");

my $DocBase = "..";
my $StardewVersion = "1.3.36";

my $SpriteInfo = {};
GatherSpriteInfo($SpriteInfo);

WriteMainIndex();
WriteCookingSummary();
WriteCropSummary();
WriteMachineSummary();
WriteFruitTreeSummary();
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

# GetItem receives 1 or 2 inputs and will use the first one that is defined & not blank.
# It then tries to resolve an ID into a name if it looks like a vanilla item
# Optional 3rd parameter for Formatting (span or wiki link) defaults true.
sub GetItem {
	my $input = shift;
	my $next = shift;
	my $doFormat = shift;
	if (not defined $input or $input eq "") {
		# first one didn't work, now try second
		$input = $next;
	}
	if (not defined $input or $input eq "") {
		# second didn't work either, give up
		return "Unknown Item";
	}
	if (not defined $doFormat) {
		$doFormat = 1;
	}

	my $output = "";
	my $outputSimple = "";
	if (looks_like_number($input)) {
		if ($input < 0) {
			# TODO: This needs better handling, either here or before it gets here
			if ($input == -999) {
				$outputSimple = "Same as Input";
				$output = qq(<span class="group">$outputSimple</span>);
			} else {
				# We want to say "Any ___" but the wiki link should be on just the "___"
				$outputSimple = GetCategory($input);
				$output = '<span class="group">Any ' . Wikify($outputSimple) . '</span>';
				$outputSimple = "Any $outputSimple";
			}
		}
		elsif (exists $GameData->{'ObjectInformation'}{$input}) {
			my $name = $GameData->{'ObjectInformation'}{$input}{'split'}[0];
			$outputSimple = $name;
			$output = Wikify($name);
		}
	} else {
		# Custom, probably JA, but maybe not. JA takes priority
		if (exists $ModData->{'Objects'}{$input}) {
			# This is a JA item, but we have nothing to add yet.
			$outputSimple = $input;
			$output = $input;
		} else {
			foreach my $k (keys %{$GameData->{'ObjectInformation'}}) {
				if ($GameData->{'ObjectInformation'}{$k}{'split'}[0] eq $input) {
					$outputSimple = $input;
					$output = Wikify($input);
				}
			}
		}
	}
	if ($doFormat) {
		if ($output eq '') {
			$output = qq(<span class="note">Unknown Item: $input</span>);
		}
		return $output;
	} else {
		if ($outputSimple eq '') {
			$outputSimple = "Unknown Item: $input";
		}
		return $outputSimple;
	}
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

# GetXP returns the farming xp for a given crop value, by mimicing a formula used in
#  the game function StardewValley.Crop.Harvest()
sub GetXP {
	my $value = shift;
	if (not defined $value or not looks_like_number($value)) {
		warn "GetXP was given an invalid argument: $value";
		return -1;
	}
	return nearest(1, 16*log(0.018*$value + 1.0));
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

# GetImgTag returns the appropriate image tag for an item.
#   input - either ID num (vanilla) or name (mod)
#   type - [optiona] 'machine', 'object', etc. Defaults to 'object'
#   isBig - [optional] true value to use x2 sprites, false (default) otherwise
#   extraClasses - [optional] for additional class tags that need to be added
sub GetImgTag {
	my $input = shift;
	if (not defined $input or $input eq "") {
		warn "GetImgTag can't understand the input";
		return "";
	}
	my $type = shift;
	if (not defined $type or $type eq "") {
		$type = 'object';
	}
	my $isBig = shift;
	if (not defined $isBig or $isBig eq "") {
		$isBig = 0;
	}
	my $img_class = "";
	my $extraClasses = shift;
	if (not defined $extraClasses or $extraClasses eq "") {
		$extraClasses = "";
	} else {
		$img_class = "$extraClasses ";
	}

	# Handle some special cases
	if ($input =~ /^Any (\w+)/) {
		if ($1 =~ /^milk/i) {
			return GetImgTag("Milk", "object", $isBig, $extraClasses);
		} elsif ($1 =~ /^egg/i) {
			return GetImgTag("Egg", "object", $isBig, $extraClasses);
		} elsif ($1 =~ /^fish/i) {
			return GetImgTag("Sardine", "object", $isBig, $extraClasses);
		} elsif ($1 =~ /^flower/i) {
			return GetImgTag("Tulip", "object", $isBig, $extraClasses);
		} elsif ($1 =~ /^fruit/i) {
			return GetImgTag("Orange", "object", $isBig, $extraClasses);
		} elsif ($1 =~ /^vegetable/i) {
			return GetImgTag("Bok Choy", "object", $isBig, $extraClasses);
		} 
	}
	
	my $img_id = "";
	my $img_alt = "";
	if (looks_like_number($input)) {
		if ($input < 0) {
			# Hardcoding particular categories
			if ($input == -6) {
				return GetImgTag("Milk", "object", $isBig, $extraClasses);
			} elsif ($input == -5) {
				return GetImgTag("Egg", "object", $isBig, $extraClasses);
			} elsif ($input == -4) {
				return GetImgTag("Sardine", "object", $isBig, $extraClasses);
			} elsif ($input == -80) {
				return GetImgTag("Tulip", "object", $isBig, $extraClasses);
			} elsif ($input == -79) {
				return GetImgTag("Orange", "object", $isBig, $extraClasses);
			} elsif ($input == -75) {
				return GetImgTag("Bok Choy", "object", $isBig, $extraClasses);
			} 
		} else {
			if ($type =~ /^objects?/i) {
				if (exists $GameData->{'ObjectInformation'}{$input}) {
					my $name = $GameData->{'ObjectInformation'}{$input}{'split'}[0];
					$img_class .= "game_objects";
					$img_id = "Object_$input";
					$img_alt = $name;
				} else {
					warn "GetImgTag failed on unknown vanilla object: $input";
					return "";
				}
			} elsif ($type =~ /^crops?/i) {
				if (exists $GameData->{'Crops'}{$input}) {
					my $name = $GameData->{'ObjectInformation'}{$GameData->{'Crops'}{$input}{'split'}[3]}{'split'}[0];
					$img_class .= "game_crops";
					$img_id = "Crop_$input";
					$img_alt = $name;
				} else {
					warn "GetImgTag failed on unknown vanilla crop: $input";
					return "";
				}
			} elsif ($type =~ /^trees?/i) {
				if (exists $GameData->{'FruitTrees'}{$input}) {
					my $name = $GameData->{'ObjectInformation'}{$GameData->{'FruitTrees'}{$input}{'split'}[2]}{'split'}[0];
					$img_class .= "game_trees";
					$img_id = "Tree_$input";
					$img_alt = $name;
				} else {
					warn "GetImgTag failed on unknown vanilla tree: $input";
					return "";
				}
			} else {
				warn "GetImgTag doesn't understand type $type yet";
				return "";
			}
		}
	} else {
		# Custom, probably JA, but maybe not. JA takes priority
		if ($type =~ /^objects?/i) {
			if (exists $ModData->{'Objects'}{$input}) {
				$img_class .= 'objects';
				$img_id = "Object_$input";
				$img_alt = "$input";
			} else {
				foreach my $k (keys %{$GameData->{'ObjectInformation'}}) {
					if ($GameData->{'ObjectInformation'}{$k}{'split'}[0] eq $input) {
						$img_class .= "game_objects";
						$img_id = "Object_$k";
						$img_alt = $input;
						last;
					}
				}
			}
		} elsif ($type =~ /^crops?/i) {
			if (exists $ModData->{'Crops'}{$input}) {
				$img_class .= 'crops';
				$img_id = "Crop_$input";
				$img_alt = "$input";
			} else {
				warn "GetImgTag can't find crop $input";
				return "";
			}
		} elsif ($type =~ /^trees?/i) {
			if (exists $ModData->{'FruitTrees'}{$input}) {
				$img_class .= 'trees';
				$img_id = "Tree_$input";
				$img_alt = "$input";
			} else {
				warn "GetImgTag can't find tree $input";
				return "";
			}
		} elsif ($type =~ /^machines?/i) {
			# Machine data structure is a giant pain to search. We will trust the input.
			$img_class .= 'craftables';
			$img_id = "Machine_$input";
			$img_alt = "$input";
		} else {
			warn "GetImgTag doesn't understand type $type yet";
			return "";
		}
	}
	$img_id =~ s/ /_/g;
	if ($isBig) {
		$img_class .= "_x2";
		$img_id .= "_x2";
	}
	if ($img_class eq "" or $img_id eq "" or $img_alt = "") {
		warn "GetImgTag failed ($input) ($type) ($isBig) ($extraClasses)";
	}
	return qq(<img class="$img_class" id="$img_id" src="img/blank.png" alt="$img_alt">);
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
		$shortdesc = "Personal reference for the PPJA family of Stardew Valley mods.";
	}
	my $longdesc = shift;
	if (not defined $longdesc) {
		$longdesc = "";
	}
	
	my $output = <<"END_PRINT";
<!DOCTYPE html>
<html>
<head>
<title>Mousey's PPJA Reference: $subtitle</title>

<meta charset="UTF-8" />
<meta property="og:title" content="PPJA $subtitle" />
<meta property="og:description" content="$shortdesc" />
<!-- meta property="og:image" content="https://mouseypounds.github.io/stardew-checkup/og-embed-image.png" / -->
<!-- meta property="twitter:image" content="https://mouseypounds.github.io/stardew-checkup/og-embed-image.png" / -->
<meta name="theme-color" content="#ffe0b0">
<meta name="author" content="MouseyPounds" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />

<link rel="stylesheet" type="text/css" href="./ppja-ref.css" />
<link rel="stylesheet" type="text/css" href="./ppja-ref-img.css" />
<!-- link rel="icon" type="image/png" href="./favicon_c.png" / -->

<!-- Table sorting by https://www.kryogenix.org/code/browser/sorttable/ -->
<script type="text/javascript" src="./sorttable.js"></script>
<script type="text/javascript" src="./ppja-ref-filters.js"></script>

</head>
<body>
<div class="panel" id="header"><h1>Mousey's PPJA Reference: $subtitle</h1>
$longdesc
</div>
END_PRINT

	return $output;
}

# GetHealthAndEnergy - returns health and energy from edibility and optional quality
#   Uses formula from wiki template; should look up actual code ref to verify
sub GetHealthAndEnergy {
	my $edibility = shift;
	my $quality = shift;
	my $health = 0;
	my $energy = 0;
	if (not defined $quality) {
		$quality = 0;
	}
	if (not defined $edibility) {
		warn "GetHealthAndEnergy called with undefined edibility";
	} else {
		if ($edibility <= -300) {
			# Technically, this is just inedible
			$health = "--";
			$energy = "--";
		} else {
			$energy = ceil((2.5 + $quality) * $edibility);
			$health = max(0, floor(0.45 * $energy));
		}
	}
	
	return ($health, $energy);
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
PPJA Reference:
<a href="./index.html">Main Index</a> ||
<a href="./cooking.html">Cooking</a> || 
<a href="./crops.html">Crops</a> || 
<a href="./trees.html">Fruit Trees</a> ||
<a href="./machines.html">Machines</a>
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

# CalcGrowth - Calculates the number of days it will take for a crop to grow from seed
#
#   factor - the pct reduction factor (e.g. .10 for basic speed-gro or agriculturist)
#   phases_ref - a reference to the array of phase data
sub CalcGrowth {
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
			push @results, "($num_hearts+ &#x2665; with " . Wikify($1) . ")";
		} elsif ($arg =~ /^z /) {
			# This can look like either 'z summer, z fall, z winter' or 'z spring summer winter'
			$arg =~ s/[z, ]+/|/g;
			my @removal = split(/\|/, $arg);
			foreach my $r (@removal) {
				my $s = ucfirst $r;
				delete $seasons{$s} if (exists $seasons{$s});
				$changed_seasons = 1;
			}
		} else {
			warn "TranslatePreconditions doesn't know how to deal with {$arg}";
		}
	}
	if ($changed_seasons) {
		my $r = '(' . join(', ', (sort {$seasons{$a} <=> $seasons{$b}} (keys %seasons))) . ')';
		push @results, $r;
	}
	return @results;
}

# GatherSpriteInfo - Goes through the global GameData and ModData structures to find sprite locations
#   and saves them all into a hash.
#
#   HashRef - reference to the hash to use for storage.
sub GatherSpriteInfo {
	my $HashRef = shift;
	if (not defined $HashRef or not (ref $HashRef eq 'HASH')) {
		warn "GatherSpriteInfo was not passed a valid hash ref. Aboring.";
		return 0;
	}
	
	# Vanilla data
	# Crops - coords were saved by gather_data
	foreach my $sid (keys %{$GameData->{'Crops'}}) {
		my $id = "Crop_$sid";
		$id =~ s/ /_/g;
		warn "Sprite ID {$id} will not be unique" if (exists $HashRef->{$id});
		$HashRef->{$id} = { 'x' => 0 - $GameData->{'Crops'}{$sid}{'__SS_X'}, 'y' => 0 - $GameData->{'Crops'}{$sid}{'__SS_Y'} };
		$id .= "_x2";
		$HashRef->{$id} = { 'x' => 0 - 2*($GameData->{'Crops'}{$sid}{'__SS_X'}), 'y' => 0 - 2*$GameData->{'Crops'}{$sid}{'__SS_Y'} };
	}
	# Trees - coords were saved by gather_data
	foreach my $sid (keys %{$GameData->{'FruitTrees'}}) {
		my $id = "Tree_$sid";
		$id =~ s/ /_/g;
		warn "Sprite ID {$id} will not be unique" if (exists $HashRef->{$id});
		$HashRef->{$id} = { 'x' => 0 - $GameData->{'FruitTrees'}{$sid}{'__SS_X'}, 'y' => 0 - $GameData->{'FruitTrees'}{$sid}{'__SS_Y'} };
		$id .= "_x2";
		$HashRef->{$id} = { 'x' => 0 - 2*($GameData->{'FruitTrees'}{$sid}{'__SS_X'}), 'y' => 0 - 2*$GameData->{'FruitTrees'}{$sid}{'__SS_Y'} };
	}
	# Objects - have to calculate coords ourselves
	my $game_objects = Imager->new();
	my $object_width = 16;
	my $object_height = 16;
	$game_objects->read(file=>"../img/game_objects.png") or die "Error reading game object sprites:" . $game_objects->errstr;
	my $objects_per_row = floor($game_objects->getwidth() / 16);
	foreach my $index (keys %{$GameData->{'ObjectInformation'}}) {
		my $id = "Object_$index";
		$id =~ s/ /_/g;
		warn "Sprite ID {$id} will not be unique" if (exists $HashRef->{$id});
		my $x =  $object_width * ($index % $objects_per_row);
		my $y = $object_height * floor($index / $objects_per_row);
		$HashRef->{$id} = { 'x' => 0 - $x, 'y' => 0 - $y };
		$id .= "_x2";
		$HashRef->{$id} = { 'x' => 0 - 2*$x, 'y' => 0 - 2*$y };
	}
	
	# Mod data
	# Machines - because machines can have a variable number of sprites only the single idle animation was
	#   transferred to the sprite sheet and we don't have any further processing to do.
	foreach my $j (@{$ModData->{'Machines'}}) {
		foreach my $m (@{$j->{'machines'}}) {
			my $id = "Machine_$m->{'name'}";
			$id =~ s/ /_/g;
			my $anchor = "TOC_$id";
			warn "Sprite ID {$id} will not be unique" if (exists $HashRef->{$id});
			$HashRef->{$id} = { 'x' => 0 - $m->{'__SS_X'}, 'y' => 0 - $m->{'__SS_Y'} };
			$id .= "_x2";
			warn "Sprite ID {$id} will not be unique" if (exists $HashRef->{$id});
			$HashRef->{$id} = { 'x' => 0 - 2*$m->{'__SS_X'}, 'y' => 0 - 2*$m->{'__SS_Y'} };
		}
	}
	# Crops - the whole 128x32 crop image was transferred to our spritesheet and we need to point to the
	#   "ready for harvest" sprite as well as setting up IDs for the objects for the seeds. The actual
	#   harvested item will be handled by object processing in another section.
	foreach my $key (keys %{$ModData->{'Crops'}}) {
		my @phases = @{$ModData->{'Crops'}{$key}{'Phases'}};
		my $offset = 1 + scalar(@phases);
		my $id = "Crop_$key";
		$id =~ s/ /_/g;
		warn "Sprite ID {$id} will not be unique" if (exists $HashRef->{$id});
		$HashRef->{$id} = { 'x' => 0 - ($ModData->{'Crops'}{$key}{'__SS_X'} + $offset*16), 'y' => 0 - $ModData->{'Crops'}{$key}{'__SS_Y'} };
		$id .= "_x2";
		warn "Sprite ID {$id} will not be unique" if (exists $HashRef->{$id});
		$HashRef->{$id} = { 'x' => 0 - 2*($ModData->{'Crops'}{$key}{'__SS_X'} + $offset*16), 'y' => 0 - 2*$ModData->{'Crops'}{$key}{'__SS_Y'} };
		# The seeds should already have been turned into objects so we don't need to process them here
	}
	# Objects - these should have already been saved, so not much to do
	foreach my $key (keys %{$ModData->{'Objects'}}) {
		my $id = "Object_$key";
		$id =~ s/ /_/g;
		warn "Sprite ID {$id} will not be unique" if (exists $HashRef->{$id});
		$HashRef->{$id} = { 'x' => 0 - $ModData->{'Objects'}{$key}{'__SS_X'}, 'y' => 0 - $ModData->{'Objects'}{$key}{'__SS_Y'} };
		$id .= "_x2";
		warn "Sprite ID {$id} will not be unique" if (exists $HashRef->{$id});
		$HashRef->{$id} = { 'x' => 0 - 2*$ModData->{'Objects'}{$key}{'__SS_X'}, 'y' => 0 - 2*$ModData->{'Objects'}{$key}{'__SS_Y'} };
	}
	# Fruit Trees - The entire set of tree sprites are on the sheet, but the "full" tree is the last one on the list,
	#  384 px beyond the start. This is backwards from how the vanilla tree sprite co-ordinates were saved. Oops.
	foreach my $key (keys %{$ModData->{'FruitTrees'}}) {
		my $id = "Tree_$key";
		$id =~ s/ /_/g;
		warn "Sprite ID {$id} will not be unique" if (exists $HashRef->{$id});
		$HashRef->{$id} = { 'x' => 0 - $ModData->{'FruitTrees'}{$key}{'__SS_X'} - 384, 'y' => 0 - $ModData->{'FruitTrees'}{$key}{'__SS_Y'} };
		$id .= "_x2";
		warn "Sprite ID {$id} will not be unique" if (exists $HashRef->{$id});
		$HashRef->{$id} = { 'x' => 0 - 2*($ModData->{'FruitTrees'}{$key}{'__SS_X'} - 384), 'y' => 0 - 2*$ModData->{'FruitTrees'}{$key}{'__SS_Y'} };
	}

	return 1;
}

# GetIngredients - returns a list of cooking or crafting ingredients for a given item
#
#   item - this item (ID or Name; Name should only be given for mod items)
#   type - [optional] 'cooking' (default) or 'crafting'
sub GetIngredients {
	my $item = shift;
	my $type = shift;
	# Defaults
	my $cat_name = "Cooking";
	my $cat_num = -7;
	
	if (not defined $item or $item eq "") {
		warn "GetIngredients received invalid item ($item)";
		return undef;
	}
	if (defined $type and (lc $type ne 'cooking') and (lc $type ne 'crafting')) {
		warn "GetIngredients received invalid type ($type)";
		return undef;
	} elsif (not defined $type) {
		$type = 'cooking';
	}

	if (lc $type eq 'crafting') {
		$cat_name = "Crafting";
		$cat_num  = -8;
	}
	my @ingr_list = ();
	my $found_recipe = 0;
	
	
	# For base game items, we look the ID up in the ObjectInformation structure and check the category
	#  Then we have to see if we can find a recipe that has that ID as a product
	# For mod items we check for a defined 'Recipe' along with the category.
	if (looks_like_number($item)) {
		if (exists $GameData->{'ObjectInformation'}{$item} and 
			$GameData->{'ObjectInformation'}{$item}{'split'}[3] eq "$cat_name $cat_num") {
			foreach my $cr (keys %{$GameData->{"${cat_name}Recipes"}}) {
				my $id = $GameData->{"${cat_name}Recipes"}{$cr}{'split'}[2];
				if ($id == $item) {
					my @temp = split(/ /,  $GameData->{"${cat_name}Recipes"}{$cr}{'split'}[0]);
					for (my $i = 0; $i < scalar(@temp); $i += 2) {
						my $next_item = $temp[$i];
						my $next_count = $temp[$i+1];
						push @ingr_list, { 'item' => $next_item, 'count' => $next_count };
					}
				}
			}
		}
	} else {
		if (exists $ModData->{'Objects'}{$item} and 
			defined $ModData->{'Objects'}{$item}{'Recipe'} and
			$ModData->{'Objects'}{$item}{'Category'} eq $cat_name) {
			foreach my $i (@{$ModData->{'Objects'}{$item}{'Recipe'}{'Ingredients'}}) {
				my $next_item = $i->{'Object'};
				my $next_count = $i->{'Count'};
				push @ingr_list, { 'item' => $next_item, 'count' => $next_count };
			}
		}	
	}

	# Note, if we could not find a recipe for the item, this list is empty
	return @ingr_list;
}

# AddAllIngredients - helper function for cooking/crafting summary which accumulates ingredient counts
#
#   HashRef - the data structure keeping track of the counts
#   item - this item (ID or Name; Name should only be given for mod items)
#   count - how many of this item
#   type - [optional] 'cooking' (default) or 'crafting'
sub AddAllIngredients {
	my $HashRef = shift;
	my $item = shift;
	my $count = shift;
	my $type = shift;
	
	if (not defined $HashRef or not (ref $HashRef eq 'HASH') or not defined $item or not defined $count or $count <= 0) {
		warn "AddAllIngredients received invalid arguments ($HashRef,$item,$count,$type)";
		return;
	}
	
	if (defined $type and (lc $type ne 'cooking') and (lc $type ne 'crafting')) {
		warn "AddAllIngredients received invalid type ($type)";
		return;
	} elsif (not defined $type) {
		$type = 'cooking';
	}
	
	# enter the recursion.
	my @items_to_add = SearchIngredients($item, $count, $type);
	foreach my $i (@items_to_add) {
		if (not exists $HashRef->{$i->{'item'}}) {
			$HashRef->{$i->{'item'}} = 0;
		}
		$HashRef->{$i->{'item'}} += $i->{'count'};
	}
}

# SearchIngredients - the recursive portion of AddToIngredientList that actually finds the ingredients
#
#   item - this item (ID or Name; Name should only be given for mod items)
#   count - how many of this item
#   type - [optional] 'cooking' (default) or 'crafting'
#   max_depth - [optional] how far to recurse before giving up
sub SearchIngredients {
	my $item = shift;
	my $count = shift;
	my $type = shift;
	my $max_depth = shift;
	
	if (not defined $item or not defined $count or $count <= 0) {
		warn "SearchIngredients received invalid arguments ($item,$count,$type,$max_depth)";
		return undef;
	}
	if (defined $type and (lc $type ne 'cooking') and (lc $type ne 'crafting')) {
		warn "SearchIngredients received invalid type ($type)";
		return undef;
	} elsif (not defined $type) {
		$type = 'cooking';
	}
	if (not defined $max_depth) {
		$max_depth = 5;
	}

	my @ingr_to_return = ();
	
	# Because we don't really have a guaranteed base case, we use the $max_depth value as a failsafe which
	#  limits how deep we can go.
	my $add_current_item_to_output = 1;
	if ($max_depth > 0) {
		my @ingredient_list = GetIngredients($item, $type);
		# We do an explicit check first to know if we need to skip adding the current item to the output
		if (scalar @ingredient_list > 0) {
			$add_current_item_to_output = 0;
			foreach my $i (@ingredient_list) {
				my @temp = SearchIngredients($i->{'item'}, $i->{'count'}, $type, $max_depth-1);
				foreach my $t (@temp) {
					push @ingr_to_return, { 'item'=>$t->{'item'}, 'count'=>$count*$t->{'count'} };
				}
			}
		}
	}
	if ($add_current_item_to_output) {
		# If we got here, it is because either we've reached max depth or we couldn't find a recipe.
		# In either case, we must put the item & count we were given on the list
		push @ingr_to_return, { 'item'=> $item, 'count' => $count };
	}
	
	return @ingr_to_return;
}

###################################################################################################
# WriteMainIndex - index page generation
sub WriteMainIndex {
	my $FH;
	open $FH, ">$DocBase/index.html" or die "Can't open index.html for writing: $!";
	select $FH;

	print STDOUT "Generating Main Index\n";
	my $longdesc = <<"END_PRINT";
<p>Welcome to my personal collection of reference documentation for the PPJA (Project Populate JSON Assets) family of Stardew Valley mods.
The official documentation has always been 
<a href="https://docs.google.com/spreadsheets/d/1D3Kb45faKsXGkT9wGhWaeHZiuFN7WSkewBbLF2Iuyug/edit?usp=sharing">a large spreadsheet</a>
used by the PPJA team for organization, but I found it a bit difficult to use as a player. So this set of webpages was created by a set of
perl scripts to automatically extract information from the various mods (as well as the base game) and put it all together into a
(hopefully) more accessible format.</p>
<p>This reference covers information from the following mods, although each page only includes what is relevant to that topic:</p>
<ul>
<li><a href="https://www.nexusmods.com/stardewvalley/mods/1926">$ModInfo->{'ppja.avcfr'}{'Name'}</a> version $ModInfo->{'ppja.avcfr'}{'Version'}</li>
<li><a href="https://www.nexusmods.com/stardewvalley/mods/1926">$ModInfo->{'ppja.artisanvalleymachinegoods'}{'Name'}</a> version $ModInfo->{'ppja.artisanvalleymachinegoods'}{'Version'}</li>
<li><a href="https://www.nexusmods.com/stardewvalley/mods/1741">$ModInfo->{'PPJA.cannabiskit'}{'Name'}</a> version $ModInfo->{'PPJA.cannabiskit'}{'Version'}</li>
<li><a href="https://www.nexusmods.com/stardewvalley/mods/1742">$ModInfo->{'ppja.evenmorerecipes'}{'Name'}</a> version $ModInfo->{'ppja.evenmorerecipes'}{'Version'}</li>
<li><a href="https://www.nexusmods.com/stardewvalley/mods/1742">$ModInfo->{'ppja.MoreRecipesMeat'}{'Name'}</a> version $ModInfo->{'ppja.MoreRecipesMeat'}{'Version'}</li>
<li><a href="https://www.nexusmods.com/stardewvalley/mods/1610">$ModInfo->{'ParadigmNomad.FantasyCrops'}{'Name'}</a> version $ModInfo->{'ParadigmNomad.FantasyCrops'}{'Version'}</li>
<li><a href="https://www.nexusmods.com/stardewvalley/mods/2075">$ModInfo->{'kildarien.farmertoflorist'}{'Name'}</a> version $ModInfo->{'kildarien.farmertoflorist'}{'Version'}</li>
<li><a href="https://www.nexusmods.com/stardewvalley/mods/1721">$ModInfo->{'paradigmnomad.freshmeat'}{'Name'}</a> version $ModInfo->{'paradigmnomad.freshmeat'}{'Version'}</li>
<li><a href="https://www.nexusmods.com/stardewvalley/mods/1598">$ModInfo->{'ppja.fruitsandveggies'}{'Name'}</a> version $ModInfo->{'ppja.fruitsandveggies'}{'Version'}</li>
<li><a href="https://www.nexusmods.com/stardewvalley/mods/2028">$ModInfo->{'mizu.flowers'}{'Name'}</a> version $ModInfo->{'mizu.flowers'}{'Version'}</li>
<li><a href="https://www.nexusmods.com/stardewvalley/mods/1670">$ModInfo->{'paradigmnomad.morefood'}{'Name'}</a> version $ModInfo->{'paradigmnomad.morefood'}{'Version'}</li>
<li><a href="https://www.nexusmods.com/stardewvalley/mods/1671">$ModInfo->{'ppja.moretrees'}{'Name'}</a> version $ModInfo->{'ppja.moretrees'}{'Version'}</li>
<li><a href="https://www.nexusmods.com/stardewvalley/mods/1764">$ModInfo->{'ppja.starbrewvalley'}{'Name'}</a> version $ModInfo->{'ppja.starbrewvalley'}{'Version'}</li>
<li><a href="https://www.nexusmods.com/stardewvalley/mods/1897">$ModInfo->{'Aquilegia.SweetTooth'}{'Name'}</a> version $ModInfo->{'Aquilegia.SweetTooth'}{'Version'}</li>
</ul>
<p>Below are the links to the various summary pages for this reference. In general, each is a set of sortable tables summarizing various
aspects of the mods. There are some profit calculations included, but by necessity they are simplistic and assume base quality without
any value-adding perks. Those interested in the profit aspect might also want to check out
<a href="https://docs.google.com/spreadsheets/d/1uhRUOdNv68cbqe7yCf1C0pZC6DM_i6sYySSEwHPpy5M/edit#gid=0">this spreadsheet</a> put
together by a different PPJA user.</p>
<ul>
<li><a href="./oooking.html">Cooking</a> - Recipe ingredients and acquisition methods</li>
<li><a href="./crops.html">Crops</a> - Growth timing and other basic information sorted by season; includes base game crops</li>
<li><a href="./trees.html">Fruit Trees</a> - Basic information sorted by season; includes base game trees</li>
<li><a href="./machines.html">Machines</a> - Products, production timings, and crafting recipes</li>
</ul>
END_PRINT
	print GetHeader("Main Index", qq(Reference docs for PPJA mods for Stardew Valley.), $longdesc);
	print GetFooter();
	close $FH or die "Error closing file";
}

###################################################################################################
# WriteCookingSummary - cooking recipes
sub WriteCookingSummary {
	my $FH;
	open $FH, ">$DocBase/cooking.html" or die "Can't open index.html for writing: $!";
	select $FH;

	print STDOUT "Generating Cooking Summary\n";
	my $longdesc = <<"END_PRINT";
<p>Still working on this one; it's just a placeholder for now.</p>
END_PRINT
	print GetHeader("Cooking", qq(Cooking recipes from the PPJA mods for Stardew Valley.), $longdesc);
	print GetTOCStart();
	
	my @Panel = ( 
		{ 'key' => 'Base Game', 'row' => {}, },
		{ 'key' => 'Mods', 'row' => {}, },
		);
		
	my %IngredientCount = ();

	print STDOUT "  Processing Game Cooking Recipes\n";
	foreach my $key (keys %{$GameData->{'CookingRecipes'}}) {
		my $cid = $GameData->{'CookingRecipes'}{$key}{'split'}[2];
		my $cname = GetItem($cid);
		my $imgTag = GetImgTag($cid, "object", 1);
		my $ingr = "";
		my @ingr_list = ();
		my @temp = split(/ /,  $GameData->{'CookingRecipes'}{$key}{'split'}[0]);
		for (my $i = 0; $i < scalar(@temp); $i += 2) {
			my $item = GetItem($temp[$i]);
			my $img = GetImgTag($temp[$i]);
			my $qty = ($temp[$i+1] > 1 ? " ($temp[$i+1])" : "");
			$ingr .= "$img $item$qty<br />";
			AddAllIngredients(\%IngredientCount, $temp[$i], $temp[$i+1]);
		}
		my ($health, $energy) = GetHealthAndEnergy($GameData->{'ObjectInformation'}{$cid}{'split'}[2]);
		my $buffs = "";
		my $source = "";
		my $recipe_cost = "";
		my $value = "";
		my $profit = "";
		my $output = <<"END_PRINT";
<tr>
<td class="name">$imgTag $cname</td>
<td class="name">$ingr</td>
<td class="value">$health</td>
<td class="value">$energy</td>
<td class="name">$buffs</td>
<td>$source</td>
<td class="value">$recipe_cost</td>
<td class="value">$value</td>
<td class="value">$profit</td>
</tr>
END_PRINT

		$Panel[0]->{'row'}{StripHTML($cname)} = $output;
	}

	#TODO: Figure out what to do with bouquets.
	print STDOUT "  Processing Mod Cooking Recipes\n";
	foreach my $key (keys %{$ModData->{'Objects'}}) {
		next if (not defined $ModData->{'Objects'}{$key}{'Recipe'} or $ModData->{'Objects'}{$key}{'Category'} ne 'Cooking');
		my $key = $ModData->{'Objects'}{$key}{'Name'};
		my $cname = GetItem($key);
		#my $cdesc = $ModData->{'Objects'}{$key}{'Description'};
		my $imgTag = GetImgTag($key, "object", 1);
		my $ingr = "";
		my @ingr_list = @{$ModData->{'Objects'}{$key}{'Recipe'}{'Ingredients'}};
		foreach my $i (@ingr_list) {
			my $item = GetItem($i->{'Object'});
			my $img = GetImgTag($i->{'Object'});
			my $qty = ($i->{'Count'} > 1 ? " ($i->{'Count'})" : "");
			$ingr .= "$img $item$qty<br />";
			AddAllIngredients(\%IngredientCount, $i->{'Object'}, $i->{'Count'});
		}
		my ($health, $energy) = GetHealthAndEnergy($ModData->{'Objects'}{$key}{'Edibility'});
		my $buffs = "";
		my $source = "";
		my $recipe_cost = "";
		my $value = "";
		my $profit = "";
		my $output = <<"END_PRINT";
<tr>
<td class="name">$imgTag $cname</td>
<td class="name">$ingr</td>
<td class="value">$health</td>
<td class="value">$energy</td>
<td class="name">$buffs</td>
<td>$source</td>
<td class="value">$recipe_cost</td>
<td class="value">$value</td>
<td class="value">$profit</td>
</tr>
END_PRINT

		$Panel[1]->{'row'}{$key} = $output;
	}
		

	# Print the rest of the TOC
	foreach my $p (@Panel) {
		print qq(<li><a href="#TOC_$p->{'key'}">$p->{'key'}</a></li>);
	}
	print qq(<li><a href="#TOC_Ingredient_List">Ingredient List</a></li>);
	print GetTOCEnd();
	
	# Print the Panels
	foreach my $p (@Panel) {
		print <<"END_PRINT";
<div class="panel" id="TOC_$p->{'key'}">
<h2>$p->{'key'}</h2>

<table class="sortable output">
<thead>
<tr>
<th>Name</th>
<th>Ingredients</th>
<th>H</th>
<th>E</th>
<th>Buffs</th>
<th>Source</th>
<th>Recipe<br />Cost</th>
<th>Product<br />Value</th>
<th>Profit</th></tr>
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
	
	print <<"END_PRINT";
<div class="panel" id="TOC_Ingredient_List">
<h2>Ingredient List</h2>
<p>This is a count of the minimum number the basic ingredients necessary to cook 1 of every item on the above lists. If a cooked item
uses another cooked item as an ingredient, this list counts that second item twice, which means it does overestimate some ingredients.</p>
<table class="sortable output">
<thead>
<tr>
<th>Name</th>
<th>Amount Needed</th>
</thead>
<tbody>
END_PRINT
	
	# loop the ingredients
	foreach my $key (sort {GetItem($a, "", 0) cmp GetItem($b, "", 0)} keys %IngredientCount) {
		my $imgTag = GetImgTag($key);
		my $name = GetItem($key);
		print qq(<tr><td class="name">$imgTag $name</td><td class="value">$IngredientCount{$key}</td></tr>);
	}

	print <<"END_PRINT";
</tbody>
</table>
</div>
END_PRINT
		
	print GetFooter();
	close $FH or die "Error closing file";
}

###################################################################################################
# WriteFruitTreeSummary - main page generation for Fruit Trees
sub WriteFruitTreeSummary {
	my $FH;
	open $FH, ">$DocBase/trees.html" or die "Can't open trees.html for writing: $!";
	select $FH;

	print STDOUT "Generating Fruit Tree Summary\n";
	my $longdesc = <<"END_PRINT";
<p>A summary of fruit trees from the following from the following sources. The checkboxes next to them can be used to
show or hide content specific to that source:</p>
<fieldset id="filter_options" class="filter_set">
<label><input class="filter_check" type="checkbox" name="filter_base_game" id="filter_base_game" value="show" checked="checked"> 
Stardew Valley base game version $StardewVersion</label><br />
<label><input class="filter_check" type="checkbox" name="filter_kildarien_farmertoflorist" id="filter_kildarien_farmertoflorist" value="show" checked="checked"> 
$ModInfo->{'kildarien.farmertoflorist'}{'Name'} version $ModInfo->{'kildarien.farmertoflorist'}{'Version'}</label> 
(<a href="https://www.nexusmods.com/stardewvalley/mods/2075">Nexus page</a>)<br />
<label><input class="filter_check" type="checkbox" name="filter_paradigmnomad_freshmeat" id="filter_paradigmnomad_freshmeat" value="show" checked="checked"> 
$ModInfo->{'paradigmnomad.freshmeat'}{'Name'} version $ModInfo->{'paradigmnomad.freshmeat'}{'Version'}</label> 
(<a href="https://www.nexusmods.com/stardewvalley/mods/1721">Nexus page</a>)<br />
<label><input class="filter_check" type="checkbox" name="filter_ppja_moretrees" id="filter_ppja_moretrees" value="show" checked="checked"> 
$ModInfo->{'ppja.moretrees'}{'Name'} version $ModInfo->{'ppja.moretrees'}{'Version'}</label> 
(<a href="https://www.nexusmods.com/stardewvalley/mods/1671">Nexus page</a>)<br />
</fieldset>

<p>The <span class="note">Break Even Amount</span> column is a simplistic measure of how many base (no-star) quality products need to be sold
to recoup the cost of the initial sapling. Smaller numbers are better, although those who care about these kind of measurements will probably
be processing the items in machines where possible rather than selling them raw.</p>
END_PRINT
	print GetHeader("Fruit Trees", qq(Sumary of fruit tree information from PPJA mods and base game.), $longdesc);
	print GetTOCStart();

	# We will organize this by Season so we start with an array that will hold a hash of the table rows keyed by tree name.
	my @Panel = ( 
		{ 'key' => 'Spring', 'row' => {}, },
		{ 'key' => 'Summer', 'row' => {}, },
		{ 'key' => 'Fall', 'row' => {}, },
		{ 'key' => 'Winter', 'row' => {}, },
		);

	print STDOUT "  Processing Game Fruit Trees\n";
	foreach my $sid (keys %{$GameData->{'FruitTrees'}}) {
		# FruitTree Format -- SaplingID: SpritesheetIndex / Season / ProductID / SaplingPrice
		# We will need to extract some info from ObjectInformation as well but don't sanity-check very often since we trust game data
		my $sname = GetItem($sid);
		my $sprite_index = $GameData->{'FruitTrees'}{$sid}{'split'}[0];
		my $season = $GameData->{'FruitTrees'}{$sid}{'split'}[1];
		my $cid = $GameData->{'FruitTrees'}{$sid}{'split'}[2];
		my $scost = $GameData->{'FruitTrees'}{$sid}{'split'}[3];
		my $cname = GetItem($cid);
		my $cprice = $GameData->{'ObjectInformation'}{$cid}{'split'}[1];
		my $seed_vendor = Wikify("Pierre");
		my $imgTag = GetImgTag($sid, "tree");
		my $prodImg = GetImgTag($cid, "object");
		my $seedImg = GetImgTag($sid, "object");
		my $amt = ceil($scost/$cprice);
		
		my $output = <<"END_PRINT";
<tr class="filter_base_game">
<td class="icon">$imgTag</td>
<td class="name">$prodImg $cname</td>
<td class="name">$seedImg $sname</td>
<td>$seed_vendor</td>
<td class="value">$scost</td>
<td class="value">$cprice</td>
<td class="value">$amt</td>
</tr>
END_PRINT

		foreach my $p (@Panel) {
			my $check = lc $p->{'key'};
			if ($season =~ /$check/) {
				$p->{'row'}{StripHTML($cname)} = $output;
			}
		}
	}

	print STDOUT "  Processing Mod Fruit Trees\n";
	foreach my $key (keys %{$ModData->{'FruitTrees'}}) {
		# The keys for the Mod Trees hash should be the names of the trees but don't have to be
		my $sname = $ModData->{'FruitTrees'}{$key}{'SaplingName'};
		my $scost = $ModData->{'FruitTrees'}{$key}{'SaplingPurchasePrice'};
		my $season = $ModData->{'FruitTrees'}{$key}{'Season'};
		my $cname = GetItem($ModData->{'FruitTrees'}{$key}{'Product'});
		my $cprice = GetValue($ModData->{'FruitTrees'}{$key}{'Product'});
		my $seed_vendor = Wikify("Pierre");
		if (exists $ModData->{'FruitTrees'}{$key}{'SaplingPurchaseFrom'}) {
			$seed_vendor = Wikify($ModData->{'FruitTrees'}{$key}{'SaplingPurchaseFrom'});
		}
		if (exists $ModData->{'FruitTrees'}{$key}{'SaplingPurchaseRequirements'} and defined $ModData->{'FruitTrees'}{$key}{'SaplingPurchaseRequirements'}) {
			my @req = TranslatePreconditions(@{$ModData->{'FruitTrees'}{$key}{'SaplingPurchaseRequirements'}});
			# Note that the order here is not guaranteed. If we start getting crops with multiple different requirements we might have to deal with that
			$seed_vendor .= '<br />' . join('<br />', @req);
		}
		my $imgTag = GetImgTag($key, 'tree');
		my $prodImg = GetImgTag($ModData->{'FruitTrees'}{$key}{'Product'}, "object");
		my $seedImg = GetImgTag($sname, "object");
		my $amt = ceil($scost/$cprice);

		my $output = <<"END_PRINT";
<tr class="$ModData->{'FruitTrees'}{$key}{'__FILTER'}">
<td class="icon">$imgTag</td>
<td class="name">$prodImg $cname</td>
<td class="name">$seedImg $sname</td>
<td>$seed_vendor</td>
<td class="value">$scost</td>
<td class="value">$cprice</td>
<td class="value">$amt</td>
</tr>
END_PRINT

		foreach my $p (@Panel) {
			my $check = lc $p->{'key'};
			if ($season =~ /$check/) {
				$p->{'row'}{StripHTML($cname)} = $output;
			}
		}
	}
	
	# Print the rest of the TOC
	foreach my $p (@Panel) {
		print qq(<li><a href="#TOC_$p->{'key'}">$p->{'key'} Trees</a></li>);
	}
	print GetTOCEnd();
	
	# Print the Panels
	foreach my $p (@Panel) {
		print <<"END_PRINT";
<div class="panel" id="TOC_$p->{'key'}">
<h2>$p->{'key'} Trees</h2>

<table class="sortable output">
<thead>
<tr>
<th>Image</th>
<th>Product Name</th>
<th>Sapling Name</th>
<th>Sapling Vendor<br />(&amp; Requirements)</th>
<th>Sapling<br />Price</th>
<th>Product<br />Value</th>
<th>Break Even<br />Amount</th></tr>
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

###################################################################################################
# WriteMachineSummary - main page generation for Machines
sub WriteMachineSummary {
	my $FH;
	open $FH, ">$DocBase/machines.html" or die "Can't open machines.html for writing: $!";
	select $FH;

	print STDOUT "Generating Machine Summary\n";
	my $longdesc = <<"END_PRINT";
<p>A summary of machines from the following mods:</p>


<ul>
<li><a href="https://www.nexusmods.com/stardewvalley/mods/1926">$ModInfo->{'ppja.avcfr'}{'Name'}</a> version $ModInfo->{'ppja.avcfr'}{'Version'}
including enabling recipes from:
  <ul>
  <li><a href="https://www.nexusmods.com/stardewvalley/mods/1897">$ModInfo->{'Aquilegia.SweetTooth'}{'Name'}</a> version $ModInfo->{'Aquilegia.SweetTooth'}{'Version'}</li>
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
	print GetHeader("Machines", qq(Summary of products and timings for machines from PPJA mods), $longdesc);
	print GetTOCStart();

	my %TOC = ();

	print STDOUT "  Processind Mod Machines\n";
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
			my $anchor = "TOC_$m->{'name'}";
			$anchor =~ s/ /_/g;
			$TOC{$m->{'name'}} = $anchor;
			my $imgTag = GetImgTag($m->{'name'}, 'machine', 1, "container__image");
			#HERE 1st img tag
			my $output = <<"END_PRINT";
<div class="panel" id="$anchor">
<div class="container">
$imgTag
<div class="container__text">
<h2>$m->{'name'}</h2>
<span class="mach_desc">$m->{'description'}</span><br />
</div>
$extra_info
</div>
<table class="recipe">
<tbody><tr><th>Crafting Recipe</th><td class="name">
END_PRINT

			my @recipe = split(' ', $m->{'crafting'});
			for (my $i = 0; $i < scalar(@recipe); $i += 2) {
				my $num = $recipe[$i+1];
				$output .= GetImgTag($recipe[$i]) . " " . GetItem($recipe[$i]) . ($num > 1 ? " ($num)" : "" ) . "<br />";
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
				my $img = GetImgTag($entry{'key1'});
				$entry{'out'} = qq(<tr><td class="name">$img $name</td>);
				$entry{'out'} .= qq(<td class="name">);
				my $i_count = 0;
				my $cost = 0;
				foreach my $i (@{$p->{'materials'}}) {
					$name = GetItem($i->{'name'}, $i->{'index'});
					$img = GetImgTag(StripHTML($name));
					if ($i_count > 0) {
						#$name = "+ $name";
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
					$entry{'out'} .= "$img $name<br />";
					if ($entry{'key2'} eq '') {
						$entry{'key2'} = StripHTML($name);
					}
					$cost += $stack_size * GetValue($i->{'name'}, $i->{'index'});
				}
				if (not $starter_included and $starter ne "NO_STARTER") {
					$img = GetImgTag(StripHTML($starter));
					$entry{'out'} .= "$img $starter<br />";
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
				$entry{'out'} .= qq(<td class="value">$value</td>);
				my $profit = "";
				if ($value =~ /original/ or $value =~ /input/) {
					# This still looks like an equation
					$profit = qq(<span class="note">Varies</span>);
				} else {
					$profit = $value - $cost;
				}
				$entry{'out'} .= qq(<td class="value">$profit</td>);
				# reuse profit variable for per-hour version.
				if (looks_like_number($profit)) {
					$profit = nearest(.01,60*$profit/$p->{'time'});
				}
				$entry{'out'} .= qq(<td class="value">$profit</td>);
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
	print GetTOCEnd();

	foreach my $p (sort keys %Panel) {
		print $Panel{$p};
	}

	print GetFooter();

	close $FH or die "Error closing file";
}

###################################################################################################
# CropSummary - main page generation for crops
sub WriteCropSummary {
	my $FH;
	open $FH, ">$DocBase/crops.html" or die "Can't open crops.html for writing: $!";
	select $FH;

	print STDOUT "Generating Crop Summary\n";	
	my $longdesc = <<"END_PRINT";
<p>A summary of growth and other basic information for crops from the following sources. The checkboxes next to them can be used to
show or hide content specific to that source:</p>
<fieldset id="filter_options" class="filter_set">
<label><input class="filter_check" type="checkbox" name="filter_base_game" id="filter_base_game" value="show" checked="checked"> 
Stardew Valley base game version $StardewVersion</label><br />
<label><input class="filter_check" type="checkbox" name="filter_PPJA_cannabiskit" id="filter_PPJA_cannabiskit" value="show" checked="checked"> 
$ModInfo->{'PPJA.cannabiskit'}{'Name'} version $ModInfo->{'PPJA.cannabiskit'}{'Version'}</label> (<a href="https://www.nexusmods.com/stardewvalley/mods/1741">Nexus page</a>)<br />
<label><input class="filter_check" type="checkbox" name="filter_ParadigmNomad_FantasyCrops" id="filter_ParadigmNomad_FantasyCrops" value="show" checked="checked"> 
$ModInfo->{'ParadigmNomad.FantasyCrops'}{'Name'} version $ModInfo->{'ParadigmNomad.FantasyCrops'}{'Version'}</label> 
(<a href="https://www.nexusmods.com/stardewvalley/mods/1610">Nexus page</a>)<br />
<label><input class="filter_check" type="checkbox" name="filter_kildarien_farmertoflorist" id="filter_kildarien_farmertoflorist" value="show" checked="checked"> 
$ModInfo->{'kildarien.farmertoflorist'}{'Name'} version $ModInfo->{'kildarien.farmertoflorist'}{'Version'}</label> 
(<a href="https://www.nexusmods.com/stardewvalley/mods/2075">Nexus page</a>)<br />
<label><input class="filter_check" type="checkbox" name="filter_paradigmnomad_freshmeat" id="filter_paradigmnomad_freshmeat" value="show" checked="checked"> 
$ModInfo->{'paradigmnomad.freshmeat'}{'Name'} version $ModInfo->{'paradigmnomad.freshmeat'}{'Version'}</label> 
(<a href="https://www.nexusmods.com/stardewvalley/mods/1721">Nexus page</a>)<br />
<label><input class="filter_check" type="checkbox" name="filter_ppja_fruitsandveggies" id="filter_ppja_fruitsandveggies" value="show" checked="checked"> 
$ModInfo->{'ppja.fruitsandveggies'}{'Name'} version $ModInfo->{'ppja.fruitsandveggies'}{'Version'}</label> 
(<a href="https://www.nexusmods.com/stardewvalley/mods/1598">Nexus page</a>)<br />
<label><input class="filter_check" type="checkbox" name="filter_mizu_flowers" id="filter_mizu_flowers" value="show" checked="checked"> 
$ModInfo->{'mizu.flowers'}{'Name'} version $ModInfo->{'mizu.flowers'}{'Version'}</label> 
(<a href="https://www.nexusmods.com/stardewvalley/mods/2028">Nexus page</a>)<br />
</fieldset>
<p>In the following tables, the <img class="game_weapons" id="Weapon_Scythe" src="img/blank.png" alt="Needs Scythe"> column is for whether or not
the crop requires a scythe to harvest, and the <img class="game_crops" id="Special_Trellis" src="img/blank.png" alt="Has Trellis"> column is for
whether the crop has a trellis (or similar structure that blocks walking on it). The <span class="note">XP</span> column is the amount of
experience gained on a single harvest. Normally this is Farming experience, but for the seasonal forage crops it is Foraging experience.
The <span class="note">Seasonal Profit</span> column is an average full-season estimate that assumes the maximum number of harvests in the
month with the product sold raw at base (no-star) quality without any value-increasing professions (like Tiller.)
It also assumes all seeds are bought at the shown price and does not account for any other costs (such as purchasing fertilizer).
The growth times, maximum number of harvests, and profit all depend on growth speed modifiers which can be set in the form
below and apply to all the tables on this page.</p>
<fieldset id="growth_speed_options" class="radio_set">
<label><input type="radio" name="speed" value="0" checked="checked"> No speed modifiers</label><br />
<label><input type="radio" name="speed" value="10"> 10% (Only one of <a href="https://stardewvalleywiki.com/Farming#Farming_Skill">Agriculturist</a> Profession or <a href="https://stardewvalleywiki.com/Speed-Gro">Speed-Gro</a> Fertilizer</label>)</label><br />
<label><input type="radio" name="speed" value="20"> 20% (Both <a href="https://stardewvalleywiki.com/Farming#Farming_Skill">Agriculturist</a> Profession and <a href="https://stardewvalleywiki.com/Speed-Gro">Speed-Gro</a> Fertilizer</label>)</label><br />
<label><input type="radio" name="speed" value="25"> 25% (Only <a href="https://stardewvalleywiki.com/Deluxe_Speed-Gro">Deluxe Speed-Gro</a> Fertilizer)</label><br />
<label><input type="radio" name="speed" value="35"> 35% (Both <a href="https://stardewvalleywiki.com/Farming#Farming_Skill">Agriculturist</a> Profession and <a href="https://stardewvalleywiki.com/Deluxe_Speed-Gro">Deluxe Speed-Gro</a> Fertilizer)</label>
</fieldset>
<input type="hidden" id="last_speed" value="0" />
END_PRINT

	print GetHeader("Crop Summary", qq(Growth and other crop information for PPJA and base game), $longdesc);
	print GetTOCStart();

	# We will organize this by Season so we start with an array that will hold a hash of the table rows keyed by crop name.
	my @Panel = ( 
		{ 'key' => 'Spring', 'row' => {}, },
		{ 'key' => 'Summer', 'row' => {}, },
		{ 'key' => 'Fall', 'row' => {}, },
		{ 'key' => 'Winter', 'row' => {}, },
		{ 'key' => 'Indoor-Only', 'row' => {}, },
		#{ 'key' => 'Winter', 'row' => {}, },
		#{ 'key' => 'Winter', 'row' => {}, },
		);

	print STDOUT "  Processing Game Crops\n";
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
		my $num_harvest = $multi_data[0];
		if ($num_harvest eq 'true') {
			my ($ignored, $min, $max, $inc_per_level, $extra_chance) = @multi_data;
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
				$season_str = "indoor-only";
			}
		} elsif ($crop eq 'Strawberry') {
			$seed_vendor .= "<br />(at " . Wikify("Egg Festival") . ")";
			$scost = 100;
		} elsif ($crop eq 'Coffee Bean') {
			$seed_vendor = Wikify("Traveling Cart");
			$scost = 2500;
		} elsif ($crop eq 'Sweet Gem Berry') {
			$seed_vendor = Wikify("Traveling Cart");
			$scost = 1000;
		} elsif ($crop eq 'Ancient Fruit') {
			$seed_vendor = qq(<span class="note">None</span>);
			$scost = 0;
		}
		if ($crop eq 'Garlic' or $crop eq 'Red Cabbage' or $crop eq 'Artichoke') {
			$seed_vendor .= "<br />(Year 2+)";
		}
		my $imgTag = GetImgTag($sid, "crop");
		my $prodImg = GetImgTag($cid, "object");
		my $seedImg = GetImgTag($sid, "object");
		my $xp = GetXP($cprice);
		# Adjustments for forage crops
		# TODO: Handle value (perhaps an average for $cprice)
		if ($crop eq "Wild Horseradish") {
			$cname = qq(<span class="group">Spring Forage</span>);
			$xp = 3;
			$seed_vendor = qq(<span class="note">None</span>);
			$scost = 0;
		} elsif ($crop eq "Spice Berry") {
			$cname = qq(<span class="group">Summer Forage</span>);
			$xp = 3;
			$seed_vendor = qq(<span class="note">None</span>);
			$scost = 0;
		} elsif ($crop eq "Common Mushroom") {
			$cname = qq(<span class="group">Fall Forage</span>);
			$xp = 3;
			$seed_vendor = qq(<span class="note">None</span>);
			$scost = 0;
		} elsif ($crop eq "Winter Root") {
			$cname = qq(<span class="group">Winter Forage</span>);
			$xp = 3;
			$seed_vendor = qq(<span class="note">None</span>);
			$scost = 0;
		} 
		
		my $output = <<"END_PRINT";
<tr class="filter_base_game">
<td class="icon">$imgTag</td>
<td class="name">$prodImg $cname</td>
<td class="name">$seedImg $sname</td>
<td>$seed_vendor</td>
<td class="value">$scost</td>
<td>$need_scythe</td>
<td>$is_trellis</td>
<td class="value">$num_harvest</td>
<td class="value">$cprice</td>
<td class="value">$xp</td>
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
			my $cost = ($regrowth > 0) ? $scost : $num_harvest*$scost;
			my $profit = nearest(1, $cprice * $num_harvest * $max_harvests - $cost);
			$output .= <<"END_PRINT";
<td class="col_$opt value">$growth</td>
<td class="col_$opt value">$regrowth</td>
<td class="col_$opt value">$max_harvests</td>
<td class="col_$opt value">$profit</td>
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

	print STDOUT "  Processing Mod Crops\n";
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
		my @colors = ();
		if (exists $ModData->{'Crops'}{$key}{'Colors'} and defined $ModData->{'Crops'}{$key}{'Colors'}) {
			@colors = @{$ModData->{'Crops'}{$key}{'Colors'}};
		}
		if (scalar @colors > 1) {
			# If we ever deal with the colors, it'd happen here.
		}
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
		my $imgTag = GetImgTag($key, 'crop');
		my $prodImg = GetImgTag($ModData->{'Crops'}{$key}{'Product'}, "object");
		my $seedImg = GetImgTag($sname, "object");
		my $xp = GetXP($cprice);
		my $output = <<"END_PRINT";
<tr class="$ModData->{'Crops'}{$key}{'__FILTER'}">
<td class="icon">$imgTag</td>
<td class="name">$prodImg $cname</td>
<td class="name">$seedImg $sname</td>
<td>$seed_vendor</td>
<td class="value">$scost</td>
<td>$need_scythe</td>
<td>$is_trellis</td>
<td class="value">$num_harvest</td>
<td class="value">$cprice</td>
<td class="value">$xp</td>
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
			my $cost = ($regrowth > 0) ? $scost : $num_harvest*$scost;
			my $profit = nearest(1, $cprice * $num_harvest * $max_harvests - $cost);
			$output .= <<"END_PRINT";
<td class="col_$opt value">$growth</td>
<td class="col_$opt value">$regrowth</td>
<td class="col_$opt value">$max_harvests</td>
<td class="col_$opt value">$profit</td>
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
	print GetTOCEnd();
	
	# Print the Panels
	foreach my $p (@Panel) {
		print <<"END_PRINT";
<div class="panel" id="TOC_$p->{'key'}">
<h2>$p->{'key'} Crops</h2>

<table class="sortable output">
<thead>
<tr>
<th>Img</th>
<th>Crop Name</th>
<th>Seed Name</th>
<th>Seed Vendor<br />(&amp; Requirements)</th>
<th>Seed<br />Price</th>
<th><img class="game_weapons" id="Weapon_Scythe" src="img/blank.png" alt="Needs Scythe"></th>
<th><img class="game_crops" id="Special_Trellis" src="img/blank.png" alt="Has Trellis"></th>
<th>Avg<br />Yield</th>
<th>Crop<br />Value</th>
<th>XP</th>
<th class="col_0">Initial<br />Growth</th>
<th class="col_0">Regrowth</th>
<th class="col_0">Maximum<br />Harvests</th>
<th class="col_0">Seasonal<br />Profit</th>
<th class="col_10">Initial<br />Growth</th>
<th class="col_10">Regrowth</th>
<th class="col_10">Maximum<br />Harvests</th>
<th class="col_10">Seasonal<br />Profit</th>
<th class="col_20">Initial<br />Growth</th>
<th class="col_20">Regrowth</th>
<th class="col_20">Maximum<br />Harvests</th>
<th class="col_20">Seasonal<br />Profit</th>
<th class="col_25">Initial<br />Growth</th>
<th class="col_25">Regrowth</th>
<th class="col_25">Maximum<br />Harvests</th>
<th class="col_25">Seasonal<br />Profit</th>
<th class="col_35">Initial<br />Growth</th>
<th class="col_35">Regrowth</th>
<th class="col_35">Maximum<br />Harvests</th>
<th class="col_35">Seasonal<br />Profit</th>
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

###################################################################################################
# WriteCSS - Iterates through the SpriteInfo structure and writes out the appropriate CSS for each ID
sub WriteCSS {
	my $FH;
	open $FH, ">$DocBase/ppja-ref-img.css" or die "Can't open ppja-ref-img.css for writing: $!";
	select $FH;

	# First, the basic classes for each spritesheet
	print <<"END_PRINT";
/* ppja-ref-img.css
 * https://mouseypounds.github.io/ppja-ref/
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
	vertical-align: -10px;
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
img.game_craftables {
	vertical-align: -2px;
	width: 16px;
	height: 32px;
	background-image:url("./img/game_craftables.png")
}
img.game_craftables_x2 {
	vertical-align: -5px;
	width: 32px;
	height: 64px;
	background-image:url("./img/game_craftables_x2.png")
}
img.game_crops {
	vertical-align: -2px;
	/* Full sprite is 128px */
	width: 16px;
	height: 32px;
	background-image:url("./img/game_crops.png")
}
img.game_crops_x2 {
	vertical-align: -2px;
	width: 32px;
	height: 64px;
	background-image:url("./img/game_crops_x2.png")
}
img.game_hats {
	vertical-align: -2px;
	width: 20px;
	height: 20px;
	background-image:url("./img/game_hats.png")
}
img.game_hats_x2 {
	vertical-align: -2px;
	width: 40px;
	height: 40px;
	background-image:url("./img/game_hats_x2.png")
}
img.game_objects {
	vertical-align: -2px;
	width: 16px;
	height: 16px;
	background-image:url("./img/game_objects.png")
}
img.game_objects_x2 {
	vertical-align: -10px;
	width: 32px;
	height: 32px;
	background-image:url("./img/game_objects_x2.png")
}
img.game_trees {
	vertical-align: -2px;
	width: 48px;
	height: 80px;
	background-image:url("./img/game_trees.png")
}
img.game_trees_x2 {
	vertical-align: -2px;
	width: 96px;
	height: 160px;
	background-image:url("./img/game_trees_x2.png")
}
img.game_weapons {
	vertical-align: -2px;
	width: 16px;
	height: 16px;
	background-image:url("./img/game_weapons.png")
}
img.game_weapons_x2 {
	vertical-align: -2px;
	width: 32px;
	height: 32px;
	background-image:url("./img/game_weapons_x2.png")
}
END_PRINT

	# Now a few hardcoded extras
	# Trellis is first sprite for grapes (0,608)
	# Scythe is on game_weapons (112,80)
		print <<"END_PRINT";
img#Special_Trellis {
	background-position: 0px -608px;
}
img#Special_Trellis_x2 {
	background-position: 0px -1216px;
}
img#Weapon_Scythe {
	background-position: -112px -80px;
}
img#Weapon_Scythe_x2 {
	background-position: -224px -160px;
}
END_PRINT
	
	# Finally, everything that was gathered in SpriteInfo
	foreach my $id (sort keys %$SpriteInfo) {
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
