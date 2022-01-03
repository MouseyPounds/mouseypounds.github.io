#!/bin/perl -w
#
# https://adventofcode.com/2021/day/19
#

use strict;

print "2021 Day 19\n";
my $input = do { local $/; <DATA> }; # slurp it
my @scanner = ();
my $id;
foreach $_ (split("\n", $input)) {
	if (/scanner (\d+)/) {
		$id = $1;
		$scanner[$id] = { 'beacon' => [], 'dist' => {}, 'pos' => [] };
	} else {
		my @b = /([^,]+)/g;
		push @{$scanner[$id]{'beacon'}}, \@b if (@b);
	}
}

# Calculate relative (squared) distances between all beacons for each scanner.
# Note that this means that if a scanner knows about n beacons, we are storing
# n(n-1)/2 distances. When we later check for scanner overlap the guideline
# of 12 common points must then be extended to 12_C_2 = 66 common distances.
for (my $i = 0; $i <= $#scanner; $i++) {
	for (my $j = 0; $j < $#{$scanner[$i]{'beacon'}}; $j++) {
		for (my $k = $j+1; $k <= $#{$scanner[$i]{'beacon'}}; $k++) {
			next if ($j == $k);
			my $d = ($scanner[$i]{'beacon'}[$j][0] - $scanner[$i]{'beacon'}[$k][0])**2 + ($scanner[$i]{'beacon'}[$j][1] - $scanner[$i]{'beacon'}[$k][1])**2 + ($scanner[$i]{'beacon'}[$j][2] - $scanner[$i]{'beacon'}[$k][2])**2;
			$scanner[$i]{'dist'}{$d} = [$j, $k];
		}
	}
}


# We arbitrarily choose scanner 0 as the origin and align everything to it.
$scanner[0]{'pos'} = [0, 0, 0];
my @scanners_found = (0);
my %scanners_left = map { $_ => undef } (1 .. $#scanner);
my %all_beacons = ();
for (my $b = 0; $b < $#{$scanner[0]{'beacon'}}; $b++) {
	$all_beacons{join(',', @{$scanner[0]{'beacon'}[$b]})} = 1;
}
while (@scanners_found) {
	my $i = shift @scanners_found;
	my @new_finds = ();
	foreach my $j (keys %scanners_left) {
		my $count = 0;
		my $max = 0;
		foreach my $k (keys %{$scanner[$i]{'dist'}}) {
			if (exists $scanner[$j]{'dist'}{$k}) {
				$count++;
				$max = $k if ($k > $max);
			}
		}
		if ($count >= 66) {
			printf "Scanners %2d and %2d overlap (count $count); ", $i, $j;
			push @new_finds, $j;
			# To do the alignment we start with the pair of common points
			# that had the largest relative distance. We now want to match
			# the individual coordinate differences to get the correct
			# orientation. In addition to considering point order we also
			# may have to reorient the new scanner through rotations.
			my $target = join(',', get_diff($scanner[$i],$max));
			#print "> Target: $target from beacons $scanner[$i]{'dist'}{$max}[0] and $scanner[$i]{'dist'}{$max}[1]\n";
			my @diffs = get_diff($scanner[$j],$max);
			my @delta = ();
			my $found = 0;
			foreach my $orientation (0 .. 25) {
				orient(\@diffs, $orientation);
				if ($target eq join(',', @diffs)) {
					$found = 1;
				} elsif ($target eq join(',', map {-$_} @diffs)) {
					$found = -1;
				}
				if ($found) {
					for (my $b = 0; $b <= $#{$scanner[$j]{'beacon'}}; $b++) {
						foreach my $o (1 .. $orientation) { orient($scanner[$j]{'beacon'}[$b], $o); }
					}
					@delta = map { $scanner[$i]{'beacon'}[$scanner[$i]{'dist'}{$max}[0]][$_] -
						$scanner[$j]{'beacon'}[$scanner[$j]{'dist'}{$max}[$found > 0 ? 0 : 1]][$_] } (0..2);					
					printf "Scanner %2d should be aligned with orientation %2d and delta %s\n", $j, $orientation, join(',', @delta);
					for (my $b = 0; $b <= $#{$scanner[$j]{'beacon'}}; $b++) {
						foreach my $c (0 .. 2) {
							$scanner[$j]{'beacon'}[$b][$c] += $delta[$c];
						}
						$all_beacons{join(',', @{$scanner[$j]{'beacon'}[$b]})} = 1;
					}
					print "This scanner had ", scalar(@{$scanner[$j]{'beacon'}})," beacons in range; total unique beacon count is now ", scalar(keys %all_beacons), "\n";
					@{$scanner[$j]{'pos'}} = @delta;
					last;
				}
			}
		}
	}
	foreach my $j (@new_finds) {
		delete $scanners_left{$j};
		push @scanners_found, $j;
	}
}

print "Part 1: There are ", scalar(keys %all_beacons), " total beacons\n";

my $max = 0;
for (my $i = 0; $i < $#scanner; $i++) {
	for (my $j = $i+1; $j <= $#scanner; $j++) {
		my $md = abs($scanner[$i]{'pos'}[0] - $scanner[$j]{'pos'}[0]) +
			abs($scanner[$i]{'pos'}[1] - $scanner[$j]{'pos'}[1]) +
			abs($scanner[$i]{'pos'}[2] - $scanner[$j]{'pos'}[2]);
		$max = $md if ($md > $max);
	}
}
print "Part 2: The largest Manhattan distance between 2 scanners is $max\n";

# tuple of coordinate differences between 2 points which uses
# some really ugly and complicated notation.
sub get_diff {
	my $s = shift;
	my $d = shift;
	
	return map { $s->{'beacon'}[$s->{'dist'}{$d}[1]][$_] - $s->{'beacon'}[$s->{'dist'}{$d}[0]][$_] } (0..2);
}

# Aligns scanners using first as the base
sub align_scanner {
	my $s = shift;
	my $id = shift;
}

# There are 24 different orientations for the scanners and all can be achieved
# via a particular sequence of 90 degree clockwise rotations. This function
# maps an orientation index value to the appropriate rotation sequence.
# index 0 is the original unmofified orientation, then indices 1-23 follow
# the rotation sequence: x,x,x,xy,x,x,x,xy,x,x,x,xy,x,x,x,xz,x,x,x,xzz,x,x,x
# And finally index 24 uses a final z rotation to return to the original.
sub orient {
	my $coords = shift;
	my $index = shift;

	if ($index > 0) {
		rotate($coords, 'x');
		if ($index % 4 == 0) {
			if ($index <= 12) {
				rotate($coords, 'y');
			} elsif ($index == 20) {
				rotate($coords, 'z', 2);
			} else {
				rotate($coords, 'z');							
			}
		}
	}
}

# Does an in-place 90 degree clockwise rotation the specified number of times
# on an array of coordinates.
sub rotate {
	my $coords = shift;
	my $axis = shift;
	my $num = shift; $num = 1 unless (defined $num);
	
	my $temp;
	foreach (1 .. $num) {
		if ($axis eq 'x') {
			$temp = $coords->[1];
			$coords->[1] = -$coords->[2];
			$coords->[2] = $temp;
		} elsif ($axis eq 'y') {
			$temp = $coords->[2];
			$coords->[2] = -$coords->[0];
			$coords->[0] = $temp;
		} else {
			$temp = $coords->[0];
			$coords->[0] = -$coords->[1];
			$coords->[1] = $temp;
		}
	}
}

__DATA__
--- scanner 0 ---
385,-361,405
-852,515,-489
336,928,466
-790,-808,-512
-548,-779,374
-706,-757,-430
-635,-615,362
-630,-729,-519
-963,477,-487
753,808,-605
740,774,-615
352,-454,-949
-773,645,541
405,-470,568
-65,111,-185
325,-343,553
413,943,530
309,881,591
412,-468,-827
-189,61,-45
-818,745,486
-750,754,404
726,706,-708
440,-583,-974
-805,510,-451
-627,-769,479

--- scanner 1 ---
489,-508,-309
568,401,-321
-487,530,543
-550,798,-610
497,-391,-463
-544,497,719
-783,-550,393
652,483,-270
-457,473,658
-490,920,-624
-810,-592,562
615,392,827
-463,-582,-735
536,-627,507
-578,945,-495
-543,-597,-608
492,490,-349
-789,-476,539
25,136,126
410,-403,-299
606,508,668
685,-670,552
586,-672,641
-523,-434,-717
499,373,679
-71,3,20

--- scanner 2 ---
276,399,-624
-840,712,-852
800,526,509
360,500,-664
-742,-523,770
558,-845,613
-649,-591,756
581,-642,-957
418,-882,493
757,497,569
-827,807,-726
536,-696,-873
312,551,-727
-659,795,815
594,-778,-844
20,73,-89
-613,841,682
-752,-489,783
-906,-787,-775
-812,838,-786
749,714,565
-868,-782,-822
-698,801,710
-106,-13,21
-870,-820,-933
401,-902,658

--- scanner 3 ---
-279,-453,-786
838,461,-413
-621,800,-524
-545,369,642
815,-636,457
-646,852,-435
476,666,563
-263,-371,-818
-23,29,-57
795,-763,-737
562,-758,-745
-400,-400,-909
820,489,-355
-770,-662,706
-494,378,536
-783,-706,788
414,449,544
142,-67,-5
777,511,-512
-707,790,-599
727,-826,-761
-745,-749,708
864,-418,466
834,-574,565
-598,377,432
465,603,559

--- scanner 4 ---
-647,440,699
505,898,-901
22,-81,-123
-611,603,609
-611,-658,458
563,-536,468
-937,-323,-520
510,-416,-846
-579,848,-814
449,-429,-811
604,-566,660
-493,838,-739
304,544,210
362,636,230
346,634,324
-921,-405,-552
503,-402,-934
-664,-665,488
-96,70,-18
-800,-352,-429
-716,-709,365
-554,900,-903
469,-553,647
542,904,-903
550,896,-761
-545,628,698

--- scanner 5 ---
-414,774,582
974,-472,-609
93,174,-27
955,-324,-725
657,414,429
-394,-495,508
747,436,571
942,891,-890
850,-432,434
874,-493,347
839,-483,-716
-495,-349,-942
851,965,-859
-392,804,664
118,-17,-162
-544,-421,554
-587,-291,-962
817,-608,377
-368,788,712
-556,-394,529
-503,558,-474
-497,-333,-848
723,963,-893
-691,660,-473
-528,624,-563
566,383,560

--- scanner 6 ---
798,-555,436
-604,-897,-416
619,325,712
753,406,-711
101,-17,170
51,-136,2
-642,272,-722
-599,373,-772
-527,-832,-504
-532,491,451
-612,-748,860
-449,510,549
-622,273,-805
694,-724,-541
-612,-754,931
-645,-675,822
558,443,750
561,470,-749
-511,475,655
-543,-951,-543
794,-653,527
617,274,770
610,-630,-456
619,431,-738
820,-499,546
562,-640,-556

--- scanner 7 ---
479,542,709
-673,-467,238
673,720,-704
-534,704,314
647,672,-922
-614,848,-695
-938,-526,-493
-86,17,-20
-393,704,289
-902,-519,-547
456,-414,286
549,-447,-612
13,91,-150
431,-325,234
575,-453,-692
601,-450,-681
-461,803,242
-564,755,-675
583,646,708
-859,-564,-497
-623,608,-719
532,752,717
370,-489,296
587,600,-778
-628,-327,236
-665,-325,230

--- scanner 8 ---
-743,443,-573
-751,653,-520
744,501,-465
878,700,546
-609,-501,802
647,-549,-451
115,-13,88
658,-552,-477
-330,-588,-682
-659,-402,863
567,-531,513
-320,-513,-596
-454,574,501
670,621,-379
-742,547,-469
-631,-344,845
812,-532,539
-18,-135,33
-268,-424,-621
602,-561,524
-517,570,490
724,728,514
708,707,475
-671,555,439
578,-546,-503
888,573,-405

--- scanner 9 ---
705,-503,604
-335,-443,849
680,-530,616
652,665,746
732,-509,-465
-280,699,-557
570,695,768
-327,-606,-518
-719,425,838
822,647,-472
-309,-523,-623
59,-49,30
585,-560,-504
726,-604,766
-309,-689,-683
-661,388,843
-308,-564,802
742,550,-366
-339,758,-721
594,-516,-507
-251,780,-536
-679,295,781
701,570,-560
522,679,792
-334,-506,795

--- scanner 10 ---
-493,-738,481
626,420,-605
25,-161,-88
-343,582,748
359,747,865
446,-807,-469
867,-703,489
-24,-20,30
285,716,774
814,-714,670
-828,-960,-523
462,-855,-445
-360,728,861
-595,335,-767
-647,-713,543
-520,-690,543
-415,628,729
-821,-795,-424
-520,357,-631
-640,249,-633
-847,-832,-399
590,330,-768
287,750,646
476,-725,-491
836,-572,580
692,331,-580

--- scanner 11 ---
493,603,-940
-843,573,457
-120,-99,-113
-914,573,451
440,-656,-798
-568,747,-793
419,-631,-841
433,565,308
577,489,-919
-529,-859,706
560,504,254
-578,-811,-581
573,-601,565
-419,-837,650
558,-733,481
-551,-733,-618
-446,-660,-591
473,-649,575
-570,601,-753
466,516,-944
-510,-833,552
-805,606,530
470,-635,-955
-644,742,-738
521,488,373

--- scanner 12 ---
531,-441,734
-551,359,-671
-497,443,-626
-411,494,778
-22,154,-76
537,-661,-363
-582,-580,400
588,857,-415
481,-668,-440
-757,-603,-823
-551,-631,512
48,40,58
-373,383,780
833,716,748
459,-711,-401
-406,541,816
-770,-525,-830
912,556,755
388,-410,812
399,-412,604
-415,472,-684
346,849,-411
861,640,837
-748,-667,-765
517,837,-425
-439,-568,520

--- scanner 13 ---
-361,818,515
719,504,826
573,566,-588
596,429,-697
-580,-842,-629
-556,774,553
798,399,836
-568,-722,-486
-447,753,626
640,-405,814
383,-462,-420
494,-464,-458
528,511,-688
-441,-508,484
556,-487,865
-410,-430,341
716,-494,786
-631,-730,-598
711,387,672
-412,-638,352
541,-426,-453
-637,725,-609
53,-73,-91
-712,739,-650
-515,781,-610

--- scanner 14 ---
-432,-626,437
921,-462,-535
-1,130,-22
925,-435,-622
-547,738,358
-450,-589,388
-273,-529,-634
900,-546,-649
662,633,679
576,650,722
-672,796,422
554,-749,369
-549,836,-532
734,601,-537
-494,-681,281
-491,889,443
-476,874,-565
651,-678,480
649,768,710
-470,945,-565
719,675,-396
-327,-402,-573
-392,-490,-650
663,-675,370
774,599,-391

--- scanner 15 ---
-160,0,108
-418,691,790
537,-727,-364
-465,650,-664
-478,657,848
373,734,-508
516,854,-496
656,810,723
592,-666,733
508,821,735
-534,576,763
497,-769,-561
-89,116,-25
-454,442,-666
-647,-669,598
496,-713,-439
606,-789,881
-739,-741,-629
454,817,757
485,742,-445
-569,-584,479
-597,520,-635
-666,-762,-520
-628,-806,-715
-605,-460,611
513,-733,870

--- scanner 16 ---
-499,-680,-324
676,-527,841
286,640,838
661,-549,-468
733,-642,871
-535,-640,710
-506,-738,-350
-87,-100,23
408,626,778
766,-522,-541
-821,857,-492
261,511,750
-140,43,158
-586,738,730
634,-512,-390
709,-703,784
683,775,-342
-826,854,-557
-593,616,765
-685,-714,664
-452,-801,-351
-569,632,629
-910,864,-450
-697,-741,689
793,719,-364
702,621,-368

--- scanner 17 ---
666,-576,-800
336,505,-903
-644,-890,276
-664,574,-931
798,-547,-670
19,-1,-124
-370,-698,-507
660,-796,297
-845,221,630
285,421,-821
738,-846,335
-413,-653,-457
680,702,359
-599,-750,278
809,-545,-878
-334,-691,-453
-653,467,-796
-787,241,538
-803,335,540
851,714,345
364,581,-814
716,-803,374
-607,-892,270
-812,458,-912
-81,-171,5
609,722,349

--- scanner 18 ---
604,810,-643
74,-73,-108
748,-417,-719
-528,-769,-419
-384,-687,330
-596,358,-427
711,846,481
608,-674,447
708,-684,495
-554,585,420
621,-363,-658
660,-482,-642
762,732,477
623,-590,579
-529,-877,-373
-396,611,501
715,835,-670
-430,543,503
-710,-772,-377
-637,429,-568
-533,-752,298
741,689,502
-491,-604,259
-663,387,-590
688,831,-757
-49,74,-11

--- scanner 19 ---
-845,545,-570
638,-861,612
-470,-704,782
-754,456,817
-897,-444,-763
724,-926,723
673,530,886
529,747,-246
-752,565,-620
522,693,-282
-132,-85,77
675,322,897
-907,-498,-737
-795,-424,-671
39,46,-18
-839,537,873
567,743,-325
580,-684,-321
-605,521,-561
518,-751,-274
-602,-580,746
-589,-789,704
529,-882,685
644,400,754
583,-602,-342
-781,571,933

--- scanner 20 ---
685,561,-454
729,-658,-594
-812,-563,560
-375,718,400
20,-185,106
-851,-599,733
-116,-15,73
-858,708,-597
-744,-616,566
-411,630,470
-838,-601,-614
751,-688,520
579,722,370
617,-607,-625
692,595,-656
-852,-526,-573
-914,719,-504
609,-670,-737
-397,549,384
696,573,-602
589,699,440
794,-790,564
704,-633,575
-894,-723,-613
404,696,388
-791,571,-518

--- scanner 21 ---
-855,800,771
655,848,580
-620,-565,-666
-362,515,-925
-109,-88,-80
38,64,-142
694,-445,-719
-800,-678,370
-799,-582,-760
609,867,-679
-476,605,-883
659,-458,-780
751,875,-687
532,-389,606
-382,607,-867
662,771,636
-812,-595,-625
-843,786,600
423,-414,582
749,869,-724
-768,-746,302
-863,796,529
782,-431,-726
705,810,658
-817,-706,349
528,-431,599

--- scanner 22 ---
-859,707,534
-652,-885,854
-885,649,527
734,638,-540
501,555,415
-122,17,38
598,-630,-379
-741,518,-633
729,-614,500
565,-557,-341
685,-515,540
782,-509,590
-759,-895,938
-819,481,-606
565,-551,-270
488,500,449
-717,-888,849
-845,-750,-765
-668,491,-738
593,653,-614
609,576,394
-867,-806,-655
739,693,-616
-858,770,480
-841,-652,-674

--- scanner 23 ---
295,561,-302
-624,-580,-818
704,-540,-519
-713,657,-532
714,619,674
-667,-620,-650
-609,-575,615
320,561,-443
459,-616,632
715,723,570
-772,665,678
-698,545,764
-669,510,-473
-436,-559,675
248,462,-370
-810,-554,-737
723,513,623
-531,-664,620
590,-596,-573
521,-724,589
599,-599,-589
-36,-9,37
-916,593,738
549,-739,636
-689,417,-523

--- scanner 24 ---
-901,-836,-721
501,-702,-661
-147,-65,-100
-778,-809,-775
681,-589,375
-866,453,503
-813,-822,-714
15,-149,-23
419,818,-707
721,291,770
759,460,788
-647,-836,604
693,-672,-620
-438,348,-845
698,-561,354
649,-521,307
411,637,-674
680,-685,-755
-839,610,403
657,487,740
-443,550,-780
-852,553,420
536,703,-760
-448,465,-718
-542,-853,587
-651,-878,611

--- scanner 25 ---
709,-391,-314
465,673,559
550,-429,507
-788,-828,911
-727,-675,-806
431,330,-492
714,-488,448
-94,-82,102
-845,-868,781
22,33,-55
773,-553,-269
-710,-711,-660
-775,421,511
359,593,656
-845,396,-782
529,-400,426
-753,503,541
498,413,-373
-754,-695,-812
-820,433,-756
518,259,-426
-799,373,527
553,552,636
-850,-810,818
-721,268,-763
671,-463,-280

--- scanner 26 ---
35,14,-30
795,712,634
-496,-457,-634
-438,-512,622
911,721,793
-360,477,-699
-600,-533,723
930,605,645
-472,-593,-650
820,758,-304
-541,844,784
773,-381,509
-588,-558,696
-346,465,-870
830,-351,624
902,674,-355
806,-438,685
358,-472,-529
-539,938,768
-350,457,-628
-489,-492,-756
-631,958,826
505,-444,-644
813,598,-383
-28,144,95
383,-384,-658

--- scanner 27 ---
521,-669,538
688,752,-381
-647,-313,847
762,-675,-450
818,723,-513
-36,-76,57
-356,-876,-753
528,-635,740
681,-760,-394
-317,453,-441
517,-647,592
-681,497,766
484,584,600
604,596,457
-613,-439,740
896,754,-370
647,-702,-334
-546,-368,776
69,68,-61
-746,639,788
-356,496,-463
-414,-735,-742
-739,561,775
-377,-781,-809
-279,503,-519
596,533,569

--- scanner 28 ---
720,924,-448
724,810,-397
-385,561,-448
-630,741,525
-596,-473,973
496,-737,551
544,550,600
75,125,153
-631,-586,-569
-624,-588,826
706,-606,-451
695,560,468
-684,-602,948
622,587,573
699,767,-418
-391,415,-522
754,-596,-551
-717,680,501
518,-681,441
-651,-695,-406
622,-512,-536
-711,-713,-554
-364,584,-564
-687,565,558
522,-583,532

--- scanner 29 ---
-823,470,453
-709,512,543
-386,635,-644
788,630,-624
-565,729,-627
647,674,646
803,-625,648
851,-609,672
631,-480,-486
-424,-445,512
721,-595,626
551,-577,-592
-575,-445,-749
-334,-481,349
641,579,-585
88,46,-17
668,573,484
-668,-550,-800
-373,770,-657
-335,-379,537
779,586,-627
672,-500,-680
-545,-498,-756
30,194,-138
693,600,496
-803,528,545

--- scanner 30 ---
-778,664,828
1,-110,-8
244,-560,-500
248,710,-712
-491,-657,-314
301,-464,837
-487,-619,-235
398,724,536
340,865,525
-689,755,-559
-713,515,-550
-541,-612,-271
320,611,-639
242,-420,-545
-834,-734,765
-704,-763,897
263,-514,759
-143,-71,135
361,770,469
-669,662,-609
340,-507,815
236,-418,-508
295,611,-780
-663,691,944
-912,-765,908
-697,749,884

--- scanner 31 ---
940,572,696
-608,-545,562
-507,-439,579
68,30,107
-472,-561,586
-510,332,533
-487,-666,-268
462,-496,450
659,-840,-812
-399,-537,-293
583,-812,-723
805,432,-753
450,-325,436
743,-891,-730
-800,725,-637
758,427,-791
-675,312,516
442,-567,440
827,436,709
-459,-551,-415
-787,691,-627
-26,-37,-36
916,394,-755
-630,369,673
-773,623,-534
856,518,651

--- scanner 32 ---
455,509,-890
-779,-433,511
-465,299,387
443,677,651
-590,309,-781
409,463,-757
536,-899,-640
538,690,777
-562,228,-625
136,-163,-58
750,-510,589
-17,-14,-89
412,662,711
-673,-460,592
724,-950,-584
-437,-561,-789
-498,277,-744
449,548,-785
-512,356,535
-462,283,638
699,-462,652
753,-907,-644
-419,-482,-769
-627,-472,557
-399,-483,-864
851,-426,549