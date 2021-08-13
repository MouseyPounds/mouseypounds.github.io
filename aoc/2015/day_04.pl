#!/bin/perl -w
#
# https://adventofcode.com/2015/day/4

use strict;
use POSIX;
use Digest::MD5 qw(md5_hex);

$| = 1;

# First 2 are examples, 3rd is puzzle input
my @keys = qw(abcdef pqrstuv bgvyzdsv);

print "2015 Day 4, Part 1\n";
foreach my $k (@keys) {
	for (my $i = 0; $i < 1e9; $i++) {
		printf "Checking $i\r";
		my $md5 = md5_hex("$k$i");
		if ($md5 =~ /^0{5}/) {
			print "Decimal value $i combines with key $k to produce hash $md5\n";
			last;
		}
	}
}
print "\n2015 Day 4, Part 2\n";
my $k = $keys[$#keys];
for (my $i = 0; $i < 1e9; $i++) {
	printf "Checking $i\r";
	my $md5 = md5_hex("$k$i");
	if ($md5 =~ /^0{6}/) {
		print "Decimal value $i combines with key $k to produce hash $md5\n";
		last;
	}
}

