#!/bin/perl
#
# gather_data.pl
#
# processing JA & CFR data for PPJA Mods to create summary web pages

use strict;
use JSON::Relaxed qw(from_rjson);
use File::Slurp qw(read_file);
use Data::Dumper;
use Storable;
use Imager;
use POSIX qw(floor);

# Logging
#   0: No logging (aside from warn/die)
#   1: Simple trace messages only
#   2: Trace messages and full data dumps
#   3: Trace messages, data dumps, and file content dumps
my $LogLevel = 2;

# Important directories. These would probably be better off as optional command-line arguments with reasonable
# defaults, but for now they are just hardcoded here.
#   $GameDir is assumed to be the base (extracted) Content\Data directory.
#   $ModDir is assumed to be a directory containing all PPJA mods.
#     It could contain other mods too, but only those which are JA or CFR content packs are currently supported
my $GameDir = 'C:/Program Files/Steam/steamapps\common/Stardew Valley/Content (unpacked)/Data';
my $ModDir = 'C:/Program Files/Steam/steamapps/common/Stardew Valley/Mods/[DIR] Crops, Trees, Grass/PPJA';

# Game data stored in %GameData dictionary
#   Top level entries correspond to particular files but do not exactly mirror game file & directory organization 
#   Second level entries have the original data in 'raw' and also an array of the individual fileds in 'split'
my $GameData = {};

# Mod meta information (from manifests) in %Mod dictionary
my $ModInfo = {};

# Mod data stored in %ModData dictionary and will mostly mirror structure of JA & CFR data files
my $ModData = { 'Crops' => {}, 'Objects' => {}, 'BigCraftables' => {}, 'FruitTrees' => {}, 'Hats' => {}, 'Weapons' => {},
	'Machines' => [], 'Cooking' => {}, 'Crafting' => {}, };

# Spritesheets to consolidate mod images into single files
my $SS_WIDTH = 2048;
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

LogMessage("Dumping full GameData", 2);
LogMessage(Dumper($GameData), 2);
LogMessage("Dumping full ModData", 2);
LogMessage(Dumper($ModData), 2);
LogMessage("Dumping full ModInfo", 2);
LogMessage(Dumper($ModInfo), 2);

LogMessage("Writing cache", 1);
store $GameData, "cache_GameData";
store $ModData, "cache_ModData";
store $ModInfo, "cache_ModInfo";

LogMessage("Writing spritesheets", 1);
foreach my $k (keys %$SS) {
	my $filename = "../img/ss_${k}.png";
	$SS->{$k}{'img'}->write(file=>$filename) or 
		die "Error writing normal spritesheet to $filename" . $SS->{$k}{'img'}->errstr;
	$filename = "../img/ss_${k}_x2.png";
	$SS->{$k}{'img'}->scale(scalefactor=>2.0, qtype=>'preview')->write(file=>$filename) or 
		die "Error writing scaled spritesheet to $filename" . $SS->{$k}{'img'}->errstr;
}

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
	my @Filenames = qw(ObjectInformation Crops BigCraftablesInformation CookingRecipes CraftingRecipes);
	LogMessage("Parsing Game Data in $BaseDir", 1);
	foreach my $f (@Filenames) {
		LogMessage("  Checking for $f", 1);
		my $this_file = "$BaseDir/$f.json";
		if (-e $this_file) {
			my $file_contents = read_file("$this_file", {binmode => ':encoding(UTF-8)'});
			LogMessage("    Dumping object returned by read_file", 3);
			LogMessage(Dumper($file_contents), 3);
			# Remove UTF-8 BOM if it is there because from_rjson can't deal with it
			$file_contents =~ s/^\x{feff}//;
			my $json = from_rjson($file_contents);
			LogMessage("    Dumping object returned by from_rjson", 3);
			LogMessage(Dumper($json), 3);
			$DataRef->{$f} = {};
			foreach my $key (keys %$json) {
				$DataRef->{$f}{$key} = {};
				$DataRef->{$f}{$key}{'raw'} = $json->{$key};
				my @Fields = split('/', $json->{$key});
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

	LogMessage("Parsing Mod Data in $BaseDir", 1);
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
				my $file_contents = read_file("$BaseDir/$m/manifest.json", {binmode => ':encoding(UTF-8)'});
				LogMessage("    Dumping file contents", 3);
				LogMessage(Dumper($file_contents), 3);
				# Remove UTF-8 BOM if it is there because from_rjson can't deal with it
				$file_contents =~ s/^\x{feff}//;
				my $json = from_rjson($file_contents);
				# Saving directory to locate mod folder later
				$json->{'__PATH'} = "$BaseDir/$m";
				LogMessage("    Dumping json object", 3);
				LogMessage(Dumper($json), 3);
				my $id = $json->{'UniqueID'};
				my $name = $json->{'Name'};
				if (defined $id and defined $name) {
					LogMessage("    Mod found $id ($name)", 1);
				} else {
					LogMessage("    Manifest missing UniqueID and/or Name. Skipping.", 1);
					next;
				}
				$MetaRef->{$id} = $json;
				
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
							my $this_file = "$BaseDir/$m/$f";
							my $file_contents = read_file("$BaseDir/$m/$f", {binmode => ':encoding(UTF-8)'});
							LogMessage("      Dumping file contents", 3);
							LogMessage(Dumper($file_contents), 3);
							# Remove UTF-8 BOM if it is there because from_rjson can't deal with it
							$file_contents =~ s/^\x{feff}//;
							my $json = from_rjson($file_contents);
							# Saving directory just in case
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
									if (exists $machine->{'texture'}) {
										my $x = 16*$tileindex;
										my $y = 0;
										($x, $y) = StoreNextImage("$BaseDir/$m/$machine->{'texture'}", 'craftables', $x, $y);
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
										LogMessage("      Found and parsed item $i.", 1);
										my $file_contents = read_file("$BaseDir/$m/$t/$i/$types{$t}", {binmode => ':encoding(UTF-8)'});
										LogMessage("        Dumping file contents", 3);
										LogMessage(Dumper($file_contents), 3);
										# Remove UTF-8 BOM if it is there because from_rjson can't deal with it
										$file_contents =~ s/^\x{feff}//;
										my $json = from_rjson($file_contents);
										# Saving directory and storing images
										$json->{'__PATH'} = "$BaseDir/$m/$t/$i";
										# Image logic is hardcoded. I'm sorry.
										my ($x, $y);
										my $other_x = -1;
										my $other_y = -1;
										if ($t eq 'BigCraftables') {
											($x, $y) = StoreNextImage("$BaseDir/$m/$t/$i/big-craftable.png", 'craftables');
										} elsif ($t eq 'Crops') {
											($x, $y) = StoreNextImage("$BaseDir/$m/$t/$i/crop.png", 'crops');
											($other_x, $other_y) = StoreNextImage("$BaseDir/$m/$t/$i/seeds.png", 'objects');
										} elsif ($t eq 'FruitTrees') {
											($x, $y) = StoreNextImage("$BaseDir/$m/$t/$i/tree.png", 'trees');
											($other_x, $other_y) = StoreNextImage("$BaseDir/$m/$t/$i/sapling.png", 'objects');
										} elsif ($t eq 'Objects') {
											($x, $y) = StoreNextImage("$BaseDir/$m/$t/$i/object.png", 'objects');
											($other_x, $other_y) = StoreNextImage("$BaseDir/$m/$t/$i/color.png", 'objects')
												if (-e "$BaseDir/$m/$t/$i/color.png");
										} elsif ($t eq 'Hats') {
											($x, $y) = StoreNextImage("$BaseDir/$m/$t/$i/hat.png", 'hats');
										} elsif ($t eq 'Weapons') {
											($x, $y) = StoreNextImage("$BaseDir/$m/$t/$i/weapon.png", 'objects');
										}
										$json->{'__SS_X'} = $x;
										$json->{'__SS_Y'} = $y;
										$json->{'__SS_OTHER_X'} = $other_x if ($other_x > -1);
										$json->{'__SS_OTHER_Y'} = $other_y if ($other_y > -1);
										LogMessage("        Dumping json object", 3);
										LogMessage(Dumper($json), 3);
										if (not exists $DataRef->{$t}) {
											$DataRef->{$t} = {};
										}
										if (exists $DataRef->{$t}{$i}) {
											LogMessage("      WARNING: Item $i already exists in $t. Skipping this one.", 1);
										} else {
											$DataRef->{$t}{$i} = $json;
										}
									} else {
										LogMessage("      Found folder for item $i but no $types{$t} file.", 1);
									}
								}
							}
						}
					} else {
						LogMessage("    This is an unknown pack type ($packID)", 1);
					}
				} else {
					LogMessage("    This is not a content pack and will be skipped.", 1);
				}
			}
		}
	}
}

# StoreNextImage
#    Filename of image to copy from
#	 Type of image (one of qw[crops craftables hats trees objects])
#    X coordinate of source to start copy from (upper-left corner) [Optional; default is 0]
#    Y coordinate of source to start copy from (upper-left corner) [Optional; default is 0]
#
#    Returns (x, y) on spritesheet or (-1, -1) if something bad happened
sub StoreNextImage {
	my $src_file = shift;
	my $type = shift;
	my $src_x = shift;
	my $src_y = shift;
	
	$src_x = 0 if (not defined $src_x);
	$src_y = 0 if (not defined $src_y);
	
	LogMessage("StoreNextImage called with parameters {$src_file} {$type} {$src_x} {$src_y}", 1);

	if (not defined $src_file or not defined $type or not exists $SS->{$type}) {
		LogMessage("WARNING Missing required parameter for StoreNextImage {$src_file}, {$type}");
		return (-1, -1);
	}
	
	my $src_img = Imager->new();
	my $ok = $src_img->read(file=>$src_file, png_ignore_benign_errors => 1);
	if (not $ok) {
		LogMessage("WARNING StoreNextImage unable to read image file {$src_file}: " . $src_img->errstr);
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
	
	$ok = $SS->{$type}{'img'}->paste(src=>$src_img,
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
	print STDERR $message, "\n" if ($message =~ /WARNING/);
}

__END__