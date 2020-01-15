#!/bin/perl -w
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
use HTML::Entities;
use Text::Autoformat;

my $GameData = retrieve("../local/cache_GameData");
my $ModData = retrieve("../local/cache_ModData");
my $ModInfo = retrieve("../local/cache_ModInfo");

my $DocBase = "..";
my $StardewVersion = "1.4.3";

my $SpriteInfo = {};
GatherSpriteInfo($SpriteInfo);

my $Tagged = {};
UpdateTags();
my $Categorized = {};
UpdateCategories();

my %Machines = ();
WriteMainIndex();
WriteCookingSummary();
WriteCropSummary();
WriteMachineSummary();
WriteCraftingSummary();
WriteFruitTreeSummary();
WriteGiftSummary();
WriteCSS();

exit;

# AddCommas - Adds appropriate commas to a number as thousands separators
#  This is the `commify` function from O'Reilly's Perl Cookbook by Nathan Torkington and Tom Christiansen
#  See https://www.oreilly.com/library/view/perl-cookbook/1565922433/ch02s18.html
sub AddCommas {
	my $text = reverse $_[0];
    $text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
    return scalar reverse $text;
}

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

# WikiShop: Get wikified link for the shop which corresponds to a given NPC. Defaults to Pierre
sub WikiShop {
	my $NPC = shift;
	my $shop = "";
	if (not defined $NPC) {
		$NPC = "Pierre";
	}
	# Handling weird placeholder disabler from Ancient Crops
	if ($NPC =~ /DONTSELLTHISATNPC/i) {
		return '<span class="note">None</span>';
	}	
	if ($NPC =~ /Pierre/i) { $shop = "Pierre%27s_General_Store"; } 
	elsif ($NPC =~ /Clint/i) { $shop = "Blacksmith"; } 
	elsif ($NPC =~ /Dwarf/i) { $shop = "Dwarf"; } 
	elsif ($NPC =~ /Gus/i) { $shop = "The_Stardrop_Saloon";	}
	elsif ($NPC =~ /Harvey/i) {	$shop = "Harvey%27s_Clinic"; }
	elsif ($NPC =~ /Hatmouse/i) { $shop = "Abandoned_House"; }
	elsif ($NPC =~ /Krobus/i) {	$shop = "Krobus"; }
	elsif ($NPC =~ /Marlon/i) {	$shop = "Adventurer%27s_Guild";	}
	elsif ($NPC =~ /Marnie/i) {	$shop = "Marnie%27s_Ranch";	} 
	elsif ($NPC =~ /Robin/i) { $shop = "Carpenter%27s_Shop"; }
	elsif ($NPC =~ /Sandy/i) { $shop = "Oasis"; }
	elsif ($NPC =~ /Traveling Merchant/i) { $shop = "Traveling_Cart"; }
	elsif ($NPC =~ /Willy/i) { $shop = "Fish_Shop";	}
	else {
		warn "WikiShop: unknown vendor ($NPC);"
	}
	return qq(<a href="http://stardewvalleywiki.com/$shop">$NPC</a>);
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
# Optional 4th parameter to indicate a base game craftable
sub GetItem {
	my $input = shift;
	my $next = shift;
	my $doFormat = shift;
	my $isCraftable = shift;
	
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
	if (not defined $isCraftable) {
		$isCraftable = 0;
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
				# These used to be "Any ___" with a wiki link on the "___", but to support mod
				#  items better we are moving to a tooltip list.
				my $list = join(', ', @{$Categorized->{$input}});
				$outputSimple = GetCategory($input);
				$output = qq(<span class="group" tooltip="Includes $list">Any $outputSimple</span>);
				$outputSimple = "Any $outputSimple";
			}
		} else {
			if ($isCraftable && exists $GameData->{'BigCraftablesInformation'}{$input}) {
				my $name = $GameData->{'BigCraftablesInformation'}{$input}{'split'}[0];
				$outputSimple = $name;
				$output = Wikify($name);			
			} elsif (exists $GameData->{'ObjectInformation'}{$input}) {
				my $name = $GameData->{'ObjectInformation'}{$input}{'split'}[0];
				$outputSimple = $name;
				$output = Wikify($name);
			}
		}
	} else {
		# Custom, probably JA, but maybe not. JA takes priority
		my $found = 0;
		if (exists $ModData->{'Objects'}{$input}) {
			# This is a JA item, but we have nothing to add yet.
			my $mod = "a mod";
			if (exists $ModData->{'Objects'}{$input}{'__MOD_ID'} and exists $ModInfo->{$ModData->{'Objects'}{$input}{'__MOD_ID'}}{'Name'}) {
				$mod = $ModInfo->{$ModData->{'Objects'}{$input}{'__MOD_ID'}}{'Name'};
			} else {
				warn "Couldn't determine parent mod for $input";
			}
			$outputSimple = encode_entities($input);
			my $encoded = encode_entities($input);
			$output = qq(<span tooltip="from $mod">$encoded</span>);
			$found = 1;
		} else {
			foreach my $k (keys %{$GameData->{'ObjectInformation'}}) {
				if ($GameData->{'ObjectInformation'}{$k}{'split'}[0] eq $input) {
					$outputSimple = $input;
					$output = Wikify($input);
					$found = 1;
					last;
				}
			}
		}
		if (not $found) {
			if (exists $ModData->{'BigCraftables'}{$input}) {
				# This is a JA item, but we have nothing to add yet.
				my $mod = "a mod";
				if (exists $ModData->{'BigCraftables'}{$input}{'__MOD_ID'} and exists $ModInfo->{$ModData->{'BigCraftables'}{$input}{'__MOD_ID'}}{'Name'}) {
					$mod = $ModInfo->{$ModData->{'BigCraftables'}{$input}{'__MOD_ID'}}{'Name'};
				} else {
					warn "Couldn't determine parent mod for $input";
				}
				$outputSimple = encode_entities($input);
				my $encoded = encode_entities($input);
				$output = qq(<span tooltip="from $mod">$encoded</span>);
				$found = 1;
			} else {
				foreach my $k (keys %{$GameData->{'BigCraftablesInformation'}}) {
					if ($GameData->{'BigCraftablesInformation'}{$k}{'split'}[0] eq $input) {
						$outputSimple = $input;
						$output = Wikify($input);
						$found = 1;
						last;
					}
				}
			}
		}
		# If no match on name itself, we next try tags
		if (not $found) {
			if (exists $Tagged->{$input}) {
				# Let's make the tooltip for these actually list appropriate items
				my $list = join(', ', @{$Tagged->{$input}});
				# A bit of hardcoding here. Most tags look like blah_item or fish_blah
				# We use Text:Autoformat for capitalization, but then have to undo the 2 newlines it adds;
				if ($input =~ /_item$/) {
					$input =~ s/_/ /g;
					$input = autoformat $input, { case => 'highlight', left=>0 };
					$input =~ s/\n\n$//;
					$outputSimple =  $input;
					$output = qq(<span class="group" tooltip="Includes $list">$outputSimple</span>);
				} elsif ($input =~ /^fish_/ or $input =~ /^flower_/) {
					$input =~ s/_/ /g;
					$input =~ s/(\S+) (.*)/$2 $1/;
					$input = autoformat $input, { case => 'highlight', left=>0 };
					$input =~ s/\n\n$//;
					$outputSimple = $input;
					$output = qq(<span class="group" tooltip="Includes $list">$outputSimple</span>);
				} else {
					$input =~ s/_/ /g;
					$input = "$input (Tag)";
					$input = autoformat $input, { case => 'highlight', left=>0 };
					$input =~ s/\n\n$//;
					$outputSimple = $input;
					$output = qq(<span class="group" tooltip="Includes $list">$outputSimple</span>);
				}
				$found = 1;
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
			$outputSimple = qq(Unknown Item: $input);
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
	if ($input eq "812" or $input eq "Roe") {
		return "Varies";
	}
	if (looks_like_number($input)) {
		if ($input < 0) {
			# For an "Any Milk" or "Any Egg" entry we will use the price of cheapest option
			if ($input == -6) {
				$output = GetValue("Milk");
			} elsif ($input == -5) {
				$output = GetValue("Egg");
			} else {
				$output = "Varies";
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

# GetCategory tries to return a human-readable name for a given numberic category
#
#   input - the category number
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
		-17 => '(Special)',
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
		-777 => 'Wild Seeds', #weird special category used for Tea Sapling crafting recipe
	);	
	
	if (exists $c{$input}) {
		$output = $c{$input};
	} else {
		$output = "Category $input Item";
	}
	return $output;
}

# GetCategoryNum tries to return a numeric category for a given name (i.e. the reverse of GetCategory()
#
#   input - the category name
sub GetCategoryNum {
	my $input = shift;
	my $output = 0;
	# Since the primary purpose of this is to translate JA items, we currently only support the
	#   named categories which JA allows:
	#   Flower, Fruit, Vegetable, Gem, Fish, Egg, Milk, Cooking, Crafting, Mineral, Meat, Metal, Junk, Syrup, MonsterLoot, ArtisanGoods, and Seeds.
	my %c = (
		'Flower' => -80,
		'Vegetable' => -75,
		'Fruit' => -79,
		'Gem' => -2,
		'Fish' => -4,
		'Egg' => -5,
		'Milk' => -6,
		'Cooking' => -7,
		'Crafting' => -8,
		'Mineral' => -12,
		'Meat' => -14,
		'Metal' => -15,
		'Junk' => -20,
		'Syrup' => -27,
		'MonsterLoot' => -28,
		'ArtisanGoods' => -26,
		'AnimalGoods' => -18,
		'Seeds' => -74,
	);	
	
	if (defined $input) {
		if (exists $c{$input}) {
			$output = $c{$input};
		} else {
			print STDOUT "GetCategoryNum doesn't understand $input\n";
		}
	}
	return $output;
}	

# GetImgTag returns the appropriate image tag for an item.
#   input - either ID num (vanilla) or name (mod)
#   type - [optiona] 'machine', 'object', etc. Defaults to 'object'
#   isBig - [optional] true value to use x2 sprites, false (default) otherwise
#   extraClasses - [optional] for additional class tags that need to be added
sub GetImgTag {
	my $input = decode_entities(shift);
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

	# One situation where we don't have an image.
	if ($input eq 'Same as Input') {
		return "";
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
	if ($input eq 'Stone') {
		return GetImgTag(390, "object", $isBig, $extraClasses);
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
			} elsif ($input == -777) {
				return GetImgTag("Spring Seeds", "object", $isBig, $extraClasses);
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
			} elsif ($type =~ /^craftables?/i) {
				if (exists $GameData->{'BigCraftablesInformation'}{$input}) {
					my $name = $GameData->{'BigCraftablesInformation'}{$input}{'split'}[0];
					$img_class .= "game_craftables";
					$img_id = "Craftable_$input";
					$img_alt = $name;
				} else {
					warn "GetImgTag failed on unknown vanilla craftable: $input";
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
		my $found= 0;
		if ($type =~ /^objects?/i) {
			if (exists $ModData->{'Objects'}{$input}) {
				$img_class .= 'objects';
				$img_id = "Object_$input";
				$img_alt = "$input";
				$found = 1;
			} else {
				foreach my $k (keys %{$GameData->{'ObjectInformation'}}) {
					if ($GameData->{'ObjectInformation'}{$k}{'split'}[0] eq $input) {
						$img_class .= "game_objects";
						$img_id = "Object_$k";
						$img_alt = $input;
						$found = 1;
						last;
					}
				}
			}
			# If no match on name itself, we next try tags; we have to repeat some of the
			#  previous code to correctly identify class, id, etc.
			if (not $found) {
				if (exists $Tagged->{$input}) {
					# We can automatically grab whatever is first on the list of tags for our
					#  image, which works pretty well as a default. There are a few cases where
					#  I'd like to pick something different though, so we do that as necessary.
					if ($input eq 'herb_item' and exists $ModData->{'Objects'}{'Basil'}) {
						$input = "Basil";
					} elsif ($input eq 'milk_item') {
						$input = "Milk";
					} else {
						$input = $Tagged->{$input}[0];
					}
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
					$found = 1;
				}
			}
			# If still no match, give up and throw a warning.
			if (not $found) {
				warn "GetImgTag failed on unknown named object: $input";
				return "";
			}
		} elsif ($type =~ /^craftables?/i) {
			if (exists $ModData->{'BigCraftables'}{$input}) {
				$img_class .= 'craftables';
				$img_id = "Craftable_$input";
				$img_alt = "$input";
				$found = 1;
			} else {
				foreach my $k (keys %{$GameData->{'BigCraftablesInformation'}}) {
					if ($GameData->{'BigCraftablesInformation'}{$k}{'split'}[0] eq $input) {
						$img_class .= "game_craftables";
						$img_id = "Craftable_$k";
						$img_alt = $input;
						$found = 1;
						last;
					}
				}
			}
			if (not $found) {
				warn "GetImgTag failed on unknown named craftable: $input";
				return "";
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
	$img_id = GetIDString($img_id);
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
		$shortdesc = "Personal reference for PPJA (and other) Stardew Valley mods.";
	}
	my $longdesc = shift;
	if (not defined $longdesc) {
		$longdesc = "";
	}
	
	my $output = <<"END_PRINT";
<!DOCTYPE html>
<html>
<head>
<title>Mousey's PPJA (and Friends) Reference: $subtitle</title>

<meta charset="UTF-8" />
<meta property="og:title" content="PPJA (and Friends) $subtitle" />
<meta property="og:description" content="$shortdesc" />
<!-- meta property="og:image" content="https://mouseypounds.github.io/stardew-checkup/og-embed-image.png" / -->
<!-- meta property="twitter:image" content="https://mouseypounds.github.io/stardew-checkup/og-embed-image.png" / -->
<meta name="theme-color" content="#ffe0b0">
<meta name="author" content="MouseyPounds" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />

<link rel="stylesheet" type="text/css" href="./ppja-ref.css" />
<link rel="stylesheet" type="text/css" href="./ppja-ref-img.css" />
<link rel="icon" type="image/png" href="./book.png" />

<!-- Table sorting by https://www.kryogenix.org/code/browser/sorttable/ -->
<script type="text/javascript" src="./sorttable.js"></script>
<script type="text/javascript" src="./ppja-ref-filters.js"></script>

</head>
<body>
<div class="panel" id="header"><h1>Mousey's PPJA (and Friends) Reference: $subtitle</h1>
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
PPJA Reference:
<a href="./index.html">Main Index</a> ||
<a href="./cooking.html">Cooking</a> || 
<a href="./crafting.html">Crafting</a> || 
<a href="./crops.html">Crops</a> || 
<a href="./trees.html">Fruit Trees</a> ||
<a href="./gifts.html">Gift Tastes</a> ||
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
Stardew Valley is developed by <a href="http://twitter.com/concernedape">ConcernedApe</a> and is self-published on most platforms.
</div>
</body>
</html>
END_PRINT

	return $output;
}

# GetHealthAndEnergy - returns health and energy from edibility and optional quality
#   Uses formula from wiki template; code ref is StardewValley.Farmer.doneEating()
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
#  Does not support every possible condition
sub TranslatePreconditions {
	my %seasons = ( 'Spring' => 1, 'Summer' => 2, 'Fall' => 3, 'Winter' => 4 );
	my $changed_seasons = 0;
	my %days = ( 'Mon' => 1, 'Tue' => 2, 'Wed' => 3, 'Thu' => 4, 'Fri' => 5, 'Sat' => 6, 'Sun' => 7, );
	my $changed_days = 0;
	my @results = ();
	
	foreach my $arg (@_) {
		if ($arg =~ /^(\s+)(\S.*)/) {
			warn "TranslatePreconditions detected leading whitespace in a condition: {$arg}";
			$arg = $2;
		}
		if ($arg =~ /^y (\d+)/) {
			push @results, "Year $1+";
		} elsif ($arg =~ /^f (\w+) (\d+)/) {
			# Normally, this is a point value and must be converted to hearts, but for cooking recipes it is
			# just the heart value itself. So we guess that <= 10 is heart value and > 10 is points.
			my $num_hearts = $2;
			$num_hearts /= 250 if ($num_hearts > 10);
			push @results, "$num_hearts&#x2665; with " . Wikify($1);
		} elsif ($arg =~ /^z /) {
			# This can look like 'z summer' or 'z spring summer' or 'z summer, z fall' (last may not actually work)
			#if ($arg =~ /,/) { print STDERR "possible bugged season condition: {$arg}\n"; }
			$arg =~ s/[z, ]+/|/g;
			my @removal = split(/\|/, $arg);
			foreach my $r (@removal) {
				my $s = ucfirst $r;
				delete $seasons{$s} if (exists $seasons{$s});
				$changed_seasons = 1;
			}
		} elsif ($arg =~ /^d /) {
			# This can look like 'd mon' or 'd mon tue' or 'd mon, d tue' (last may not actually work)
			$arg =~ s/[d, ]+/|/g;
			my @removal = split(/\|/, $arg);
			foreach my $r (@removal) {
				my $d = ucfirst $r;
				delete $days{$d} if (exists $days{$d});
				$changed_days = 1;
			}
		} elsif ($arg =~ /^s (\d+) (\d+)/) {
			# Shipping precondition
			my $item = GetItem($1);
			my $num = $2;
			push @results, "Shipped at least $num of $item";
		} elsif ($arg =~ /^s (\w+) (\d+)/) {
			# Skill conditions for recipes defined in Data\CookingRecipes
			my $skill = ucfirst $1;
			my $level = $2;
			my $extra = "";
			if ($skill =~ /luck/i) {
				$extra = qq[ (requires <a href="https://www.nexusmods.com/stardewvalley/mods/521">mod</a>)];
			}
			push @results, "Level $level in " . Wikify($skill) . $extra;
		} elsif ($arg =~ /^h (\w+)/) {
			my $pet = $1;
			push @results, "Have no pet, but prefer $pet";
		} elsif ($arg =~ /^r ([\.\d]+)/) {
			my $chance = $1 * 100;
			push @results, "Random chance (${chance}\%)";
		} elsif ($arg =~ /^w (\w+)/) {
			my $type = ucfirst $1;
			push @results, "$type weather";
		} else {
			warn "TranslatePreconditions doesn't know how to deal with {$arg}";
		}
	}
	if ($changed_seasons) {
		my $r = join(', ', (sort {$seasons{$a} <=> $seasons{$b}} (keys %seasons)));
		push @results, $r;
	}
	if ($changed_days) {
		my $r = join(', ', (sort {$days{$a} <=> $days{$b}} (keys %days)));
		push @results, $r;
	}
	return @results;
}

# GetIDString - Does some filtering on names to make a valid ID/Class for css
#
# Basically we are turning anything that isn't a letter (either case), number, hyphen or underscore into an underscore.
# There are other rectrictions on identifiers we aren't dealing with currently
# https://www.w3.org/TR/CSS21/syndata.html#characters
sub GetIDString {
	my $str = shift;
	$str =~ s/[^-_a-zA-Z0-9]/_/g;
	return $str;
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
		my $id = GetIDString("Crop_$sid");
		warn "Sprite ID {$id} will not be unique" if (exists $HashRef->{$id});
		$HashRef->{$id} = { 'x' => 0 - $GameData->{'Crops'}{$sid}{'__SS_X'}, 'y' => 0 - $GameData->{'Crops'}{$sid}{'__SS_Y'} };
		$id .= "_x2";
		$HashRef->{$id} = { 'x' => 0 - 2*($GameData->{'Crops'}{$sid}{'__SS_X'}), 'y' => 0 - 2*$GameData->{'Crops'}{$sid}{'__SS_Y'} };
	}
	# Trees - coords were saved by gather_data
	foreach my $sid (keys %{$GameData->{'FruitTrees'}}) {
		my $id = GetIDString("Tree_$sid");
		warn "Sprite ID {$id} will not be unique" if (exists $HashRef->{$id});
		$HashRef->{$id} = { 'x' => 0 - $GameData->{'FruitTrees'}{$sid}{'__SS_X'}, 'y' => 0 - $GameData->{'FruitTrees'}{$sid}{'__SS_Y'} };
		$id .= "_x2";
		$HashRef->{$id} = { 'x' => 0 - 2*($GameData->{'FruitTrees'}{$sid}{'__SS_X'}), 'y' => 0 - 2*$GameData->{'FruitTrees'}{$sid}{'__SS_Y'} };
	}
	# Objects - have to calculate coords ourselves
	my $game_sprites = Imager->new();
	my $sprite_width = 16;
	my $sprite_height = 16;
	$game_sprites->read(file=>"../img/game_objects.png") or die "Error reading game object sprites:" . $game_sprites->errstr;
	my $sprites_per_row = floor($game_sprites->getwidth() / $sprite_width);
	foreach my $index (keys %{$GameData->{'ObjectInformation'}}) {
		my $id = GetIDString("Object_$index");
		warn "Sprite ID {$id} will not be unique" if (exists $HashRef->{$id});
		my $x =  $sprite_width * ($index % $sprites_per_row);
		my $y = $sprite_height * floor($index / $sprites_per_row);
		$HashRef->{$id} = { 'x' => 0 - $x, 'y' => 0 - $y };
		$id .= "_x2";
		$HashRef->{$id} = { 'x' => 0 - 2*$x, 'y' => 0 - 2*$y };
	}
	# Craftables - have to calculate coords ourselves
	$game_sprites = Imager->new();
	$sprite_width = 16;
	$sprite_height = 32;
	$game_sprites->read(file=>"../img/game_craftables.png") or die "Error reading game craftable sprites:" . $game_sprites->errstr;
	$sprites_per_row = floor($game_sprites->getwidth() / $sprite_width);
	foreach my $index (keys %{$GameData->{'BigCraftablesInformation'}}) {
		my $id = GetIDString("Craftable_$index");
		warn "Sprite ID {$id} will not be unique" if (exists $HashRef->{$id});
		my $x =  $sprite_width * ($index % $sprites_per_row);
		my $y = $sprite_height * floor($index / $sprites_per_row);
		$HashRef->{$id} = { 'x' => 0 - $x, 'y' => 0 - $y };
		$id .= "_x2";
		$HashRef->{$id} = { 'x' => 0 - 2*$x, 'y' => 0 - 2*$y };
	}
	# Quality stars - hardcoded formula
	foreach my $q (1 .. 4) {
		my $id = GetIDString("Quality_$q");
		warn "Sprite ID {$id} will not be unique" if (exists $HashRef->{$id});
		my $x = 8 * ($q - 1);
		my $y = 0;
		$HashRef->{$id} = { 'x' => 0 - $x, 'y' => 0 - $y };
		$id .= "_x2";
		$HashRef->{$id} = { 'x' => 0 - 2*$x, 'y' => 0 - 2*$y };
	}
	
	# Mod data
	# Machines - because machines can have a variable number of sprites only the single idle animation was
	#   transferred to the sprite sheet and we don't have any further processing to do.
	foreach my $j (@{$ModData->{'Machines'}}) {
		foreach my $m (@{$j->{'machines'}}) {
			my $id = GetIDString("Machine_$m->{'name'}");
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
		my $id = GetIDString("Crop_$key");
		warn "Sprite ID {$id} will not be unique" if (exists $HashRef->{$id});
		$HashRef->{$id} = { 'x' => 0 - ($ModData->{'Crops'}{$key}{'__SS_X'} + $offset*16), 'y' => 0 - $ModData->{'Crops'}{$key}{'__SS_Y'} };
		$id .= "_x2";
		warn "Sprite ID {$id} will not be unique" if (exists $HashRef->{$id});
		$HashRef->{$id} = { 'x' => 0 - 2*($ModData->{'Crops'}{$key}{'__SS_X'} + $offset*16), 'y' => 0 - 2*$ModData->{'Crops'}{$key}{'__SS_Y'} };
		# The seeds should already have been turned into objects so we don't need to process them here
	}
	# Objects - these should have already been saved, so not much to do
	foreach my $key (keys %{$ModData->{'Objects'}}) {
		my $id = GetIDString("Object_$key");
		warn "Sprite ID {$id} will not be unique" if (exists $HashRef->{$id});
		$HashRef->{$id} = { 'x' => 0 - $ModData->{'Objects'}{$key}{'__SS_X'}, 'y' => 0 - $ModData->{'Objects'}{$key}{'__SS_Y'} };
		$id .= "_x2";
		warn "Sprite ID {$id} will not be unique" if (exists $HashRef->{$id});
		$HashRef->{$id} = { 'x' => 0 - 2*$ModData->{'Objects'}{$key}{'__SS_X'}, 'y' => 0 - 2*$ModData->{'Objects'}{$key}{'__SS_Y'} };
	}
	# Craftables - these should have already been saved, so not much to do
	foreach my $key (keys %{$ModData->{'BigCraftables'}}) {
		my $id = GetIDString("Craftable_$key");
		warn "Sprite ID {$id} will not be unique" if (exists $HashRef->{$id});
		$HashRef->{$id} = { 'x' => 0 - $ModData->{'BigCraftables'}{$key}{'__SS_X'}, 'y' => 0 - $ModData->{'BigCraftables'}{$key}{'__SS_Y'} };
		$id .= "_x2";
		warn "Sprite ID {$id} will not be unique" if (exists $HashRef->{$id});
		$HashRef->{$id} = { 'x' => 0 - 2*$ModData->{'BigCraftables'}{$key}{'__SS_X'}, 'y' => 0 - 2*$ModData->{'BigCraftables'}{$key}{'__SS_Y'} };
	}
	# Fruit Trees - The entire set of tree sprites are on the sheet, but the "full" tree is the last one on the list,
	#  384 px beyond the start. This is backwards from how the vanilla tree sprite co-ordinates were saved. Oops.
	foreach my $key (keys %{$ModData->{'FruitTrees'}}) {
		my $id = GetIDString("Tree_$key");
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
#  It returns the total value of all ingredients added or "varies" if that is not reasonable
#
#   HashRef - the data structure keeping track of the counts
#   item - this item (ID or Name; Name should only be given for mod items)
#   count - how many of this item
#   ArrayRef - keeps track of how many of each basic ingredient are actually added
#   type - [optional] 'cooking' (default) or 'crafting'
sub AddAllIngredients {
	my $HashRef = shift;
	my $item = shift;
	my $count = shift;
	my $ArrayRef = shift;
	my $type = shift;
	my $ingr_value = 0;
	
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
	my %temp = ();
	foreach my $i (@items_to_add) {
		if (not exists $HashRef->{$i->{'item'}}) {
			$HashRef->{$i->{'item'}} = 0;
		}
		$HashRef->{$i->{'item'}} += $i->{'count'};
		# These need to be translated into strings of a special form
		my $item = lc GetItem($i->{'item'}, "", 0);
		$item =~ s/ /_/g;
		if (not exists $temp{$item}) {
			$temp{$item} = 0;
		}
		$temp{$item} += $i->{'count'};
		my $this_value = GetValue($i->{'item'});
		if (looks_like_number($ingr_value) and looks_like_number($this_value)) {
			$ingr_value += $i->{'count'} * $this_value;
		} else {
			$ingr_value = "varies";
		}
	}
	foreach my $t (keys %temp) {
		push @$ArrayRef, "$t/$temp{$t}";
	}
	return $ingr_value;
}

# SearchIngredients - the recursive portion of AddAllIngredients that actually finds the ingredients
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
		$max_depth = 8;
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

# FindMailRecipe - searches MFM pack data for the given recipe
#
#   item - the name of the item being searched for
sub FindMailRecipe {
	my $item = shift;
	my $result = "";
	
	if (defined $item) {
		foreach my $mcp (@{$ModData->{'Mail'}}) {
			foreach my $letter (@{$mcp->{'letters'}}) {
				if (exists $letter->{'Recipe'} and $letter->{'Recipe'} eq $item) {
					my @con = TranslateMFMConditions($letter);
					return "Sent in Mail<br />" . join("<br />", @con);
				}
			}
		}
	}
	return $result;
}

# TranslateMFMConditions - tries to determine conditions for an MFM letter object
#   As with the event precondition function, this does not check every possible option
#   and instead is limited to those which I have had to support so far
#
#   letter - the letter object
sub TranslateMFMConditions {
	my $letter = shift;
	my @results = ();
	
	if (exists $letter->{'Date'} and $letter->{'Date'} ne '') {
		$letter->{'Date'} =~ /(\d+)\s+(\w+)\s+Y(\d+)/;
		my $day = $1;
		my $mon = ucfirst $2;
		my $yr = $3;
		push @results, "$mon $day, Year $yr (or later)";
	}
	if (exists $letter->{'Seasons'} and $letter->{'Seasons'} ne '') {
		push @results, join(', ', map {ucfirst $_} @{$letter->{'Seasons'}});
	}
	if (exists $letter->{'Weather'} and $letter->{'Weather'} ne '') {
		push @results, ucfirst($letter->{'Weather'}) . " weather";
	}
	if (exists $letter->{'FriendshipConditions'}) {
		foreach my $c (@{$letter->{'FriendshipConditions'}}) {
			push @results, "$c->{'FriendshipLevel'}&#x2665; with " . Wikify($c->{'NpcName'});
		}
	}	
	if (exists $letter->{'SkillConditions'}) {
		foreach my $c (@{$letter->{'SkillConditions'}}) {
			push @results, Wikify($c->{'SkillName'}) . " level $c->{'SkillLevel'}" ;
		}
	}
	return @results;
}

# GetNexusKey - returns Nexus ID number for a given mod uniqueID
#  Mainly used as a helper for GetModInfo. Returns "" if something went wrong.
#
#   modID - the uniqueID to lookup
sub GetNexusKey {
	my $modID = shift;

	if (defined $modID and exists $ModInfo->{$modID} and defined $ModInfo->{$modID}{'UpdateKeys'}) {
		foreach my $u (@{$ModInfo->{$modID}{'UpdateKeys'}}) {
			if ($u =~ /Nexus:(\d+)/) {
				return $1;
			}
		}
	}
	# Hardcoded substitutions for known mods which don't supply an update key in their manifest.
	if ($modID eq 'Stupiddullhans.BFAVquails') {
		return "4847";
	} elsif ($modID eq 'TrentNewRaccoons') {
		return "4132";
	} elsif ($modID eq 'MythicPhoenix.BFAVGoldenGoose') {
		return "4432";
	} elsif ($modID eq 'rearda88.GemandMineralCrops') {
		return "3395";
	} elsif ($modID eq 'StephansLotsOfWildCrops') {
		return "3171";
	} 
	# Currently suppressing this because so many of the "sub-mods" don't have this that it dominates the output
	#print STDOUT "** GetNexusKey did not find a key for ($modID) and is returning an empty string\n";
	return "";
}

# GetModInfo - returns a formatted HTML string with name & version info for a given uniqueID
#
#   modID - the uniqueID to lookup; will return base game info string if this is missing/blank
#   includeLink - [optional] link the name to Nexus page (default is true)
#   formatType - [optional] see below, 1 is default
#                 1 is like <a href="url">Mod Name</a> Version
#                 2 is like Mod Name Version (<a href="url">Nexus link</a>)
sub GetModInfo {
	my $modID = shift;
	my $includeLink = shift;
	my $formatType = shift;

	my $name = "Stardew Valley (base game)";
	my $version = $StardewVersion;
	my $url = "https://stardewvalley.net/";
	
	if (not defined $includeLink) {
		$includeLink = 1;
	}
	if (not defined $formatType) {
		$formatType = 1;
	}

	if (defined $modID and $modID ne "") {
		if (exists $ModInfo->{$modID}) {
			$name =$ModInfo->{$modID}{'Name'};
			$version = $ModInfo->{$modID}{'Version'};
			# We no longer handle missing update keys for "sub-mods"; GetExtendedModInfo can instead
			#  be used to get the parent ID and the parent can be looked up to get the key.
			my $NexusKey = GetNexusKey($modID);
			if ($NexusKey eq "") {
				$includeLink = 0;
			}
			$url = "https://www.nexusmods.com/stardewvalley/mods/$NexusKey";
		} else {
			warn "** GetModInfo received unknown modID ($modID)";
			return undef;
		}
	}

	if ($includeLink) {
		if ($formatType == 1) {
				return qq(<a href="$url">$name</a> version $version);
		} elsif ($formatType == 2) {
				return qq[$name version $version (<a href="$url">Nexus page</a>)];
		} else {
			warn "** GetModInfo unknown format type $formatType";
		}
	} else {
		return qq($name version $version);
	}
}

# GetExtendedModInfo - wrapper for GetModInfo to include not only the basic info string, but any
#   parent mod indicator and a flag if this is part of the PPJA family. This info is hardcoded.
#
#   modID - the uniqueID to lookup; will return base game info string if this is missing/blank
#   includeLink - [optional] link the name to Nexus page (default is true)
#   formatType - [optional] see below, 1 is default
#                 1 is like <a href="url">Mod Name</a> Version
#                 2 is like Mod Name Version (<a href="url">Nexus link</a>)
sub GetExtendedModInfo {
	my $modID = shift;
	my $includeLink = shift;
	my $formatType = shift;

	my $basicInfo = GetModInfo($modID, $includeLink, $formatType);
	my $parentID = undef;
	my $isPPJA = 0;

	# PPJA-stuff first; all of these will use the JA pack as the primary/parent
	# From Ancient Crops
	if ($modID eq 'ppja.ancientcrops') {
		$isPPJA = 1;
	} elsif ($modID eq 'PPJAAncientCropsCP') {
		$parentID = 'ppja.ancientcrops';
		$isPPJA = 1;
	} elsif ($modID eq 'PPJA.AncientCropsAddOn') { #PFM
		$parentID = 'ppja.ancientcrops';
		$isPPJA = 1;
	# From Artisan Valley
	} elsif ($modID eq 'ppja.artisanvalleymachinegoods') {
		$isPPJA = 1;
	} elsif ($modID eq 'ppja.avcfr') { #CFR, legacy
		$parentID = 'ppja.artisanvalleymachinegoods';
		$isPPJA = 1;
	} elsif ($modID eq 'ppja.artisanvalleyPFM') {
		$parentID = 'ppja.artisanvalleymachinegoods';
		$isPPJA = 1;
	} elsif ($modID eq 'ppja.artisanvalleyCP') {
		$parentID = 'ppja.artisanvalleymachinegoods';
		$isPPJA = 1;
	} elsif ($modID eq 'ppja.artisanvalleyforMFM') {
		$parentID = 'ppja.artisanvalleymachinegoods';
		$isPPJA = 1;
	} elsif ($modID eq 'PPJA.BFAVQuailsAddOn') { #Supplied by Artisan Valley so AV is parent, but no ppja flag.
		$parentID = 'ppja.artisanvalleymachinegoods';
	} elsif ($modID eq 'PPJA.SweetToothAddOn') { #Supplied by Artisan Valley so AV is parent, but no ppja flag.
		$parentID = 'ppja.artisanvalleymachinegoods';
	# From Cannabis Kit
	} elsif ($modID eq 'PPJA.cannabiskit') {
		$isPPJA = 1;
	} elsif ($modID eq 'PPJA.CannabisKitAddOn') {
		$parentID = 'PPJA.cannabiskit';
		$isPPJA = 1;
	# From Christmas Sweets
	} elsif ($modID eq 'ppja.christmassweets') {
		$isPPJA = 1;
	} elsif ($modID eq 'ppja.christmassweetsforMFM') {
		$parentID = 'ppja.christmassweets';
		$isPPJA = 1;
	# From Even More Recipes
	} elsif ($modID eq 'ppja.evenmorerecipes') {
		$isPPJA = 1;
	} elsif ($modID eq 'ppja.MoreRecipesMeat') {
		$parentID = 'ppja.evenmorerecipes';
		$isPPJA = 1;
	} elsif ($modID eq 'ppja.EvenMoreRecipesforMFM') {
		$parentID = 'ppja.evenmorerecipes';
		$isPPJA = 1;
	# Fantasy crops; ppja flag only
	} elsif ($modID eq 'ParadigmNomad.FantasyCrops') {
		$isPPJA = 1;
	# From Farmer to Florist; ignoring BAGI component: kildarien.farmertofloristbagi
	} elsif ($modID eq 'kildarien.farmertoflorist') {
		$isPPJA = 1;
	} elsif ($modID eq 'kildarien.farmertofloristcfr') { #CFR, legacy
		$parentID = 'kildarien.farmertoflorist';
		$isPPJA = 1;
	} elsif ($modID eq 'Kildarien.CP.FarmerToFlorist') {
		$parentID = 'kildarien.farmertoflorist';
		$isPPJA = 1;
	} elsif ($modID eq 'PPJA.FarmerToFloristForMailFrameworkMod') {
		$parentID = 'kildarien.farmertoflorist';
		$isPPJA = 1;
	} elsif ($modID eq 'kildarien.PFM.FarmerToFlorist') {
		$parentID = 'kildarien.farmertoflorist';
		$isPPJA = 1;
	# From Fresh Meat
	} elsif ($modID eq 'paradigmnomad.freshmeat') {
		$isPPJA = 1;
	} elsif ($modID eq 'ppja.FreshMeatforMFM') {
		$parentID = 'paradigmnomad.freshmeat';
		$isPPJA = 1;
	# From Fruits and Veggies
	} elsif ($modID eq 'ppja.fruitsandveggies') {
		$isPPJA = 1;
	} elsif ($modID eq 'ppja.legacyfruitsveggies') { # CP sprites; need for main index
		$parentID = 'ppja.fruitsandveggies';
		$isPPJA = 1;
	} elsif ($modID eq 'ppja.FruitsandVeggiesforMFM') {
		$parentID = 'ppja.fruitsandveggies';
		$isPPJA = 1;
	# From Mizu's Flowers
	} elsif ($modID eq 'mizu.flowers') {
		$isPPJA = 1;
	} elsif ($modID eq 'ppja.MizusFlowersforMFM') {
		$parentID = 'mizu.flowers';
		$isPPJA = 1;
	# From More Recipes
	} elsif ($modID eq 'paradigmnomad.morefood') {
		$isPPJA = 1;
	} elsif ($modID eq 'ppja.MoreRecipesforMFM') {
		$parentID = 'paradigmnomad.morefood';
		$isPPJA = 1;
	# From More Trees
	} elsif ($modID eq 'ppja.moretrees') {
		$isPPJA = 1;
	} elsif ($modID eq 'ppja.MoreTreesforMFM') {
		$parentID = 'ppja.moretrees';
		$isPPJA = 1;
	# From Starbrew Valley
	} elsif ($modID eq 'ppja.starbrewvalley') {
		$isPPJA = 1;
	} elsif ($modID eq 'ppja.StarbrewValleyforMFM') {
		$parentID = 'ppja.starbrewvalley';
		$isPPJA = 1;
	# Now non-PPJA Stuff. 
	# From Bonster's Crops; F&V will be parent
	} elsif ($modID eq 'BonsterTrees') {
		$parentID = 'BFV.FruitVeggie';
	# From Bonster's Recipes
	} elsif ($modID eq 'Bonster.Adv.Recipes') {
		$parentID = 'Bonster.Recipes';
	# BFAV packs will use the BFAV component as parent
	# From BFAV Quails
	} elsif ($modID eq 'Lavapulse.QuailProducts') {
		$parentID = 'Stupiddullhans.BFAVquails';
	# From Golden Goose
	} elsif ($modID eq 'MythicPhoenix.JA.GoldenGoose') {
		$parentID = 'MythicPhoenix.BFAVGoldenGoose';
	} elsif ($modID eq 'MythicPhoenix.PFM.GoldenGoose') {
		$parentID = 'MythicPhoenix.BFAVGoldenGoose';
	# From Phoenixes/Firebirds
	} elsif ($modID eq 'MythicPhoenix.JA.PhoenixItems') {
		$parentID = 'MythicPhoenix.BFAV.Firebirds';
	} elsif ($modID eq 'MythicPhoenix.PFM.Firebirds') {
		$parentID = 'MythicPhoenix.BFAV.Firebirds';
	# From Trent's Bulls
	} elsif ($modID eq 'ManurePack') {
		$parentID = 'BFAVBulls';
	} elsif ($modID eq 'PFManureMachines') {
		$parentID = 'BFAVBulls';
	# From Trent's New Animals; ignoring CCM component: ppja.TrentsNewAnimalsCCM
	} elsif ($modID eq 'TrentNewAnimalPack') {
		$parentID = 'Trent.NewAnimals';
	} elsif ($modID eq 'PPJA.TrentNewAnimalsAddOn') {
		$parentID = 'Trent.NewAnimals';
	# From Trent's Raccoons
	} elsif ($modID eq 'MultiRaccoonPack') {
		$parentID = 'TrentNewRaccoons';
	} elsif ($modID eq 'Raccoons.MachineSetting') {
		$parentID = 'TrentNewRaccoons';
	# From Hot Cocoa Shop; the TMX should probably be the parent mod, but we don't parse those
	} elsif ($modID eq 'penny3.JA.HCS') {
		$parentID = 'penny3.CP.HCS';
	} elsif ($modID eq 'penny3.TMX.HCS') {
		$parentID = 'penny3.CP.HCS';
	}
	
	my $parentInfo = GetModInfo($parentID, $includeLink, $formatType) if (defined $parentID);
	return {'info' => $basicInfo, 'ppja' => $isPPJA, 'parentID' => $parentID, 'parentInfo' => $parentInfo};
}

# UpdateTags - checks Content Patcher packs for changes to ObjectContextTags and merges into game data
#   Content Patcher packs can be ridiculously complex; we are only looking for a specific type of patch;
#   that is one which edits object context tags, so we are greatly limiting our search.
#   Also checks JA packs for defined Tags so that tags are all in one place.
sub UpdateTags {
	foreach my $cp (@{$ModData->{'ContentPatches'}}) {
		if (exists $cp->{'Changes'}) {
			foreach my $change (@{$cp->{'Changes'}}) {
				if (exists $change->{'Target'} and $change->{'Target'} =~ /Data.ObjectContextTags/i and
					exists $change->{'Action'} and $change->{'Action'} eq 'EditData' and
					exists $change->{'Entries'}) {
					foreach my $k (keys %{$change->{'Entries'}}) {
						$GameData->{'ObjectContextTags'}{$k}{'raw'} = $change->{'Entries'}{$k};
						my @fields = split(', ', $change->{'Entries'}{$k});
						$GameData->{'ObjectContextTags'}{$k}{'split'} = \@fields;
					}
				}
			}
		}
	}
	foreach my $k (keys %{$GameData->{'ObjectContextTags'}}) {
		foreach my $t (@{$GameData->{'ObjectContextTags'}{$k}{'split'}}) {
			if (not exists $Tagged->{$t}) {
				$Tagged->{$t} = [];
			}
			push @{$Tagged->{$t}}, $k;
		}
	}
	foreach my $k (keys %{$ModData->{'Objects'}}) {
		foreach my $t (@{$ModData->{'Objects'}{$k}{'ContextTags'}}) {
			if (not exists $Tagged->{$t}) {
				$Tagged->{$t} = [];
			}
			push @{$Tagged->{$t}}, $k;
		}
	}
	# Because these are used for icons and I don't want the images changing that often, I am going to
	#  pre-sort all the arrays now. This might make temporary copies but it shouldn't matter much.
	foreach my $t (keys %$Tagged) {
		@{$Tagged->{$t}} = sort @{$Tagged->{$t}};
	}
}

# UpdateCategories - goes through ObjectInformation and JA items to construct a dictionary of
#   items for each category. Basically just makes it easier to build some tooltips later.
sub UpdateCategories {
	foreach my $k (keys %{$GameData->{'ObjectInformation'}}) {
		my $temp = $GameData->{'ObjectInformation'}{$k}{'split'}[3];
		$temp =~ /([-\d]*)$/;
		my $cat = $1;
		if ($cat ne '') {
			if (not exists $Categorized->{$cat}) {
				$Categorized->{$cat} = [];
			}
			push @{$Categorized->{$cat}}, $GameData->{'ObjectInformation'}{$k}{'split'}[0];
		}
	}
	foreach my $k (keys %{$ModData->{'Objects'}}) {
		my $cat = GetCategoryNum($ModData->{'Objects'}{$k}{'Category'});
		if (looks_like_number $cat and $cat < 0) {
			if (not exists $Categorized->{$cat}) {
				$Categorized->{$cat} = [];
			}
			push @{$Categorized->{$cat}}, encode_entities($k);
		}
	}
	# Hardcoding the weird special category used in tea sapling crafting
	$Categorized->{-777} = ["Spring Seeds", "Summer Seeds", "Fall Seeds", "Winter Seeds"];
	# Because these are used for icons and I don't want the images changing that often, I am going to
	#  pre-sort all the arrays now. This might make temporary copies but it shouldn't matter much.
	foreach my $t (keys %$Categorized) {
		@{$Categorized->{$t}} = sort @{$Categorized->{$t}};
	}
}

###################################################################################################
# WriteMainIndex - index page generation
sub WriteMainIndex {
	my $FH;
	open $FH, ">$DocBase/index.html" or die "Can't open index.html for writing: $!";
	select $FH;

	print STDOUT "Generating Main Index\n";
	my $longdesc = <<"END_PRINT";
<p>Welcome to my personal collection of reference documentation for the PPJA (Project Populate JSON Assets) family of Stardew Valley mods
and some closely-related mods that may not actually fall under the PPJA umbrella.
The official documentation has always been 
<a href="https://docs.google.com/spreadsheets/d/1D3Kb45faKsXGkT9wGhWaeHZiuFN7WSkewBbLF2Iuyug/edit?usp=sharing">a large spreadsheet</a>
used by the PPJA team for organization, but I found it a bit difficult to use as a player. So this set of webpages was created by a set of
custom perl scripts to automatically extract information from the various mods (as well as the base game) and put it all together into a
(hopefully) more accessible format.</p>
<p>Mods covered by this reference are listed below; note that each individual summary page will only include those relevant to that
specific topic. On this list, mods which are officially part of PPJA are prefaced with the symbol &#x24c5; and are listed first in the list.
Mods with multiple components are listed with the primary component (JA for most mods; BFAV for animal packs) first and the other components
grouped together under that.</p>
<ul>
END_PRINT

	# First divide ModInfo into parents and children
	my %Children = ();
	my %Parents = ();
	foreach my $mod (keys %$ModInfo) {
		my $info = GetExtendedModInfo($mod, 1, 1);
		my $prefix = ($info->{'ppja'}) ? qq(&#x24c5; ) : "";
		if (not defined $info->{'parentID'}) {
			$Parents{$mod} = "${prefix}$info->{'info'}" ;
		} else {
			if (not exists $Children{$info->{'parentID'}}) {
				$Children{$info->{'parentID'}} = {};
			}
			$Children{$info->{'parentID'}}{$mod} = $info->{'info'};
		}
	}

	# Top option will sort PPJA first; bottom option will mix them together
	foreach my $mod (sort {StripHTML($Parents{$a}) cmp StripHTML($Parents{$b})} keys %Parents) {
	#foreach my $mod (sort {$ModInfo->{$a}{'Name'} cmp $ModInfo->{$b}{'Name'}} keys %Parents) {
		$longdesc .= qq(<li>$Parents{$mod});
		if (exists $Children{$mod}) {
			$longdesc .= "<ul>";
			foreach my $child (sort {$ModInfo->{$a}{'Name'} cmp $ModInfo->{$b}{'Name'}} keys %{$Children{$mod}}) {
				$longdesc .= qq(<li>$Children{$mod}{$child}</li>);
			}
			$longdesc .= "</ul>";
		}
		$longdesc .= "</li>";
	}

	$longdesc .= <<"END_PRINT";
</ul>
<p>Below are the links to the various summary pages for this reference. In general, each is a set of sortable tables summarizing various
aspects of the mods. There are some profit calculations included, but by necessity they are simplistic and assume base quality without
any value-adding perks. Those interested in the profit aspect might also want to check out
<a href="https://docs.google.com/spreadsheets/d/1uhRUOdNv68cbqe7yCf1C0pZC6DM_i6sYySSEwHPpy5M/edit#gid=0">this spreadsheet</a> put
together by a different PPJA user.</p>
<ul>
<li><a href="./cooking.html">Cooking</a> - Recipe ingredients and acquisition methods</li>
<li><a href="./crafting.html">Crafting</a> - Recipe ingredients and acquisition methods</li>
<li><a href="./crops.html">Crops</a> - Growth timing and other basic information sorted by season; includes base game crops</li>
<li><a href="./trees.html">Fruit Trees</a> - Basic information sorted by season; includes base game trees</li>
<li><a href="./gifts.html">Gift Tastes</a> - A large table summarizing NPC gift tastes for items from all supported mods</li>
<li><a href="./machines.html">Machines</a> - Products, production timings, and crafting recipes</li>
</ul>
<p>If you have any suggestions for improvement or bugs to report, please contact me either at <span class="username">MouseyPounds#0557</span>
on <a href="https://discordapp.com">Discord</a> or through 
<a href="https://community.playstarbound.com/threads/personal-ppja-reference-project.156334/">the topic for this project on Chucklefish forums.</a></p>
END_PRINT
	print GetHeader("Main Index", qq(Reference docs for PPJA (and other) mods for Stardew Valley.), $longdesc);
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
	# This function has been reorganized. In order to properly detect all mods that are referenced
	#  and be able to automatically add them to the filter form in the header, we must process all
	#  the recipes first before we print anything at all.
	my @Panel = ( 
		{ 'key' => 'food', 'name' => "Food Recipes", 'count' => 0, 'total_cost' => 0, 'row' => {}, },
		{ 'key' => 'drink', 'name' => "Drink Recipes", 'count' => 0, 'total_cost' => 0, 'row' => {}, },
		);
		
	my %IngredientCount = ();
	my %ModList = ();

	print STDOUT "  Processing Game Cooking Recipes\n";
	# Recipe source information for game data is in a variety of locations. We'll start by scanning
	#  the TV data to find out when each Queen of Sauce recipe airs.
	# In that file, the keys are basically the week numbers from 1 to 32. We will translate these week numbers
	#  into a nicer game date and save them into a hash keyed on recipe name.
	my %TVDates = ();
	foreach my $key (keys %{$GameData->{'TV/CookingChannel'}}) {
		my $year = floor(($key + 15) / 16);
		my $week_within_year = ($key - 1) % 16;
		my @season = qw(Spring Summer Fall Winter);
		my $season_num = floor($week_within_year / 4);
		my $day_of_season = 7 + 7 * ($week_within_year % 4);
		my $date_string = Wikify("Queen of Sauce") . qq( - $day_of_season $season[$season_num], Year $year<br />);
		my $recipe_key = $GameData->{'TV/CookingChannel'}{$key}{'split'}[0];
		$TVDates{$recipe_key} = $date_string;
	}
	# Some recipes can be purchased at the saloon. This is hardcoded in StardewValley.Utility.getSaloonStock()
	#  and we'll copy the relevant info here.
	my %SaloonRecipes = (
		'Hashbrowns' => 250,
		'Omelet' => 500,
		'Pancakes' => 500,
		'Bread' => 500,
		'Tortilla' => 500,
		'Pizza' => 750,
		'Maki Roll' => 1500,
		'Triple Shot Espresso' => 2500,
		);
	# And then there are some others that are just completely special
	my %Special = (
		'Cookies' => Wikify("Evelyn") . " 4&#x2665; Event",
		);
	# Buff descriptions will be shared by vanilla and mods
	my @buff_desc = (
		Wikify("Farming") . " level",
		Wikify("Fishing") . " level",
		Wikify("Mining") . " level",
		"UNUSED",
		Wikify("Luck") . " level",
		Wikify("Foraging") . " level",
		"UNUSED",
		"Max " . Wikify("Energy"),
		Wikify("Magnetism"),
		Wikify("Speed"),
		Wikify("Defense"),
		Wikify("Attack"),
	);
	foreach my $key (keys %{$GameData->{'CookingRecipes'}}) {
		my $cid = $GameData->{'CookingRecipes'}{$key}{'split'}[2];
		my $cname = GetItem($cid);
		my $imgTag = GetImgTag($cid, "object", 1);
		my $ingr = "";
		my $ingr_value = 0;
		my @temp = split(/ /,  $GameData->{'CookingRecipes'}{$key}{'split'}[0]);
		my @ingr_data = ();
		for (my $i = 0; $i < scalar(@temp); $i += 2) {
			my $item = GetItem($temp[$i]);
			my $img = GetImgTag($temp[$i]);
			my $qty = ($temp[$i+1] > 1 ? " ($temp[$i+1])" : "");
			$ingr .= "$img $item$qty<br />";
			my $value_to_add = AddAllIngredients(\%IngredientCount, $temp[$i], $temp[$i+1], \@ingr_data);
			if (looks_like_number($ingr_value) and looks_like_number($value_to_add)) {
				$ingr_value += $value_to_add;
			} else {
				$ingr_value = "Varies";
			}
		}
		my ($health, $energy) = GetHealthAndEnergy($GameData->{'ObjectInformation'}{$cid}{'split'}[2]);
		my $item_type = $GameData->{'ObjectInformation'}{$cid}{'split'}[6];
		my $buffs = "";
		# Buffs are part of the object data for the product
		@temp = split(/ /, $GameData->{'ObjectInformation'}{$cid}{'split'}[7]);
		for (my $i = 0; $i < scalar(@buff_desc); $i++) {
			# There are supposed to be 12 fields here, but often there are only 11.
			last if ($i > $#temp);
			if ($temp[$i] != 0) {
				my $sign = "";
				if ($temp[$i] > 0) {
					$sign = "+";
				}
				next if ($buff_desc[$i] eq "UNUSED");
				$buffs .= "$sign$temp[$i] $buff_desc[$i]<br />";
			}
		}
		if ($buffs ne "") {
			my $dur_ticks = $GameData->{'ObjectInformation'}{$cid}{'split'}[8];
			my $dur_mins = $dur_ticks * 7 / 600;
			my $min = floor($dur_mins);
			my $sec = floor(60 * ($dur_mins - $min));
			$buffs .= sprintf(qq(<span class="duration"> for %d:%02d</span>), $min, $sec);
		}
		$buffs = qq(<span class="duration">(None)</span>) if ($buffs eq "");
		my $source = "";
		# We will list sources in the order Special, Saloon purchase, TV,
		#  and then the ones defined by condition (default, friend mail, skill bonus)
		if (exists $Special{$key}) {
			$source .= $Special{$key};
		}
		if (exists $SaloonRecipes{$key}) {
			$source .= qq(Buy for $SaloonRecipes{$key}g from ) . WikiShop("Gus") . qq(<br />);
		}
		if (exists $TVDates{$key}) {
			$source .= $TVDates{$key};
		}
		# Some conditions are defined in the last field of the recipe data
		my $condition = $GameData->{'CookingRecipes'}{$key}{'split'}[3];
		if ($condition eq 'default') {
			$source .= "Given automatically";
		} elsif ($condition =~ /^f/) {
			my @temp = TranslatePreconditions($condition);
			$source .= "Sent in Mail<br />$temp[0]<br />";
		} elsif ($condition =~ /^s/) {
			my @temp = TranslatePreconditions($condition);
			$source .= "$temp[0]<br />";
		} 
		my $recipe_cost = "--";
		# Triple shot espresso does not have a free alternative.
		if ($key eq "Triple Shot Espresso") {
			$recipe_cost = $SaloonRecipes{$key};
		}
		my $value = GetValue($cid);
		my $profit = (looks_like_number($ingr_value) and looks_like_number($value)) ? $value - $ingr_value : $ingr_value;
		my $filter = "filter_base_game";
		my $data_attr = join('|', @ingr_data);
		my $output = <<"END_PRINT";
<tr class="$filter">
<td class="name">$imgTag $cname</td>
<td class="name ingr" data-ingr="$data_attr">$ingr</td>
<td class="value">$health</td>
<td class="value">$energy</td>
<td class="name">$buffs</td>
<td>$source</td>
<td class="value total_$item_type">$recipe_cost</td>
<td class="value">$value</td>
<td class="value">$profit</td>
</tr>
END_PRINT

		# It is a little weird to do it this way when there are only 2 options, but it is consistent with
		#  other pages and makes it easier to adjust if we change the categories later.
		foreach my $p (@Panel) {
			if ($p->{'key'} eq $item_type) {
				$p->{'row'}{StripHTML($cname)} = $output;
				$p->{'count'}++;
				if (looks_like_number($recipe_cost)) {
					$p->{'total_cost'} += $recipe_cost;
				}
				last;
			}
		}
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
		my $ingr_value = 0;
		my @ingr_list = @{$ModData->{'Objects'}{$key}{'Recipe'}{'Ingredients'}};
		my @ingr_data = ();
		foreach my $i (@ingr_list) {
			my $item = GetItem($i->{'Object'});
			my $img = GetImgTag($i->{'Object'});
			my $qty = ($i->{'Count'} > 1 ? " ($i->{'Count'})" : "");
			$ingr .= "$img $item$qty<br />";
			my $value_to_add = AddAllIngredients(\%IngredientCount, $i->{'Object'}, $i->{'Count'}, \@ingr_data);
			if (looks_like_number($ingr_value) and looks_like_number($value_to_add)) {
				$ingr_value += $value_to_add;
			} else {
				$ingr_value = "Varies";
			}
		}
		my ($health, $energy) = GetHealthAndEnergy($ModData->{'Objects'}{$key}{'Edibility'});
		if (not exists $ModList{$ModData->{'Objects'}{$key}{'__MOD_ID'}}) {
			$ModList{$ModData->{'Objects'}{$key}{'__MOD_ID'}} = 1;
		}
		my $item_type = (defined $ModData->{'Objects'}{$key}{'EdibleIsDrink'} and $ModData->{'Objects'}{$key}{'EdibleIsDrink'} == 1) ? "drink" : "food";
		my $buffs = "";
		if (defined $ModData->{'Objects'}{$key}{'EdibleBuffs'}) {
			# Buffs will be ordered the same way the vanilla array is ordered
			my %buff_keys = (
				0 => 'Farming',
				1 => 'Fishing',
				2 => 'Mining',
				4 => 'Luck',
				5 => 'Foraging',
				7 => 'MaxStamina',
				8 => 'MagnetRadius',
				9 => 'Speed',
				10 => 'Defense',
				11 => 'Attack',
			);
			foreach my $i (sort keys %buff_keys) {
				if (exists $ModData->{'Objects'}{$key}{'EdibleBuffs'}{$buff_keys{$i}} and
					$ModData->{'Objects'}{$key}{'EdibleBuffs'}{$buff_keys{$i}} != 0) {
					my $sign = "";
					if ($ModData->{'Objects'}{$key}{'EdibleBuffs'}{$buff_keys{$i}} > 0) {
						$sign = "+";
					}
					$buffs .= "$sign$ModData->{'Objects'}{$key}{'EdibleBuffs'}{$buff_keys{$i}} $buff_desc[$i]<br />";
				}
			}
			if ($buffs ne "") {
				my $dur_ticks = $ModData->{'Objects'}{$key}{'EdibleBuffs'}{'Duration'};
				my $dur_mins = $dur_ticks * 7 / 600;
				my $min = floor($dur_mins);
				my $sec = floor(60 * ($dur_mins - $min));
				$buffs .= sprintf(qq(<span class="duration"> for %d:%02d</span>), $min, $sec);
			}
		}
		$buffs = qq(<span class="duration">(None)</span>) if ($buffs eq "");
		my $source = "Given automatically";
		my $recipe_cost = "--";
		if (not $ModData->{'Objects'}{$key}{'Recipe'}{'IsDefault'}) {
			if ($ModData->{'Objects'}{$key}{'Recipe'}{'CanPurchase'}) {
				$source = qq(Buy for $ModData->{'Objects'}{$key}{'Recipe'}{'PurchasePrice'}g from ) .
					WikiShop($ModData->{'Objects'}{$key}{'Recipe'}{'PurchaseFrom'}) . qq(<br />);
				$recipe_cost = $ModData->{'Objects'}{$key}{'Recipe'}{'PurchasePrice'};
			} else {
				$source = FindMailRecipe($key);
			}
		}
		my @conditions = ();
		if (defined $ModData->{'Objects'}{$key}{'Recipe'}{'PurchaseRequirements'}) {
			@conditions = @{$ModData->{'Objects'}{$key}{'Recipe'}{'PurchaseRequirements'}};
		}
		foreach my $condition (@conditions) {
			my @temp = TranslatePreconditions($condition);
			$source .= "$temp[0]<br />";
		}

		my $value = GetValue($key);
		my $profit = (looks_like_number($ingr_value) and looks_like_number($value)) ? $value - $ingr_value : $ingr_value;
		my $filter = $ModInfo->{$ModData->{'Objects'}{$key}{'__MOD_ID'}}{'__FILTER'};
		my $data_attr = join('|', @ingr_data);
		my $output = <<"END_PRINT";
<tr class="$filter">
<td class="name">$imgTag $cname</td>
<td class="name ingr" data-ingr="$data_attr">$ingr</td>
<td class="value">$health</td>
<td class="value">$energy</td>
<td class="name">$buffs</td>
<td>$source</td>
<td class="value total_$item_type">$recipe_cost</td>
<td class="value">$value</td>
<td class="value">$profit</td>
</tr>
END_PRINT

		foreach my $p (@Panel) {
			if ($p->{'key'} eq $item_type) {
				$p->{'row'}{$key} = $output;
				$p->{'count'}++;
				if (looks_like_number($recipe_cost)) {
					$p->{'total_cost'} += $recipe_cost;
				}
				last;
			}
		}
	}

	my $longdesc = <<"END_PRINT";
<p>A summary of cooking recipes from various sources. In the list below, the checkboxes can be used to show or hide
information specific to that particular source; the symbol &#x24c5 indicates an official PPJA mod. Additionally there
are some buttons which will show or hide multiple sources at once.</p>
<fieldset id="filter_options" class="filter_set">
<label><input class="filter_check" type="checkbox" name="filter_base_game" id="filter_base_game" value="show" checked="checked"> 
Stardew Valley base game version $StardewVersion</label><br />
END_PRINT

	foreach my $k (sort {$ModInfo->{$a}{'Name'} cmp $ModInfo->{$b}{'Name'}} keys %ModList) {
		my $filter = $ModInfo->{$k}{'__FILTER'};
		my $info = GetExtendedModInfo($k, 1, 2);
		my $prefix = ($info->{'ppja'}) ? qq(&#x24c5; ) : "";
		my $suffix = "";
		if ($info->{'info'} !~ /href/ and defined $info->{'parentID'}) {
			$info->{'parentInfo'} =~ /(\(.*\))/;
			$suffix = " $1";
		}	
		my $class = "filter_check";
		if ($info->{'ppja'}) {
			$class .= " filter_ppja";
		}
		$longdesc .= <<"END_PRINT";
<label><input class="$class" type="checkbox" name="$filter" id="$filter" value="show" checked="checked">
$prefix$info->{'info'}</label>$suffix<br />
END_PRINT
	}

	$longdesc .= <<"END_PRINT";
</fieldset>
<fieldset id="filter_control" class="filter_set">
<button type="button" id="filter_check_all_off">All Sources Off</button>
<button type="button" id="filter_check_all_on">All Sources On</button>
<button type="button" id="filter_check_ppja">PPJA Mods Only</button>
<button type="button" id="filter_check_nonppja">Non-PPJA Mods Only</button>
</fieldset>
<p>The following tables only contain information about cooked items made in the kitchen. The <span class="note">H</span>
and <span class="note">E</span> columns represent Health and Energy/Stamina restored respectively. The 
<span class="note">Profit</span> column is meant to indicate whether cooking that item is better than selling the base
ingredients raw. It is calculated by the difference between the finished product and the most basic ingredients; for
example, when calculating the profit for Complete Breakfast, the value of the Complete Breakfast is compared to the total
value of 2 eggs, 1 potato, 1 oil, and 1 wheat flour. If a recipe can take <span class="group">any Egg</span> or 
<span class="group">any Milk</span>, the cheapest possibility is used, but for other categories like
<span class="group">any Fish</span>, there is too much variation to get a useful answer.</p>
<p>The recipe tables have a footer that shows the total cost to buy every shown recipe; this will adjust based on filtering.
When calculating this total, the only base game recipes included are those which do not have alternative (free)
ways to learn them such as from the Queen of Sauce TV channel or NPC friendship.</p>
<p>The Ingredient list summarizes how many of each ingredient would be necessary to make one of every recipe on this page.
Note that it is not truly minimal because it doesn't consider the possibility of reusing one product as an ingredient for
a different product (for example, when calculating the ingredients for Complete Breakfast, it assumes a new Hashbrowns
dish will be made during the process.) The ingredient will also auto-adjust based on filtering.
</p>

END_PRINT
	print GetHeader("Cooking", qq(Cooking recipes from PPJA (and other) mods for Stardew Valley.), $longdesc);
	print GetTOCStart();


	# Print the rest of the TOC
	foreach my $p (@Panel) {
		my $text = $p->{'name'};
		$text =~ s/ /&nbsp;/g;
		print qq(<li><a href="#TOC_$p->{'key'}">$text</a></li>);
	}
	print qq(<li><a href="#TOC_Ingredient_List">Ingredient List</a></li>);
	print GetTOCEnd();
	
	# Print the Panels
	foreach my $p (@Panel) {
		print <<"END_PRINT";
<div class="panel" id="TOC_$p->{'key'}">
<h2>$p->{'name'}</h2>
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
		# Note we take the easy way out on plural vs singular because of the javascript filters changing the counts
		my $total_desc = qq(Total purchase cost for <span id="foot_count_$p->{'key'}">$p->{'count'}</span> shown recipe(s):);
		my $pretty_cost = AddCommas($p->{'total_cost'});
		
		print <<"END_PRINT";
</tbody>
<tfoot>
<tr>
<td class="foot_total" colspan="6">$total_desc</td>
<td id="foot_total_$p->{'key'}" class="value">$pretty_cost</td>
<td>--</td>
<td>--</td>
</tr>
</tfoot>
</table>
</div>
END_PRINT
	}
	
	print <<"END_PRINT";
<div class="panel" id="TOC_Ingredient_List">
<h2>Ingredient List</h2>
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
		my $data = lc GetItem($key, '', 0);
		$data =~ s/ /_/g;
		print qq(<tr class="ingr_list" data-ingr="$data"><td class="name">$imgTag $name</td><td class="value">$IngredientCount{$key}</td></tr>);
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
# WriteCraftingSummary - crafting recipes; must be run after machine summary
sub WriteCraftingSummary {
	my $FH;
	open $FH, ">$DocBase/crafting.html" or die "Can't open index.html for writing: $!";
	select $FH;

	print STDOUT "Generating Crafting Summary\n";
	my @Panel = ( 
		{ 'key' => 'object', 'name' => "Object Recipes", 'count' => 0, 'total_cost' => 0, 'row' => {}, },
		{ 'key' => 'craftable', 'name' => "Big Craftable Recipes", 'count' => 0, 'total_cost' => 0, 'row' => {}, },
		);
		
	my %IngredientCount = ();
	my %ModList = ();

	print STDOUT "  Processing Game Crafting Recipes\n";
	# We are starting by straight copying a lot of the Cooking recipe code.
	# There is no TV channel for these, so we can skip that part.
	# However purchased recipes come from a much wider variety of sources.
	my %VendorRecipes = ( 
			'Wood Floor' => { 'Robin' => 500 },
			'Stone Floor' => { 'Robin' => 500 },
			'Brick Floor' => { 'Robin' => 500 },
			'Stepping Stone Path' => { 'Robin' => 500 },
			'Straw Floor' => { 'Robin' => 1000 },
			'Crystal Path' => { 'Robin' => 1000 },
			'Wooden Brazier' => { 'Robin' => 250 },
			'Stone Brazier' => { 'Robin' => 400 },
			'Gold Brazier' => { 'Robin' => 1000 },
			'Carved Brazier' => { 'Robin' => 2000 },
			'Stump Brazier' => { 'Robin' => 800 },
			'Barrel Brazier' => { 'Robin' => 800 },
			'Skull Brazier' => { 'Robin' => 3000 },
			'Marble Brazier' => { 'Robin' => 5000 },
			'Wood Lamp-post' => { 'Robin' => 500 },
			'Iron Lamp-post' => { 'Robin' => 1000 },
			'Grass Starter' => { 'Pierre' => 1000 },
			'Weathered Floor' => { 'Dwarf' => 500 },
			'Crystal Floor' => { 'Krobus' => 500 },
			'Wicked Statue' => { 'Krobus' => 2000 },
			'Wedding Ring' => { 'Traveling Merchant' => 500 },
		);
	my %FestivalRecipes = (
			"Jack-O-Lantern" => { "Spirit's Eve" => 2000 },
			"Tub o' Flowers" => { "Flower Dance" => 2000 },
		);
	# More defaults for crafting, and they aren't explicitly identified in the data file,
	#  so we'll add them along with other specials.
	my %Special = (
		'Gate' => "Given automatically",
		'Wood Fence' => "Given automatically",
		'Wood Path' => "Given automatically",
		'Gravel Path' => "Given automatically",
		'Cobblestone Path' => "Given automatically",
		'Torch' => "Given automatically",
		'Campfire' => "Given automatically",
		'Chest' => "Given automatically",
		'Wood Sign' => "Given automatically",
		'Stone Sign' => "Given automatically",
		'Cask' => "Farmhouse " . Wikify("Cellar") . " upgrade",
		'Ancient Seeds' => "Museum reward for donating " . Wikify("Ancient Seed"),
		'Tea Sapling' => "Mail from " . Wikify("Caroline") . " after event",
		'Deluxe Scarecrow' => "Mail after collecting all " . Wikify("Rarecrows"),
		'Garden Pot' => Wikify("Evelyn") . " event after fixing " . Wikify("Greenhouse"),
		'Wild Bait' => Wikify("Linus") . " 4&#x2665; Event",
		'Mini-Jukebox' => Wikify("Gus") . " 5&#x2665; Event",
		'Drum Block' => Wikify("Robin") . " 6&#x2665; Event",
		'Flute Block' => Wikify("Robin") . " 6&#x2665; Event",
		"Warp Totem: Desert" => "Purchase from " . Wikify("Desert Trader") . " for 10 " . Wikify("Iridium Bar"),
		);
	foreach my $key (keys %{$GameData->{'CraftingRecipes'}}) {
		# Skip anything on machine summary
		next if (exists $Machines{$key});
		my @temp = split(/ /, $GameData->{'CraftingRecipes'}{$key}{'split'}[2]);
		my $cid = $temp[0];
		my $item_type = ($GameData->{'CraftingRecipes'}{$key}{'split'}[3] eq 'true') ? 'craftable' : 'object';
		my $cname = GetItem($cid, "", 1, 1);
		my $imgTag = GetImgTag($cid, $item_type, 1);
		my $ingr = "";
		@temp = split(/ /, $GameData->{'CraftingRecipes'}{$key}{'split'}[0]);
		my @ingr_data = ();
		for (my $i = 0; $i < scalar(@temp); $i += 2) {
			my $item = GetItem($temp[$i]);
			my $img = GetImgTag($temp[$i]);
			my $qty = ($temp[$i+1] > 1 ? " ($temp[$i+1])" : "");
			$ingr .= "$img $item$qty<br />";
			AddAllIngredients(\%IngredientCount, $temp[$i], $temp[$i+1], \@ingr_data);
		}
		my $source = "";
		if (exists $Special{$key}) {
			$source .= $Special{$key};
		}
		my $recipe_cost = "--";
		if (exists $VendorRecipes{$key}) {
			foreach my $v (keys %{$VendorRecipes{$key}}) {
				$source .= qq(Buy for $VendorRecipes{$key}{$v}g from ) . WikiShop($v) . qq(<br />);
				$recipe_cost = $VendorRecipes{$key}{$v};
			}
		}
		if (exists $FestivalRecipes{$key}) {
			foreach my $v (keys %{$FestivalRecipes{$key}}) {
				$source .= qq(Buy for $FestivalRecipes{$key}{$v}g at ) . Wikify($v) . qq( <br />);
				$recipe_cost = $FestivalRecipes{$key}{$v};
			}
		}
		# Some conditions are defined in the last field of the recipe data. Only skills are useful
		# To make our lives difficult, some of them have the leading s and some of them don't.
		# Also we start with 2 \w because some of the special/default recipes have conditions like "l 0"
		my $condition = $GameData->{'CraftingRecipes'}{$key}{'split'}[4];
		if ($condition =~ /^s \w\w+ \d+$/) {
			my @temp = TranslatePreconditions("$condition");
			$source .= "$temp[0]<br />";
		} elsif ($condition =~ /\w\w+ \d+$/) {
			my @temp = TranslatePreconditions("s $condition");
			$source .= "$temp[0]<br />";
		}
		my $filter = "filter_base_game";
		my $data_attr = join('|', @ingr_data);
		my $output = <<"END_PRINT";
<tr class="$filter">
<td class="name">$imgTag $cname</td>
<td class="name ingr" data-ingr="$data_attr">$ingr</td>
<td>$source</td>
<td class="value total_$item_type">$recipe_cost</td>
</tr>
END_PRINT

		# It is a little weird to do it this way when there are only 2 options, but it is consistent with
		#  other pages and makes it easier to adjust if we change the categories later.
		foreach my $p (@Panel) {
			if ($p->{'key'} eq $item_type) {
				$p->{'row'}{StripHTML($cname)} = $output;
				$p->{'count'}++;
				if (looks_like_number($recipe_cost)) {
					$p->{'total_cost'} += $recipe_cost;
				}
				last;
			}
		}
	}

	print STDOUT "  Processing Mod Crafting Recipes (Objects)\n";
	foreach my $key (keys %{$ModData->{'Objects'}}) {
		next if (not defined $ModData->{'Objects'}{$key}{'Recipe'} or $ModData->{'Objects'}{$key}{'Category'} ne 'Crafting');
		my $key = $ModData->{'Objects'}{$key}{'Name'};
		my $cname = GetItem($key);
		#my $cdesc = $ModData->{'Objects'}{$key}{'Description'};
		my $imgTag = GetImgTag($key, "object", 1);
		my $ingr = "";
		my @ingr_list = @{$ModData->{'Objects'}{$key}{'Recipe'}{'Ingredients'}};
		my @ingr_data = ();
		foreach my $i (@ingr_list) {
			my $item = GetItem($i->{'Object'});
			my $img = GetImgTag($i->{'Object'});
			my $qty = ($i->{'Count'} > 1 ? " ($i->{'Count'})" : "");
			$ingr .= "$img $item$qty<br />";
			my $value_to_add = AddAllIngredients(\%IngredientCount, $i->{'Object'}, $i->{'Count'}, \@ingr_data);
		}
		if (not exists $ModList{$ModData->{'Objects'}{$key}{'__MOD_ID'}}) {
			$ModList{$ModData->{'Objects'}{$key}{'__MOD_ID'}} = 1;
		}
		my $item_type = "object";
		my $source = "Given automatically";
		my $recipe_cost = "--";
		if (not $ModData->{'Objects'}{$key}{'Recipe'}{'IsDefault'}) {
			if ($ModData->{'Objects'}{$key}{'Recipe'}{'CanPurchase'}) {
				$source = qq(Buy for $ModData->{'Objects'}{$key}{'Recipe'}{'PurchasePrice'}g from ) .
					WikiShop($ModData->{'Objects'}{$key}{'Recipe'}{'PurchaseFrom'}) . qq(<br />);
				$recipe_cost = $ModData->{'Objects'}{$key}{'Recipe'}{'PurchasePrice'};
			} else {
				$source = FindMailRecipe($key);
			}
		}
		my @conditions = ();
		if (defined $ModData->{'Objects'}{$key}{'Recipe'}{'PurchaseRequirements'}) {
			@conditions = @{$ModData->{'Objects'}{$key}{'Recipe'}{'PurchaseRequirements'}};
		}
		foreach my $condition (@conditions) {
			my @temp = TranslatePreconditions($condition);
			$source .= "$temp[0]<br />";
		}

		my $value = GetValue($key);
		my $filter = $ModInfo->{$ModData->{'Objects'}{$key}{'__MOD_ID'}}{'__FILTER'};
		my $data_attr = join('|', @ingr_data);
		my $output = <<"END_PRINT";
<tr class="$filter">
<td class="name">$imgTag $cname</td>
<td class="name ingr" data-ingr="$data_attr">$ingr</td>
<td>$source</td>
<td class="value total_$item_type">$recipe_cost</td>
</tr>
END_PRINT

		foreach my $p (@Panel) {
			if ($p->{'key'} eq $item_type) {
				$p->{'row'}{$key} = $output;
				$p->{'count'}++;
				if (looks_like_number($recipe_cost)) {
					$p->{'total_cost'} += $recipe_cost;
				}
				last;
			}
		}
	}

	print STDOUT "  Processing Mod Crafting Recipes (Big Craftables)\n";
	foreach my $key (keys %{$ModData->{'BigCraftables'}}) {
		# Skip anything on machine summary or anything not actually craftable
		next if (exists $Machines{$key});
		next if (not defined $ModData->{'BigCraftables'}{$key}{'Recipe'});
		my $key = $ModData->{'BigCraftables'}{$key}{'Name'};
		my $cname = GetItem($key);
		#my $cdesc = $ModData->{'Objects'}{$key}{'Description'};
		my $imgTag = GetImgTag($key, "craftable", 1);
		my $ingr = "";
		my @ingr_list = @{$ModData->{'BigCraftables'}{$key}{'Recipe'}{'Ingredients'}};
		my @ingr_data = ();
		foreach my $i (@ingr_list) {
			my $item = GetItem($i->{'Object'});
			my $img = GetImgTag($i->{'Object'});
			my $qty = ($i->{'Count'} > 1 ? " ($i->{'Count'})" : "");
			$ingr .= "$img $item$qty<br />";
			my $value_to_add = AddAllIngredients(\%IngredientCount, $i->{'Object'}, $i->{'Count'}, \@ingr_data);
		}
		if (not exists $ModList{$ModData->{'BigCraftables'}{$key}{'__MOD_ID'}}) {
			$ModList{$ModData->{'BigCraftables'}{$key}{'__MOD_ID'}} = 1;
		}
		my $item_type = "craftable";
		my $source = "Given automatically";
		my $recipe_cost = "--";
		if (not $ModData->{'BigCraftables'}{$key}{'Recipe'}{'IsDefault'}) {
			if ($ModData->{'BigCraftables'}{$key}{'Recipe'}{'CanPurchase'}) {
				$source = qq(Buy for $ModData->{'BigCraftables'}{$key}{'Recipe'}{'PurchasePrice'}g from ) .
					WikiShop($ModData->{'BigCraftables'}{$key}{'Recipe'}{'PurchaseFrom'}) . qq(<br />);
				$recipe_cost = $ModData->{'BigCraftables'}{$key}{'Recipe'}{'PurchasePrice'};
			} else {
				$source = FindMailRecipe($key);
			}
		}
		my @conditions = ();
		if (defined $ModData->{'BigCraftables'}{$key}{'Recipe'}{'PurchaseRequirements'}) {
			@conditions = @{$ModData->{'BigCraftables'}{$key}{'Recipe'}{'PurchaseRequirements'}};
		}
		foreach my $condition (@conditions) {
			my @temp = TranslatePreconditions($condition);
			$source .= "$temp[0]<br />";
		}

		my $value = GetValue($key);
		my $filter = $ModInfo->{$ModData->{'BigCraftables'}{$key}{'__MOD_ID'}}{'__FILTER'};
		my $data_attr = join('|', @ingr_data);
		my $output = <<"END_PRINT";
<tr class="$filter">
<td class="name">$imgTag $cname</td>
<td class="name ingr" data-ingr="$data_attr">$ingr</td>
<td>$source</td>
<td class="value total_$item_type">$recipe_cost</td>
</tr>
END_PRINT

		foreach my $p (@Panel) {
			if ($p->{'key'} eq $item_type) {
				$p->{'row'}{$key} = $output;
				$p->{'count'}++;
				if (looks_like_number($recipe_cost)) {
					$p->{'total_cost'} += $recipe_cost;
				}
				last;
			}
		}
	}

	my $longdesc = <<"END_PRINT";
<p>A summary of crafting recipes from various sources. In the list below, the checkboxes can be used to show or hide
information specific to that particular source; the symbol &#x24c5 indicates an official PPJA mod. Additionally there
are some buttons which will show or hide multiple sources at once.</p>
<fieldset id="filter_options" class="filter_set">
<label><input class="filter_check" type="checkbox" name="filter_base_game" id="filter_base_game" value="show" checked="checked"> 
Stardew Valley base game version $StardewVersion</label><br />
END_PRINT

	foreach my $k (sort {$ModInfo->{$a}{'Name'} cmp $ModInfo->{$b}{'Name'}} keys %ModList) {
		my $filter = $ModInfo->{$k}{'__FILTER'};
		my $info = GetExtendedModInfo($k, 1, 2);
		my $prefix = ($info->{'ppja'}) ? qq(&#x24c5; ) : "";
		my $suffix = "";
		if ($info->{'info'} !~ /href/ and defined $info->{'parentID'}) {
			$info->{'parentInfo'} =~ /(\(.*\))/;
			$suffix = " $1";
		}
		my $class = "filter_check";
		if ($info->{'ppja'}) {
			$class .= " filter_ppja";
		}
		$longdesc .= <<"END_PRINT";
<label><input class="$class" type="checkbox" name="$filter" id="$filter" value="show" checked="checked">
$prefix$info->{'info'}</label>$suffix<br />
END_PRINT
	}

	$longdesc .= <<"END_PRINT";
</fieldset>
<fieldset id="filter_control" class="filter_set">
<button type="button" id="filter_check_all_off">All Sources Off</button>
<button type="button" id="filter_check_all_on">All Sources On</button>
<button type="button" id="filter_check_ppja">PPJA Mods Only</button>
<button type="button" id="filter_check_nonppja">Non-PPJA Mods Only</button>
</fieldset>
<p>The following tables contain information about crafted items. These are separated into small objects and larger 
placeable items ("Big Craftables"), but items which are listed on the <a href="machines.html">machine summary</a>
are not included. A total is calculated for recipes which must be purchased and an ingredient list summarizes
all the items which are necessary to craft one of everything shown. Both the total and the ingredient list
will auto-adjust based on filtering.</p>
END_PRINT
	print GetHeader("Crafting", qq(Crafting recipes from PPJA (and other) mods for Stardew Valley.), $longdesc);
	print GetTOCStart();


	# Print the rest of the TOC
	foreach my $p (@Panel) {
		my $text = $p->{'name'};
		$text =~ s/ /&nbsp;/g;
		print qq(<li><a href="#TOC_$p->{'key'}">$text</a></li>);
	}
	print qq(<li><a href="#TOC_Ingredient_List">Ingredient List</a></li>);
	print GetTOCEnd();
	
	# Print the Panels
	foreach my $p (@Panel) {
		print <<"END_PRINT";
<div class="panel" id="TOC_$p->{'key'}">
<h2>$p->{'name'}</h2>
<table class="sortable output">
<thead>
<tr>
<th>Name</th>
<th>Ingredients</th>
<th>Source</th>
<th>Recipe<br />Cost</th>
</thead>
<tbody>
END_PRINT

		foreach my $k (sort keys %{$p->{'row'}}) {
			print $p->{'row'}{$k};
		}
		# Note we take the easy way out on plural vs singular because of the javascript filters changing the counts
		my $total_desc = qq(Total purchase cost for <span id="foot_count_$p->{'key'}">$p->{'count'}</span> shown recipe(s):);
		my $pretty_cost = AddCommas($p->{'total_cost'});
		
		print <<"END_PRINT";
</tbody>
<tfoot>
<tr>
<td class="foot_total" colspan="3">$total_desc</td>
<td id="foot_total_$p->{'key'}" class="value">$pretty_cost</td>
</tr>
</tfoot>
</table>
</div>
END_PRINT
	}
	
	print <<"END_PRINT";
<div class="panel" id="TOC_Ingredient_List">
<h2>Ingredient List</h2>
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
		my $data = lc GetItem($key, '', 0);
		$data =~ s/ /_/g;
		print qq(<tr class="ingr_list" data-ingr="$data"><td class="name">$imgTag $name</td><td class="value">$IngredientCount{$key}</td></tr>);
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
	# As with Cooking, we are reorganizing so that the list of mods in use is auto-generated
	my %ModList = ();

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
		$GameData->{'ObjectInformation'}{$cid}{'split'}[3] =~ /(\-?\d*)$/;
		my $category = GetCategory($1);
		my $cprice = $GameData->{'ObjectInformation'}{$cid}{'split'}[1];
		my $seed_vendor = WikiShop("Pierre");
		my $imgTag = GetImgTag($sid, "tree");
		my $prodImg = GetImgTag($cid, "object");
		my $seedImg = GetImgTag($sid, "object");
		my $amt = ceil($scost/$cprice);
		my $filter = "filter_base_game";
		
		my $output = <<"END_PRINT";
<tr class="$filter">
<td class="icon">$imgTag</td>
<td class="name">$prodImg $cname</td>
<td class="name">$category</td>
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
		my $sname = GetItem($ModData->{'FruitTrees'}{$key}{'SaplingName'});
		my $scost = $ModData->{'FruitTrees'}{$key}{'SaplingPurchasePrice'};
		my $season = $ModData->{'FruitTrees'}{$key}{'Season'};
		my $cname = GetItem($ModData->{'FruitTrees'}{$key}{'Product'});
		my $category = "";
		if (looks_like_number($ModData->{'FruitTrees'}{$key}{'Product'})) {
			$GameData->{'ObjectInformation'}{$ModData->{'FruitTrees'}{$key}{'Product'}}{'split'}[3] =~ /(\-?\d*)$/;
			$category = GetCategory($1);
		} else {
			$category = $ModData->{'Objects'}{$ModData->{'FruitTrees'}{$key}{'Product'}}{'Category'};
		}
		my $cprice = GetValue($ModData->{'FruitTrees'}{$key}{'Product'});
		my $seed_vendor = WikiShop("Pierre");
		if (exists $ModData->{'FruitTrees'}{$key}{'SaplingPurchaseFrom'}) {
			$seed_vendor = WikiShop($ModData->{'FruitTrees'}{$key}{'SaplingPurchaseFrom'});
		}
		if (exists $ModData->{'FruitTrees'}{$key}{'SaplingPurchaseRequirements'} and defined $ModData->{'FruitTrees'}{$key}{'SaplingPurchaseRequirements'}) {
			my @req = TranslatePreconditions(@{$ModData->{'FruitTrees'}{$key}{'SaplingPurchaseRequirements'}});
			# Note that the order here is not guaranteed. If we start getting crops with multiple different requirements we might have to deal with that
			$seed_vendor .= '<br />' . join('<br />', map {"($_)"} @req);
		}
		my $imgTag = GetImgTag($key, 'tree');
		my $prodImg = GetImgTag($ModData->{'FruitTrees'}{$key}{'Product'}, "object");
		my $seedImg = GetImgTag($ModData->{'FruitTrees'}{$key}{'SaplingName'}, "object");
		my $amt = ceil($scost/$cprice);
		if (not exists $ModList{$ModData->{'FruitTrees'}{$key}{'__MOD_ID'}}) {
			$ModList{$ModData->{'FruitTrees'}{$key}{'__MOD_ID'}} = 1;
		}
		my $filter = $ModInfo->{$ModData->{'FruitTrees'}{$key}{'__MOD_ID'}}{'__FILTER'};

		my $output = <<"END_PRINT";
<tr class="$filter">
<td class="icon">$imgTag</td>
<td class="name">$prodImg $cname</td>
<td class="name">$category</td>
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
	
	my $longdesc = <<"END_PRINT";
<p>A summary of fruit trees from various sources. In the list below, the checkboxes can be used to show or hide
information specific to that particular source; the symbol &#x24c5 indicates an official PPJA mod. Additionally there
are some buttons which will show or hide multiple sources at once.</p>
<fieldset id="filter_options" class="filter_set">
<label><input class="filter_check" type="checkbox" name="filter_base_game" id="filter_base_game" value="show" checked="checked"> 
Stardew Valley base game version $StardewVersion</label><br />
END_PRINT
	
	foreach my $k (sort {$ModInfo->{$a}{'Name'} cmp $ModInfo->{$b}{'Name'}} keys %ModList) {
		my $filter = $ModInfo->{$k}{'__FILTER'};
		my $info = GetExtendedModInfo($k, 1, 2);
		my $prefix = ($info->{'ppja'}) ? qq(&#x24c5; ) : "";
		my $suffix = "";
		if ($info->{'info'} !~ /href/ and defined $info->{'parentID'}) {
			$info->{'parentInfo'} =~ /(\(.*\))/;
			$suffix = " $1";
		}
		my $class = "filter_check";
		if ($info->{'ppja'}) {
			$class .= " filter_ppja";
		}
		$longdesc .= <<"END_PRINT";
<label><input class="$class" type="checkbox" name="$filter" id="$filter" value="show" checked="checked">
$prefix$info->{'info'}</label>$suffix<br />
END_PRINT
	}

	$longdesc .= <<"END_PRINT";
</fieldset>
<fieldset id="filter_control" class="filter_set">
<button type="button" id="filter_check_all_off">All Sources Off</button>
<button type="button" id="filter_check_all_on">All Sources On</button>
<button type="button" id="filter_check_ppja">PPJA Mods Only</button>
<button type="button" id="filter_check_nonppja">Non-PPJA Mods Only</button>
</fieldset>
<p>The <span class="note">Break Even Amount</span> column is a simplistic measure of how many base (no-star) quality products need to be sold
to recoup the cost of the initial sapling. Smaller numbers are better, although those who care about these kind of measurements will probably
be processing the items in machines where possible rather than selling them raw.</p>
END_PRINT

	print GetHeader("Fruit Trees", qq(Sumary of fruit tree info from PPJA (and other) mods for Stardew Valley.), $longdesc);
	print GetTOCStart();

	# Print the rest of the TOC
	foreach my $p (@Panel) {
		my $text = "$p->{'key'} Trees";
		$text =~ s/ /&nbsp;/g;
		print qq(<li><a href="#TOC_$p->{'key'}">$text</a></li>);
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
<th>Product Type</th>
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

	# This is tricky because we don't know all the actual machines ahead of time. We are going to
	#  build up the data within the Panel hash and then use it to sort later. Filtering is also
	#  a bit weird; previously we filtered at the machine level, but with the advent of PFM
	#  and the ability to add new recipes to vanilla machines, filtering at the product level makes
	#  more sense.
	# We are going to try to initially sort entries by output first, input second. 
	
	print STDOUT "Generating Machine Summary\n";
	my %ModList = ();
	my %TOC = ();
	my %Panel = ( );
	my @quality_desc = ("", "Silver", "Gold", "", "Iridium");
	# Panel will be keyed on machine name and have elements for the following:
	#  'products' => [ {'prod', 'ingr', 'time', 'val'} ]

	print STDOUT "  Processing PFM Machines\n";
	# The mod Digus.CustomProducerMod has nearly all the vanilla machine data, so we'll use that to setup
	#  vanilla stuff and mess with the filtering when we see it. It is missing an aged Roe recipe since
	#  PFM doesn't support it yet and seedmakers only have a single example. Here we try to correct that
	foreach my $i (@{$ModData->{'Producers'}}) {
		if (defined $ModInfo->{$i->{'__MOD_ID'}} and $i->{'__MOD_ID'} eq "Digus.CustomProducerMod") {
			my $roe = 	{
							"ProducerName" => "Preserves Jar",
							"InputIdentifier"=> "812",
							"MinutesUntilReady"=> 4000,
							"OutputIdentifier"=> "447",
							"PreserveType"=> "AgedRoe",
							"InputPriceBased"=> 1,
							"OutputPriceIncrement"=> 60,
							"OutputPriceMultiplier"=> 1,
							"Sounds"=> ["Ship"],
							"PlacingAnimation"=> "Bubbles",
							"PlacingAnimationColorName"=> "LightBlue"
						};
			push @{$i->{'producers'}}, $roe;
		}
	}

	foreach my $j (@{$ModData->{'Producers'}}) {
		my $filter = "";
		my $mod_id = "";
		my $extra_info = "";
		if (defined $ModInfo->{$j->{'__MOD_ID'}}) {
			if ($j->{'__MOD_ID'} eq "Digus.CustomProducerMod") {
				$filter = 'filter_base_game';
			} else {
				$mod_id = $j->{'__MOD_ID'};
				if (not defined $ModList{$mod_id}) {
					$ModList{$mod_id} = 1;
				}
				$filter = $ModInfo->{$mod_id}{'__FILTER'};
			}
		}
		foreach my $m (@{$j->{'producers'}}) {
			my $key = $m->{'ProducerName'};
			if (not defined $key) { warn "Producer without a name in pack $mod_id"; }
			if (not exists $Panel{$key}) {
				$Panel{$key} = {'rules' => [], 'out' => ''};
				# Might as well set this stuff up now.
				my $anchor = "TOC_$key";
				$anchor =~ s/ /_/g;
				$TOC{$key} = {'anchor' => $anchor, 'filter' => $filter};
				my $imgTag = GetImgTag($key, 'craftable', 1, "container__image");
				# This duplicates code used in GetImgTag which makes me sad
				my $desc = "";
				my $recipe = "";
				my $source = "";
				if (exists $ModData->{'BigCraftables'}{$key}) {
					$desc = $ModData->{'BigCraftables'}{$key}{'Description'};
					$extra_info = qq(<p><span class="note">From ) . GetModInfo($ModData->{'BigCraftables'}{$key}{"__MOD_ID"},0) . qq(</span></p>);
					my @ingr_list = @{$ModData->{'BigCraftables'}{$key}{'Recipe'}{'Ingredients'}};
					foreach my $i (@ingr_list) {
						my $item = GetItem($i->{'Object'});
						my $img = GetImgTag($i->{'Object'});
						my $qty = ($i->{'Count'} > 1 ? " ($i->{'Count'})" : "");
						$recipe .= "$img $item$qty<br />";
					}
					if (not $ModData->{'BigCraftables'}{$key}{'Recipe'}{'IsDefault'}) {
						if ($ModData->{'BigCraftables'}{$key}{'Recipe'}{'CanPurchase'}) {
							$source = qq(Buy for $ModData->{'BigCraftables'}{$key}{'Recipe'}{'PurchasePrice'}g from ) .
								WikiShop($ModData->{'BigCraftables'}{$key}{'Recipe'}{'PurchaseFrom'}) . qq(<br />);
						} elsif (defined $ModData->{'BigCraftables'}{$key}{'Recipe'}{'SkillUnlockName'}) {
							my $lvl = $ModData->{'BigCraftables'}{$key}{'Recipe'}{'SkillUnlockLevel'};
							my $skill = Wikify($ModData->{'BigCraftables'}{$key}{'Recipe'}{'SkillUnlockName'});
							$source = qq(Level $lvl in $skill<br />);
						} else {
							$source = FindMailRecipe($key);
						}
					} else {
						$source = "Given automatically";
					}
					my @conditions = ();
					if (defined $ModData->{'BigCraftables'}{$key}{'Recipe'}{'PurchaseRequirements'}) {
						@conditions = @{$ModData->{'BigCraftables'}{$key}{'Recipe'}{'PurchaseRequirements'}};
					}
					foreach my $condition (@conditions) {
						my @temp = TranslatePreconditions($condition);
						$source .= "$temp[0]<br />";
					}
				} else {
					foreach my $k (keys %{$GameData->{'BigCraftablesInformation'}}) {
						if ($GameData->{'BigCraftablesInformation'}{$k}{'split'}[0] eq $key) {
							$desc = $GameData->{'BigCraftablesInformation'}{$k}{'split'}[4];
							$extra_info = qq(<p><span class="note">From ) . GetModInfo("",0) . qq(</span></p>);
							if (exists $GameData->{'CraftingRecipes'}{$key}) {
								my @temp = split(/ /,  $GameData->{'CraftingRecipes'}{$key}{'split'}[0]);
								for (my $i = 0; $i < scalar(@temp); $i += 2) {
									my $item = GetItem($temp[$i]);
									my $img = GetImgTag($temp[$i]);
									my $qty = ($temp[$i+1] > 1 ? " ($temp[$i+1])" : "");
									$recipe .= "$img $item$qty<br />";
								}
								my $condition = $GameData->{'CraftingRecipes'}{$key}{'split'}[4];
								# Vanilla conditions here are not the same as they are for cooking recipes.
								# We hardcode the furnace recipe and do silly things with skill levels.
								if ($key eq 'Furnace') {
									$source .= "Given by " . Wikify("Clint") . " after finding ore.<br />";
								} elsif ($condition eq 'default') {
									$source .= "Given automatically";
								} elsif ($condition =~ /^\w+ \d+$/) {
									my @temp = TranslatePreconditions("s $condition");
									$source .= "$temp[0]<br />";
								} else {
									print STDERR "Can't understand conditions {$condition} for vanilla machine $key\n";
								}
							} else {
								warn "Can't find crafting recipe for vanilla machine $k ($key)\n";
							}
							last;
						}
					}
				}
				if ($source eq "") {
					$source = qq(<span class="note">Unknown source</span>);
				}
				if ($recipe eq "") {
					$recipe = qq(<span class="note">Can't be crafted</span>);
				}
				my $output = <<"END_PRINT";
<div class="panel" id="$anchor">
<div class="container">
$imgTag
<div class="container__text">
<h2>$key</h2>
<span class="mach_desc">$desc</span><br />
</div>
$extra_info
</div>
<table class="recipe">
<tbody><tr><th>Crafting Recipe</th><td class="name">$recipe</td></tr>
<tr><th>Recipe Source</th><td class="name">$source</td></tr></tbody></table>
<table class="sortable output">
<thead>
<tr><th>Product</th><th>Ingredients</th><th>Time</th><th>Value</th><th>Profit<br />(Item)</th><th>Profit<br />(Hr)</th></tr>
</thead>
<tbody>
END_PRINT
				$Panel{$key}{'out'} = $output;
			}
			# Now it is time to parse a product and add it to the panel
			# The whole quality input thing makes this really tricky. We are going to create an array that tells us which
			#  inputs are defined so we know what to process.
			my @iterations = (1, 0, 0, 0);
			$iterations[1] = 1 if (defined $m->{"SilverQualityInput"});
			$iterations[2] = 1 if (defined $m->{"GoldQualityInput"});
			$iterations[3] = 1 if (defined $m->{"IridiumQualityInput"});
			for (my $i = 0; $i < scalar(@iterations); $i++) {
				next unless ($iterations[$i] == 1);
				my $input_quality = 0;
				my $input_prob = 1;
				my $amt_min = (defined $m->{'OutputStack'} and $m->{'OutputStack'} > 1) ? $m->{'OutputStack'} : 1;
				my $amt_max = (defined $m->{'OutputMaxStack'} and $m->{'OutputMaxStack'} > 1) ? $m->{'OutputMaxStack'} : 1;
				if ($i > 0) {
					my $override_tag = "";
					if ($i == 1) {
						$input_quality = 1;
						$override_tag = "SilverQualityInput";
					} elsif ($i == 2) {
						$input_quality = 2;
						$override_tag = "GoldQualityInput";
					} elsif ($i == 3) {
						$input_quality = 4;
						$override_tag = "IridiumQualityInput";
					}
					$input_prob = $m->{$override_tag}{'Probability'};
					$amt_min = (defined $m->{$override_tag}{'OutputStack'}) ? $m->{$override_tag}{'OutputStack'} : 1;
					$amt_max = (defined $m->{$override_tag}{'OutputMaxStack'}) ? $m->{$override_tag}{'OutputMaxStack'} : $amt_min;
				}
				next if ($input_prob == 0);
				my %entry = ( 'key1' => '', 'key2' => '', 'out' => '' );
				my $name = GetItem($m->{'OutputIdentifier'});
				# key1 is the output name, but we need to strip HTML. Because we created the HTML ourselves we know
				# that a simple regex can do the job rather than needing a more robust general approach.
				$entry{'key1'} = StripHTML($name);
				my $img = GetImgTag($entry{'key1'});
				my $val_mult = 1;
				if (defined $m->{'OutputQuality'} and $m->{'OutputQuality'} > 0) {
					my $q = $m->{'OutputQuality'};
					$val_mult *= (1 + .25*$q);
					my $alt = $quality_desc[$q];
					my $tag = GetImgTag($entry{'key1'}, 'object', 0, "quality-item");
					$img = qq(<div class="quality-container">$tag<img class="quality quality-star" id="Quality_$q" alt="$alt" src="img/blank.png"></div>);
				};
				# Quality should probably apply to these as well
				my $prob = 1;
				my $left = 1;
				my %outs = ();
				if (defined $m->{'AdditionalOutputs'}) {
					foreach my $a (@{$m->{'AdditionalOutputs'}}) {
						my $this_name = GetItem($a->{'OutputIdentifier'});
						my $key = StripHTML($this_name);
						my $this_img = GetImgTag($a->{'OutputIdentifier'});
						my $this_prob = (defined $a->{'OutputProbability'}) ? $a->{'OutputProbability'} : 0;
						if ($this_prob == 0) {
							$left++;
							$this_prob = "LEFT";
						} else {
							$prob -= $this_prob;
							$this_prob = sprintf("%0.1f", $this_prob*100);
						}
						$this_name .= " [$this_prob%]";
						$outs{$key} = "$this_img $this_name";
					}
					$prob = sprintf("%0.1f", $prob*100/$left);
					foreach my $k (keys %outs) {
						$outs{$k} =~ s/LEFT/$prob/;
					}
				}
				if ($amt_max < $amt_min) {
					$amt_max = $amt_min;
				}
				if ($amt_max > 1) {
					if ($amt_min < $amt_max) {
						$name .= " ($amt_min-$amt_max)";
						$val_mult = ($amt_min+$amt_max)/2;
					} else {
						$name .= " ($amt_max)";
						$val_mult = $amt_max;
					}
				}
				if ($prob ne "1") {
					$name .= " [$prob%]";
				}
				my $adds = "";
				foreach my $k (sort keys %outs) {
					$adds .= "<br/>$outs{$k}";
				}
				$entry{'out'} = qq(<tr class="$filter"><td class="name">$img $name$adds</td>);
				my $cost = 0;
				$name = GetItem($m->{'InputIdentifier'});
				$entry{'key2'} = StripHTML($name);
				if ($input_prob != 1) {
					$name .= sprintf(" [%0.1f%%]", $input_prob*100);
				}
				$img = GetImgTag($m->{'InputIdentifier'});
				my $val = GetValue($m->{'InputIdentifier'});
				if ($input_quality > 0) {
					my $q = $input_quality;
					my $alt = $quality_desc[$q];
					my $tag = GetImgTag($m->{'InputIdentifier'}, 'object', 0, "quality-item");
					$img = qq(<div class="quality-container">$tag<img class="quality quality-star" id="Quality_$q" alt="$alt" src="img/blank.png"></div>);
					$val *= (1 + .25*$q);
				}
				my $input_val = $val;
				my $amt = 1;
				if (defined $m->{'InputStack'} and $m->{'InputStack'} > 1) {
					$amt = $m->{'InputStack'};
					$name .= " ($amt)";
					if (looks_like_number($val)) {
						$val *= $amt;
					}
				}
				if (looks_like_number($cost) and looks_like_number($val)) {
					$cost += $val;
				} else {
					$cost = "Varies";
				}
				my @inputs = ("$img $name");
				if (defined $m->{'FuelIdentifier'}) {
					$name = GetItem($m->{'FuelIdentifier'});
					$img = GetImgTag($m->{'FuelIdentifier'});
					$val = GetValue($m->{'FuelIdentifier'});
					if (defined $m->{'FuelStack'} and $m->{'FuelStack'} > 1) {
						$amt = $m->{'FuelStack'};
						$name .= " ($amt)";
						if (looks_like_number($val)) {
							$val *= $amt;
						}
					}
					if (looks_like_number($cost) and looks_like_number($val)) {
						$cost += $val;
					} else {
						$cost = "Varies";
					}
					push @inputs, "$img $name";
				}
				if (defined $m->{'AdditionalFuel'}) {
					foreach my $f (keys %{$m->{'AdditionalFuel'}}) {
						$name = GetItem($f);
						$img = GetImgTag($f);
						my $amt = $m->{'AdditionalFuel'}{$f};
						$val = GetValue($f);
						if ($amt > 1) {
							$name .= " ($amt)";
							if (looks_like_number($val)) {
								$val *= $amt;
							}
						}
						if (looks_like_number($cost) and looks_like_number($val)) {
							$cost += $val;
						} else {
							$cost = "Varies";
						}
						push @inputs, "$img $name";
					}
				}
				$entry{'out'} .= qq(<td class="name">) . join("<br/>", @inputs);
				if (defined $m->{'ExcludeIdentifiers'}) {
					$entry{'out'} .= '<br /><span class="group">Except ' . join(', ', (map {GetItem($_)} @{$m->{'ExcludeIdentifiers'}})) . "</span><br />";
				}
				$entry{'out'} .= "</td>";
				my $time = $m->{'MinutesUntilReady'};
				# 1.4 standardized machine time to be 60 min per hour from 6a-2a and then 100min per hour after. This gives
				#  a total of 1600 min rather than the 1440 we used to use. This does cause complications estimating time.
				my $min_per_day = 1600;
				if ($time > $min_per_day) { 
					$time = "$time min (~" . nearest(.1, $time/$min_per_day) . " days)";
				} elsif ($time >= 1440) {
					# anything from 1440 to 1600 will be estimated as a day.
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
				my $value = GetValue($m->{'OutputIdentifier'});
				my $equation = "";
				if (defined $m->{'InputPriceBased'} and $m->{'InputPriceBased'}) {
					$equation = "Input";
					if (defined $m->{'OutputPriceMultiplier'} and $m->{'OutputPriceMultiplier'} != 1) {
						$equation .= " * $m->{'OutputPriceMultiplier'}";
					}
					if (defined $m->{'OutputPriceIncrement'} and $m->{'OutputPriceIncrement'} != 0) {
						$equation .= " + $m->{'OutputPriceIncrement'}";
					}
				}
				if ($equation ne "") {
					if (looks_like_number($input_val)) {
						$equation =~ s/Input/$input_val/;
						my $eq_eval = eval $equation;
						$eq_eval = '' if (not defined $eq_eval);
						if ($eq_eval ne '' and looks_like_number($eq_eval)) {
							$value = floor($eq_eval);
						}
					}
				} else {	
					if (not looks_like_number($value)) {
						$value = qq(<span class="note">Varies</span>);
					}
				}
				my $profit = "";
				if ($equation =~ /Input/) {
					$profit = qq(<span class="note">Varies</span>);
					$value = $equation;
				} elsif (looks_like_number($cost) and looks_like_number($value)) {
					$value *= $val_mult;
					$profit = $value - $cost;
				} else {
					$profit = qq(<span class="note">--</span>);
				}
				$entry{'out'} .= qq(<td class="value">$value</td>);
				$entry{'out'} .= qq(<td class="value">$profit</td>);
				# reuse profit variable for per-hour version.
				if (looks_like_number($profit)) {
					$profit = nearest(.01,60*$profit/$m->{'MinutesUntilReady'});
				}
				$entry{'out'} .= qq(<td class="value">$profit</td>);
				$entry{'out'} .= qq(</tr>);
				push @{$Panel{$key}{'rules'}}, \%entry;
			}
		}
	}
	
	# We may not have any more CFR machines ever, but we're keeping the code just in case.
	print STDOUT "  Processing CFR Machines\n";
	foreach my $j (@{$ModData->{'Machines'}}) {
		my $extra_info = "";
		my $filter = "";
		if (exists $ModInfo->{$j->{'__MOD_ID'}}) {
			$extra_info = qq(<p><span class="note">From ) . GetModInfo($j->{'__MOD_ID'},0) . qq(</span></p>);
			if (not exists $ModList{$j->{'__MOD_ID'}}) {
				$ModList{$j->{'__MOD_ID'}} = 1;
			}
			$filter = $ModInfo->{$j->{'__MOD_ID'}}{'__FILTER'};
		}
		foreach my $m (@{$j->{'machines'}}) {
			my $key = $m->{'name'};
			if (not exists $Panel{$key}) {
				$Panel{$key} = {'rules' => [], 'out' => ''};
				# Might as well set this stuff up now.
				my $anchor = "TOC_$m->{'name'}";
				$anchor =~ s/ /_/g;
				$TOC{$m->{'name'}} = {'anchor' => $anchor, 'filter' => $filter};
				my $imgTag = GetImgTag($m->{'name'}, 'machine', 1, "container__image");
				my $output = <<"END_PRINT";
<div class="panel $filter" id="$anchor">
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

				if (defined $m->{'crafting'}) {
					my @recipe = split(' ', $m->{'crafting'});
					for (my $i = 0; $i < scalar(@recipe); $i += 2) {
						my $num = $recipe[$i+1];
						$output .= GetImgTag($recipe[$i]) . " " . GetItem($recipe[$i]) . ($num > 1 ? " ($num)" : "" ) . "<br />";
					}
				} else {
					$output .= qq(<span class="note">Can't be crafted</span>);
				}
			
				$output .= <<"END_PRINT";
</td></tbody></table>
<table class="sortable output">
<thead>
<tr><th>Product</th><th>Ingredients</th><th>Time</th><th>Value</th><th>Profit<br />(Item)</th><th>Profit<br />(Hr)</th></tr>
</thead>
<tbody>
END_PRINT
				$Panel{$key}{'out'} = $output;
			}
			# Handle production
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
			foreach my $p (@{$m->{'production'}}, @add) {
				# Note, some of Trent's mods use initially capitalized keys, so we need to handle that.
				# Currently we only add those extra checks for known changed keys. Both here and in materials.
				if (!exists $p->{'item'} and exists $p->{'Item'}) {
					$p->{'item'} = $p->{'Item'};
				}
				if (!exists $p->{'name'} and exists $p->{'Name'}) {
					$p->{'name'} = $p->{'Name'};
				}
				my $pname = "";
				if (exists $p->{'item'}) {
					$pname = $p->{'item'};
				} elsif (!exists $p->{'index'} and exists $p->{'name'}) {
					$pname = $p->{'name'};
				}
				my $name = GetItem($pname, $p->{'index'});
				my $starter_included = 0;
				my %entry = ( 'key1' => '', 'key2' => '', 'out' => '' );
				# key1 is the output name, but we need to strip HTML. Because we created the HTML ourselves we know
				# that a simple regex can do the job rather than needing a more robust general approach.
				$entry{'key1'} = StripHTML($name);
				my $img = GetImgTag($entry{'key1'});
				$entry{'out'} = qq(<tr><td class="name">$img $name</td>);
				$entry{'out'} .= qq(<td class="name">);
				my $i_count = 0;
				my $cost = 0;
				foreach my $i (@{$p->{'materials'}}) {
					# Once again, handling some case problems
					if (!exists $i->{'name'} and exists $i->{'Name'}) {
						$i->{'name'} = $i->{'Name'}
					}
					$name = "";
					if (exists $i->{'name'}) {
						$name = $i->{'name'};
					}	
					$name = GetItem($name, $i->{'index'});
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
					my $this_value = GetValue($i->{'name'}, $i->{'index'});
					if (looks_like_number($cost) and looks_like_number($this_value)) {
						$cost += $stack_size * $this_value;
					} else {
						$cost = "Varies";
					}
				}
				if (not $starter_included and $starter ne "NO_STARTER") {
					$img = GetImgTag(StripHTML($starter));
					$entry{'out'} .= "$img $starter<br />";
					my $this_value = GetValue($m->{'starter'}{'name'}, $m->{'starter'}{'index'});
					if (looks_like_number($cost) and looks_like_number($this_value)) {
						$cost += $this_value;
					} else {
						$cost = "Varies";
					}
				}
				if (exists $p->{'exclude'}) {
					$entry{'out'} .= '<span class="group">Except ' . join(', ', (map {GetItem($_)} @{$p->{'exclude'}})) . "</span><br />";
				}
				$entry{'out'} .= "</td>";
				my $time = $p->{'time'};
				# 1.4 standardized machine time to be 60 min per hour from 6a-2a and then 100min per hour after. This gives
				#  a total of 1600 min rather than the 1440 we used to use. This does cause complications estimating time.
				my $min_per_day = 1600;
				if ($time > $min_per_day) { 
					$time = "$time min (~" . nearest(.1, $time/$min_per_day) . " days)";
				} elsif ($time >= 1440) {
					# anything from 1440 to 1600 will be estimated as a day.
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
					$value = GetValue($pname, $p->{'index'});
				} elsif ($value =~ /original/) {
					my $temp = GetValue($pname, $p->{'index'});
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
				$eq_eval = '' if (not defined $eq_eval);
				if ($eq_eval ne '' and looks_like_number($eq_eval)) {
					$value = floor($eq_eval);
				}
				$entry{'out'} .= qq(<td class="value">$value</td>);
				my $profit = "";
				if ($value =~ /original/ or $value =~ /input/) {
					# This still looks like an equation
					$profit = qq(<span class="note">Varies</span>);
				} elsif (looks_like_number($value) and looks_like_number($cost)) {
					$profit = $value - $cost;
				} else {
					$profit = qq(<span class="note">--</span>);
				}
				$entry{'out'} .= qq(<td class="value">$profit</td>);
				# reuse profit variable for per-hour version.
				if (looks_like_number($profit)) {
					$profit = nearest(.01,60*$profit/$p->{'time'});
				}
				$entry{'out'} .= qq(<td class="value">$profit</td>);
				$entry{'out'} .= "</tr>";
				push @{$Panel{$key}{'rules'}}, \%entry;
			}
		} # end of machine loop
	} # end of "json" loop

	my $longdesc = <<"END_PRINT";
<p>A summary of machines with production rules from various sources. In the list below, the checkboxes can be used to show or hide
information specific to that particular source; the symbol &#x24c5 indicates an official PPJA mod. Additionally there
are some buttons which will show or hide multiple sources at once.</p>
<fieldset id="filter_options" class="filter_set">
<label><input class="filter_check" type="checkbox" name="filter_base_game" id="filter_base_game" value="show" checked="checked"> 
Stardew Valley base game version $StardewVersion</label><br />
END_PRINT
	
	foreach my $k (sort {$ModInfo->{$a}{'Name'} cmp $ModInfo->{$b}{'Name'}} keys %ModList) {
		my $filter = $ModInfo->{$k}{'__FILTER'};
		my $info = GetExtendedModInfo($k, 1, 2);
		my $prefix = ($info->{'ppja'}) ? qq(&#x24c5; ) : "";
		my $suffix = "";
		if ($info->{'info'} !~ /href/ and defined $info->{'parentID'}) {
			$info->{'parentInfo'} =~ /(\(.*\))/;
			$suffix = " $1";
		}
		my $class = "filter_check";
		if ($info->{'ppja'}) {
			$class .= " filter_ppja";
		}
		$longdesc .= <<"END_PRINT";
<label><input class="$class" type="checkbox" name="$filter" id="$filter" value="show" checked="checked">
$prefix$info->{'info'}</label>$suffix<br />
END_PRINT
	}

	$longdesc .= <<"END_PRINT";
</fieldset>
<fieldset id="filter_control" class="filter_set">
<button type="button" id="filter_check_all_off">All Sources Off</button>
<button type="button" id="filter_check_all_on">All Sources On</button>
<button type="button" id="filter_check_ppja">PPJA Mods Only</button>
<button type="button" id="filter_check_nonppja">Non-PPJA Mods Only</button>
</fieldset>
<p>Note that filtering is per production rule; the individual machines will always display even if all of their rules are hidden. The base game
Seedmaker recipe uses Poppy as an example but actually applies to a large variety of crops & seeds.
</p>
<p>Inputs related to an entire category (e.g. <span class="group">Any Fruit</span>) or tag (e.g. <span class="group">Lake Fish</span>) will accept both
mod and base game items; this summary will have a tooltip listing relevant items from all sources, but these tooltips will not change based on the mod filtering used.
In general, value and profit calculations are not attempted for these recipes, with the exceptions of 
the value of small cow <a href="https://stardewvalleywiki.com/Milk">Milk</a> used for <span class="group">Any Milk</span> and
the value of small <a href="https://stardewvalleywiki.com/Egg">Egg</a> used for <span class="group">Any Egg</span>. Similarly, most recipes can accept ingredients of
any <a href="https://stardewvalleywiki.com/Crops#Crop_Quality">quality</a> and in these cases
the value of the basic (no-star) version is used.</p>
<p>There are two types of profit listed: <span class="note">Profit (Item)</span> is purely based on the difference between the values of the ingredients
and products while <span class="note">Profit (Hr)</span> takes the production time into account and divides the per-item profit by the number of hours the
machine takes. The latter is rounded to two decimal places. Machines which only change the quality but return the same base item (similar to Casks) are
not currently documented correctly and will list zero profit.
</p>
END_PRINT
	print GetHeader("Machines", qq(Summary of products and timings for machines from PPJA (and other) mods), $longdesc);
	print GetTOCStart();


	foreach my $p (sort keys %TOC) {
		my $text = $p;
		$text =~ s/ /&nbsp;/g;
		print qq(<li class="$TOC{$p}{'filter'}"><a href="#$TOC{$p}{'anchor'}">$text</a></li>);
	}
	print GetTOCEnd();

	foreach my $p (sort keys %Panel) {
		# preserving machine list for exclusion from crafting summary
		$Machines{$p} = 1;
		foreach my $e (sort {$a->{'key1'} cmp $b->{'key1'} or $a->{'key2'} cmp $b->{'key2'}} @{$Panel{$p}{'rules'}}) {
			$Panel{$p}{'out'} .= $e->{'out'};
		}

		print $Panel{$p}{'out'};
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
# WriteCropSummary - main page generation for crops
sub WriteCropSummary {
	my $FH;
	open $FH, ">$DocBase/crops.html" or die "Can't open crops.html for writing: $!";
	select $FH;

	print STDOUT "Generating Crop Summary\n";
	my %ModList = ();
	# We will organize this by Season so we start with an array that will hold a hash of the table rows keyed by crop name.
	my @Panel = ( 
		{ 'key' => 'Spring', 'row' => {}, },
		{ 'key' => 'Summer', 'row' => {}, },
		{ 'key' => 'Fall', 'row' => {}, },
		{ 'key' => 'Winter', 'row' => {}, },
		{ 'key' => 'Indoor-Only', 'row' => {}, },
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
		$GameData->{'ObjectInformation'}{$cid}{'split'}[3] =~ /(\-?\d*)$/;
		my $category = GetCategory($1);
		my $cprice = $GameData->{'ObjectInformation'}{$cid}{'split'}[1];
		my $regrowth = $GameData->{'Crops'}{$sid}{'split'}[4];
		$regrowth = (($regrowth > 0) ? $regrowth : "--");
		my $need_scythe = ($GameData->{'Crops'}{$sid}{'split'}[5] ? "Yes" : "--");
		my $is_paddy = 0;
		my @multi_data = (split(' ', $GameData->{'Crops'}{$sid}{'split'}[6]));
		my $num_per_harvest = $multi_data[0];
		if ($num_per_harvest eq 'true') {
			my ($ignored, $min, $max, $inc_per_level, $extra_chance) = @multi_data;
			$num_per_harvest = $min + $extra_chance;
		} else {
			$num_per_harvest = 1;
		}
		my $is_trellis = (($GameData->{'Crops'}{$sid}{'split'}[7] eq 'true') ? "Yes" : "--");
		my @color_data = (split(' ', $GameData->{'Crops'}{$sid}{'split'}[8]));
		my $num_colors = 0;
		if ($color_data[0] eq 'true') {
			$num_colors = (scalar @color_data - 1)/3;
			$category .= "<br />($num_colors colors)";
		}
		# This is all hard-coded since it is handled in the exe
		# To make it easier to read we check the name rather than id, so we have to strip it
		my $crop = StripHTML($cname);
		my $seed_vendor = WikiShop("Pierre");
		if ($crop eq 'Rhubarb' or $crop eq 'Starfruit' or $crop eq 'Beet' or $crop eq 'Cactus Fruit') {
			$seed_vendor = WikiShop("Sandy");
			if ($crop eq 'Cactus Fruit') {
				$scost = 150;
				$season_str = "indoor-only";
			}
		} elsif ($crop eq 'Strawberry') {
			$seed_vendor .= "<br />(at " . Wikify("Egg Festival") . ")";
			$scost = 100;
		} elsif ($crop eq 'Coffee Bean') {
			$seed_vendor = WikiShop("Traveling Merchant");
			$scost = 2500;
		} elsif ($crop eq 'Sweet Gem Berry') {
			$seed_vendor = WikiShop("Traveling Merchant");
			$scost = 1000;
		} elsif ($crop eq 'Ancient Fruit') {
			$seed_vendor = qq(<span class="note">None</span>);
			$scost = 0;
		}
		if ($crop eq 'Garlic' or $crop eq 'Red Cabbage' or $crop eq 'Artichoke' or $crop eq 'Unmilled Rice') {
			$seed_vendor .= "<br />(Year 2+)";
			# This is also hardcoded. Might as well do it here
			if ($crop eq 'Unmilled Rice') {
				$is_paddy = 1;
			} 
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
<td class="name">$category</td>
<td class="name">$seedImg $sname</td>
<td>$seed_vendor</td>
<td class="value">$scost</td>
<td>$need_scythe</td>
<td>$is_trellis</td>
<td class="value">$num_per_harvest</td>
<td class="value">$cprice</td>
<td class="value">$xp</td>
END_PRINT

		foreach my $opt (qw(0 10 20 25 35)) {
			my $growth = CalcGrowth($opt/100, \@phases);
			my $max_harvests = floor(27/$growth);
			my $wasted_days = 27 - $growth * $max_harvests;
			if ($growth > 27) {
				$wasted_days = "--";
			}
			if (looks_like_number($regrowth) and $regrowth > -1) {
				if ($growth < 28) {
					$max_harvests = 1 + max(0, floor((27-$growth)/$regrowth));
					$wasted_days = 27 - $growth - $regrowth * ($max_harvests - 1);
				}
			}
			my $cost = (looks_like_number($regrowth) and $regrowth > 0) ? $scost : $max_harvests*$scost;
			my $profit = nearest(1, $cprice * $num_per_harvest * $max_harvests - $cost);
			# Paddy bonus. Yes, we pretty much copy & paste everything
			if ($is_paddy) {
				my $p_growth = CalcGrowth((25+$opt)/100, \@phases);
				my $p_harvests = floor(27/$p_growth);
				my $p_wasted_days = 27 - $p_growth * $p_harvests;
				if ($p_growth > 27) {
					$p_wasted_days = "--";
				}
				if (looks_like_number($regrowth) and $regrowth > -1) {
					if ($p_growth < 28) {
						$p_harvests = 1 + max(0, floor((27-$p_growth)/$regrowth));
						$p_wasted_days = 27 - $p_growth - $regrowth * ($p_harvests - 1);
					}
				}
				my $p_cost = (looks_like_number($regrowth) and $regrowth > 0) ? $scost : $p_harvests*$scost;
				my $p_profit = nearest(1, $cprice * $num_per_harvest * $p_harvests - $p_cost);
				$growth = "$p_growth<br />($growth)";
				$max_harvests = "$p_harvests<br />($max_harvests)";
				$profit = "$p_profit<br />($profit)";
				$wasted_days = "$p_wasted_days<br />($wasted_days)";
			}
			$output .= <<"END_PRINT";
<td class="col_$opt value">$growth</td>
<td class="col_$opt value">$regrowth</td>
<td class="col_$opt value">$max_harvests</td>
<td class="col_$opt value">$wasted_days</td>
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
		my $sname = GetItem($ModData->{'Crops'}{$key}{'SeedName'});
		my $scost = 0;
		if (exists $ModData->{'Crops'}{$key}{'SeedPurchasePrice'}) {
			$scost = $ModData->{'Crops'}{$key}{'SeedPurchasePrice'};
		}
		my @phases = @{$ModData->{'Crops'}{$key}{'Phases'}};
		my $season_str = join(" ", @{$ModData->{'Crops'}{$key}{'Seasons'}});
		my $is_paddy = 0;
		my $crop_type = "Normal";
		if (exists $ModData->{'Crops'}{$key}{'CropType'}) {
			$crop_type = $ModData->{'Crops'}{$key}{'CropType'};
		}
		if ($crop_type eq 'IndoorsOnly') {
			$season_str = 'indoor-only';
		} elsif  ($crop_type eq 'Paddy') {
			$is_paddy = 1;
		} 
		#my @seasons = $ModData->{'Crops'}{$key}{'Seasons'};
		#Sprites are the __SS keys
		my $cname = GetItem($ModData->{'Crops'}{$key}{'Product'});
		my $category = "";
		if (looks_like_number($ModData->{'Crops'}{$key}{'Product'})) {
			$GameData->{'ObjectInformation'}{$ModData->{'Crops'}{$key}{'Product'}}{'split'}[3] =~ /(\-?\d*)$/;
			$category = GetCategory($1);
		} else {
			$category = $ModData->{'Objects'}{$ModData->{'Crops'}{$key}{'Product'}}{'Category'};
		}
		my $cprice = GetValue($ModData->{'Crops'}{$key}{'Product'});
		if ($cname eq $sname) {
			$cprice = $scost;
		}
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
			$category .= "<br />(" . (scalar @colors) . " colors)";
		}
		# 1.4 fixed the rounding bug with MaximumPerHarvest so we now include it in the calculation
		my $avg_harvest = ($ModData->{'Crops'}{$key}{'Bonus'}{'MinimumPerHarvest'} + $ModData->{'Crops'}{$key}{'Bonus'}{'MaximumPerHarvest'}) / 2.0;
		my $num_per_harvest = $avg_harvest + $ModData->{'Crops'}{$key}{'Bonus'}{'ExtraChance'};
		# This is for detecting crops which might produce more in SDV 1.4
		#if ($ModData->{'Crops'}{$key}{'Bonus'}{'MaximumPerHarvest'} > $ModData->{'Crops'}{$key}{'Bonus'}{'MinimumPerHarvest'}) {
		#	print STDOUT "Crop $key will produce more now (Min: $ModData->{'Crops'}{$key}{'Bonus'}{'MinimumPerHarvest'}) (Max: $ModData->{'Crops'}{$key}{'Bonus'}{'MaximumPerHarvest'})\n"; }
		my $seed_vendor = WikiShop("Pierre");
		if (exists $ModData->{'Crops'}{$key}{'SeedPurchaseFrom'}) {
			$seed_vendor = WikiShop($ModData->{'Crops'}{$key}{'SeedPurchaseFrom'});
		}
		if (exists $ModData->{'Crops'}{$key}{'SeedPurchaseRequirements'} and defined $ModData->{'Crops'}{$key}{'SeedPurchaseRequirements'}) {
			my @req = TranslatePreconditions(@{$ModData->{'Crops'}{$key}{'SeedPurchaseRequirements'}});
			# Note that the order here is not guaranteed. If we start getting crops with multiple different requirements we might have to deal with that
			$seed_vendor .= '<br />' . join('<br />', map {"($_)"} @req);
		}
		my $imgTag = GetImgTag($key, 'crop');
		my $prodImg = GetImgTag($ModData->{'Crops'}{$key}{'Product'}, "object");
		my $seedImg = GetImgTag($ModData->{'Crops'}{$key}{'SeedName'}, "object");
		my $xp = GetXP($cprice);
		if (not exists $ModList{$ModData->{'Crops'}{$key}{'__MOD_ID'}}) {
			$ModList{$ModData->{'Crops'}{$key}{'__MOD_ID'}} = 1;
		}

		my $output = <<"END_PRINT";
<tr class="$ModInfo->{$ModData->{'Crops'}{$key}{'__MOD_ID'}}{'__FILTER'}">
<td class="icon">$imgTag</td>
<td class="name">$prodImg $cname</td>
<td class="name">$category</td>
<td class="name">$seedImg $sname</td>
<td>$seed_vendor</td>
<td class="value">$scost</td>
<td>$need_scythe</td>
<td>$is_trellis</td>
<td class="value">$num_per_harvest</td>
<td class="value">$cprice</td>
<td class="value">$xp</td>
END_PRINT

		foreach my $opt (qw(0 10 20 25 35)) {
			my $growth = CalcGrowth($opt/100, \@phases);
			my $max_harvests = floor(27/$growth);
			my $wasted_days = 27 - $growth * $max_harvests;
			if ($growth > 27) {
				$wasted_days = "--";
			}
			if (looks_like_number($regrowth) and $regrowth > -1) {
				if ($growth < 28) {
					$max_harvests = 1 + max(0, floor((27-$growth)/$regrowth));
					$wasted_days = 27 - $growth - $regrowth * ($max_harvests - 1);
				}
			}
			my $cost = (looks_like_number($regrowth) and $regrowth > 0) ? $scost : $max_harvests*$scost;
			my $profit = nearest(1, $cprice * $num_per_harvest * $max_harvests - $cost);
			# Paddy bonus. Yes, we pretty much copy & paste everything.
			if ($is_paddy) {
				my $p_growth = CalcGrowth((25+$opt)/100, \@phases);
				my $p_harvests = floor(27/$p_growth);
				my $p_wasted_days = 27 - $p_growth * $p_harvests;
				if ($p_growth > 27) {
					$p_wasted_days = "--";
				}
				if (looks_like_number($regrowth) and $regrowth > -1) {
					if ($p_growth < 28) {
						$p_harvests = 1 + max(0, floor((27-$p_growth)/$regrowth));
						$p_wasted_days = 27 - $p_growth - $regrowth * ($p_harvests - 1);
					}
				}
				my $p_cost = (looks_like_number($regrowth) and $regrowth > 0) ? $scost : $p_harvests*$scost;
				my $p_profit = nearest(1, $cprice * $num_per_harvest * $p_harvests - $p_cost);
				$growth = "$p_growth<br />($growth)";
				$max_harvests = "$p_harvests<br />($max_harvests)";
				$profit = "$p_profit<br />($profit)";
				$wasted_days = "$p_wasted_days<br />($p_profit)";
			}
			$output .= <<"END_PRINT";
<td class="col_$opt value">$growth</td>
<td class="col_$opt value">$regrowth</td>
<td class="col_$opt value">$max_harvests</td>
<td class="col_$opt value">$wasted_days</td>
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
	
	my $longdesc = <<"END_PRINT";
<p>A summary of growth and other basic information for crops from various sources. In the list below, the checkboxes can be used to show or hide
information specific to that particular source; the symbol &#x24c5 indicates an official PPJA mod. Additionally there
are some buttons which will show or hide multiple sources at once.</p>
<fieldset id="filter_options" class="filter_set">
<label><input class="filter_check" type="checkbox" name="filter_base_game" id="filter_base_game" value="show" checked="checked"> 
Stardew Valley base game version $StardewVersion</label><br />
END_PRINT

	foreach my $k (sort {$ModInfo->{$a}{'Name'} cmp $ModInfo->{$b}{'Name'}} keys %ModList) {
		my $filter = $ModInfo->{$k}{'__FILTER'};
		my $info = GetExtendedModInfo($k, 1, 2);
		my $prefix = ($info->{'ppja'}) ? qq(&#x24c5; ) : "";
		my $suffix = "";
		if ($info->{'info'} !~ /href/ and defined $info->{'parentID'}) {
			$info->{'parentInfo'} =~ /(\(.*\))/;
			$suffix = " $1";
		}
		my $class = "filter_check";
		if ($info->{'ppja'}) {
			$class .= " filter_ppja";
		}
		$longdesc .= <<"END_PRINT";
<label><input class="$class" type="checkbox" name="$filter" id="$filter" value="show" checked="checked">
$prefix$info->{'info'}</label>$suffix<br />
END_PRINT
	}

	$longdesc .= <<"END_PRINT";
</fieldset>
<fieldset id="filter_control" class="filter_set">
<button type="button" id="filter_check_all_off">All Sources Off</button>
<button type="button" id="filter_check_all_on">All Sources On</button>
<button type="button" id="filter_check_ppja">PPJA Mods Only</button>
<button type="button" id="filter_check_nonppja">Non-PPJA Mods Only</button>
</fieldset>
<p>In the following tables, the <img class="game_weapons" id="Weapon_Scythe" src="img/blank.png" alt="Needs Scythe"> column is for whether or not
the crop requires a scythe to harvest, and the <img class="game_crops" id="Special_Trellis" src="img/blank.png" alt="Has Trellis"> column is for
whether the crop has a trellis (or similar structure that blocks walking on it). The <span class="note">XP</span> column is the amount of
experience gained on a single harvest. Normally this is Farming experience, but for the seasonal forage crops it is Foraging experience.</p>
<p>The <span class="note">Seasonal Profit</span> column is an average full-season estimate that assumes the maximum number of harvests in the
month with the product sold raw at base (no-star) quality without any value-increasing professions (like Tiller.)
It also assumes all seeds are bought at the shown price and does not account for any other costs (such as purchasing fertilizer).
The growth times, maximum number of harvests, and profit all depend on growth speed modifiers which can be set in the form
below and apply to all the tables on this page. <span class="note">Wasted Days</span> would be how many leftover days there are after reaching the
maxiumum number of harvests. This can be useful for planning a second crop to fill the gap or delaying the initial planting.</p>
<p>Paddy crops will show two numbers for growth time and some other fields; the first number is
with the close-water bonus, and the number in parentheses is without. Unfortunately, these entries will not sort properly.</p>
<fieldset id="growth_speed_options" class="radio_set">
<label><input type="radio" name="speed" value="0" checked="checked"> No speed modifiers</label><br />
<label><input type="radio" name="speed" value="10"> 10% (Only one of <a href="https://stardewvalleywiki.com/Farming#Farming_Skill">Agriculturist</a> Profession or <a href="https://stardewvalleywiki.com/Speed-Gro">Speed-Gro</a> Fertilizer</label>)</label><br />
<label><input type="radio" name="speed" value="20"> 20% (Both <a href="https://stardewvalleywiki.com/Farming#Farming_Skill">Agriculturist</a> Profession and <a href="https://stardewvalleywiki.com/Speed-Gro">Speed-Gro</a> Fertilizer</label>)</label><br />
<label><input type="radio" name="speed" value="25"> 25% (Only <a href="https://stardewvalleywiki.com/Deluxe_Speed-Gro">Deluxe Speed-Gro</a> Fertilizer)</label><br />
<label><input type="radio" name="speed" value="35"> 35% (Both <a href="https://stardewvalleywiki.com/Farming#Farming_Skill">Agriculturist</a> Profession and <a href="https://stardewvalleywiki.com/Deluxe_Speed-Gro">Deluxe Speed-Gro</a> Fertilizer)</label>
</fieldset>
<input type="hidden" id="last_speed" value="0" />
END_PRINT

	print GetHeader("Crop Summary", qq(Growth and other crop information for PPJA (and other) mods for Stardew Valley), $longdesc);
	print GetTOCStart();


	# Print the rest of the TOC
	foreach my $p (@Panel) {
		my $text = "$p->{'key'} Crops";
		$text =~ s/ /&nbsp;/g;
		print qq(<li><a href="#TOC_$p->{'key'}">$text</a></li>);
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
<th>Crop Type</th>
<th>Seed Name</th>
<th>Seed Vendor<br />(&amp; Conditions)</th>
<th>Seed<br />Price</th>
<th><img class="game_weapons" id="Weapon_Scythe" src="img/blank.png" alt="Needs Scythe"></th>
<th><img class="game_crops" id="Special_Trellis" src="img/blank.png" alt="Has Trellis"></th>
<th>Avg<br />Yield</th>
<th>Crop<br />Value</th>
<th>XP</th>
<th class="col_0">Grow<br />Days</th>
<th class="col_0">Regrow<br />Days</th>
<th class="col_0">Max<br />Harvests</th>
<th class="col_0">Wasted<br />Days</th>
<th class="col_0">Seasonal<br />Profit</th>
<th class="col_10">Initial<br />Growth</th>
<th class="col_10">Regrow<br />Days</th>
<th class="col_10">Max<br />Harvests</th>
<th class="col_10">Wasted<br />Days</th>
<th class="col_10">Seasonal<br />Profit</th>
<th class="col_20">Initial<br />Growth</th>
<th class="col_20">Regrow<br />Days</th>
<th class="col_20">Max<br />Harvests</th>
<th class="col_20">Wasted<br />Days</th>
<th class="col_20">Seasonal<br />Profit</th>
<th class="col_25">Initial<br />Growth</th>
<th class="col_25">Regrow<br />Days</th>
<th class="col_25">Max<br />Harvests</th>
<th class="col_25">Wasted<br />Days</th>
<th class="col_25">Seasonal<br />Profit</th>
<th class="col_35">Initial<br />Growth</th>
<th class="col_35">Regrow<br />Days</th>
<th class="col_35">Max<br />Harvests</th>
<th class="col_35">Wasted<br />Days</th>
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
# WriteGiftSummary - NPC Gift Tastes
sub WriteGiftSummary {
	my $FH;
	open $FH, ">$DocBase/gifts.html" or die "Can't open gifts.html for writing: $!";
	select $FH;

	print STDOUT "Generating Gift Summary\n";
	my %ModList = ();
	# by_item will be ItemName => NPCName => Taste so that it is easier to put into a table.
	# by_npc will be NPCName => Taste => [ItemName] and we might not even use it.
	my %by_item = ();
	my %by_npc = ();
	my @npcs = qw(Abigail Alex Caroline Clint Demetrius Dwarf Elliott Emily Evelyn George Gus Haley Harvey Jas Jodi Kent Krobus Leah Lewis Linus Marnie Maru Pam Penny Pierre Robin Sam Sandy Sebastian Shane Vincent Willy Wizard);
	# These are the values used by tasteForItem in the game code. We'll make hashes that go both ways
	my %tasteFromIndex = ( 0 => "Love", 2 => "Like", 4 => "Dislike", 6 => "Hate", 8 => "Neutral" );
	my %tasteToIndex = ( "Love" => 0, "Like" => 2, "Dislike" => 4, "Hate" => 6, "Neutral" => 8 );
	my %tasteSort = ( "Love" => 0, "Like" => 1, "Neutral" => 2, "Dislike" => 3, "Hate" => 4 );
	my %tasteSymbols = ( "Love" => "Lv", "Like" => "L", "Neutral" => "&ndash;", "Dislike" => "D", "Hate" => "H" );
	my %universal = ();
	my %specific = ();
	
	# Setup the %by_npc structure early so we are guaranteed to have all the arrays ready.
	foreach my $n (@npcs) {
		if (not exists $by_npc{$n}) {
			$by_npc{$n} = {};
			foreach my $t (keys %tasteToIndex) {
				$by_npc{$n}{$t} = [];
			}
		}
	}
	
	# Gather universal info from Game data. Need categories regardless of whether we include vanilla items.
	foreach my $t (keys %tasteToIndex) {
		$universal{$t} = {};
		if (defined $GameData->{'NPCGiftTastes'}{"Universal_$t"}) {
			my @temp = split(' ', $GameData->{'NPCGiftTastes'}{"Universal_$t"}{'raw'});
			foreach my $i (@temp) {
				$universal{$t}{$i} = 1;
			}
		}
	}
	# Gather specific NPC info from Game data too. Again, the categories are mandatory.
	foreach my $n (@npcs) {
		$specific{$n} = {};
		if (defined $GameData->{'NPCGiftTastes'}{$n}) {
			foreach my $t (keys %tasteToIndex) {
				my @temp = split(' ', $GameData->{'NPCGiftTastes'}{$n}{'split'}[$tasteToIndex{$t}+1]);
				foreach my $i (@temp) {
					$specific{$n}{$i} = $tasteToIndex{$t};
				}
			}
		}
	}

	print STDOUT "  Processing tastes for game items\n";
	# The biggest problem here is excluding items which aren't normally available such as the different types of
	#   mine stones. We are going to have to hardcode exclusions.
	foreach my $id (keys %{$GameData->{'ObjectInformation'}}) {
		my $name = $GameData->{'ObjectInformation'}{$id}{'split'}[0];
		next if ($name eq 'Stone' and $id ne 390);
		next if ($name eq 'Weeds');
		next if ($name eq 'Twig');
		next if ($GameData->{'ObjectInformation'}{$id}{'split'}[3] =~ /asdf/);
		next if ($GameData->{'ObjectInformation'}{$id}{'split'}[3] =~ /Ring/);
		next if ($GameData->{'ObjectInformation'}{$id}{'split'}[3] =~ /Quest/);
		next if ($id == 458); #Bouquet
		next if ($id == 461); #Decorative Pot
		next if ($id == 326); #Dwarvish Translation Guide
		next if ($id == 803); #Iridium Milk
		next if ($id == 30); #Lumber
		next if ($id == 460); #Mermaid's Pendant
		next if ($id == 809); #Movie Ticket
		next if ($id == 94); #Spirit Torch
		next if ($id == 434); #Stardrop
		next if ($id == 808); #Void Ghost Pendant
		next if ($id == 277); #Wilted Bouquet
		
		my @temp = split(' ', $GameData->{'ObjectInformation'}{$id}{'split'}[3]);
		my $category = 0;
		if (scalar (@temp) > 1) {
			$category = $temp[1];
		}
		my $edibility = $GameData->{'ObjectInformation'}{$id}{'split'}[2];
		my $price = $GameData->{'ObjectInformation'}{$id}{'split'}[1];
		
		# Actual taste processing begins here, with universal categories
		my $tasteForItem = 8;
		if (exists $universal{'Love'}{$category}) {
			$tasteForItem = 0;
		} elsif (exists $universal{'Hate'}{$category}) {
			$tasteForItem = 6;
		} elsif (exists $universal{'Like'}{$category}) {
			$tasteForItem = 2;
		} elsif (exists $universal{'Dislike'}{$category}) {
			$tasteForItem = 4;
		}
		my $wasIndividualUniversal = 0;
		my $skipDefaultValueRules = 0;
		# Next the code checks the Universals for the exact item ID.
		if (exists $universal{'Love'}{$id}) {
			$tasteForItem = 0;
			$wasIndividualUniversal = 1;
		} elsif (exists $universal{'Hate'}{$id}) {
			$tasteForItem = 6;
			$wasIndividualUniversal = 1;
		} elsif (exists $universal{'Like'}{$id}) {
			$tasteForItem = 2;
			$wasIndividualUniversal = 1;
		} elsif (exists $universal{'Dislike'}{$id}) {
			$tasteForItem = 4;
			$wasIndividualUniversal = 1;
		} elsif (exists $universal{'Neutral'}{$id}) {
			$tasteForItem = 8;
			$wasIndividualUniversal = 1;
			$skipDefaultValueRules = 1;
		}
		# After that, it sets some defaults based on edibility & price for neutral items
		my $pennyOverride = -1;
		if ($tasteForItem == 8 and not $skipDefaultValueRules) {
			if ($edibility != -300 and $edibility < 0) {
				$tasteForItem = 6;
			} elsif ($price < 20) {
				$tasteForItem = 4;
			} elsif ($GameData->{'ObjectInformation'}{$id}{'split'}[3] =~ /Arch/) {
				$tasteForItem = 4;
				$pennyOverride = 2;
			} 
		}
		# Now we go into NPC specifics
		foreach my $n (@npcs) {
			my $thisTasteForItem = $tasteForItem; # resetting for each NPC
			if ($n eq 'Penny' and $pennyOverride >= 0) {
				$thisTasteForItem = $pennyOverride;
			}
			if (exists $specific{$n}{$id}) {
				$thisTasteForItem = $specific{$n}{$id};
			} else {
				if (not $wasIndividualUniversal) {
					# Now we need to check for an individual NPC category match.
					if (exists $specific{$n}{$category}) {
						$thisTasteForItem = $specific{$n}{$category};
					}
				}
			}
			# We're done. Store the tastes
			$by_item{$id}{$n} = $tasteFromIndex{$thisTasteForItem};
			push @{$by_npc{$n}{$tasteFromIndex{$thisTasteForItem}}}, $id;
		}
	}
	
	print STDOUT "  Processing tastes for mod items\n";
	# Iterate all mod objects to get the taste; uses some logic from StardewValley.NPC.getGiftTasteForThisItem()
	foreach my $i (keys %{$ModData->{'Objects'}}) {
		# Grab some info from the object data with reasonable defaults.
		my $category = 0;
		if (defined $ModData->{'Objects'}{$i}{'Category'}) {
			$category = GetCategoryNum($ModData->{'Objects'}{$i}{'Category'});
		}
		my $edibility = -300;
		if (defined $ModData->{'Objects'}{$i}{'Edibility'}) {
			$edibility = $ModData->{'Objects'}{$i}{'Edibility'};
		}
		my $price = 0;
		if (defined $ModData->{'Objects'}{$i}{'Price'}) {
			$price = $ModData->{'Objects'}{$i}{'Price'};
		}		
		
		# Actual taste processing begins here
		my $tasteForItem = 8;
		if (exists $universal{'Love'}{$category}) {
			$tasteForItem = 0;
		} elsif (exists $universal{'Hate'}{$category}) {
			$tasteForItem = 6;
		} elsif (exists $universal{'Like'}{$category}) {
			$tasteForItem = 2;
		} elsif (exists $universal{'Dislike'}{$category}) {
			$tasteForItem = 4;
		}
		my $wasIndividualUniversal = 0;
		my $skipDefaultValueRules = 0;
		# Next the code checks the Universals for the exact item ID. This shouldn't ever be a thing with JA items.
		# After that, it sets some defaults based on edibility & price for neutral items
		if ($tasteForItem == 8 and not $skipDefaultValueRules) {
			if ($edibility != -300 and $edibility < 0) {
				$tasteForItem = 6;
			} elsif ($price < 20) {
				$tasteForItem = 4;
			} # Next it sets "Arch" items to liked for Penny but custom items should never be "Arch"
		}
		# Okay, preliminaries are out of the way, so now it checks for the actual item defined in the gift tastes
		# This next bit is tricky. We need to know if there is a specific gift taste for this item for each NPC,
		#  but if there isn't we still need to check for possible category matches. So we will build a temporary
		#  lookup of whatever the mod defined first. We are using the numerical taste here for consistency
		my %modDefinedTaste = ();
		if (defined $ModData->{'Objects'}{$i}{'GiftTastes'}) {
			foreach my $t (keys %tasteToIndex) {
				if (defined $ModData->{'Objects'}{$i}{'GiftTastes'}{$t}) {
					foreach my $n (@{$ModData->{'Objects'}{$i}{'GiftTastes'}{$t}}) {
						$modDefinedTaste{$n} = $tasteToIndex{$t};
					}
				}
			}
		}
		# Now we can go back to the game logic to finish the checks.
		foreach my $n (@npcs) {
			my $thisTasteForItem = $tasteForItem; # resetting for each NPC
			if (exists $modDefinedTaste{$n}) {
				$thisTasteForItem = $modDefinedTaste{$n};
			} else {
				if (not $wasIndividualUniversal) {
					# Now we need to check for an individual NPC category match.
					if (exists $specific{$n}{$category}) {
						$thisTasteForItem = $specific{$n}{$category};
					}
				}
			}
			# We're done. Store the taste s
			$by_item{$i}{$n} = $tasteFromIndex{$thisTasteForItem};
			push @{$by_npc{$n}{$tasteFromIndex{$thisTasteForItem}}}, $i;
		}
		if (not exists $ModList{$ModData->{'Objects'}{$i}{'__MOD_ID'}}) {
			$ModList{$ModData->{'Objects'}{$i}{'__MOD_ID'}} = 1;
		}

	}
	
	my $longdesc = <<"END_PRINT";
<p>A summary of gift tastes for items from various sources. In the list below, the checkboxes can be used to show or hide
information specific to that particular source; the symbol &#x24c5 indicates an official PPJA mod. Additionally there
are some buttons which will show or hide multiple sources at once.</p>
<fieldset id="filter_options" class="filter_set">
<label><input class="filter_check" type="checkbox" name="filter_base_game" id="filter_base_game" value="show" checked="checked"> 
Stardew Valley base game version $StardewVersion</label><br />
END_PRINT

	foreach my $k (sort {$ModInfo->{$a}{'Name'} cmp $ModInfo->{$b}{'Name'}} keys %ModList) {
		my $filter = $ModInfo->{$k}{'__FILTER'};
		my $info = GetExtendedModInfo($k, 1, 2);
		my $prefix = ($info->{'ppja'}) ? qq(&#x24c5; ) : "";
		my $suffix = "";
		if ($info->{'info'} !~ /href/ and defined $info->{'parentID'}) {
			$info->{'parentInfo'} =~ /(\(.*\))/;
			$suffix = " $1";
		}
		my $class = "filter_check";
		if ($info->{'ppja'}) {
			$class .= " filter_ppja";
		}
		$longdesc .= <<"END_PRINT";
<label><input class="$class" type="checkbox" name="$filter" id="$filter" value="show" checked="checked">
$prefix$info->{'info'}</label>$suffix<br />
END_PRINT
	}

	$longdesc .= <<"END_PRINT";
</fieldset>
<fieldset id="filter_control" class="filter_set">
<button type="button" id="filter_check_all_off">All Sources Off</button>
<button type="button" id="filter_check_all_on">All Sources On</button>
<button type="button" id="filter_check_ppja">PPJA Mods Only</button>
<button type="button" id="filter_check_nonppja">Non-PPJA Mods Only</button>
</fieldset>
<p>This summary only lists vanilla NPCs but includes a large number of items; thus the table is very big and somewhat hard to read.
Each cell has a tooltip listing the NPC, item, and preference to make it a bit easier. Additionally, the columns are sortable
in order to focus on a specific NPC and the standard mod filters are in place. Both sorting and filtering may be slow
depending on the capabilities of your browser and device.
For brevity, the entries use symbols to indicate the preferences. The key to the symbols is as follows:</p>
<table class="output"><tr><th>Taste</th><th>Symbol</th></tr>
<tr><td class="name">Love</td><td class="gift_0">$tasteSymbols{'Love'}</td></tr>
<tr><td class="name">Like</td><td class="gift_1">$tasteSymbols{'Like'}</td></tr>
<tr><td class="name">Neutral</td><td class="gift_2">$tasteSymbols{'Neutral'}</td></tr>
<tr><td class="name">Dislike</td><td class="gift_3">$tasteSymbols{'Dislike'}</td></tr>
<tr><td class="name">Hate</td><td class="gift_4">$tasteSymbols{'Hate'}</td></tr>
</table>
END_PRINT
	print GetHeader("Gift Tastes", qq(Summary of gift tastes for items from PPJA (and other) mods), $longdesc);

	#print GetTOCStart();
	# Print the rest of the TOC
	#print GetTOCEnd();

	print qq(<div class="panel"><h2>Gift Tastes by Item</h2>);
	print <<"END_PRINT";
<table class="sortable output">
<thead>
<tr>
<th>Item</th>
END_PRINT

	foreach my $n (@npcs) {
		my $id = "character_" . lc $n;
		print qq(<th><img class="characters" id="$id" src="img/blank.png" alt="$n"></th>);
	}
	
	print <<"END_PRINT";
</tr>
</thead>
<tbody>
END_PRINT
	my $count = 0;
	# This sort is so hacky now that vanilla IDs are possible keys
	foreach my $i (sort {StripHTML(GetItem($a, "", 0)) cmp StripHTML(GetItem($b, "", 0))} keys %by_item) {
		my $name = GetItem($i);
		my $img = GetImgTag($i);
		my $filter = "filter_base_game";
		my $tip_name = StripHTML(GetItem($i, "", 0));
		if (not looks_like_number($i)) {
			$filter = "$ModInfo->{$ModData->{'Objects'}{$i}{'__MOD_ID'}}{'__FILTER'}";
			$tip_name = encode_entities($i);
		}
		
		print qq(<tr class="$filter">);
		print qq(<td class="name">$img $name</td>);
		foreach my $n (@npcs) {
			my $t = $tasteSymbols{$by_item{$i}{$n}};
			my $tt = "$n: $by_item{$i}{$n} for $tip_name";
			my $sort = qq(sorttable_customkey="$tasteSort{$by_item{$i}{$n}}");
			print qq(<td tooltip="$tt" $sort class="gift_$tasteSort{$by_item{$i}{$n}}">$t</td>);
		}
		print "</td>";
		$count++;
	}
	$count = AddCommas($count);
	my $total_desc = qq(Gift summary showing <span id="foot_count_object">$count</span> of $count known items);
	
	print <<"END_PRINT";
</tbody>
<tfoot>
<tr id="gift_footer">
<td colspan="34">$total_desc</td>
</tr>
</tfoot>
</table>
</div>
END_PRINT

	print STDOUT "  Table contains $count rows and " . (1 + scalar(@npcs)) . " columns.\n";
	print GetFooter();

	close $FH or die "Error closing file";
}

###################################################################################################
# WriteCSS - Iterates through the SpriteInfo structure and writes out the appropriate CSS for each ID
sub WriteCSS {
	my $FH;
	open $FH, ">$DocBase/ppja-ref-img.css" or die "Can't open ppja-ref-img.css for writing: $!";
	select $FH;

	print STDOUT "Generating CSS for image sprites\n";
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
td img.craftables_x2 {
	vertical-align: -27px;
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
td img.game_craftables_x2 {
	vertical-align: -27px;
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
img.quality {
	vertical-align: -2px;
	width: 8px;
	height: 8px;
	background-image:url("./img/game_quality.png")
}
img.quality_x2 {
	vertical-align: -2px;
	width: 16px;
	height: 16px;
	background-image:url("./img/game_quality_x2.png")
}
.quality-container {
	position: relative;
	width: 16px;
	height: 16px;
	display: inline-block;
}
.quality-item {
	position: absolute;
	top: 0px;
	left: 0px;
	z-index: 1;
}
.quality-star {
	position: absolute;
	top: 8px;
	left: 8px;
	z-index: 2;
}
img.characters {
	vertical-align: -2px;
	width: 16px;
	height: 16px;
	background-image:url("./img/characters.png")
}
img.characters_x2 {
	vertical-align: -2px;
	width: 32px;
	height: 32px;
	background-image:url("./img/characters_x2.png")
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
	
	# Everything that was gathered in SpriteInfo
	foreach my $id (sort keys %$SpriteInfo) {
		my $x = $SpriteInfo->{$id}{'x'};
		my $y = $SpriteInfo->{$id}{'y'};
		print <<"END_PRINT";
img#$id {
	background-position: ${x}px ${y}px;
}
END_PRINT
	}
	
	# Characters are also somewhat hardcoded as they are processed by a different image script
	# To have just headshots, we need to adjust the y based upon the following values and keep the img.character definition 16x16.
	# For full-body sprites, we'd ignore the offsets (keeping y=0 for everyone) and make the img.characters definition 16x32.
	#my @npcs = qw(Abigail Alex Bouncer Caroline Clint Demetrius Dwarf Elliott Emily Evelyn George Governor Gunther Gus Haley Harvey Henchman Jas Jodi Kent Krobus Leah Lewis Linus Marcello Mariner Marlon Marnie Maru Morris MrQi Pam Penny Pierre Robin Sam Sandy Sebastian Shane Vincent Willy Wizard);
	my %npcs = ('Abigail' => 5,'Alex' => 3,'Bouncer' => 4,'Caroline' => 7,'Clint' => 3,'Demetrius' => 1,'Dwarf' => 12,'Elliott' => 3,'Emily' => 4,'Evelyn' => 8,'George' => 7,'Governor' => 4,'Gunther' => 3,'Gus' => 2,'Haley' => 6,'Harvey' => 2,'Henchman' => 3,'Jas' => 7,'Jodi' => 6,'Kent' => 1,'Krobus' => 8,'Leah' => 6,'Lewis' => 3,'Linus' => 7,'Marcello' => 2,'Mariner' => 1,'Marlon' => 3,'Marnie' => 6,'Maru' => 6,'Morris' => 2,'MrQi' => 1,'Pam' => 7,'Penny' => 7,'Pierre' => 3,'Robin' => 4,'Sam' => 0,'Sandy' => 3,'Sebastian' => 4,'Shane' => 4,'Vincent' => 9,'Willy' => 2,'Wizard' => 1,);

	my $x = 0;
	foreach my $n (sort keys %npcs) {
		my $xx = $x*2;
		my $y = 0 - $npcs{$n};
		my $yy = $y*2;
		my $id = "character_" . lc($n);
		print <<"END_PRINT";
img#$id {
	background-position: ${x}px ${y}px;
}
img#${id}_x2 {
	background-position: ${xx}px ${yy}px;
}
END_PRINT
		$x -= 16;
	}
	
	close $FH;
}

__END__ 
