#!/bin/perl -w
#
# https://adventofcode.com/2017/day/21
#
# We represent the board in 3 different ways -- single string with rows separated by slash which is used for the rules and
# rule checks, a half-grid that is an array of strings that is mainly useful for the transitions from 1 iteration to the next,
# and a full grid that is a 2d array of individual characters/pixels.

use strict;

print "2017 Day 21\n\n";
my $puzzle = do { local $/; <DATA> }; # slurp it
my %rules = map { /(\S+) => (\S+)/; } split("\n", $puzzle);
add_missing_rules(\%rules);

my $start = ".#./..#/###";
my @grid = string_to_grid($start);
my $iteration = 0;
my $p1_limit = 5;
my $p2_limit = 18;
while ($iteration++ < $p2_limit) {
	my $size = scalar(@grid);
	my $tiles = 0;
	if ($size % 2 == 0) {
		$tiles = $size / 2;
	} elsif ($size % 3 == 0) {
		$tiles = $size / 3;
	}
	$size /= $tiles;
	my @next_hg = ();
	my $next_size = $size + 1;
	for (my $ty = 0; $ty < $tiles; $ty++) {
		for (my $tx = 0; $tx < $tiles; $tx++) {
			my @hg = ();
			for (my $y = 0; $y < $size; $y++) {
				$hg[$y] = "";
				for (my $x = 0; $x < $size; $x++) {
					$hg[$y] .= $grid[$ty*$size + $y][$tx*$size + $x];
				}
			}
			@hg = string_to_halfgrid($rules{halfgrid_to_string(\@hg)});
			if ($tx == 0) {
				push @next_hg, @hg;
			} else {
				for (my $i = 0; $i < $next_size; $i++) {
					$next_hg[$ty * $next_size + $i] .= $hg[$i];
				}
			}
		}
	}
	my $count = 0;
	map { $count += count_active_string($_) } @next_hg;
	@grid = halfgrid_to_grid(\@next_hg);
	if ($iteration == $p1_limit) {
		print "P1: After iteration $iteration, there are $count active cells\n";
	} elsif ($iteration == $p2_limit) {
		print "P2: After iteration $iteration, there are $count active cells\n";
	}
	#print_grid(\@grid);
}

# print grid
sub print_grid {
	my $g_ref = shift;
	my $desc = shift;
	
	$desc = "" unless (defined $desc);
	print "GRID -- $desc\n";
	for (my $y = 0; $y <= $#$g_ref; $y++) {
		my $line = "";
		for (my $x = 0; $x <= $#{$g_ref->[$y]}; $x++) {
			$line .= $g_ref->[$y][$x];
		}
		print "$line\n";
	}
}

sub count_active_string {
	my $line = shift;
	return $line =~ tr/#/#/;
}

sub get_size {
	my $line = shift;
	return sqrt($line =~ tr/#./#./);
}

# Adds flipped & rotated versions of every rule
sub add_missing_rules {
	my $rule_ref = shift;

	foreach my $r (keys %$rule_ref) {
		my $rule = $r;
		foreach my $rot (0 .. 3) {
			my $temp = rotate_string($rule);
			$rule_ref->{$temp} = $rule_ref->{$r} unless (exists $rule_ref->{$temp});
			$rule = $temp;
			$temp = flip_string($rule);
			$rule_ref->{$temp} = $rule_ref->{$r} unless (exists $rule_ref->{$temp});
		}
	}
}

# 90-degree clockwise rotation
sub rotate_string {
	my $str = shift;
	my $size = get_size($str);
	my @g = string_to_grid($str);
	my @gg = ();
	for (my $y = 0; $y < $size; $y ++) {
		$gg[$y] = [];
		for (my $x = 0; $x < $size; $x++) {
			$gg[$y][$x] = $g[$size - $x - 1][$y]
		}
	}
	return grid_to_string(@gg);
}

# horizontal flip
sub flip_string {
	return halfgrid_to_string(map { scalar reverse $_ } string_to_halfgrid($_[0]));
}

# conversions
sub string_to_halfgrid {
	my $str = shift;
	return ($str =~ m|([^/]+)|g);
}

sub string_to_grid {
	return halfgrid_to_grid(string_to_halfgrid($_[0]));
}

sub halfgrid_to_string {
	if (ref $_[0] eq 'ARRAY') {
		return join('/', @{$_[0]});
	} else {
		return join('/', @_);
	}
}

sub halfgrid_to_grid {
	if (ref $_[0] eq 'ARRAY') {
		return map { [ split('', $_) ] } @{$_[0]};
	} else {
		return map { [ split('', $_) ] } @_;
	}
}

sub grid_to_halfgrid {
	return map { join('', @{$_}) } @_;
}

sub grid_to_string {
	return halfgrid_to_string(grid_to_halfgrid(@_));
}

__DATA__
../.. => ##./###/...
#./.. => ..#/##./##.
##/.. => #.#/##./...
.#/#. => ##./###/###
##/#. => ###/.#./#.#
##/## => .#./.#./###
.../.../... => #.../.#.#/..##/#...
#../.../... => .##./#.##/##../##..
.#./.../... => ##../#.../.#.#/###.
##./.../... => .#.#/###./.#.#/.#..
#.#/.../... => .#.#/##../.#../###.
###/.../... => #.##/.##./..##/#.##
.#./#../... => #..#/...#/.###/.##.
##./#../... => .###/..#./#.../####
..#/#../... => ..../.#../#.##/....
#.#/#../... => ..##/.##./.##./....
.##/#../... => ###./#.../#.#./.#.#
###/#../... => .#../##.#/.#.#/..#.
.../.#./... => ####/##../..#./#..#
#../.#./... => ####/#.##/#..#/..#.
.#./.#./... => #.##/.#../.#../.#.#
##./.#./... => ..##/###./..../...#
#.#/.#./... => ...#/.#.#/.#../....
###/.#./... => ..../..#./#..#/##.#
.#./##./... => ##../.#.#/#.#./.#.#
##./##./... => ###./##.#/#.#./.##.
..#/##./... => ..#./.#.#/###./##.#
#.#/##./... => ##.#/.#../#.../#.#.
.##/##./... => ####/..../...#/#.##
###/##./... => ####/.###/.###/.###
.../#.#/... => .#.#/###./.##./.#..
#../#.#/... => #.##/#..#/#..#/##..
.#./#.#/... => ...#/##../..../#..#
##./#.#/... => #..#/.#../##.#/..##
#.#/#.#/... => ..../...#/..#./#..#
###/#.#/... => .##./#..#/...#/.##.
.../###/... => ..../#.##/.#../##..
#../###/... => .#.#/.###/###./#..#
.#./###/... => ...#/.#../###./.###
##./###/... => #..#/###./#.##/.#..
#.#/###/... => .#../##../###./.#.#
###/###/... => ###./.#.#/.##./###.
..#/.../#.. => ...#/#..#/###./.###
#.#/.../#.. => #.#./#.##/#.#./...#
.##/.../#.. => .#.#/#.#./..../#.##
###/.../#.. => ##.#/..##/.#.#/##..
.##/#../#.. => ####/#..#/.#.#/...#
###/#../#.. => .#.#/####/..##/.#.#
..#/.#./#.. => ##.#/.#../#.../.##.
#.#/.#./#.. => #..#/.#.#/#.#./#..#
.##/.#./#.. => #..#/..#./#.../...#
###/.#./#.. => #.##/.#../#.##/##.#
.##/##./#.. => .###/..../#..#/.##.
###/##./#.. => #.../.#.#/..#./.#..
#../..#/#.. => ..../##../#.../##.#
.#./..#/#.. => ..##/...#/###./##..
##./..#/#.. => .#.#/.###/...#/.#.#
#.#/..#/#.. => .#../..../.###/.##.
.##/..#/#.. => #.##/.##./.##./####
###/..#/#.. => #.../.#../..../#...
#../#.#/#.. => .#../.#.#/..##/###.
.#./#.#/#.. => ##.#/#.##/...#/#.##
##./#.#/#.. => .##./####/.#.#/.#..
..#/#.#/#.. => #.##/##.#/..#./.###
#.#/#.#/#.. => ###./.#../###./###.
.##/#.#/#.. => .#../.#../####/##.#
###/#.#/#.. => #.##/##.#/#.../##..
#../.##/#.. => ..#./.###/#.#./..#.
.#./.##/#.. => ##.#/##../..#./#...
##./.##/#.. => #.../..#./#.../.#..
#.#/.##/#.. => ..#./#.##/.##./####
.##/.##/#.. => #.#./.#../####/..##
###/.##/#.. => ...#/#..#/#.../.#..
#../###/#.. => ..../..../##.#/.##.
.#./###/#.. => ..##/..#./##../....
##./###/#.. => .#../..##/..../.#.#
..#/###/#.. => ...#/...#/..#./###.
#.#/###/#.. => ####/##.#/##../..##
.##/###/#.. => ..##/##../#..#/##..
###/###/#.. => ##.#/.##./...#/.#.#
.#./#.#/.#. => ###./####/.##./#..#
##./#.#/.#. => #.../..#./.##./##..
#.#/#.#/.#. => .##./####/##../.#.#
###/#.#/.#. => ##../..../.#.#/....
.#./###/.#. => ..##/##.#/.##./.#.#
##./###/.#. => #.../.#../..##/..#.
#.#/###/.#. => ####/.##./#..#/...#
###/###/.#. => ####/..../##.#/.#.#
#.#/..#/##. => ####/####/####/#...
###/..#/##. => #.#./####/##.#/####
.##/#.#/##. => .###/#.../#.../...#
###/#.#/##. => ..#./#.#./##../##.#
#.#/.##/##. => ###./###./#..#/.###
###/.##/##. => ##.#/..#./##../....
.##/###/##. => ##.#/###./.#.#/.##.
###/###/##. => #.##/.#.#/#..#/.##.
#.#/.../#.# => ..#./####/...#/#.##
###/.../#.# => .##./..#./####/#...
###/#../#.# => .##./##../..../###.
#.#/.#./#.# => #.##/#.##/#.##/#...
###/.#./#.# => ####/#.##/####/.###
###/##./#.# => .#.#/..../.#.#/#.##
#.#/#.#/#.# => ###./#.##/####/.###
###/#.#/#.# => .##./.##./.#.#/....
#.#/###/#.# => ##../..##/...#/.##.
###/###/#.# => .#../#.##/..##/.#..
###/#.#/### => ##.#/..#./...#/.###
###/###/### => ..##/###./.###/.###