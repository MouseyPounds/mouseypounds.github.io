#!/bin/perl -w
#
# knothash.pm
#
# Utility module used by several puzzles in AoC 2017. Functions are specifically tailored to support the needs
# of those puzzles and so might be somewhat different than a general implementation. Not terribly fast due to
# a ton of splices every round.

package knothash;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(get_hash);
@EXPORT_OK = qw(do_round);

use strict;
use List::Util qw(reduce);

# Full hash algorithm, exported by default. Returns 32-character string of hex digits.
sub get_hash {
	my $key_string = shift;
	
	my @lengths =  map { ord $_ } split('', $key_string);
	push @lengths, 17, 31, 73, 47, 23;
	my @list = 0 .. 255;
	my $skip = 0;
	my $pos = 0;
	map { do_round(\@list, \@lengths, \$skip, \$pos) } (1 .. 64);
	return join('', map { sprintf("%02x", reduce { $a ^ $b } splice(@list, 0, 16)); } (1 .. 16) );
}

# Single round of the hash. Exportable due to AoC 2017 Day 10, Part 1.
sub do_round {
	my $list_ref = shift;
	my $length_ref = shift;
	my $skip_ref = shift;
	my $pos_ref = shift;
	
	for (my $i = 0; $i <= $#$length_ref; $i++) {
		my $t = $length_ref->[$i];
		if (($$pos_ref + $t) <= $#$list_ref) {
			splice(@$list_ref, $$pos_ref, 0, reverse splice(@$list_ref, $$pos_ref, $t));
		} else {
			my $front_len = $$pos_ref + $t - $#$list_ref - 1;
			my $back_len = $t - $front_len;
			my @temp = reverse (splice(@$list_ref, $$pos_ref, $back_len), splice(@$list_ref, 0, $front_len));
			splice(@$list_ref, 0, 0, splice(@temp, $back_len, $front_len));
			splice(@$list_ref, $$pos_ref, 0, splice(@temp, 0, $back_len));
		}
		$$pos_ref = ($$pos_ref + $$skip_ref + $t) % scalar(@$list_ref);
		$$skip_ref++;
	}
}	

1;
