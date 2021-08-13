#!/bin/perl -w
#
# https://adventofcode.com/2016/day/16
#

use strict;

print "2016 Day 16\n";
my $initial_state = "10111100110001111";
my $disk_size = 272;

my $data = dragon_curve($initial_state, $disk_size);
my $check = calc_checksum($data);
print "\nP1: The checksum of the generated data for disk size $disk_size is $check.\n";

$disk_size = 35651584;
$data = dragon_curve($initial_state, $disk_size);
$check = calc_checksum($data);
print "\nP2: The checksum of the generated data for disk size $disk_size is $check.\n";

sub dragon_curve {
	my $data = shift;
	my $length = shift;
	
	while (length $data < $length) {
		my $copy = reverse $data;
		$copy =~ tr/01/10/;
		$data = "${data}0${copy}";
	}
	
	return substr $data, 0, $length;
}

# The calc_checksum_bf "brute force" method follows the directions as closely as possible and works fine for part 1, but it
# has trouble scaling to larger input sizes such as we have with part 2 eating up a ton of time and memory.
sub calc_checksum_bf {
	my $data = shift;
	$data = join('', map { /(.)\1/ ? '1' : '0' } unpack '(a2)*', $data) while ((length $data) % 2 == 0);
	return $data;
}

# Examing the checksum algorithm we see the following important features:
# - The continual recalculation until there is an odd length is essentially dividing the initial length by the highest possible
#   power of 2. The relevant divisor (n) could be quickly calculated via some "bit magic" using: length & ~(length-1).
# - The checksum digit rules boil down to: 1 if there were an even number of ones and 0 if an odd number. While this was
#   presented as only examining a pair of characters/digits, the logic extends all the way up to chunk size n. 
# So, our improved algorithm is to break the data into chunks of size n = length & ~(length-1) and then count the number of
# ones in each chunk using a meaningless tr///, setting checksum "digits" based on whether those counts are even or odd.
sub calc_checksum {
	my $data = shift;
	my $n = ( (length $data) & ~((length $data) - 1) );
	return join('', map { (tr/1/1/) % 2 ? '0' : '1' } unpack "(a$n)*", $data);
}


__DATA__