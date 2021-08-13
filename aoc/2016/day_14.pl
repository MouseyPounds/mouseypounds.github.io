#!/bin/perl -w
#
# https://adventofcode.com/2016/day/14

use strict;
use POSIX;
use Digest::MD5 qw(md5_hex);
use List::Util qw(min max);

$| = 1;

print "2016 Day 14\n";
my $puzzle = "ahsbgdzn";
#$puzzle = "abc";
my $which_key = 64;

(my ($hash, $index)) = get_key($which_key, $puzzle);
print "P1: Without stretching, the ${which_key}th key found was $hash from index $index.\n";

my $stretch_amount = 2016;
($hash, $index) = get_key($which_key, $puzzle, $stretch_amount);
print "P2: Stretching $stretch_amount times, the ${which_key}th key found was $hash from index $index.\n";

sub get_key {
	my $max_keys = shift;
	my $salt = shift;
	my $stretch = shift;
	
	my %valid_keys = ();	# key is index, value is md5hash
	my %to_check = ();		# key is index, value is hash containing md5hash and triple number
	my $keys_found = 0;		# for convenience since this is also scalar(keys %valid_keys)
	my $max_index = 1e15;	# arbitrarily high number that will be later adjusted
	my $index = 0;

	while ($index < $max_index or $keys_found < $max_keys) {
		$index++;
		my $md5 = md5_hex("$salt$index");
		if (defined $stretch) { foreach my $x (1 .. $stretch) { $md5 = md5_hex($md5); } }
		if (my @quintuples = $md5 =~ /(\w)\1{4}/) {
			foreach my $q (@quintuples) {
				foreach my $i (sort keys %to_check) {
					if ($i < $index - 1000) { delete $to_check{$i} ; next; }
					if ($to_check{$i}{'trip'} eq $q) {
						$valid_keys{$i} = $to_check{$i}{'hash'};
						delete $to_check{$i};
						$keys_found++;
						if ($keys_found == $max_keys) {
							# We have all the keys we need but it is possible that one of the pending keys
							# might have an earlier index. 
							my $last_key_index = max(keys %valid_keys);
							$max_index = $index; 
							foreach my $k (sort keys %to_check) {
								$max_index = $k + 1000 if ($k < $last_key_index)
							}
						}	
					}
				}
			}	
		}
		if (my @triples = $md5 =~ /(\w)\1{2}/) {
			$to_check{$index} = { 'hash' => $md5, 'trip' => $triples[0] };
		}
	}

	my @index_list = sort {$a <=> $b} (keys %valid_keys);
	return $valid_keys{$index_list[$max_keys-1]}, $index_list[$max_keys-1];
}

__DATA__