#!/bin/perl -w
#
# https://adventofcode.com/2020/day/25

use strict;

print "2020 Day 25\n\n";
my $puzzle = do { local $/; <DATA> }; # slurp it
my @public_key = split("\n", $puzzle);
my @loop = ();

my $subject_number = 7;
my $modulus = 20201227;
my $val = 1;
my $loop = 0;
# Since the algorithm is just continually multiplying $subject_number with modulus, we'll just do that directly and
# keep going that until we find both values so that we don't waste any time calculating anything more than once.
until (defined $loop[0] and defined $loop[1]) {
	$loop++;
	$val *= $subject_number;
	$val %= $modulus;
	$loop[0] = $loop if ($val == $public_key[0]);
	$loop[1] = $loop if ($val == $public_key[1]);
}
for (my $k = 0; $k < 2; $k ++) {
	print "Device with public key $public_key[$k] has a loop size of $loop[$k]\n";
}

# This section runs under bignum to get the modular power function now that the speed penalty will no longer matter.
{
	use bignum;
	
	$val = 0 + $public_key[0];
	$val->bmodpow($loop[1], 20201227);
	print "The encryption key is $val\n";
}

__DATA__
12320657
9659666
