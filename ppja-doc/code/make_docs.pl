#!/bin/perl
#
# make_docs.pl
#
# processing JA & CFR data for PPJA Mods to create summary web pages

use strict;
use Scalar::Util qw(looks_like_number);
use POSIX qw(ceil floor);
use Storable;
use Math::Round;

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
			$output = "varies";
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
<title>MouseyPounds' PPJA Documentation: $subtitle</title>

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

</head>
<body>
<div class="panel" id="header"><h1>MouseyPounds' PPJA Documentation: $subtitle</h1>
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
	print GetHeader("Crop Summary", qq(PPJA Artisan Valley Crop Summary),
		qq(<p>A summary of crop growth information from the base game as well as <a href="https://www.nexusmods.com/stardewvalley/mods/1926">Artisan Valley</a>.</p>));

		
	print "</ul></div></div>";
	print GetFooter();
	return;
	my %TOC = ();

	# To most easily sort the machines alphabetically, I will save all output in this Panel hash, keyed on machine name
	my %Panel = ();
	foreach my $j (@{$ModData->{'Machines'}}) {
		# These are the individual json files from each machine mod
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
<table class="output">
<thead>
<tr><th>Product</th><th>Ingredients</th><th>Time</th><th>Value</th></tr>
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
				$entry{'key1'} = StripHTML($name);
				$entry{'out'} = "<tr><td>$name</td>";
				$entry{'out'} .= "<td>";
				my $i_count = 0;
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
				}
				if (not $starter_included and $starter ne "NO_STARTER") {
					$entry{'out'} .= "+ $starter<br />";
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
				$entry{'out'} .= "<td>$value</td>";
				$entry{'out'} .= "</tr>";
				push @rows, \%entry;
			}
			foreach my $e (sort {$a->{'key1'} cmp $b->{'key1'} or $a->{'key2'} cmp $b->{'key2'}} @rows) {
				$output .= $e->{'out'};
			}

			$output .= <<"END_PRINT";
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

sub MachineSummary {
	my $FH;
	open $FH, ">$DocBase/machines.html" or die "Can't open machines.html for writing: $!";
	select $FH;

	my $longdesc = <<"END_PRINT";
<p>A summary of machines from <a href="https://www.nexusmods.com/stardewvalley/mods/1926">Artisan Valley</a> version $ModInfo->{'ppja.avcfr'}{'Version'}. 
Value and profit calculations all assume basic (no-star) <a href="https://stardewvalleywiki.com/Crops#Crop_Quality">quality</a>.
Inputs related to an entire category (e.g. <span class="note">Any Fruit</span>) accept appropriate mod items too even though this summary links them to
the wiki which only shows base game items. 
There are two types of profit listed. <span class="note">Profit (Item)</span> is purely based on the difference between the value of ingredients and product
while <span class="note">Profit (Hr)</span> takes the production time into account and divides the per-item profit by the number of hours the
production takes. The latter is rounded to two decimal places.
</p>
END_PRINT
	print GetHeader("Machine Summary", qq(PPJA Artisan Valley Machine Summary), $longdesc);

	my %TOC = ();

	# To most easily sort the machines alphabetically, I will save all output in this Panel hash, keyed on machine name
	my %Panel = ();
	foreach my $j (@{$ModData->{'Machines'}}) {
		# These are the individual json files from each machine mod
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

sub calc_reduction($+@) {
	my $factor = shift;
	my $phases_ref = shift;
	my @phases = @$phases_ref;
	my $days = 0;
	my $num_phases = scalar @phases;
	for (my $i = 0; $i < $num_phases; $i++) {
		$days += $phases[$i];
	}
	my $reduction = ceil($factor * $days);
	# mimic imprecision errors due to excessive type casting
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
foreach my $k (sort {$game_data{'obj'}{$a}[0] cmp $game_data{'obj'}{$b}[0]} keys %{$game_data{'crops'}}) {
	my $base = 0;
	my $out = "";
	foreach my $op (sort {$options{$a} <=> $options{$b}} keys %options) {
		my $all_phases = $game_data{'crops'}{$k}[0];
		my @phases = (split(' ', $all_phases));
		$base = calc_reduction($options{$op}, \@phases);
		my $cost = 2*$game_data{'obj'}{$k}[1];
		my $sell = $game_data{'obj'}{$game_data{'crops'}{$k}[3]}[1];
		my @bonus = (split(' ', $game_data{'crops'}{$k}[6]));
		my $harvest = 1;
		if ($bonus[0] eq 'true') {
			$harvest = $bonus[1]+$bonus[4];
		}
		my $income = $sell*$harvest;
		my $profit = sprintf("%d   g(raw)",$income - $cost);
		my $regrowth = "  ";
		if ($game_data{'crops'}{$k}[4] > -1) {
			$regrowth = sprintf("+%d",$game_data{'crops'}{$k}[4]);
			$profit = sprintf("%.1f g/day ",$income/($game_data{'crops'}{$k}[4]));
		}
		my $trellis = ($game_data{'crops'}{$k}[7] eq "true")? "t": " ";
		$out .= sprintf(" | %s (%d%%): %2d%2s%s %13s",$op,100*$options{$op},$base,$regrowth,$trellis,$profit);
	}
	my $name = $game_data{'obj'}{$k}[0];
	printf("%23s (%3d)$out\n", $name, $k);
}

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
