#!/bin/perl -w
#
# https://adventofcode.com/2018/day/10

# https://blog.jle.im/entry/shifting-the-stars.html

use strict;
use List::Util qw(max);

print "2018 Day 10\n\n";
my $puzzle = do { local $/; <DATA> }; # slurp it
my @lines = split("\n", $puzzle);
my @stars = ();
foreach my $line (@lines) {
	(my ($x, $y, $vx, $vy)) = $line =~ /position=.\s*(\S+),\s*(\S+). velocity=.\s*(\S+),\s*(\S+)./;
	push @stars, { 'x'=>$x, 'y'=>$y, 'vx'=>$vx, 'vy'=>$vy };
}
my $num_stars = scalar(@stars);

# The assumtion we will use is that the stars will get closer together until they make the message,
# and then they will get further apart. So we want to stop the process when the distance is minimized.
my $max_dist = 200000;

my $t = 0;
while (1) {
	$t++;
	my $min_y = 99999;
	my $max_y = -99999;
	for (my $i = 0; $i < $num_stars; $i++) {
		$stars[$i]->{'x'} += $stars[$i]->{'vx'};
		$stars[$i]->{'y'} += $stars[$i]->{'vy'};
		if ($stars[$i]->{'y'} > $max_y) { $max_y = $stars[$i]->{'y'} };
		if ($stars[$i]->{'y'} < $min_y) { $min_y = $stars[$i]->{'y'} };
	}
	my $dist = $max_y - $min_y;
	last if ($dist > $max_dist);
	$max_dist = $dist;
}

# Roll it back to previous time step
$t--;
my $min_x = 99999;
my $max_x = -99999;
my $min_y = 99999;
my $max_y = -99999;
my %grid = ();
for (my $i = 0; $i < $num_stars; $i++) {
	$stars[$i]->{'x'} -= $stars[$i]->{'vx'};
	$stars[$i]->{'y'} -= $stars[$i]->{'vy'};
	$grid{"$stars[$i]->{'x'},$stars[$i]->{'y'}"} = 1;
	if ($stars[$i]->{'y'} > $max_y) { $max_y = $stars[$i]->{'y'} };
	if ($stars[$i]->{'y'} < $min_y) { $min_y = $stars[$i]->{'y'} };
	if ($stars[$i]->{'x'} > $max_x) { $max_x = $stars[$i]->{'x'} };
	if ($stars[$i]->{'x'} < $min_x) { $min_x = $stars[$i]->{'x'} };
}

print "P1: The stars show the following arrangement:\n";
for (my $y = $min_y; $y <= $max_y; $y++) {
	for (my $x = $min_x; $x <= $max_x; $x++) {
		if (defined $grid{"$x,$y"}) {
			print '#';
		} else {
			print ' ';
		}
	}
	print "\n";
}
print "P2: It took $t seconds for the message to appear.\n";
# Answers are PPNJEENH, 10375

__DATA__
position=< 41710,  52012> velocity=<-4, -5>
position=<-20558, -20616> velocity=< 2,  2>
position=<-41271,  52017> velocity=< 4, -5>
position=< 31365, -41361> velocity=<-3,  4>
position=< 20944,  41633> velocity=<-2, -4>
position=< 10588, -20613> velocity=<-1,  2>
position=<-20510, -10238> velocity=< 2,  1>
position=< 52099,  41642> velocity=<-5, -4>
position=< 10584,  10510> velocity=<-1, -1>
position=< 41734,  20883> velocity=<-4, -2>
position=<-51679, -51742> velocity=< 5,  5>
position=<-20542,  52017> velocity=< 2, -5>
position=< 41732, -10237> velocity=<-4,  1>
position=<-30892,  10517> velocity=< 3, -1>
position=<-51663, -30984> velocity=< 5,  3>
position=< 41733,  10512> velocity=<-4, -1>
position=< 41735, -10238> velocity=<-4,  1>
position=< 20990,  52017> velocity=<-2, -5>
position=< 31370, -10233> velocity=<-3,  1>
position=< 52096,  20883> velocity=<-5, -2>
position=<-51631,  31266> velocity=< 5, -3>
position=< 41720,  41641> velocity=<-4, -4>
position=< 31325, -51739> velocity=<-3,  5>
position=<-30884,  41634> velocity=< 3, -4>
position=<-41257, -51736> velocity=< 4,  5>
position=<-51643,  41634> velocity=< 5, -4>
position=< 41748, -41359> velocity=<-4,  4>
position=<-10130,  52009> velocity=< 1, -5>
position=< 10588,  31261> velocity=<-1, -3>
position=< 10569, -20613> velocity=<-1,  2>
position=<-10130, -51738> velocity=< 1,  5>
position=<-10155,  31258> velocity=< 1, -3>
position=< 10567,  31265> velocity=<-1, -3>
position=<-51675,  20883> velocity=< 5, -2>
position=<-30909,  10515> velocity=< 3, -1>
position=<-10155,  31259> velocity=< 1, -3>
position=< 52108, -30988> velocity=<-5,  3>
position=<-20497,  31260> velocity=< 2, -3>
position=< 10588,  52010> velocity=<-1, -5>
position=< 41708,  20888> velocity=<-4, -2>
position=< 52107, -20611> velocity=<-5,  2>
position=< 10571, -30988> velocity=<-1,  3>
position=< 20975,  20892> velocity=<-2, -2>
position=< 10620,  20889> velocity=<-1, -2>
position=< 52096,  41633> velocity=<-5, -4>
position=< 20984,  10512> velocity=<-2, -1>
position=< 31327,  20887> velocity=<-3, -2>
position=<-30920, -20615> velocity=< 3,  2>
position=< 31370,  10512> velocity=<-3, -1>
position=<-41290,  10512> velocity=< 4, -1>
position=< 52118,  41638> velocity=<-5, -4>
position=< 52083,  31259> velocity=<-5, -3>
position=<-51630, -20612> velocity=< 5,  2>
position=< 41711,  31264> velocity=<-4, -3>
position=<-30912, -10233> velocity=< 3,  1>
position=<-51646, -51742> velocity=< 5,  5>
position=< 52123,  10515> velocity=<-5, -1>
position=< 52120,  31267> velocity=<-5, -3>
position=< 20998, -30983> velocity=<-2,  3>
position=< 10601,  52017> velocity=<-1, -5>
position=<-30933,  52012> velocity=< 3, -5>
position=<-51667, -20617> velocity=< 5,  2>
position=< 20975, -20617> velocity=<-2,  2>
position=<-41308,  41633> velocity=< 4, -4>
position=<-51655, -51739> velocity=< 5,  5>
position=<-30893, -10238> velocity=< 3,  1>
position=<-51630, -10239> velocity=< 5,  1>
position=< 52067,  10513> velocity=<-5, -1>
position=< 41742, -41364> velocity=<-4,  4>
position=<-51683,  52015> velocity=< 5, -5>
position=<-10122,  52009> velocity=< 1, -5>
position=<-20549, -20613> velocity=< 2,  2>
position=<-51627,  31262> velocity=< 5, -3>
position=<-41256,  10515> velocity=< 4, -1>
position=< 20950,  31258> velocity=<-2, -3>
position=< 41697, -10241> velocity=<-4,  1>
position=<-41247,  52013> velocity=< 4, -5>
position=<-20530,  41639> velocity=< 2, -4>
position=<-30893,  20890> velocity=< 3, -2>
position=<-20505,  52015> velocity=< 2, -5>
position=< 41702,  52008> velocity=<-4, -5>
position=<-10179,  41637> velocity=< 1, -4>
position=< 41703,  20887> velocity=<-4, -2>
position=<-10139, -20613> velocity=< 1,  2>
position=< 41748, -51738> velocity=<-4,  5>
position=< 10618, -30986> velocity=<-1,  3>
position=< 31329,  20887> velocity=<-3, -2>
position=<-41259,  31260> velocity=< 4, -3>
position=< 10615,  10513> velocity=<-1, -1>
position=< 31345,  20890> velocity=<-3, -2>
position=< 52070, -20617> velocity=<-5,  2>
position=<-30892, -30992> velocity=< 3,  3>
position=< 41748, -51735> velocity=<-4,  5>
position=<-51650, -20617> velocity=< 5,  2>
position=< 10567,  20883> velocity=<-1, -2>
position=<-30893, -10234> velocity=< 3,  1>
position=<-20554,  20887> velocity=< 2, -2>
position=< 41753, -20614> velocity=<-4,  2>
position=<-51649,  10512> velocity=< 5, -1>
position=< 10594, -20608> velocity=<-1,  2>
position=<-10130,  41635> velocity=< 1, -4>
position=< 41708, -41359> velocity=<-4,  4>
position=<-10127,  41637> velocity=< 1, -4>
position=<-30877, -30989> velocity=< 3,  3>
position=<-20558, -10234> velocity=< 2,  1>
position=< 10567, -30991> velocity=<-1,  3>
position=< 31357,  31267> velocity=<-3, -3>
position=<-51622, -41363> velocity=< 5,  4>
position=<-20522, -41358> velocity=< 2,  4>
position=<-20502,  10513> velocity=< 2, -1>
position=< 41718,  31267> velocity=<-4, -3>
position=<-30928,  52009> velocity=< 3, -5>
position=<-10174,  10508> velocity=< 1, -1>
position=<-20550,  10517> velocity=< 2, -1>
position=< 10607,  10516> velocity=<-1, -1>
position=< 31373, -51734> velocity=<-3,  5>
position=< 41708,  41636> velocity=<-4, -4>
position=< 20978,  31258> velocity=<-2, -3>
position=< 52108,  41642> velocity=<-5, -4>
position=< 10623, -51741> velocity=<-1,  5>
position=<-51675,  52009> velocity=< 5, -5>
position=< 20977, -30983> velocity=<-2,  3>
position=<-41268,  52008> velocity=< 4, -5>
position=< 41713,  31258> velocity=<-4, -3>
position=<-10138, -30983> velocity=< 1,  3>
position=<-51635, -51738> velocity=< 5,  5>
position=< 52120,  52014> velocity=<-5, -5>
position=<-41300,  31265> velocity=< 4, -3>
position=< 41713, -51741> velocity=<-4,  5>
position=<-30905,  20888> velocity=< 3, -2>
position=<-30898,  10508> velocity=< 3, -1>
position=<-20523, -51742> velocity=< 2,  5>
position=< 31336, -20612> velocity=<-3,  2>
position=<-51622,  52012> velocity=< 5, -5>
position=< 10595, -20613> velocity=<-1,  2>
position=<-51635,  52010> velocity=< 5, -5>
position=< 20976, -51742> velocity=<-2,  5>
position=<-20510,  31259> velocity=< 2, -3>
position=< 31320,  41633> velocity=<-3, -4>
position=< 31351, -30992> velocity=<-3,  3>
position=< 41705, -41366> velocity=<-4,  4>
position=< 41741, -30991> velocity=<-4,  3>
position=< 20995, -51735> velocity=<-2,  5>
position=<-51675, -10239> velocity=< 5,  1>
position=< 31349, -30990> velocity=<-3,  3>
position=<-30896, -30992> velocity=< 3,  3>
position=< 20963,  10517> velocity=<-2, -1>
position=< 52128, -20610> velocity=<-5,  2>
position=<-20522, -41358> velocity=< 2,  4>
position=<-51683, -51739> velocity=< 5,  5>
position=< 10610,  52017> velocity=<-1, -5>
position=< 31361,  41633> velocity=<-3, -4>
position=< 31334, -41365> velocity=<-3,  4>
position=< 20958,  52017> velocity=<-2, -5>
position=<-10146, -20617> velocity=< 1,  2>
position=<-51643,  31258> velocity=< 5, -3>
position=<-10155, -30987> velocity=< 1,  3>
position=<-20550, -20611> velocity=< 2,  2>
position=< 31349,  31264> velocity=<-3, -3>
position=< 10620,  20888> velocity=<-1, -2>
position=<-10183, -10236> velocity=< 1,  1>
position=<-10162, -51734> velocity=< 1,  5>
position=<-41266, -10242> velocity=< 4,  1>
position=<-30933,  10510> velocity=< 3, -1>
position=<-30872,  10516> velocity=< 3, -1>
position=< 20976, -10238> velocity=<-2,  1>
position=<-30877, -20614> velocity=< 3,  2>
position=<-41247,  52011> velocity=< 4, -5>
position=<-10151,  10509> velocity=< 1, -1>
position=< 10600, -41363> velocity=<-1,  4>
position=<-20510,  41639> velocity=< 2, -4>
position=<-30914,  31263> velocity=< 3, -3>
position=< 52083,  41637> velocity=<-5, -4>
position=<-10143, -30986> velocity=< 1,  3>
position=<-51675, -41365> velocity=< 5,  4>
position=<-41287,  41640> velocity=< 4, -4>
position=< 41705,  10510> velocity=<-4, -1>
position=< 10595, -41364> velocity=<-1,  4>
position=<-10122,  20891> velocity=< 1, -2>
position=<-51657, -10233> velocity=< 5,  1>
position=< 20970,  20887> velocity=<-2, -2>
position=< 20960,  52011> velocity=<-2, -5>
position=< 10588,  10515> velocity=<-1, -1>
position=< 10607, -20609> velocity=<-1,  2>
position=<-41295,  20884> velocity=< 4, -2>
position=< 52075, -51738> velocity=<-5,  5>
position=< 52115,  20890> velocity=<-5, -2>
position=<-41268,  41635> velocity=< 4, -4>
position=< 41705, -41366> velocity=<-4,  4>
position=<-41287, -51740> velocity=< 4,  5>
position=< 20977, -51738> velocity=<-2,  5>
position=< 20960, -10239> velocity=<-2,  1>
position=<-41265,  31267> velocity=< 4, -3>
position=<-20524, -30983> velocity=< 2,  3>
position=<-30898, -51742> velocity=< 3,  5>
position=<-51666, -30990> velocity=< 5,  3>
position=<-20497, -41366> velocity=< 2,  4>
position=< 10595,  10508> velocity=<-1, -1>
position=< 41752, -20613> velocity=<-4,  2>
position=<-30893,  41633> velocity=< 3, -4>
position=< 41692, -51742> velocity=<-4,  5>
position=< 31338, -30987> velocity=<-3,  3>
position=< 41692, -51741> velocity=<-4,  5>
position=<-10172, -10242> velocity=< 1,  1>
position=< 41728,  31262> velocity=<-4, -3>
position=< 20970, -10234> velocity=<-2,  1>
position=<-30872, -10241> velocity=< 3,  1>
position=< 31359, -10238> velocity=<-3,  1>
position=<-10175, -30992> velocity=< 1,  3>
position=< 41740,  52016> velocity=<-4, -5>
position=< 10599, -20612> velocity=<-1,  2>
position=<-20534, -30985> velocity=< 2,  3>
position=<-30893, -30991> velocity=< 3,  3>
position=< 10568, -10242> velocity=<-1,  1>
position=< 10603,  52017> velocity=<-1, -5>
position=<-20537,  52011> velocity=< 2, -5>
position=<-10174,  20887> velocity=< 1, -2>
position=<-30904, -20617> velocity=< 3,  2>
position=< 20982, -51741> velocity=<-2,  5>
position=< 31373,  20883> velocity=<-3, -2>
position=<-10143,  10514> velocity=< 1, -1>
position=<-41292,  10515> velocity=< 4, -1>
position=< 10599, -30990> velocity=<-1,  3>
position=< 52128,  41637> velocity=<-5, -4>
position=< 52115,  10517> velocity=<-5, -1>
position=<-30893, -51739> velocity=< 3,  5>
position=< 52123, -10237> velocity=<-5,  1>
position=<-10175, -20616> velocity=< 1,  2>
position=< 20974,  20891> velocity=<-2, -2>
position=< 21003,  52014> velocity=<-2, -5>
position=<-41255, -41359> velocity=< 4,  4>
position=<-41268, -30989> velocity=< 4,  3>
position=< 41700, -30989> velocity=<-4,  3>
position=< 10599,  31261> velocity=<-1, -3>
position=< 31343, -51733> velocity=<-3,  5>
position=<-20497, -51735> velocity=< 2,  5>
position=<-20517, -30983> velocity=< 2,  3>
position=< 52102, -20608> velocity=<-5,  2>
position=<-30900,  20883> velocity=< 3, -2>
position=<-51651,  20883> velocity=< 5, -2>
position=<-30898, -41358> velocity=< 3,  4>
position=< 52084, -10241> velocity=<-5,  1>
position=< 41708,  10512> velocity=<-4, -1>
position=<-20556,  52008> velocity=< 2, -5>
position=< 31325, -30986> velocity=<-3,  3>
position=<-30925,  20888> velocity=< 3, -2>
position=<-10151, -20616> velocity=< 1,  2>
position=< 52101, -20617> velocity=<-5,  2>
position=< 52072, -20615> velocity=<-5,  2>
position=< 21003,  10517> velocity=<-2, -1>
position=<-51658, -30983> velocity=< 5,  3>
position=<-30933,  52013> velocity=< 3, -5>
position=<-51630,  10516> velocity=< 5, -1>
position=<-20531, -10233> velocity=< 2,  1>
position=<-30933, -10238> velocity=< 3,  1>
position=< 10584,  10509> velocity=<-1, -1>
position=< 20994,  41641> velocity=<-2, -4>
position=< 52091,  31265> velocity=<-5, -3>
position=<-10130, -51741> velocity=< 1,  5>
position=<-30885,  31261> velocity=< 3, -3>
position=<-41276, -30985> velocity=< 4,  3>
position=< 41751, -20613> velocity=<-4,  2>
position=<-41272, -20613> velocity=< 4,  2>
position=<-30901, -51739> velocity=< 3,  5>
position=<-20501,  31262> velocity=< 2, -3>
position=<-10130, -51742> velocity=< 1,  5>
position=<-41266,  20883> velocity=< 4, -2>
position=<-30877,  10516> velocity=< 3, -1>
position=<-10156, -20617> velocity=< 1,  2>
position=< 10609,  31262> velocity=<-1, -3>
position=< 41695,  41637> velocity=<-4, -4>
position=<-41252,  20892> velocity=< 4, -2>
position=< 52123, -41365> velocity=<-5,  4>
position=< 41740, -30987> velocity=<-4,  3>
position=<-41275,  20892> velocity=< 4, -2>
position=< 20970, -30990> velocity=<-2,  3>
position=< 10569,  52008> velocity=<-1, -5>
position=<-41295, -51739> velocity=< 4,  5>
position=<-20541, -51741> velocity=< 2,  5>
position=<-30921,  20883> velocity=< 3, -2>
position=<-20502,  41639> velocity=< 2, -4>
position=<-30930,  20883> velocity=< 3, -2>
position=< 20975, -10233> velocity=<-2,  1>
position=< 31362, -51742> velocity=<-3,  5>
position=<-20505, -41366> velocity=< 2,  4>
position=< 41753,  52008> velocity=<-4, -5>
position=<-41252, -41361> velocity=< 4,  4>
position=<-41276,  20886> velocity=< 4, -2>
position=<-30892,  31262> velocity=< 3, -3>
position=< 52099, -30986> velocity=<-5,  3>
position=<-30912,  31261> velocity=< 3, -3>
position=< 31365,  41636> velocity=<-3, -4>
position=<-41292, -10242> velocity=< 4,  1>
position=< 10583,  41639> velocity=<-1, -4>
position=< 52123,  10510> velocity=<-5, -1>
position=<-20553,  10509> velocity=< 2, -1>
position=<-41257, -30987> velocity=< 4,  3>
position=< 52083, -41358> velocity=<-5,  4>
position=<-30885, -51741> velocity=< 3,  5>
position=< 41713, -41365> velocity=<-4,  4>
position=< 31360,  31258> velocity=<-3, -3>
position=< 52099, -30992> velocity=<-5,  3>
position=<-41255,  41637> velocity=< 4, -4>
position=<-30932,  20887> velocity=< 3, -2>
position=< 10599,  41633> velocity=<-1, -4>
position=<-51683,  52010> velocity=< 5, -5>
position=< 41745,  31258> velocity=<-4, -3>
position=< 20991,  31260> velocity=<-2, -3>
position=<-30925, -10234> velocity=< 3,  1>
position=< 20974,  20889> velocity=<-2, -2>
position=<-30921, -20617> velocity=< 3,  2>
position=<-30893,  41635> velocity=< 3, -4>
position=< 41736, -41358> velocity=<-4,  4>
position=<-51627, -41358> velocity=< 5,  4>
position=< 10595,  41633> velocity=<-1, -4>
position=<-20498,  20887> velocity=< 2, -2>
position=<-10167,  10510> velocity=< 1, -1>
position=<-51675,  10510> velocity=< 5, -1>
position=<-41287,  10514> velocity=< 4, -1>
position=< 20992, -51738> velocity=<-2,  5>
position=< 31321, -10242> velocity=<-3,  1>
position=< 20990, -51741> velocity=<-2,  5>
position=< 10585, -20613> velocity=<-1,  2>
position=<-10151,  10510> velocity=< 1, -1>
position=<-51643, -10237> velocity=< 5,  1>
position=<-10183,  20892> velocity=< 1, -2>
position=< 31317,  20892> velocity=<-3, -2>
position=<-30905, -10236> velocity=< 3,  1>
position=<-51627,  20885> velocity=< 5, -2>
position=< 31341,  41641> velocity=<-3, -4>
position=< 52109,  52017> velocity=<-5, -5>
position=<-30893,  31265> velocity=< 3, -3>
position=< 41724,  31262> velocity=<-4, -3>
position=<-30933, -51740> velocity=< 3,  5>
position=<-10163, -41360> velocity=< 1,  4>
position=<-20542,  20885> velocity=< 2, -2>
position=< 52123, -41362> velocity=<-5,  4>
position=< 10615,  10508> velocity=<-1, -1>
position=< 52086, -10237> velocity=<-5,  1>
position=< 10588,  41633> velocity=<-1, -4>
position=<-41268, -41358> velocity=< 4,  4>
position=<-41255,  20888> velocity=< 4, -2>
position=< 41753,  20889> velocity=<-4, -2>
position=<-41260, -20611> velocity=< 4,  2>
position=<-41308, -10233> velocity=< 4,  1>
position=<-10162,  10512> velocity=< 1, -1>
position=< 10594, -51733> velocity=<-1,  5>
position=< 20978, -20617> velocity=<-2,  2>
position=< 10576, -41367> velocity=<-1,  4>
position=< 31338, -30988> velocity=<-3,  3>
position=<-30917,  10508> velocity=< 3, -1>
position=< 41732,  20885> velocity=<-4, -2>
position=< 10595,  52010> velocity=<-1, -5>
position=< 52125, -41363> velocity=<-5,  4>
position=< 20974, -20610> velocity=<-2,  2>
position=< 10572,  52011> velocity=<-1, -5>
position=< 20958,  10514> velocity=<-2, -1>
position=<-30885, -10234> velocity=< 3,  1>
position=< 31320,  52012> velocity=<-3, -5>