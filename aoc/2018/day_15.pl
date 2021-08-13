#!/bin/perl -w
#
# https://adventofcode.com/2018/day/15

use strict;
use List::Util qw(sum);

my $debugging = 0;

print "2018 Day 15\n\n";
my $puzzle = do { local $/; <DATA> }; # slurp it
my @lines = split("\n", $puzzle);

my $height = scalar(@lines);
my $width = length($lines[0]);
my $result;
my %grid;
my %units;

$result = run_sim(1);
print "P1: $result\n";
$result = run_sim(2);
print "P2: $result\n";

exit;

sub init {
	my $elf_ap = shift;
	$elf_ap = 3 unless (defined $elf_ap);
	%grid = ();
	%units = ( 'G' => [], 'E' => [] );
	
	for (my $y = 0; $y < $height; $y++) {
		for (my $x = 0; $x < $width; $x++) {
			$grid{"$x,$y"} = substr($lines[$y], $x, 1);
			if ($grid{"$x,$y"} eq 'G') {
				push @{$units{$grid{"$x,$y"}}}, { 'x' => $x, 'y' => $y, 'hp' => 200, 'ap' => 3 };
			} elsif ($grid{"$x,$y"} eq 'E') {
				push @{$units{$grid{"$x,$y"}}}, { 'x' => $x, 'y' => $y, 'hp' => 200, 'ap' => $elf_ap };
			}
		}
	}
}

sub run_sim {
	my $part = shift;

	my $done = 0;
	my $elf_ap = 3;
	
	main: until ($done) {
		$elf_ap++ if ($part == 2);
		init($elf_ap);
		
		print_all("Initial State") if $debugging;

		my $r = 0;
		while (1) {
			$r++;
			my %u = ( 'G' => 0, 'E' => 0 );
			while (1) {
				my ($type, $etype);
				if ($u{'G'} >= scalar(@{$units{'G'}})) {
					if ($u{'E'} >= scalar(@{$units{'E'}})) {
						last;
					} else {
						$type = 'E';
						$etype = 'G';
					}
				} elsif ($u{'E'} >= scalar(@{$units{'E'}})) {
					$type = 'G';
					$etype = 'E';
				} else {
					if (ro_cmp($units{'G'}[$u{'G'}]{'x'}, $units{'G'}[$u{'G'}]{'y'},
						$units{'E'}[$u{'E'}]{'x'}, $units{'E'}[$u{'E'}]{'y'}) < 0) {
						$type = 'G';
						$etype = 'E';
					} else {
						$type = 'E';
						$etype = 'G';
					}
				}
				print "> ${type}[$u{$type}] takes their turn.\n" if $debugging;
				# identify potential enemy targets
				if (scalar(@{$units{$etype}})) {
					unless (type_adjacent($etype, $units{$type}[$u{$type}]{'x'}, $units{$type}[$u{$type}]{'y'})) {
						print ">>  ${type}[$u{$type}] wants to move.\n" if $debugging;
						# First we need to determine where this unit would like to end up
						my %possible_dest = ();
						for (my $e = 0; $e < scalar(@{$units{$etype}}); $e++) {
							my $x = $units{$etype}[$e]{'x'};
							my $y = $units{$etype}[$e]{'y'};

							$possible_dest{($x-1) . ",$y"} = { 'x' => ($x-1), 'y' => $y, 'd' => 999 } if ($grid{($x-1) . ",$y"} eq '.');
							$possible_dest{($x+1) . ",$y"} = { 'x' => ($x+1), 'y' => $y, 'd' => 999 } if ($grid{($x+1) . ",$y"} eq '.');
							$possible_dest{"$x," . ($y-1)} = { 'x' => $x, 'y' => ($y-1), 'd' => 999 } if ($grid{"$x," . ($y-1)} eq '.');
							$possible_dest{"$x," . ($y+1)} = { 'x' => $x, 'y' => ($y+1), 'd' => 999 } if ($grid{"$x," . ($y+1)} eq '.');
						}
						get_all_distance(\%possible_dest, $units{$type}[$u{$type}]{'x'}, $units{$type}[$u{$type}]{'y'});
						my %best = ( 'x' => -1, 'y' => -1, 'd' => 999);
						foreach my $k (keys %possible_dest) {
							if (($possible_dest{$k}{'d'} < $best{'d'}) or
								($possible_dest{$k}{'d'} == $best{'d'} and
								ro_cmp($possible_dest{$k}{'x'}, $possible_dest{$k}{'y'}, $best{'x'}, $best{'y'}) < 0) ){
								$best{'x'} = $possible_dest{$k}{'x'};
								$best{'y'} = $possible_dest{$k}{'y'};
								$best{'d'} = $possible_dest{$k}{'d'};
							}
						}
						print ">>  Best destination is ($best{'x'},$best{'y'}) with dist $best{'d'}\n" if $debugging;
						if ($best{'x'} > -1) {
							# Now we need to determine where this unit will move this round; the overall logic is very similar to the
							# previous decision, but we have reversed our focus.
							%possible_dest = ();
							my $x = $units{$type}[$u{$type}]{'x'};
							my $y = $units{$type}[$u{$type}]{'y'};

							$possible_dest{($x-1) . ",$y"} = { 'x' => ($x-1), 'y' => $y, 'd' => 999 } if ($grid{($x-1) . ",$y"} eq '.');
							$possible_dest{($x+1) . ",$y"} = { 'x' => ($x+1), 'y' => $y, 'd' => 999 } if ($grid{($x+1) . ",$y"} eq '.');
							$possible_dest{"$x," . ($y-1)} = { 'x' => $x, 'y' => ($y-1), 'd' => 999 } if ($grid{"$x," . ($y-1)} eq '.');
							$possible_dest{"$x," . ($y+1)} = { 'x' => $x, 'y' => ($y+1), 'd' => 999 } if ($grid{"$x," . ($y+1)} eq '.');
							get_all_distance(\%possible_dest, $best{'x'}, $best{'y'});
							%best = ( 'x' => -1, 'y' => -1, 'd' => 999);
							foreach my $k (keys %possible_dest) {
								if (($possible_dest{$k}{'d'} < $best{'d'}) or
									($possible_dest{$k}{'d'} == $best{'d'} and
									ro_cmp($possible_dest{$k}{'x'}, $possible_dest{$k}{'y'}, $best{'x'}, $best{'y'}) < 0) ){
									$best{'x'} = $possible_dest{$k}{'x'};
									$best{'y'} = $possible_dest{$k}{'y'};
									$best{'d'} = $possible_dest{$k}{'d'};
								}
							}
							print ">>  Best move is ($best{'x'},$best{'y'}) on path of dist $best{'d'}.\n" if $debugging;
							if ($best{'x'} > -1) {
								$grid{"$x,$y"} = '.';
								$units{$type}[$u{$type}]{'x'} = $best{'x'};
								$units{$type}[$u{$type}]{'y'} = $best{'y'};
								$grid{"$best{'x'},$best{'y'}"} = $type;
							print ">>  ${type}[$u{$type}] moves to ($best{'x'},$best{'y'})\n" if $debugging;
							}
						}
					}
					if (type_adjacent($etype, $units{$type}[$u{$type}]{'x'}, $units{$type}[$u{$type}]{'y'})) {
						# Try to attack. We are doing this a little bit backwards and looping over all enemies since we'd need to
						# get their indices or hp values later anyway.
						my $target = -1;
						for (my $e = 0; $e < scalar(@{$units{$etype}}); $e++) {
							my $dx = abs($units{$etype}[$e]{'x'} - $units{$type}[$u{$type}]{'x'});
							my $dy = abs($units{$etype}[$e]{'y'} - $units{$type}[$u{$type}]{'y'});
							if ( ($dx == 1 and $dy == 0) or ($dx == 0 and $dy == 1) ) {
								# make this our target if we don't have a target yet, or it has lower hp, or it has == hp and better RO
								if ( ($target < 0) or ($units{$etype}[$e]{'hp'} < $units{$etype}[$target]{'hp'}) or
									 ( ($units{$etype}[$e]{'hp'} == $units{$etype}[$target]{'hp'}) and
										(ro_cmp($units{$etype}[$e]{'x'},$units{$etype}[$e]{'y'},
										$units{$etype}[$target]{'x'},$units{$etype}[$target]{'y'}) < 0) ) ) {
									print ">>  Switching target from ${etype}[$target] to ${etype}[$e]\n" if $debugging;
									$target = $e;
								}
							}
						}
						die "${type}[$u{$type}] failed to find combat target" if ($target < 0);
						print ">>  ${type}[$u{$type}] attacks ${etype}[$target]\n" if $debugging;
						$units{$etype}[$target]{'hp'} -= $units{$type}[$u{$type}]{'ap'};
						if ($units{$etype}[$target]{'hp'} <= 0) {
							print ">>  ${etype}[$target] was killed; indices may change\n" if $debugging;
							next main if ($part == 2 and $etype eq 'E');
							$grid{"$units{$etype}[$target]{'x'},$units{$etype}[$target]{'y'}"} = '.';
							splice(@{$units{$etype}}, $target, 1);
							$u{$etype}-- if ($target < $u{$etype});
						}
					}
				} else {
					print ">>  There are no remaining $etype units, so $type wins.\n" if $debugging;
					my $score = 0;
					for (my $i = 0; $i < scalar(@{$units{$type}}); $i++) {
						$score += $units{$type}[$i]{'hp'};
					}
					$score *= ($r-1);
					if ($type eq 'E' or $part == 1) {
						return ("Combat resolves in favor of $type during round $r with a score of $score. Elf AP was $elf_ap.");
					} else {
						next main;
					}
				}
				$u{$type}++;
			}
			# Now we must reorder the unit lists because RO order may have changed
			@{$units{'G'}} = sort {ro_cmp($a->{'x'},$a->{'y'},$b->{'x'},$b->{'y'})} @{$units{'G'}};
			@{$units{'E'}} = sort {ro_cmp($a->{'x'},$a->{'y'},$b->{'x'},$b->{'y'})} @{$units{'E'}};
			print_all("End of Round $r") if $debugging;
		}
	}
}

# BFS search which calculates shortest path to all elements of the destinations hash.
sub get_all_distance {
	my $destinations = shift;
	my $ox = shift;
	my $oy = shift;

	my %visited = ();
	my @queue = ();
	push @queue, {'x'=>$ox, 'y'=>$oy, 'd'=>0};
	$visited{"$ox,$oy"} = 1;
	my $dist = 0;

	my %left_to_find = map { $_ => 1 } (keys %$destinations);

	while (my $p = shift @queue) {
		my $key = "$p->{'x'},$p->{'y'}";
		if (exists $left_to_find{$key}) {
			$destinations->{$key}{'d'} = $p->{'d'};
			delete $left_to_find{$key};
			last unless scalar(keys %left_to_find);
		}
		$dist = $p->{'d'} + 1;
		foreach my $offset (-1, 1) {
			my $tx = $p->{'x'} + $offset;
			if (exists $grid{"$tx,$p->{'y'}"} and $grid{"$tx,$p->{'y'}"} eq '.' and not exists $visited{"$tx,$p->{'y'}"}) {
				push @queue, {'x'=>$tx, 'y'=>$p->{'y'}, 'd'=>$dist};
				$visited{"$tx,$p->{'y'}"} = 1;
			}
			my $ty = $p->{'y'} + $offset;
			if (exists $grid{"$p->{'x'},$ty"} and $grid{"$p->{'x'},$ty"} eq '.' and not exists $visited{"$p->{'x'},$ty"}) {
				push @queue, {'x'=>$p->{'x'}, 'y'=>$ty, 'd'=>$dist};
				$visited{"$p->{'x'},$ty"} = 1;
			}
		}
	}
}

sub type_adjacent {
	my $t = shift;
	my $x = shift;
	my $y = shift;

	return ( ($grid{($x-1) . ",$y"} eq $t) or ($grid{($x+1) . ",$y"} eq $t) or
		($grid{"$x," . ($y-1)} eq $t) or ($grid{"$x," . ($y+1)} eq $t) );
}

sub print_all {
	my $title = shift;
	my %u = ( 'G' => 0, 'E' => 0 );

	print "$title\n";
	for (my $y = 0; $y < $height; $y++) {
		my $line = "";
		my $extra = "";
		for (my $x = 0; $x < $width; $x++) {
			$line .= $grid{"$x,$y"};
			if ( $grid{"$x,$y"} eq 'G' or $grid{"$x,$y"} eq 'E') {
				$extra .= qq(  ${grid{"$x,$y"}}[$u{$grid{"$x,$y"}}]($units{$grid{"$x,$y"}}[$u{$grid{"$x,$y"}}]{'x'},$units{$grid{"$x,$y"}}[$u{$grid{"$x,$y"}}]{'y'}):$units{$grid{"$x,$y"}}[$u{$grid{"$x,$y"}}]{'hp'});
				$u{$grid{"$x,$y"}}++;
			}
		}
		print "$line$extra\n";
	}
	print "\n";
}

sub ro_cmp_str {
	(my ($ax, $ay)) = $_[0] =~ /^(.+),(.+)$/;
	(my ($bx, $by)) = $_[1] =~ /^(.+),(.+)$/;
	return ( ($ay <=> $by) or ($ax <=> $bx) );
}

sub ro_cmp {
	# arguments in order $ax, $ay, $bx, $by
	return ( ($_[1] <=> $_[3]) or ($_[0] <=> $_[2]) );
}

# A useful set of test cases: https://github.com/ShaneMcC/aoc-2018/tree/master/15/tests

__DATA__
################################
#############..#################
#############..#.###############
############G..G.###############
#############....###############
##############.#...#############
################..##############
#############G.##..#..##########
#############.##.......#..######
#######.####.G##.......##.######
######..####.G.......#.##.######
#####.....#..GG....G......######
####..###.....#####.......######
####.........#######..E.G..#####
####.G..G...#########....E.#####
#####....G.G#########.#...######
###........G#########....#######
##..#.......#########....##.E.##
##.#........#########.#####...##
#............#######..#.......##
#.G...........#####........E..##
#....G........G..G.............#
#..................E#...E...E..#
#....#...##...G...E..........###
#..###...####..........G###E.###
#.###########..E.......#########
#.###############.......########
#################.......########
##################....#..#######
##################..####.#######
#################..#####.#######
################################
