#!/bin/perl -w
#
# https://adventofcode.com/2016/day/17

use strict;
use POSIX;
use Digest::MD5 qw(md5_hex);

print "2016 Day 17\n\n";
my $puzzle = "qzthpkfp";

my $path = do_BFS($puzzle);
print "P1 Solution: Shortest path to found to be $path.\n\n";

$path = do_BFS($puzzle, 1);
print "P2 Solution: Longest path to have a length of " . (length $path) . " moves.\n";

# Since this maze is small and the part 2 description implies it is guaranteed to terminate, we forgo any "visited" checks.
sub do_BFS {
	my $code = shift;
	my $keep_going = shift;
	
	$keep_going = 0 unless (defined $keep_going);

	print "Running BFS on code $code\n";
	
	my $x = 0;
	my $y = 0;
	my $max_x = 3;
	my $max_y = 3;
	my @dirs = ({ 'p' => 'U', 'off' => [0, -1] },
				{ 'p' => 'D', 'off' => [0, 1] },
				{ 'p' => 'L', 'off' => [-1, 0] },
				{ 'p' => 'R', 'off' => [1, 0] });
	my $path = "";
	my @queue = ( {'x'=>$x, 'y'=>$y, 'p'=>$path} );
	
	while (my $p = shift @queue) {
		my $moves = length $p->{'p'};
		if ($p->{'x'} == $max_x and $p->{'y'} == $max_y) {
			$path = $p->{'p'};
			last unless $keep_going;
		} else {
			my $md5 = md5_hex("$code$p->{'p'}");
			print "($p->{'x'},$p->{'y'}) $p->{'p'} MD5:$md5\n" if $debugging;
			foreach my $i (0 .. 3) {
				if (substr($md5, $i, 1) =~ /[bcdef]/i) {
					my $tx = $p->{'x'} + $dirs[$i]{'off'}[0];
					my $ty = $p->{'y'} + $dirs[$i]{'off'}[1];
					my $tp = $p->{'p'} . $dirs[$i]{'p'};
					print "  Evaluating ($tx,$ty) $tp...\n" if $debugging;
					next if ($tx > $max_x or $tx < 0 or $ty > $max_y or $ty < 0);
					print "  QUEUED\n" if $debugging;
					push @queue, {'x'=>$tx, 'y'=>$ty, 'p'=>$tp};
				}
			}
		}
	}
	return $path;
}


__DATA__
