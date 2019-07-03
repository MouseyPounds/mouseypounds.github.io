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

# Logging
#   0: No logging (aside from warn/die)
#   1: Simple trace messages only
#   2: Trace messages and full data dumps
#   3: Trace messages, data dumps, and file content dumps
my $LogLevel = 1;

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
				LogMessage("    Dumping object returned by read_file", 3);
				LogMessage(Dumper($file_contents), 3);
				# Remove UTF-8 BOM if it is there because from_rjson can't deal with it
				$file_contents =~ s/^\x{feff}//;
				my $json = from_rjson($file_contents);
				LogMessage("    Dumping object returned by from_rjson", 3);
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
							LogMessage("      Dumping object returned by read_file", 3);
							LogMessage(Dumper($file_contents), 3);
							# Remove UTF-8 BOM if it is there because from_rjson can't deal with it
							$file_contents =~ s/^\x{feff}//;
							my $json = from_rjson($file_contents);
							LogMessage("      Dumping object returned by from_rjson", 3);
							LogMessage(Dumper($json), 3);
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
										LogMessage("        Dumping object returned by read_file", 3);
										LogMessage(Dumper($file_contents), 3);
										# Remove UTF-8 BOM if it is there because from_rjson can't deal with it
										$file_contents =~ s/^\x{feff}//;
										my $json = from_rjson($file_contents);
										LogMessage("        Dumping object returned by from_rjson", 3);
										LogMessage(Dumper($json), 3);
										if (not exists $DataRef->{$t}) {
											$DataRef->{$t} = {};
										}
										if (exists $DataRef->{$t}{$i}) {
											LogMessage("      WARNING: Item $i already exists in $t", 1);
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

# LogMessage
#    string to print
#    log level (defaults to 1)
sub LogMessage {
	my $message = shift;
	my $level = shift;
	$level = 1 if (not defined $level);
	
	print STDOUT $message, "\n" if ($LogLevel >= $level);
	print STDERR $message if ($message =~ /WARNING/);
}

__END__