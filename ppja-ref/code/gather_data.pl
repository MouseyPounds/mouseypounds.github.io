#!/bin/perl
#
# gather_data.pl
#
# processing JA & CFR data for PPJA Mods to create summary web pages

use strict;
use JSON::Relaxed qw(from_rjson);
use File::Slurp qw(read_file);
use File::Copy;
use Data::Dumper;
use Storable;
use Imager;
use POSIX qw(floor);
use List::Util qw(min max);
use Scalar::Util qw(looks_like_number);

# Logging
#   0: No logging (aside from warn/die)
#   1: Simple trace messages only
#   2: Trace messages and full data dumps
#   3: Normal trace messages, data dumps, file content dumps, and extra spammy trace messages
my $LogLevel = 2;

# Important directories. These would probably be better off as optional command-line arguments with reasonable
# defaults, but for now they are just hardcoded here.
#   $GameDir is assumed to be the base (extracted) Content\Data directory.
#   $ModDir is assumed to be a directory containing all the mods we need to process
#     It could contain other mods too, but only certain mods are supported.
#     We don't currently recurse into this directory and the mods are all expected to be just 1 level deep
my $GameDir = 'C:/Program Files/Steam/steamapps/common/Stardew Valley/Content (unpacked)/Data';
my $ModDir = 'C:/Program Files/Steam/steamapps/common/Stardew Valley/Mods';

# Game data stored in %GameData dictionary
#   Top level entries correspond to particular files but do not exactly mirror game file & directory organization 
#   Second level entries have the original data in 'raw' and also an array of the individual fileds in 'split'
my $GameData = {};

# Mod meta information (from manifests) in %Mod dictionary
my $ModInfo = {};

# Mod data stored in %ModData dictionary and will mostly mirror structure of JA & CFR data files
my $ModData = { 'Crops' => {}, 'Objects' => {}, 'BigCraftables' => {}, 'FruitTrees' => {}, 'Hats' => {}, 'Weapons' => {},
	'Machines' => [], 'Cooking' => {}, 'Crafting' => {}, };

# Spritesheets to consolidate mod images into single files;
# Currently choosing 1296 for width to fit 3 trees and 2048 for length just because it is half of the game limit.
# At the end of the script we will crop out unused areas since if anything gets added the script will have to be rerun anyway.
my $SS_WIDTH = 1296;
my $SS_HEIGHT = 2048;
my $SS = {
		'crops' => { 
			'index' => -1,
			'width' => 128,
			'height' => 32,
			},
		'craftables' => { 
			'index' => -1,
			'width' => 16,
			'height' => 32,
			},
		'hats' => { 
			'index' => -1,
			'width' => 20,
			'height' => 80,
			},
		'trees' => { 
			'index' => -1,
			'width' => 432,
			'height' => 80,
			},
		'objects' => { 
			'index' => -1,
			'width' => 16,
			'height' => 16,
			},
		};
# Imager object creation put in this loop for error-checking purposes
foreach my $k (keys %$SS) {
	$SS->{$k}{'img'} = Imager->new(xsize=>$SS_WIDTH, ysize=>$SS_HEIGHT, channels=>4) or
		die "Can't create Imager objects for spritesheet: " . Imager->errstr;
}
	
# Main program logic
LogMessage("Script started", 1);

ParseGameData($GameDir, $GameData);
ParseModData($ModDir, $ModData, $ModInfo);

LogMessage("Adding object info for mod crop seeds & tree saplings", 1);
# It is a little less messy to do this here rather than trying to create a second json during file processing.
foreach my $c (keys %{$ModData->{'Crops'}}) {
	my $name = $ModData->{'Crops'}{$c}{'SeedName'};
	my $desc = $ModData->{'Crops'}{$c}{'SeedDescription'};
	my $price = $ModData->{'Crops'}{$c}{'SeedPurchasePrice'};
	if (not exists $ModData->{'Objects'}{$name}) {
		$ModData->{'Objects'}{$name} = {
			'Name' => $name,
			'Description' => $desc,
			'Price' => $price,
			'Category' => 'Seeds',
			'Edibility' => -300,
			'Recipe' => undef,
			'__MOD_ID' => $ModData->{'Crops'}{$c}{'__MOD_ID'},
			'__PATH' => $ModData->{'Crops'}{$c}{'__PATH'},
			'__SS_X' => $ModData->{'Crops'}{$c}{'__SS_OTHER_X'},
			'__SS_Y' => $ModData->{'Crops'}{$c}{'__SS_OTHER_Y'},
			};
	} else {
		LogMessage("WARNING: Already have an object entry for $name while processing $c seeds", 1);
	}
}
foreach my $t (keys %{$ModData->{'FruitTrees'}}) {
	my $name = $ModData->{'FruitTrees'}{$t}{'SaplingName'};
	my $desc = $ModData->{'FruitTrees'}{$t}{'SaplingDescription'};
	my $price = $ModData->{'FruitTrees'}{$t}{'SaplingPurchasePrice'};
	if (not exists $ModData->{'Objects'}{$name}) {
		$ModData->{'Objects'}{$name} = {
			'Name' => $name,
			'Description' => $desc,
			'Price' => $price,
			'Category' => 'Seeds',
			'Edibility' => -300,
			'Recipe' => undef,
			'__MOD_ID' => $ModData->{'FruitTrees'}{$t}{'__MOD_ID'},
			'__PATH' => $ModData->{'FruitTrees'}{$t}{'__PATH'},
			'__SS_X' => $ModData->{'FruitTrees'}{$t}{'__SS_OTHER_X'},
			'__SS_Y' => $ModData->{'FruitTrees'}{$t}{'__SS_OTHER_Y'},
			};
	} else {
		LogMessage("WARNING: Already have an object entry for $name while processing $t saplings", 1);
	}
}

LogMessage("Copying some game spritesheets", 1);
# These are unchanged and so can be directly copied. Failure is only a warning
copy("$GameDir/../Maps/springobjects.png", "../img/game_objects.png") or LogMessage("WARNING: Error copying game object sprites: $!", 1);
copy("$GameDir/../Tilesheets/Craftables.png", "../img/game_craftables.png") or LogMessage("WARNING: Error copying game craftable sprites: $!", 1);
copy("$GameDir/../Tilesheets/weapons.png", "../img/game_weapons.png") or LogMessage("WARNING: Error copying game weapon sprites: $!", 1);
copy("$GameDir/../Characters/Farmer/hats.png", "../img/game_hats.png") or LogMessage("WARNING: Error copying game hat sprites: $!", 1);
# But to make the x2 versions we need to use Imager
LogMessage("And scaling those spritesheets", 1);
my $game_sprites = Imager->new();
$game_sprites->read(file=>"$GameDir/../Maps/springobjects.png") or LogMessage("DIE: Error reading game object sprites:" . $game_sprites->errstr, 1);
$game_sprites->scale(scalefactor=>2.0, qtype=>'preview')->write(file=>"../img/game_objects_x2.png") or
	LogMessage("DIE: Error writing x2 game object sprites: " . $game_sprites->errstr, 1);
$game_sprites->read(file=>"$GameDir/../Tilesheets/Craftables.png") or LogMessage("DIE: Error reading game craftable sprites:" . $game_sprites->errstr, 1);
$game_sprites->scale(scalefactor=>2.0, qtype=>'preview')->write(file=>"../img/game_craftables_x2.png") or
	LogMessage("DIE: Error writing x2 game craftable sprites: " . $game_sprites->errstr, 1);
$game_sprites->read(file=>"$GameDir/../Tilesheets/weapons.png") or LogMessage("DIE: Error reading game weapon sprites:" . $game_sprites->errstr, 1);
$game_sprites->scale(scalefactor=>2.0, qtype=>'preview')->write(file=>"../img/game_weapons_x2.png") or
	LogMessage("DIE: Error writing x2 game weapon sprites: " . $game_sprites->errstr, 1);
$game_sprites->read(file=>"$GameDir/../Characters/Farmer/hats.png") or LogMessage("DIE: Error reading game hat sprites:" . $game_sprites->errstr, 1);
$game_sprites->scale(scalefactor=>2.0, qtype=>'preview')->write(file=>"../img/game_hats_x2.png") or
	LogMessage("DIE: Error writing x2 game hat sprites: " . $game_sprites->errstr, 1);
	
LogMessage("Modifying other game spritesheets", 1);
# For Fruit Trees we are going to discard the final sprite which has just the stump and falling leaves and replace it
#  with a fully stocked tree. This requires copying over the appropriate seasonal tree and then overlaying three
#  of the product objects in appropriate spots. In game, these overlays are somewhat random but we will just pick
#  some reasonable coordinates and use them for all sprites.
my $game_trees = Imager->new();
$game_trees->read(file=>"$GameDir/../Tilesheets/fruitTrees.png") or LogMessage("DIE: Error reading game tree sprites:" . $game_trees->errstr, 1);
my $trees_per_row = floor($game_trees->getwidth() / $SS->{'trees'}{'width'});
my $game_objects = Imager->new();
$game_objects->read(file=>"$GameDir/../Maps/springobjects.png") or LogMessage("DIE: Error reading game object sprites:" . $game_objects->errstr, 1);
my $objects_per_row = floor($game_objects->getwidth() / $SS->{'objects'}{'width'});
foreach my $t (keys %{$GameData->{'FruitTrees'}}) {
	# FruitTree Format -- SaplingID: SpritesheetIndex / Season / ProductID / SaplingPrice
	# Grabbing the produce object first
	my $index = $GameData->{'FruitTrees'}{$t}{'split'}[2];
	my $base_x = $SS->{'objects'}{'width'} * ($index % $objects_per_row);
	my $base_y = $SS->{'objects'}{'height'} * floor($index / $objects_per_row);
	my $overlay = $game_objects->crop(left=>$base_x, top=>$base_y, width=>16, height=>16);
	# There's actually only 1 tree per row and I don't have a good reason why I still do this stuff
	$index = $GameData->{'FruitTrees'}{$t}{'split'}[0];
	$base_x = $SS->{'trees'}{'width'} * ($index % $trees_per_row);
	$base_y = $SS->{'trees'}{'height'} * floor($index / $trees_per_row);
	my %seasons = ('spring'=>0,'summer'=>1,'fall'=>2,'winter'=>3);
	my $offset = (4 + $seasons{$GameData->{'FruitTrees'}{$t}{'split'}[1]}) * 48;
	my $tree_replacement = $game_trees->crop(left=>($base_x + $offset), top=>$base_y, width=>48, height=>80);
	# Now overlay the fruits at hardcoded coordinates
	$tree_replacement->rubthrough(src=>$overlay, tx=>2, ty=>14, src_maxx=>16, src_maxy=>16) or
		LogMessage("DIE: Failed to overlay fruit #1: " . $tree_replacement->errstr, 1);
	$tree_replacement->rubthrough(src=>$overlay, tx=>26, ty=>4, src_maxx=>16, src_maxy=>16) or
		LogMessage("DIE: Failed to overlay fruit #2: " . $tree_replacement->errstr, 1);
	$tree_replacement->rubthrough(src=>$overlay->flip(dir=>'h'), tx=>20, ty=>28, src_maxx=>16, src_maxy=>16) or
		LogMessage("DIE: Failed to overlay fruit #3: " . $tree_replacement->errstr, 1);
	# And finally, paste the complete tree over the stump sprite
	$game_trees->paste(src=>$tree_replacement, left=>$base_x + 384, top=>$base_y, width=>48, height=>80) or
		LogMessage("DIE: Failed to paste complete tree: " . $tree_replacement->errstr, 1);
	$GameData->{'FruitTrees'}{$t}{'__SS_X'} = $base_x + 384;
	$GameData->{'FruitTrees'}{$t}{'__SS_Y'} = $base_y;
}
$game_trees->write(file=>"../img/game_trees.png") or LogMessage("DIE: Error writing game tree sprites: " . $game_trees->errstr, 1);
$game_trees->scale(scalefactor=>2.0, qtype=>'preview')->write(file=>"../img/game_trees_x2.png") or
	LogMessage("DIE: Error writing x2 game tree sprites: " . $game_trees->errstr, 1);

# For Crops we need to handle those cases where the crop has dynamic coloring.
# We need to grab the greyscale placeholder, color it based on first color definition, and then overlay onto final growth phase.
my $game_crops = Imager->new();
$game_crops->read(file=>"$GameDir/../Tilesheets/crops.png") or LogMessage("DIE: Error reading game crop sprites: $!", 1);
my $crops_per_row = floor($game_crops->getwidth() / $SS->{'crops'}{'width'});
foreach my $c (keys %{$GameData->{'Crops'}}) {
	my $index = $GameData->{'Crops'}{$c}{'split'}[2];
	my $base_x = $SS->{'crops'}{'width'} * ($index % $crops_per_row);
	my $base_y = $SS->{'crops'}{'height'} * floor($index / $crops_per_row);
	my @phases = split(' ', $GameData->{'Crops'}{$c}{'split'}[0]);
	my @colors = split(' ', $GameData->{'Crops'}{$c}{'split'}[8]);
	my $has_colors = shift @colors;
	my $x = $base_x + 16*(1 + scalar(@phases));
	my $y = $base_y;
	$GameData->{'Crops'}{$c}{'__SS_X'} = $x;
	$GameData->{'Crops'}{$c}{'__SS_Y'} = $y;

	if ($has_colors eq 'true') {
		my ($r, $g, $b, @rest) = @colors;
		my $target = Imager::Color->new(rgb=>[$r, $g, $b]);
		my $overlay = $game_crops->crop(left=>$base_x + 16*(2 + scalar(@phases)), top=>$base_y, width=>16, height=>32);
		$overlay = Colorize($overlay, $target);
		$game_crops->rubthrough(src=>$overlay, tx=>$x, ty=>$y, src_maxx=>16, src_maxy=>32) or
			LogMessage("DIE: Failed to overlay color placeholder: " . $game_crops->errstr, 1);
	}
}
$game_crops->write(file=>"../img/game_crops.png") or LogMessage("DIE: Error writing game crop sprites: " . $game_crops->errstr, 1);
$game_crops->scale(scalefactor=>2.0, qtype=>'preview')->write(file=>"../img/game_crops_x2.png") or
	LogMessage("DIE: Error writing x2 game crop sprites: " . $game_crops->errstr, 1);

# We also want the quality stars for overlaying.
my $game_cursors = Imager->new();
$game_cursors->read(file=>"$GameDir/../LooseSprites/Cursors.png") or LogMessage("DIE: Error reading game cursors: $!", 1);
my $quality_stars = Imager->new(xsize=>8*4, ysize=>8, channels=>4);
$quality_stars->paste(src=>$game_cursors, src_minx =>338, src_miny =>400, left=>0, top=>0, width=>8, height=>8) or
	LogMessage("DIE: Failed to copy silver quality star " . $quality_stars->errstr, 1);
$quality_stars->paste(src=>$game_cursors, src_minx =>346, src_miny =>400, left=>8, top=>0, width=>8, height=>8) or
	LogMessage("DIE: Failed to copy gold quality star " . $quality_stars->errstr, 1);
$quality_stars->paste(src=>$game_cursors, src_minx =>346, src_miny =>392, left=>24, top=>0, width=>8, height=>8) or
	LogMessage("DIE: Failed to copy iridium quality star " . $quality_stars->errstr, 1);
$quality_stars->write(file=>"../img/game_quality.png") or LogMessage("DIE: Error writing game quality sprites: " . $quality_stars->errstr, 1);
$quality_stars->scale(scalefactor=>2.0, qtype=>'preview')->write(file=>"../img/game_quality_x2.png") or
	LogMessage("DIE: Error writing x2 game quality sprites: " . $quality_stars->errstr, 1);
	
LogMessage("Changing mod fruit tree sprites", 1);
foreach my $t (keys %{$ModData->{'FruitTrees'}}) {
	# Now we can make the same change we made for vanilla trees. Since fruit trees already use their _OTHER_ coordinates
	#  for the sapling object, we don't change the saved co-ordinates, but that isn't too big of a problem since the
	#  "full" tree sprite is always at the same offset (x+384,y)
	my $product = $ModData->{'FruitTrees'}{$t}{'Product'};
	my $overlay;
	if (looks_like_number($product)) {
		# oh shit, I can't handle this yet
		LogMessage("WARNING: Mod Tree wants to make a vanilla product.", 1);
		next;
	} else {
		$overlay = $SS->{'objects'}{'img'}->crop(left=>$ModData->{'Objects'}{$product}{'__SS_X'},
			top=>$ModData->{'Objects'}{$product}{'__SS_Y'}, width=>16, height=>16);
	}
	my $base_x = $ModData->{'FruitTrees'}{$t}{'__SS_X'};
	my $base_y = $ModData->{'FruitTrees'}{$t}{'__SS_Y'};
	my %seasons = ('spring'=>0,'summer'=>1,'fall'=>2,'winter'=>3);
	my $offset = (4 + $seasons{lc $ModData->{'FruitTrees'}{$t}{'Season'}}) * 48;
	my $tree_replacement = $SS->{'trees'}{'img'}->crop(left=>($base_x + $offset), top=>$base_y, width=>48, height=>80);
	# Now overlay the fruits at hardcoded coordinates
	$tree_replacement->rubthrough(src=>$overlay, tx=>2, ty=>14, src_maxx=>16, src_maxy=>16) or
		LogMessage("DIE: Failed to overlay fruit #1 on mod tree: " . $tree_replacement->errstr, 1);
	$tree_replacement->rubthrough(src=>$overlay, tx=>26, ty=>4, src_maxx=>16, src_maxy=>16) or
		LogMessage("DIE: Failed to overlay fruit #2 on mod tree: " . $tree_replacement->errstr, 1);
	$tree_replacement->rubthrough(src=>$overlay->flip(dir=>'h'), tx=>20, ty=>28, src_maxx=>16, src_maxy=>16) or
		LogMessage("DIE: Failed to overlay fruit #3 on mod tree: " . $tree_replacement->errstr, 1);
	# And finally, paste the complete tree over the stump sprite
	$SS->{'trees'}{'img'}->paste(src=>$tree_replacement, left=>$base_x + 384, top=>$base_y, width=>48, height=>80) or
		LogMessage("DIE: Failed to paste complete mod tree: " . $SS->{'trees'}{'img'}->errstr, 1);
}

LogMessage("Cropping and writing mod spritesheets", 1);
foreach my $k (keys %$SS) {
	LogMessage("Trying to crop $k which has values I($SS->{$k}{'index'}), W($SS->{$k}{'width'}), H($SS->{$k}{'height'})", 1);
	my $index = $SS->{$k}{'index'};
	# This is done so that we still generate a small image for unused spritesheets
	$index = 0 if ($index < 0);
	my $sprites_per_row = floor($SS_WIDTH / $SS->{$k}{'width'});
	my $max_width = $SS->{$k}{'width'} * min($sprites_per_row, ($index + 1));
	my $max_height = $SS->{$k}{'height'} * (1 + floor($index / $sprites_per_row));
	my $cropped_img = $SS->{$k}{'img'}->crop(left=>0, top=>0, width=>$max_width, height=>$max_height) or
		LogMessage("DIE: Couldn't crop image: " . $SS->{$k}{'img'}->errstr, 1);
	LogMessage(" Spritesheet for $k is now " . $cropped_img->getwidth() . " x " . $cropped_img->getheight(), 1);

	my $filename = "../img/ss_${k}.png";
	$cropped_img->write(file=>$filename) or 
		LogMessage("DIE: Error writing normal spritesheet to $filename" . $cropped_img->errstr, 1);;
	$filename = "../img/ss_${k}_x2.png";
	$cropped_img->scale(scalefactor=>2.0, qtype=>'preview')->write(file=>$filename) or 
		LogMessage("DIE: Error writing scaled spritesheet to $filename" . $cropped_img->errstr, 1);;
}

LogMessage("Writing cache", 1);
store $GameData, "../local/cache_GameData";
store $ModData, "../local/cache_ModData";
store $ModInfo, "../local/cache_ModInfo";

LogMessage("Dumping full GameData", 2);
LogMessage(Dumper($GameData), 2);
LogMessage("Dumping full ModData", 2);
LogMessage(Dumper($ModData), 2);
LogMessage("Dumping full ModInfo", 2);
LogMessage(Dumper($ModInfo), 2);

LogMessage("Script ended", 1);
exit;

# ParseGameData
#   Base directory to look for data files
#   Reference for hash/dictionary to store the data
sub ParseGameData {
	my $BaseDir = shift;
	my $DataRef = shift;

	# There are only certain folders we explicitly want to open; these are hardcoded
	# Files are assumed to be JSON format without headers, like those from StardewXNBHack
	my @Filenames = qw(ObjectInformation Crops BigCraftablesInformation CookingRecipes CraftingRecipes 
						FruitTrees TV/CookingChannel ObjectContextTags NPCDispositions);
	LogMessage("Parsing Game Data in $BaseDir", 1);
	foreach my $f (@Filenames) {
		LogMessage("  Checking for $f", 1);
		my $this_file = "$BaseDir/$f.json";
		if (-e $this_file) {
			my $json = ParseJsonFile($this_file);
			LogMessage("    Dumping object returned by from_rjson", 3);
			LogMessage(Dumper($json), 3);
			$DataRef->{$f} = {};
			my $delimiter = '/';
			$delimiter = ', ' if ($f eq 'ObjectContextTags');
			foreach my $key (keys %$json) {
				$DataRef->{$f}{$key} = {};
				$DataRef->{$f}{$key}{'raw'} = $json->{$key};
				my @Fields = split($delimiter, $json->{$key});
				$DataRef->{$f}{$key}{'split'} = \@Fields;
			}
		} else {
			LogMessage("    WARNING: Did not find $f ($this_file)", 1);
		}
	}
}

# ParseModData
#   Base directory to look for mod files
#   Reference for hash/dictionary to store the data
#   Reference for hash/dictionary to store the mod meta information
sub ParseModData {
	my $BaseDir = shift;
	my $DataRef = shift;
	my $MetaRef = shift;

	LogMessage("Parsing Mod Data in Mods folder $BaseDir", 1);
	if (-d "$BaseDir/PPJA") {
		$BaseDir = "$BaseDir/PPJA";
		LogMessage("Found PPJA in $BaseDir", 1);
	} elsif (-d "$BaseDir/..PPJA") {
		$BaseDir = "$BaseDir/..PPJA";
		LogMessage("Found PPJA in $BaseDir", 1);
	} else {
		LogMessage("No PPJA subdirectory, so scanning $BaseDir", 1);
	}
	my $DH;
	opendir($DH, "$BaseDir");
	my @mods = readdir($DH);
	closedir $DH;

	foreach my $m (@mods) {
		next if ($m eq '.' or $m eq '..');
		LogMessage("  Checking directory entry $m", 1);
		if (-d "$BaseDir/$m") {
			LogMessage("    This is a subdirectory, looking for manifest", 1);
			my $manifest = "$BaseDir/$m/manifest.json";

			if (-e $manifest) {
				LogMessage("    Manifest found. Parsing", 1);
				my $json = ParseJsonFile($manifest);
				my $id = $json->{'UniqueID'};
				my $name = $json->{'Name'};
				if (defined $id and defined $name) {
					LogMessage("    Mod found $id ($name)", 1);
				} else {
					LogMessage("    Manifest missing UniqueID and/or Name. Skipping.", 1);
					next;
				}
				# Saving filter and path information in case we need them later
				$json->{'__PATH'} = "$BaseDir/$m";
				my $filter_id = "filter_$id";
				$filter_id =~ s/\./_/g;
				$json->{'__FILTER'} = $filter_id;
				# Note, the json is only dumped if it had passed the name & ID check
				LogMessage("    Dumping json object", 3);
				LogMessage(Dumper($json), 3);
				# Note, we are not storing the meta-info until we process the pack.
				my $storeMeta = 1;
				
				if (exists $json->{'ContentPackFor'}{'UniqueID'}) {
					my $packID = $json->{'ContentPackFor'}{'UniqueID'};
					if ($packID eq "Platonymous.CustomFarming") {
						LogMessage("    This is a CFR pack. Looking for other json files.", 1);
						opendir($DH, "$BaseDir/$m");
						my @files = readdir($DH);
						closedir $DH;
						foreach my $f (@files) {
							next if ($f =~ /^manifest\.json$/i);
							next unless ($f =~ /\.json$/i);
							LogMessage("    Found another json: $f.", 1);
							my $json = ParseJsonFile("$BaseDir/$m/$f");
							# Saving directory just in case. Also want the ModID in the main json too
							$json->{'__MOD_ID'} = $id;
							$json->{'__PATH'} = "$BaseDir/$m";
							LogMessage("      Dumping json object", 3);
							LogMessage(Dumper($json), 3);
							# Now we actually parse the json a bit to extract the machine sprites. Currently we
							#  only capture the static idle image even though it is possible to make animated gifs.
							if (exists $json->{'machines'}) {
								foreach my $machine (@{$json->{'machines'}}) {
									my $tileindex = 0;
									if (exists $machine->{'tileindex'}) {
										$tileindex = $machine->{'tileindex'};
									}
									$machine->{'__MOD_ID'} = $id;
									if (exists $machine->{'texture'}) {
										my $x = 16*$tileindex;
										my $y = 0;
										($x, $y) = StoreNextImageFile("$BaseDir/$m/$machine->{'texture'}", 'craftables', $x, $y);
										$machine->{'__SS_X'} = $x;
										$machine->{'__SS_Y'} = $y;
									}
								}
							}
							# Machines are just a giant array because I don't know what unique key would make sense
							if (not exists $DataRef->{'Machines'}) {
								$DataRef->{'Machines'} = [];
							}
							push @{$DataRef->{'Machines'}}, $json;
						}
					} elsif ($packID eq "spacechase0.JsonAssets") {
						LogMessage("    This is a JA pack. Looking for specific directories.", 1);
						my %types = ( 
							'BigCraftables' => 'big-craftable.json',
							'Crops' => 'crop.json',
							'FruitTrees' => 'tree.json',
							'Objects' => 'object.json',
							'Hats' => 'hat.json',
							'Weapons' => 'weapon.json'
							);
						foreach my $t (keys %types) {
							if (-d "$BaseDir/$m/$t") {
								LogMessage("    Found $t folder.", 1);
								my $DH;
								opendir($DH, "$BaseDir/$m/$t");
								my @items = readdir($DH);
								closedir $DH;
								foreach my $i (@items) {
									next if ($i eq '.' or $i eq '..');
									if (-e "$BaseDir/$m/$t/$i/$types{$t}") {
										LogMessage("      Found and parsed item folder $i.", 1);
										my $json = ParseJsonFile("$BaseDir/$m/$t/$i/$types{$t}");
										my $key = $i;
										if ($json->{'Name'} ne $key) {
											if (not defined $json->{'Name'} or $json->{'Name'} eq "") {
												LogMessage("WARNING: Item in folder {$i} has no name. Will be skipped", 1);
												next;
											}
											LogMessage("        Item in folder {$i} is actually named {$json->{'Name'}}. Will use that for key instead", 1);
											$key = $json->{'Name'};
										}
										# Saving directory and storing images
										$json->{'__PATH'} = "$BaseDir/$m/$t/$i";
										# Image logic is hardcoded. I'm sorry.
										my ($x, $y);
										my $other_x = -1;
										my $other_y = -1;
										if ($t eq 'BigCraftables') {
											($x, $y) = StoreNextImageFile("$BaseDir/$m/$t/$i/big-craftable.png", 'craftables');
										} elsif ($t eq 'Crops') {
											# Colored crops are special and reserve the 5th sprite for the overlay
											# Cannabis crops for some reason have a single transparent white defined which breaks everything.
											if (exists $json->{'Colors'} and defined $json->{'Colors'}) {
												my $base = Imager->new();
												$base->read(file=>"$BaseDir/$m/$t/$i/crop.png", png_ignore_benign_errors => 1) or
													die "Failed to read crop image: " . $base->errstr;
												my $num_colors = scalar @{$json->{'Colors'}};
												my $num_phases = scalar @{$json->{'Phases'}};
												my $overlay = $base->crop(left=>16*(2+$num_phases), top=>0, width=>16, height=>32);
												my ($r, $g, $b, $a) = split(/,/, $json->{'Colors'}[0]);
												my $target = Imager::Color->new(rgb=>[$r, $g, $b], alpha=>$a);
												$overlay = Colorize($overlay, $target);
												$base->rubthrough(src=>$overlay, tx=> 16*(1+$num_phases), ty=>0, src_maxx=>16, src_maxy=>32) or
													die "Failed to overlay colored crop: " . $base->errstr;
												($x, $y) = StoreNextImage($base, 'crops');
											} else {
												($x, $y) = StoreNextImageFile("$BaseDir/$m/$t/$i/crop.png", 'crops');
											}
											($other_x, $other_y) = StoreNextImageFile("$BaseDir/$m/$t/$i/seeds.png", 'objects');
										} elsif ($t eq 'Objects') {
											($x, $y) = StoreNextImageFile("$BaseDir/$m/$t/$i/object.png", 'objects');
											if (-e "$BaseDir/$m/$t/$i/color.png") {
												($other_x, $other_y) = StoreNextImageFile("$BaseDir/$m/$t/$i/color.png", 'objects')
											}
										} elsif ($t eq 'FruitTrees') {
											# We want to make the same change we made for the base game Fruit Trees, but there is
											#  no guarantee the object sprites are available yet. So we'll put this off until later.
											($x, $y) = StoreNextImageFile("$BaseDir/$m/$t/$i/tree.png", 'trees');
											($other_x, $other_y) = StoreNextImageFile("$BaseDir/$m/$t/$i/sapling.png", 'objects');
										} elsif ($t eq 'Hats') {
											($x, $y) = StoreNextImageFile("$BaseDir/$m/$t/$i/hat.png", 'hats');
										} elsif ($t eq 'Weapons') {
											($x, $y) = StoreNextImageFile("$BaseDir/$m/$t/$i/weapon.png", 'objects');
										}
										$json->{'__MOD_ID'} = $id;
										$json->{'__SS_X'} = $x;
										$json->{'__SS_Y'} = $y;
										$json->{'__SS_OTHER_X'} = $other_x if ($other_x > -1);
										$json->{'__SS_OTHER_Y'} = $other_y if ($other_y > -1);
										LogMessage("        Dumping json object", 3);
										LogMessage(Dumper($json), 3);
										if (not exists $DataRef->{$t}) {
											$DataRef->{$t} = {};
										}
										if (exists $DataRef->{$t}{$key}) {
											LogMessage("      WARNING: Item $key already exists in $t. Skipping this one.", 1);
										} else {
											$DataRef->{$t}{$key} = $json;
										}
									} else {
										LogMessage("      Found folder for item $i but no $types{$t} file.", 1);
									}
								}
							}
						}
					} elsif ($packID eq "DIGUS.MailFrameworkMod") {
						LogMessage("    This is an MFM pack. Looking for mail.json file.", 1);
						if (-e "$BaseDir/$m/mail.json") {
							LogMessage("      Found mail.json; attempting to parse", 1);
							my $json = ParseJsonFile("$BaseDir/$m/mail.json");
							# Since MFM packs are a list at top level, we want to make a new container object for them
							my $container = { 'name' => $name, '__MOD_ID' => $id, '__PATH' => "$BaseDir/$m", 'letters' => $json };
							LogMessage("      Dumping json object", 3);
							LogMessage(Dumper($json), 3);
							# Merge them into a bigger list
							if (not exists $DataRef->{'Mail'}) {
								$DataRef->{'Mail'} = [];
							}
							push @{$DataRef->{'Mail'}}, $container;
						} else {
							LogMessage("      WARNING: No mail.json found, skipping mod", 1);
							$storeMeta = 0;
						}
					# The example pack has different capitalization than the actual mod :(
					} elsif ($packID eq "DIGUS.ProducerFrameworkMod" or $packID eq "Digus.ProducerFrameworkMod") {
						LogMessage("    This is a PFM pack. Looking for producerRules.json file.", 1);
						if (-e "$BaseDir/$m/producerRules.json") {
							LogMessage("      Found producerRules.json; attempting to parse", 1);
							my $json = ParseJsonFile("$BaseDir/$m/producerRules.json");
							# PFM packs are also just a big list, so we need a container
							my $container = { 'name' => $name, '__MOD_ID' => $id, '__PATH' => "$BaseDir/$m", 'producers' => $json };
							LogMessage("      Dumping json object", 3);
							LogMessage(Dumper($json), 3);
							# Merge them into a bigger list
							if (not exists $DataRef->{'Producers'}) {
								$DataRef->{'Producers'} = [];
							}
							push @{$DataRef->{'Producers'}}, $container;
						} else {
							LogMessage("      WARNING: No producerRules.json found, skipping mod", 1);
							$storeMeta = 0;
						}
					} elsif ($packID eq "Pathoschild.ContentPatcher") {
						LogMessage("    This is a CP pack. Looking for content.json file.", 1);
						if (-e "$BaseDir/$m/content.json") {
							LogMessage("      Found content.json; attempting to parse", 1);
							my $json = ParseJsonFile("$BaseDir/$m/content.json");
							$json->{'__MOD_ID'} = $id;
							$json->{'__PATH'} = "$BaseDir/$m";
							LogMessage("      Dumping json object", 3);
							LogMessage(Dumper($json), 3);
							# CP packs will be dumped into a list since keying on mod ID doesn't do anything for us
							if (not exists $DataRef->{'ContentPatches'}) {
								$DataRef->{'ContentPatches'} = [];
							}
							push @{$DataRef->{'ContentPatches'}}, $json;
						} else {
							LogMessage("      WARNING: No content.json found, skipping mod", 1);
							$storeMeta = 0;
						}
					} elsif ($packID eq "Paritee.BetterFarmAnimalVariety") {
						LogMessage("    This is a BFAV pack; storing meta information only.", 1);
					} else {
						LogMessage("    This is an unknown pack type ($packID)", 1);
						$storeMeta = 0;
					}
				} else {
					LogMessage("    This is not a content pack and will be skipped.", 1);
					$storeMeta = 0;
				}
				$MetaRef->{$id} = $json if ($storeMeta);
			} else {
				LogMessage("    No manifest found, time to recurse!", 1);
				ParseModData("$BaseDir/$m", $DataRef, $MetaRef);
			}
		}
	}
}

# Colorize - Changes Hue and Saturation of an image to match an input color
#   while preserving Luminance. Returns the new image
#
#   Image - Imager image object
#   Color - Imager::Color object
sub Colorize {
	my $source = shift;
	my $color = shift;

	if (not defined $source or not defined $color) {
		LogMessage("WARNING Colorize received invalid parameters", 1);
		return undef;
	}
	my $image = $source->copy();
	my ($ch, $cs, $cv, $ca) = $color->hsv();
	# Here is where we deal with weirdness from Cannabis Kit crops
	return $source if ($ca == 0);
	for (my $x = 0; $x < $image->getwidth(); $x++) {
		for (my $y = 0; $y < $image->getheight(); $y++) {
			my ($h, $s, $v, $a) = $image->getpixel(x=>$x, y=>$y)->hsv();
			my $new_color = Imager::Color->new(hsv=>[$ch, $cs, $v], alpha=>$a);
			$image->setpixel(x=>$x, y=>$y, color=>$new_color);
		}
	}
	return $image;
}

# StoreNextImageFile - wrapper for StoreNextImage
#    Filename of image to copy from
#	 Type of image (one of qw[crops craftables hats trees objects])
#    X coordinate of source to start copy from (upper-left corner) [Optional; default is 0]
#    Y coordinate of source to start copy from (upper-left corner) [Optional; default is 0]
#
#    Returns (x, y) on spritesheet or (-1, -1) if something bad happened
sub StoreNextImageFile {
	my $src_file = shift;
	my $type = shift;
	my $src_x = shift;
	my $src_y = shift;
	
	# Passing everything off to another function, only thing we need to check is reading the $src_file
	my $src_img = Imager->new();
	my $ok = $src_img->read(file=>$src_file, png_ignore_benign_errors => 1);
	if (not $ok) {
		LogMessage("WARNING StoreNextImageFile unable to read image file {$src_file}: " . $src_img->errstr);
		return (-1, -1);
	}
	
	return StoreNextImage($src_img, $type, $src_x, $src_y);
}

# StoreNextImage
#    Imager object of image to copy
#	 Type of image (one of qw[crops craftables hats trees objects])
#    X coordinate of source to start copy from (upper-left corner) [Optional; default is 0]
#    Y coordinate of source to start copy from (upper-left corner) [Optional; default is 0]
#
#    Returns (x, y) on spritesheet or (-1, -1) if something bad happened
sub StoreNextImage {
	my $src_img = shift;
	my $type = shift;
	my $src_x = shift;
	my $src_y = shift;
	
	$src_x = 0 if (not defined $src_x);
	$src_y = 0 if (not defined $src_y);
	
	LogMessage("StoreNextImage called with parameters {$src_img} {$type} {$src_x} {$src_y}", 3);

	if (not defined $src_img or not defined $type or not exists $SS->{$type}) {
		LogMessage("WARNING Missing required parameter for StoreNextImage {$src_img}, {$type}");
		return (-1, -1);
	}
	
	if ($src_x < 0 or $src_y < 0) {
		LogMessage("WARNING StoreNextImage: x or y coordinate of source is negative");
		return (-1, -1);
	}
	# These still work, so we have to deal
	my $copy_width = $SS->{$type}{'width'};
	my $copy_height = $SS->{$type}{'height'};
	if ($src_x + $SS->{$type}{'width'} > $src_img->getwidth()) {
		LogMessage("WARNING StoreNextImage: source is too narrow, but we'll use it anyway.");
		$copy_width = $src_img->getwidth() - $src_x;
	}
	if ($src_y + $SS->{$type}{'height'} > $src_img->getheight()) {
		LogMessage("WARNING StoreNextImage: source is too short, but we'll use it anyway.");
		$copy_height = $src_img->getheight() - $src_y;
	}

	my $next_index = $SS->{$type}{'index'} + 1;
	my $sprites_per_row = floor($SS_WIDTH / $SS->{$type}{'width'});
	my $next_x = $SS->{$type}{'width'} * ($next_index % $sprites_per_row);
	my $next_y = $SS->{$type}{'height'} * floor($next_index / $sprites_per_row);
	if ($next_y + $SS->{$type}{'height'} > $SS_HEIGHT) {
		LogMessage("WARNING StoreNextImage: Spritesheet for $type is full");
		return (-1, -1);
	}
	
	my $ok = $SS->{$type}{'img'}->paste(src=>$src_img,
            left => $next_x, top => $next_y, src_minx => $src_x, src_miny => $src_y,
			width=>$copy_width, height=>$copy_height);
	if (not $ok) {
		LogMessage("WARNING StoreNextImage failed to copy image into spritesheet: " . $src_img->errstr);
		return (-1, -1);
	}
	# We made it!
	$SS->{$type}{'index'} = $next_index;
	return ($next_x, $next_y);
}

# LogMessage
#    string to print
#    log level (defaults to 1)
sub LogMessage {
	my $message = shift;
	my $level = shift;
	$level = 1 if (not defined $level);
	
	print STDOUT $message, "\n" if ($LogLevel >= $level);
	print STDERR $message, "\n" if ($message =~ /^(\w)*WARNING/);
	die $message if ($message =~ /^(\w)*DIE/);
}

# ParseJsonFile - Reads file, parses JSON, handles errors. 
#    filename
sub ParseJsonFile {
	my $filename = shift;
	my $file_contents = read_file($filename, {binmode => ':encoding(UTF-8)'});
	LogMessage("      Dumping file contents", 3);
	LogMessage(Dumper($file_contents), 3);
	# Remove UTF-8 BOM if it is there because from_rjson can't deal with it
	$file_contents =~ s/^\x{feff}//;
	# The JSON parser cannot handle situations like the following
	# "key": //comment
	# { ...
	# So we are going to try to prevent that. This might backfire spectacularly.
	my $comment_removed = ($file_contents =~ s|(?<=:)\s*//[^*\r\n]*(?=[\r\n])||g);
	if ($comment_removed) { LogMessage("      $comment_removed potentially problematic comment(s) removed", 2); }
	# And trailing spaces sometimes screw us too.
	$comment_removed = ($file_contents =~ s|(?<=\S)[^\S\r\n]+(?=[\r\n])||g);
	if ($comment_removed) { LogMessage("      $comment_removed trailing space(s) removed", 2); }
	my $json = from_rjson($file_contents);
	if (not defined $json) {
		LogMessage("WARNING JSON parsing failed on $filename\n  Error $JSON::Relaxed::err_id: $JSON::Relaxed::err_msg");
	}
	return $json;
}

__END__