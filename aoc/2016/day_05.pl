#!/bin/perl -w
#
# https://adventofcode.com/2016/day/5

use strict;
use POSIX;
use Digest::MD5 qw(md5_hex);

my $silly_anim = 1;

$| = 1;

print "2016 Day 5\n";
my $puzzle = do { local $/; <DATA> }; # slurp it

my @password_1 = qw(_ _ _ _ _ _ _ _);
my @password_2 = qw(_ _ _ _ _ _ _ _);
my $index = 0;
my $p1_pos = 0;
my $p2_count = 0;
print "Cracking password...\r";
while ($p2_count < 8) {
	$index++;
	my $md5 = md5_hex("$puzzle$index");
	if ($md5 =~ /^0{5}/) {
		my @char = split('', (substr $md5, 5, 2));
		$password_1[$p1_pos++] = $char[0] if ($p1_pos < 8);
		my $pos = hex $char[0];
		#print "cc = {$char[0] $char[1]}, pos = $pos\n";
		if ($pos < 8 and $password_2[$pos] eq '_') {
			$password_2[$pos] = $char[1];
			$p2_count++;
		}
	}
	if ($silly_anim and $index % 11 == 0) {
		my @display = (@password_1, "  ", @password_2);
		for (my $i = 0; $i <= $#display; $i++) {
			$display[$i] = sprintf("%x", ($index - 3*$i) % 16) if ($display[$i] eq '_');
		}
		print "Cracking passwords: " . join('', @display) . "\r";
	}
}

print "P1: The password for the first door is " . join('', @password_1) . "\n";
print "P2: The password for the second door is " . join('', @password_2) . "\n";

__DATA__
ffykfhsq