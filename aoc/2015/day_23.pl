#!/bin/perl -w
#
# https://adventofcode.com/2015/day/23
#

use strict;
use POSIX;

my $debugging = 0;

$| = 1;

print "2015 Day 23\n";
my $puzzle = do { local $/; <DATA> }; # slurp it
my @instructions = split("\n", $puzzle);

print "\nPart 1:\n";
(my ($a, $b)) = run_program(\@instructions);
print "P1: After program completion with default starting values, register a is $a and register b is $b\n";

print "\nPart 2:\n";
($a, $b) = run_program(\@instructions, 1);
print "P2: After program completion with register a starting at 1, register a is $a and register b is $b\n";

sub run_program {
	my $ins = shift;
	my $initial_a = shift;
	
	$initial_a = 0 unless (defined $initial_a);
	
	my $ip = 0;	# instruction pointer
	my %reg = ( 'a' => $initial_a, 'b' => 0 );
	
	while ($ip < scalar(@$ins)) {
		(my ($in, $arg)) = $ins->[$ip] =~ /^(\w+) (.*)/;
		printf "[%3d] a = $reg{'a'} ; b = $reg{'b'}\r", $ip;
		if ($in eq 'hlf') {
			$reg{$arg} = POSIX::floor($reg{$arg} / 2);
			$ip++;
		} elsif ($in eq 'tpl') {
			$reg{$arg} *= 3;
			$ip++;
		} elsif ($in eq 'inc') {
			$reg{$arg} += 1;
			$ip++;
		} elsif ($in eq 'jmp') {
			$ip += $arg;
		} elsif ($in eq 'jie') {
			(my ($r, $off)) = $arg =~ /^(\w), (.*)/;
			$ip += ($reg{$r} % 2) ? 1 : $off;
		} elsif ($in eq 'jio') {
			(my ($r, $off)) = $arg =~ /^(\w), (.*)/;
			$ip += ($reg{$r} == 1) ? $off : 1;
		} else {
			warn "Skipping invalid instruction {$in}\n";
			$ip++;
		}
	}
	
	return ($reg{'a'}, $reg{'b'});
}


__DATA__
jio a, +16
inc a
inc a
tpl a
tpl a
tpl a
inc a
inc a
tpl a
inc a
inc a
tpl a
tpl a
tpl a
inc a
jmp +23
tpl a
inc a
inc a
tpl a
inc a
inc a
tpl a
tpl a
inc a
inc a
tpl a
inc a
tpl a
inc a
tpl a
inc a
inc a
tpl a
inc a
tpl a
tpl a
inc a
jio a, +8
inc b
jie a, +4
tpl a
inc a
jmp +2
hlf a
jmp -7