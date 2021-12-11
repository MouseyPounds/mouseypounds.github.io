#!/bin/perl -w
#
# https://adventofcode.com/2021/day/11

use strict;

print "2021 Day 11\n";
my $input = do { local $/; <DATA> }; # slurp it
my $x;
my $y = 0;
my %octo = ();
foreach my $line (split("\n", $input)) {
	$x = 0;
	foreach my $c (split('', $line)) {
		$octo{"$x,$y"} = $c;
		$x++;
	}
	$y++;
}

my $total_octo = $x*$y;
my $total_flash = 0;
my $p1_steps = 100;
my $max_steps = 1000;
for (my $step = 1; $step <= $max_steps; $step++) {
	my @to_flash = ();
	my %has_flashed = ();
	my $step_flash = 0;
	for (my $j = 0; $j < $y; $j++) {
		for (my $i = 0; $i < $x; $i++) {
			$octo{"$i,$j"}++;
			if ($octo{"$i,$j"} > 9) {
				push @to_flash, { 'x'=>$i, 'y'=>$j };
				$has_flashed{"$i,$j"} = 1;
			}
		}
	}
	while (my $f = shift(@to_flash)) {
#		print qq(Octo ($f->{'x'},$f->{'y'}) with energy $octo{"$f->{'x'},$f->{'y'}"} flashing\n) if ($step == 7);
		for (my $j = $f->{'y'}-1; $j <= $f->{'y'}+1; $j++) {
			for (my $i = $f->{'x'}-1; $i <= $f->{'x'}+1; $i++) {
				next if ($i == $f->{'x'} and $j == $f->{'y'});
				if (exists $octo{"$i,$j"}) {
#					print qq(  Triggers Octo ($i,$j) with energy $octo{"$i,$j"}) if ($step == 7);
					$octo{"$i,$j"}++;
					if ($octo{"$i,$j"} > 9 and not exists $has_flashed{"$i,$j"}) {
						push @to_flash, { 'x'=>$i, 'y'=>$j };
						$has_flashed{"$i,$j"} = 1;
					}	
#					print qq( -> $octo{"$i,$j"} [), scalar(@to_flash), "]\n" if ($step == 7);
				}
			}
		}
		$step_flash++;
	}
	foreach my $k (keys %has_flashed) {
		$octo{$k} = 0;
	}
	$total_flash += $step_flash;
	print "Part 1: After $p1_steps steps, there were $total_flash total flashes\n" if ($step == $p1_steps);
	#dump_grid("\nAfter step $step ($total_flash total flashes)");
	if ($step_flash >= $total_octo) {
		print "Part 2: After $step steps, all octopi flash in sync\n";
		last;
	}
	
}



sub dump_grid {
	my $title = shift;
	print "$title\n";
	for (my $j = 0; $j <= 9; $j++) {
		my $line = "";
		for (my $i = 0; $i <= 9; $i++) {
			$line .= $octo{"$i,$j"};
		}
		print "$line\n";
	}
}
__DATA__
7777838353
2217272478
3355318645
2242618113
7182468666
5441641111
4773862364
5717125521
7542127721
4576678341