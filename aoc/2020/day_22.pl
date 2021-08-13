#!/bin/perl -w
#
# https://adventofcode.com/2020/day/22

use strict;
use List::Util qw(max);

print "2020 Day 22\n\n";
my $puzzle = do { local $/; <DATA> }; # slurp it
my @lines = split("\n", $puzzle);

my %deck = ();
parse_input (\@lines, \%deck);
my $winner = play_game(\%deck);
my $score = calc_score(\%deck, $winner);
print "P1: Player $winner wins normal Combat with a score of $score.\n";

parse_input (\@lines, \%deck);
$winner = play_game(\%deck, 1);
$score = calc_score(\%deck, $winner);
print "P2: Player $winner wins Recursive Combat with a score of $score.\n";

sub play_game {
	my $deck_ref = shift;
	my $recursive = shift;
	
	$recursive = 0 unless (defined $recursive);
	my %state = ();

	my $round = 0;
	while (scalar(@{$deck_ref->{1}}) and scalar(@{$deck_ref->{2}})) {
		$round++;
		my $round_winner = 0;
		my $state_1 = "1:" . join(',', @{$deck_ref->{1}});
		my $state_2 = "2:" . join(',', @{$deck_ref->{2}});
		return 1 if (exists $state{$state_1} or exists $state{$state_2});
		$state{$state_1} = "";
		$state{$state_2} = "";
		my $p1_card = shift @{$deck_ref->{1}};
		my $p2_card = shift @{$deck_ref->{2}};
		print "Round $round\n -Player 1 deals $p1_card with deck (", join(', ',  @{$deck_ref->{1}}), ")\n";
		print " -Player 2 deals $p2_card with deck (", join(', ',  @{$deck_ref->{2}}), ")\n";
		if ( (not $recursive) or (scalar(@{$deck_ref->{1}}) < $p1_card) or (scalar(@{$deck_ref->{2}}) < $p2_card) ) {
			$round_winner = ($p1_card > $p2_card) ? 1 : 2;
		} else {
			my @c1 = @{$deck_ref->{1}}[0 .. ($p1_card - 1)];
			my @c2 = @{$deck_ref->{2}}[0 .. ($p2_card - 1)];
			my %copy = ( 1 => \@c1, 2 => \@c2 );
			if (max(@c1) > max(@c2)) {
				$round_winner = 1;
				print " > Short-circuiting sub-game with player 1 win\n";
			} else {
				print " > Launching sub-game\n";
				$round_winner = play_game(\%copy, $recursive);
			}
		}
		if ($round_winner == 1) {
			push @{$deck_ref->{1}}, $p1_card, $p2_card;
		} else {
			push @{$deck_ref->{2}}, $p2_card, $p1_card;
		}
	}
	return (scalar(@{$deck_ref->{1}})) ? 1 : 2;
}

sub calc_score {
	my $deck_ref = shift;
	my $which = shift;

	my $score = 0;
	for (my $i = $#{$deck_ref->{$which}}; $i >= 0; $i--) {
		$score += $deck_ref->{$which}[$i] * ($#{$deck_ref->{$which}} + 1 - $i);
	}
	return $score;
}

sub parse_input {
	my $lines = shift;
	my $deck_ref = shift;

	my $which = 0;
	foreach my $line (@$lines) {
		if ($line =~ /^Player (\d+)/) {
			$which = $1;
			$deck_ref->{$which} = [];
		} elsif ($line =~ /^\d+/) {
			push @{$deck_ref->{$which}}, $line;
		}
	}
}

__DATA__
Player 1:
48
23
9
34
37
36
40
26
49
7
12
20
6
45
14
42
18
31
39
47
44
15
43
10
35

Player 2:
13
19
21
32
27
16
11
29
41
46
33
1
30
22
38
5
17
4
50
2
3
28
8
25
24