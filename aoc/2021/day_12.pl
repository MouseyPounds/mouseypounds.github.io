#!/bin/perl -w
#
# https://adventofcode.com/2021/day/12

use strict;

print "2021 Day 12\n";
my $input = do { local $/; <DATA> }; # slurp it
my %connections = ();
foreach my $line (split("\n", $input)) {
	(my ($from, $to)) = $line =~ /(\w+)/g;
	$connections{$from} = [] unless (exists $connections{$from});
	push @{$connections{$from}}, $to;
	$connections{$to} = [] unless (exists $connections{$to});
	push @{$connections{$to}}, $from;
}

print "Part 1: There are ", search_paths(\%connections, 0) ," unique paths.\n";
print "Part 2: There are ", search_paths(\%connections, 1) ," unique paths.\n";

sub is_big {
	my $name = shift;
	return $name =~ /[A-Z]/;
}

sub search_paths {
	my $conn = shift;
	my $max_short = shift;
	
	my $num_paths = 0;
	my @queue = ();
	foreach my $dest (@{$conn->{'start'}}) {
		push @queue, { 'p' => 'start', 'c' => $dest, 'ds' => 0 };
	}
	# Our check for having visited a cave is based on searching the path up to now;
	# We are thus assuming that cave names never contain other cave names.
	while (my $c = shift @queue) {
		my $p = "$c->{'p'},$c->{'c'}";
		#print "Searching path $p\n";
		foreach my $dest (@{$conn->{$c->{'c'}}}) {
			#print "Checking destination $dest\n";
			next if ($dest eq 'start');
			if ($dest eq 'end') {
				#print ">> Finished path $p,$dest\n";
				$num_paths++;
			} elsif (is_big($dest) or ($p !~ /$dest/)) {
				push @queue, { 'p' => "$p", 'c' => $dest, 'ds' => $c->{'ds'} };
			} elsif ($c->{'ds'} < $max_short) {
				push @queue, { 'p' => "$p", 'c' => $dest, 'ds' => ($c->{'ds'}+1) };
			}
		}
	}
	return $num_paths;
}

__DATA__
pq-GX
GX-ah
mj-PI
ey-start
end-PI
YV-mj
ah-iw
te-GX
te-mj
ZM-iw
te-PI
ah-ZM
ey-te
ZM-end
end-mj
te-iw
te-vc
PI-pq
PI-start
pq-ey
PI-iw
ah-ey
pq-iw
pq-start
mj-GX