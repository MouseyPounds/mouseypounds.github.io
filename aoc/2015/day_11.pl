#!/bin/perl -w
#
# https://adventofcode.com/2015/day/11
#

use strict;
use POSIX;

my $debugging = 0;
my $max_value = ord('z');

my $puzzle = "hepxcrrq";

print "2015 Day 11\n\n";

my $password = $puzzle;
my $attempts = 0;
while(not is_valid($password)) {
	$attempts++;
	printf "[%7d] Checking $password\r", $attempts;
	$password = increment($password);
}

print "P1: First valid password after {$puzzle} is {$password} ($attempts increments required).\n";

$puzzle = $password;
$password = increment($password);
$attempts = 1;
while(not is_valid($password)) {
	$attempts++;
	printf "[%7d] Checking $password\r", $attempts;
	$password = increment($password);
}

print "P2: Next valid password after {$puzzle} is {$password} ($attempts increments required).\n";


sub is_valid {
	my $string = shift;
	
	return 0 if ($string =~ /[iol]/);
	
	my %unique = ();
	foreach my $p ($string =~ /([a-z])\1/g) { $unique{$p} = 1; }
	return 0 if (scalar(keys %unique) < 2);
	
	my @letters = split('', $string);
	my $straight = 1;
	my $last_ord = 1e9;
	for (my $i = 0; $i <= $#letters; $i++) {
		my $this_ord = ord($letters[$i]);
		$straight = ($this_ord == $last_ord + 1) ? $straight + 1 : 1;
		last if ($straight >= 3);
		$last_ord = $this_ord;
	}
	return ($straight >= 3);
}

sub increment {
	my $string = shift;
	my @letters = split('', $string);
	
	my $carry = 1;
	for (my $i = $#letters; $i >= 0; $i--) {
		my $this_letter = ord($letters[$i]) + $carry;
		if ($this_letter > $max_value) {
			$letters[$i] = 'a';
			$carry = 1;
		} else {
			$letters[$i] = chr $this_letter;
			last;
		}
	}
	
	return join('', @letters);
}

__DATA__
