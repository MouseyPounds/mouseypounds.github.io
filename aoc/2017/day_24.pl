#!/bin/perl -w
#
# https://adventofcode.com/2017/day/24
#
# This is quite slow, taking several minutes on an old system.

use strict;
use Storable qw(dclone);
use List::Util qw(sum);

print "2017 Day 24\n";
my $puzzle = do { local $/; <DATA> }; # slurp it
my %component = map { $_, [split("/")] } split("\n", $puzzle);

my $bridge = build_bridge(\%component);
my $str = get_strength($bridge);
print "\nP1: The strongest bridge is $bridge with strength value $str\n";

$bridge = build_bridge(\%component, 1);
$str = get_strength($bridge);
my $len = get_length($bridge);
print "\nP2: The longest bridge is $bridge with length $len and strength value $str\n";

sub build_bridge {
	my $com_ref = shift;
	my $by_length = shift;
	my $bridge = shift;
	my $next_port = shift;
	
	$bridge = "0" unless (defined $bridge);
	$next_port = 0 unless (defined $next_port);
	$by_length = 0 unless (defined $by_length);
	
	my $final_bridge = $bridge;
	
	foreach my $k (keys %$com_ref) {
		if ($com_ref->{$k}[0] == $next_port) {
			my $copy = dclone($com_ref);
			delete $copy->{$k};
			my $result = build_bridge($copy, $by_length, "$bridge - $k", $com_ref->{$k}[1]);
			if ($by_length) {
				$final_bridge = $result if (get_length($result) > get_length($final_bridge) or 
					(get_length($result) == get_length($final_bridge) and get_strength($result) > get_strength($final_bridge)));
			} else {
				$final_bridge = $result if (get_strength($result) > get_strength($final_bridge));
			}
		} elsif ($com_ref->{$k}[1] == $next_port) {
			my $copy = dclone($com_ref);
			delete $copy->{$k};
			my $result = build_bridge($copy, $by_length, "$bridge - $com_ref->{$k}[1]/$com_ref->{$k}[0]", $com_ref->{$k}[0]);
			if ($by_length) {
				$final_bridge = $result if (get_length($result) > get_length($final_bridge) or 
					(get_length($result) == get_length($final_bridge) and get_strength($result) > get_strength($final_bridge)));
			} else {
				$final_bridge = $result if (get_strength($result) > get_strength($final_bridge));
			}
		}
	}
	return $final_bridge;
}

# sum all numbers we find
sub get_strength {
	return sum($_[0] =~ /(\d+)/g);
}

# count the slashes
sub get_length {
	return $_[0] =~ tr|/|/|;
}

__DATA__
14/42
2/3
6/44
4/10
23/49
35/39
46/46
5/29
13/20
33/9
24/50
0/30
9/10
41/44
35/50
44/50
5/11
21/24
7/39
46/31
38/38
22/26
8/9
16/4
23/39
26/5
40/40
29/29
5/20
3/32
42/11
16/14
27/49
36/20
18/39
49/41
16/6
24/46
44/48
36/4
6/6
13/6
42/12
29/41
39/39
9/3
30/2
25/20
15/6
15/23
28/40
8/7
26/23
48/10
28/28
2/13
48/14