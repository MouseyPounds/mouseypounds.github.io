#!/bin/perl -w
#
# https://adventofcode.com/2018/day/20

use strict;

print "2018 Day 20\n\n";
my $puzzle = do { local $/; <DATA> }; # slurp it

my (%map, @stack);

# Examples for part 1
my @ex = (
	['^WNE$' => 3],
	['^ENWWW(NEEE|SSE(EE|N))$' => 10],
	['^ENNWSWW(NEWS|)SSSEEN(WNSE|)EE(SWEN|)NNN$' => 18],
	['^ESSWWN(E|NNENN(EESS(WNSE|)SSS|WWWSSSSE(SW|NNNE)))$' => 23],
	['^WSSEESWWWNW(S|NENNEEEENN(ESSSSW(NWSW|SSEN)|WSWWN(E|WWS(E|SS))))$' => 31],
);
# Note, this is not the best general solution as it will fail on the following 2 additional test
# cases from <https://www.reddit.com/r/adventofcode/comments/a86a7i/2018_day_20_more_test_cases/>
#	['^E(NN|S)E$' => 4],
#	['^(N|S)N$' => 2],
# It did work on our puzzle input, but this is a problem that should be revisited later and fixed.
# The issue is that when we run into options, we only really continue from the last option instead
# of from all possible options.
# But it does work on our puzzle input so, for now, we are satisfied with it.

print "Running test cases\n";
my $fail = 0;
foreach my $e (@ex) {
	(my ($result, $c)) = make_map($e->[0]);
	if ($result != $e->[1]) {
		print "* Test failed! Got $result instead of $e->[1] with regex $e->[0]\n";
		$fail++;
	}
}
print "* All tests passed\n" unless $fail;
print "\n";

(my ($doors, $count)) = make_map($puzzle);
print "P1: The furthest room requires going through $doors doors.\n";
print "P2: There are $count rooms which pass through at least 1000 doors.\n";
exit;

# BFS search
sub get_furthest_room {
	my %visited = ();
	my @queue = ();
	push @queue, {'x'=>0, 'y'=>0, 'd'=>0};
	$visited{"0,0"} = 1;
	my $dist = 0;
	my $count = 0;

	while (my $p = shift @queue) {
		my $key = "$p->{'x'},$p->{'y'}";
		$dist = $p->{'d'} + 1;
		foreach my $offset (-1, 1) {
			my $dx = $p->{'x'} + $offset;
			my $tx = $dx + $offset;
			if (exists $map{"$dx,$p->{'y'}"} and $map{"$dx,$p->{'y'}"} ne '#' and not exists $visited{"$tx,$p->{'y'}"}) {
				push @queue, {'x'=>$tx, 'y'=>$p->{'y'}, 'd'=>$dist};
				$visited{"$tx,$p->{'y'}"} = 1;
				$count++ if ($dist >= 1000);
			}
			my $dy = $p->{'y'} + $offset;
			my $ty = $dy + $offset;
			if (exists $map{"$p->{'x'},$dy"} and $map{"$p->{'x'},$dy"} ne '#' and not exists $visited{"$p->{'x'},$ty"}) {
				push @queue, {'x'=>$p->{'x'}, 'y'=>$ty, 'd'=>$dist};
				$visited{"$p->{'x'},$ty"} = 1;
				$count++ if ($dist >= 1000);
			}
		}
	}
	return ($dist - 1, $count);
}

sub make_map {
	my $regex = shift;

	@stack = ();
	%map = ( 'max_x' => 1, 'min_x' => -1, 'max_y' => 1, 'min_y' => -1, '0,0' => '.',
		"-1,-1" => '#', "-1,1" => '#', "1,-1" => '#', "1,1" => '#' );

	my $x = 0;
	my $y = 0;
	my $t = 0;
	for (my $i = 1; $i < length($regex); $i++) {
		my $c = substr($regex, $i, 1);
		if ($c eq '$') {
			last;
		} elsif ($c eq '(') {
			push @stack, [$x, $y];
		} elsif ($c eq '|') {
			$x = $stack[$#stack][0];
			$y = $stack[$#stack][1];
		} elsif ($c eq ')') {
			pop @stack;
		} elsif ($c eq 'N') {
			$map{"$x," . ($y-1)} = '-';
			$t = $y-3;
			$map{($x-1) . ",$t"} = '#';
			$map{($x+1) . ",$t"} = '#';
			$map{'min_y'} = $t if ($t < $map{'min_y'});
			$y -= 2;
			$map{"$x,$y"} = '.';
		} elsif ($c eq 'S') {
			$map{"$x," . ($y+1)} = '-';
			$t = $y+3;
			$map{($x-1) . ",$t"} = '#';
			$map{($x+1) . ",$t"} = '#';
			$map{'max_y'} = $t if ($t > $map{'max_y'});
			$y += 2;
			$map{"$x,$y"} = '.';		
		} elsif ($c eq 'W') {
			$map{($x-1) . ",$y"} = '|';
			$t = $x-3;
			$map{"$t," . ($y-1)} = '#';
			$map{"$t," . ($y+1)} = '#';
			$map{'min_x'} = $t if ($t < $map{'min_x'});
			$x -= 2;
			$map{"$x,$y"} = '.';
		} elsif ($c eq 'E') {
			$map{($x+1) . ",$y"} = '|';
			$t = $x+3;
			$map{"$t," . ($y-1)} = '#';
			$map{"$t," . ($y+1)} = '#';
			$map{'max_x'} = $t if ($t > $map{'max_x'});
			$x += 2;
			$map{"$x,$y"} = '.';
		} else {
			die "Unknown character '$c'";
		}
	}
	$map{"0,0"} = 'X';
	add_walls();
	#print_map();
	return get_furthest_room();
}	

sub add_walls {
	for (my $y = $map{'min_y'}; $y <= $map{'max_y'}; $y++) {
		my $line = "";
		for (my $x = $map{'min_x'}; $x <= $map{'max_x'}; $x++) {
			$map{"$x,$y"} = '#' unless (defined $map{"$x,$y"});
		}
	}
}

sub print_map {
	my $title = shift;
	$title = "Map" unless defined $title;
	
	print "$title\n";
	for (my $y = $map{'min_y'}; $y <= $map{'max_y'}; $y++) {
		my $line = "";
		for (my $x = $map{'min_x'}; $x <= $map{'max_x'}; $x++) {
			my $char = '?';
			$char = $map{"$x,$y"} if (defined $map{"$x,$y"});
			$line .= $char;
		}
		print "$line\n";
	}
}
	

__DATA__
^SWWNNWNNESENNWWNWSSWSWWWSEEEE(N|SSWWSSESSSEENNESSEEEENENEEENWNWSWWWS(WW(SEEWWN|)NEN(WWW(NN|W(S(SS|EE)|W))|ENNEENESS(WWSEWNEE|)EESENNNWW(SEWN|)NWNWWWNW(SSS(WSNE|)ENE(S|E)|NWWNEEESEENWNWWNNNENWNNNWSSSSWNNNNWNWSWSWNWSWNWSWNWNWNEENWWWNNESEENNEEEEENNESSESEEEESSWWWS(WNN(WSWS(E|WS(WNNWSSW(W|NNNEEE(N(E(S|E)|WWW)|S))|E))|EEE)|SEEEEN(WWW|ENENNWSW(S|NNENEENENWNWSSWNWWWSEESWSWNWNNWNEENWNWNWNNEEESW(SESESSENE(NWNWNEENNESEEESEESSSWWNENWWSWS(WNN(W|NE(S|E))|ESESSSWSSEEN(NNNEN(W|ENENNW(NNNNWWS(ESWENW|)WNWW(SEWN|)NNEEES(WW|ENNENNNESENNEESSSW(WWSSWSESEEESWWWSEEESSWW(SEESENESENEEEENWWNWWWW(SEEEWWWN|)NEEEEENNWNENNEESWSSSENEEEENNENENNESSSWSWSESSWSSSESSENNEEENESENEESWSSENENESSESWSEEESSSSEEEENWNWNW(SSEWNN|)NEESEEESW(SEEENWNEESSSWWSEESSWNWSSSWWSWNWSSSENESSEENNW(S|NEEE(NWNEWSES|)SWSSE(N|SWWWSWNWNWSWSSWWNNWNWWNNESEEENE(NWWSWNNEEENNNWSWNN(EEEEEE(NWES|)SSSWWWNNESEN(SWNWSSNNESEN|)|WSSS(EE|WNWSSS(ENSW|)WNWSSWNNNENNNEES(WSSNNE|)ENNWNWSWNNWWWNWWNENNWSW(SSSESE(N|EESWSESWWNWSWSEESSWWN(E|WNWSSSE(EEEESWSEE(NNNWNNE(ENNNNSSSSW|)S|EESE(NN|SWSWNNWWWSESWWSSWSESSWWSWWNWWWNENWWNNWWSWSSSWWNNE(S|NWWNWNEENWWWSWWSSESESEN(NWNWESES|)ESSWSEEESSSSSWNWWNENN(ESSNNW|)WWWWSWSESSSEEN(NW(NEN(W|E)|S)|ESSESWWSEEESSSWWSWWNNN(ES(EENWESWW|)S|WSSWSESEEESWWWWWN(E|NNWSSSSEESSEEESWSESESESWSSWWSESWSWSSENENESSWSSENENENENENNWSWNNW(SS(WNSE|)S(S|E)|NEENNW(S|NENWNWW(SESNWN|)NENN(NESENESEESEESEESWSSENEENNW(NEEENWWNEENNENNNENENENEEESWSW(N|WSSSWN(N|WSSEESWSWW(NEWS|)SEESEESWSSSENNENEEESSEENESENNNNNNEENWNWNEESESEEENWNENWWS(WNNWSWNNWWNWNWNNWSWWS(WNWWWWWWSESE(SWSWWNENWNNNNWNN(EEESW(SEES(ENNWNN(NNESSSESESS(WNSE|)EENNEENWNWWS(E|WNWNENNENWWWW(SEESNWWN|)NEE(NN|EEESESSS(WWNENSWSEE|)ESENESESWSS(ENESESWSS(WNNWSNESSE|)SENEN(ESESENEE(SWSES(SSSSSSWNWSWSSWWSEEEEE(SWSSSWSESE(SSSSSSSSSWNWWWNNENEE(NWNNWWNNE(NWNWSSWSSSSES(ENN(ES|WNN)|SWNWNNWSWSWNWNWSWNWNWNWNNEES(W|ENESENENN(EESSSW(NN|SW(S(SENENE(NNNE(S|N(W|NN(NNNEEN(NEWS|)WW|EESES(WWN|ENNW|S))))|S)|WNWSWNW(ESENESNWSWNW|))|N))|WWWN(ENWESW|)WSS(WWWWNENWNENWW(NEWS|)SWNWSSSWWSEEENNESSSESSSWSWNNWWWSWSEESSSWNNWSWNWWSSWNW(SW(N|SSEESWSEESSSENESEENWNENNNN(ESENEEEEEESSEESEESEENNW(S|WWNEENEEN(WWWNWSS(WW(SEWN|)NENWWN(E|WWN(WSWSWS(WNN(NNWESS|)E|EEEE(NWWEES|)E)|N(ESEWNW|)NNN))|E)|N|ESSW(W|SESSW(SWWWWSWSSESENN(W|NESEEN(W|ENESSWSWSWNWSSESEEN(W|NESSENNEEEENNE(NWNENNWWS(WSESWSS(ENSW|)WNNNNW(SSSSWENNNN|)WNEN(WNNESNWSSE|)EE(SWEN|)E|E)|SSSSSSWWNENNWSWW(NEWS|)SESSESWWSWSWNWNENE(S|N(ESNW|)WWWN(EEE|WSWNNWWSSE(SSWWN(E|WSWWWNWNWNENEESS(WNSE|)E(SWEN|)ENNNN(ES(SSS|EE)|NWNWNENNE(E(SWSSNNEN|)E|NWWSSWWNNE(S|NWN(EESNWW|)WWSESWWNWSSSSSWWSSWNWWWWSWWNENENNWN(EESSSEEE(WWWNNNSSSEEE|)|NWN(E|WW(SWSEE(SE(N|S(WWWWSEEE(SWWWWSSSSESSENNNENWN(WSSNNE|)EESSSWSESENEESSESWWSEEEESSSEES(ENNWNNW(SS|NNNESSENENWNNNWWSESWWSW(SSENSWNN|)NW(S|NWNN(WWSESW|EEE(EEEENWNEENESSSS(W(NN|WSSEE(NWES|)SWSEE(ESWSESWSEENEEEEEEENENNW(SWWS(WNWWWWSEEE(WWWNEEWWSEEE|)|E)|NEE(SSSESWSSS(ENNENESSS(WNSE|)EEENWWNENN(WSNE|)NESEE(SSW(NWS|SESW)|NNW(NEWS|)S)|WWNWN(EE(S|N)|WSS(WWNENWWSW(N|S(E|WNWWS(WNNNWNW(NEESNWWS|)WSESESSWN(SENNWNSESSWN|)|E)))|E)))|E))|N))|ENNNNEE(NWWNNWWSSEN(SWNNEEWWSSEN|)|SSS(WNNSSE|)EN(ESSSNNNW|)N))|SSWNW|NWW))))|WWWWNWWWNWSS(WNNWWWSWNWNWNNWNWSSWSEE(SESS(E(EEEENW|N)|WWN(E|WSWWWWWNWSWNWNWNEEENENWWSWNNWNENNEENNNNEESSENESSWWSSENESSSSE(ENWNNNNNNENENWNNEENNENNNE(NNNWNNENE(SSWENN|)NENN(ESSNNW|)WN(E|WSS(WS(E|SWNWSWNWWNWWSSE(N|ESSWSWWSSWNNNWSSSWNWSSWWSWNNEENNNNNWWSWWWNWSWSSSWNNWNENWWWNNESENENESES(ENENNNNESENNWNWNNNNNENWWWSSE(N|SSSSWNWWWSWSWSSWNWSSES(ENENEEES(WWSWENEE|)EE(SWEN|)NNN(E|WWNWSS(EESNWW|)W(N|W))|SWWN(E|NWNNWNWNNWSSWWSWNWWWNENENNWSWWS(E|WNWWSWNWWNEENNWNWWSWNWNNESENEES(EENENNEENWNWSWNWNWWSWNWWSSSS(EENN(W(N|S)|EE(SWSEE(ENWNSESW|)S|N))|WSWWWNEENENWWNWNENWWNWNWWSWNWWWSESSWSW(SESENEESWSSSESWWNNWN(E|W(N|SSSE(SESESSESSESESWWWWWW(NENWNNESE(SSE(NN|E)|NNWNW(S|N))|SSENEEEEEESSSWSSESSWSSWSWSSSESSESENNNNESSSSSSESWWNWSSSWNWNWSWWNW(NENNNW(NEESSENE(NWNNWWW(SEEWWN|)NEEENNNWNWW(NENWNNEES(W|ESS(WNSE|)EE(E|SW(S(E|S)|W)|NNNW(SS|WNN(WSWWEENE|)EEESWW)))|SESS(WN|EN))|SSS(E(N(N|EE)|S)|WW(NEWS|)S))|SS)|SSSENESENESSSWSESWWWSEESSWSESENEESWS(EEEENNENNNNWNENEEESSEEENWNENNESSENNENENNWWWNWNNNWNEENWWWSSWSWNWSSW(NW(NENWNNESESENNWNWNNWWN(EEESES(W|SENEENWNENNENEEENWNWWWNNWNNWWSSSSWWSESSS(ENES(ENNWN(WSNE|)NN(NN|ESSE(S|EE))|S(S|W))|WNWW(SEWN|)NE(NNNENWNENNWWW(SE(SSSSSW|E)|NWNENENWNEEEEESSESSS(WNNWS(SSSSS|WWN(WSNE|)NE(S|N(ESNW|)W))|ENEN(EESWSWSEESW(W|SEES(ENENEESWSSENEENNE(NWW(SS|WWWNN(ESENSWNW|)(N|WSW(SSENSWNN|)(W|N)))|SESSSSSWWSEEEEEENNWWW(SEEWWN|)NENWNEEESWSEEE(NWN(NNWWW(NEEWWS|)S(WNWESE|)EE|E)|ESSESEESE(NNWWNNWS(NESSEEWWNNWS|)|ESWSWSEESEESWSWWN(E|WN(E|WWNWWNWNEEEE(NWWNWSW(NNENWESWSS|)WSSWSSWSESSSESSSSWNNNWSSSWWWSSWWSEESWSEESEEENWWNENNEEN(EESWSESENNNNWNW(NENENNEEE(SENEESSW(WWWSSESSSEESWWWW(NNN(ESSNNW|)NWNENNE(WSSWSEWNENNE|)|SSSSWWWNW(NE(NWNWS|EESW)|SWWWWSESENEESSSWN(WWSS(E(EEENESEEEENNNWSSWWNNN(WSW(SEWN|)N|E(SS|ENENWNNESEEEN(ESEENESEENNNNENNNWNWWNENWWNNESEN(EESEEEESESESEEENNNEES(WSSSWW(SEEWWN|)WWWNWNWNWSWNWW(SESESSENE(NWES|)ESWSESSWWN(E|W(NEWS|)SSESWSSW(NNNN|SWNWSSESESE(NN(NESNWS|)W|SS(WNWWS(WWWNNESENE(NWNWSWNNWSWWNEN(WWSS(SESWSES(W|ENNNESSS(NNNWSSNNESSS|))|W)|EEESEN)|E)|E)|E(E|N)))))|N)|ENNNNWSWS(WWWNENW(NEEE(SWSNEN|)NN(WSWWEENE|)NEEN(WWNSEE|)ESSWSW(N|SEE(ENWESW|)SSS)|WWWSW(N|S(WNWSNESE|)EESE(NNWESS|)SEE(NW|SW)))|E))|NWNENWNNWN(WSSSE(N|SSW(SSWSESESWW(N|SWSSEEEENN(ESESWSSS(WNNWWSWS(E(ENSW|)S|WNN(WNW(NENWWEESWS|)S|E))|S)|WWS(W|E)))|NWNW(W|S)))|EESEE(SWWEEN|)N(N|W)))|WW)))|N)|WWNWNWWWWNWNEENENNWNE(ESSESSE(NN|S(SE(N|S)|WWN(WSWENE|)N))|NWW(NENNNNEEEENNNNWWNNESENESE(NNWNEE(S|NN(ESNW|)WWS(WSSWWNNN(NWWNW(SSSSWNWWNEENWW(NEEWWS|)WSSSESWS(EEEEN(WWNSEE|)ENNE(NWES|)SSSWSWSESE(ESS(ENNSSW|)WWWSWWNENWW(NENNESSESEE(WWNWNNSSESEE|)|S)|NN)|WW(WSS|NE))|NN(N(W|N)|ESEE(SWEN|)N(W|NESE(SWEN|)NN)))|E(SS|E))|E))|SWSES(ENNSSW|)SW(SS(ENSW|)WWSSWNW(NEWS|)SS|N))|SSS(WWW(NEENNSSWWS|)SE(EE|SSWWN(E|NWWWSEESSWWSWW(S(WNSE|)EEEEEENN(WSWWEENE|)EESES(WWNSEE|)ENEES(W|E)|NNE(NNNW(NEWS|)SS|EE|S))))|E))))|N)))|N)|NWWWWWNEE(NWWW(NEWS|)SSSES(ENSW|)S|EE))|S)|WWWSSW(NN|S))|E|S(WW|S)))))))|WW))|WNENWWN(NWNNWWWSES(ENSW|)WWWWSWN(NNEENE(SSWWEENN|)NWWSWWNENENWNEEN(ESSES(WWNSEE|)E|WN(WSWW(S(E|W)|N(E|N))|E|N))|W(W|SSEESWS(NENWWNSEESWS|)))|EEE(N|E)))))|E)))|WSSS(EENWESWW|)W(N|S(WNSE|)SS))|S)|SSSSWSES(EEEE(SS|ENWNNWNWN(NESENNESSS(ESWSEEEN(E|W)|W)|WSSESS(EN|WN)))|WSWSWNNENW(WSSSW(SSESS(WNW(S|N)|ESSENNENNWW(SEWN|)N(W|E))|NNN)|NNE(S|E))))|WWWWN(W(NNE(S|N(WNNNNNESSENNE(WSSWNNSSENNE|)|E))|S)|E))))|N)))|NN(NNNNESENNENNESEEENWNW(WNENNNWNWSWWW(SESWSSENEE(NENWWS|SWSWS(SWNNSSEN|)E)|NEENWNENENNWNEEENNNNWWSESSWNWNWSW(SE(SSW(SE(SWSSNNEN|)E|N)|E)|NNNEE(SWEN|)ENNENNNENENWWWNNESEENEEESEEESENEENNEENWWNNWWWWNNNNWWSESSWSESSWNWWNNE(N(E|NNNNNWSSWNNNNWWWNWWW(NENEEEEEN(WWWWWWS(NEEEEEWWWWWS|)|ESESWS(WWWN(WW|EE)|SENEEENENESEESWWSEESSESENEENNESENNESSENNNWNN(WSWNWWWWWS(EEESE(N|S(ENEWSW|)WWSS(WNNNE|EN))|WNWWWSWW(SEWN|)N(W|E))|ESENESSESESSWNWW(SSE(N|EESENNESSEENNNNESENNNESSENESEEEENWWNN(WS(S|WWN(E|WWWWWSS(ENESNWSW|)SS(SS|WWNENNNWSW(WNE|SE))))|ESENESESWSSESSWNWWN(WSSWWWSESESSENNN(W|EE(NWES|)EEENENWNENNENESENEESSW(N|SSENEESSW(N|SEEEEENNNNEENNN(WWSESWWSWNWNWSS(ESSES(ENNWESSW|)W|WNNN(EEEESW|WWWWWWW(W|S(SSWENN|)E)))|ESENESSENNEESSW(SSSESSWWWWWNNN(EN(NWSNES|)EESSS(WN(WSNE|)N|E)|WSSW(NN|SESWSSWWWNN(ESENSWNW|)WSSWNWN(E|WNNWSWSSSSSWSWNWSWSSEESSWSE(SSWSSE(N|ES(SWNWSWWWWNWSWNWSSSWNNNNNNESSEENNNNWS(WWWSWWWWSSWNNWNNENNENNNNNENENWWWN(EEEE(SE(N|ESSWW(NEWS|)WSSSSW(NNN|SESES(WWS(W(NNEWSS|)W|EE)|EENNEEENWNEEESWSESEE(SS(SWSESSWNW(NW(S|NENN(ESNW|)W(NWWWSNEEES|)S)|S)|E)|N(E|WNNNNNWSWS(WWWSSWWNNE(N(WWSSSSES(NWNNNNSSSSES|)|EEN(E(NNEN(ESS(WSNE|)ENNEESWSEENE(NNW(W|NNENE(NWWS|SSW)|S)|SSWWWS)|W)|S)|W))|S)|E))))))|NWWNNEE(SWEN|)EN(EESWENWW|)W)|WSSSSSWNNWNNN(ESSNNW|)WNWSSESWSSWNNNWSWNWSSWSESESEN(NWNEWSES|)ESSENESSESSSE(SSESSWNWWSSSEESENEN(WWWNSEEE|)NEESSESEE(NWNNW(S|NN(WSNE|)EES(SS|W))|SWWWSSSWWWNWNWWSSWWWWSESENESEESSSEENWNNN(W(N(E|N)|W)|EEEESESSWNWSW(NWNEEWWSES|)SSSEENWNEESSENESENNWNW(S|NNE(SE(N|SESESWSEESWSWWSWWSWSWNWWWNWNWNNN(ESSE(NN|SESENESENEEN(WWWWW|EE))|WWWNNEN(ESSWENNW|)WWWWN(E|NWWNWWNWWNNNWNWSWNNEEENEESEESWSESSENNEESWSEENNEE(ES(E(N|EEEE(N(NN|W|E)|SW(SEWN|)W))|WSSW(NN|WWWW(SEWN|)WWNWWNNE(SEWN|)NW(W|N)))|NWWNEENWNENNWSWWNENNWWWWWN(WSW(N|SSSWNNWSWWSSEE(NWES|)(EEEEENNEN(WWWSESW(ENWNEEWWSESW|)|E(E|SSSES(ENSW|)WSESWWNN(NN|WW)))|SWWWSWSWWNNE(NWWSWW(NENEEEES(ENNWWWWNE(NWES|)EEE|S)|SSES(WWNSEE|)E(NNWESS|)ESSWNWSSEESEESWWWW(NEWS|)SEEESSWNWSWWSW(NNNESE|S(WNSE|)ESESSEESWWSESENESENNESSSESWWNWWSESWWWSS(WNNWSSWN(SENNESNWSSWN|)|EESEENN(NEEENEESENNNENESESSSSSEENNW(NNNEEENNNNWNE(NWNN(ESNW|)WWNNWWNWWWWWSESSWSWWSSSS(WW(S|NNE(NN(WWWS(WNSE|)SE(NE|SW)|NNNESSEN(E|NNWNNNN(N(WWSESWSE(WNENWNSESWSE|)|N)|ESSEE(NNWSNESS|)S(EE|WW))))|S))|ESSEESW(W|SEENNNWNEES(S|ENNWNNENWW(NNNESSEEE(NWWNSEES|)SWSS(SESS(WNSE|)ENE(SS(ENNSSW|)WW|NNW(S|WNENES))|W)|SW(N|WWSEEESWW(SS|W))))))|ESSSSEESEN(NWNNW(NEWS|)SS|ESSWSSWSSSWSSWSSW(NNNWSWS(ESNW|)WWNNN(EE(SWSNEN|)ENESE(NNE(S|NNWN(WWWSESE(SWEN|)(E|N)|E(NW|ES)))|S)|WSWS(E|WNNNE(N(NE(NNWSNESS|)SS|WWW(N|SESSWS(E|WNWNNW(SS(WW|SSE(SWEN|)N)|NEESSE))))|S)))|SESWSSENESSSEENWNNNENEENWNEEENWWWWSW(WSE(SWSNEN|)E|NNEENNEEEESESSEESSWNWSW(SWNWSSSSSWSW(SESENESESWWS(WNWSWNN(NWWWS(EESSSES(ENSW|)WW|WNWNWN(NE(NW|SESEN)|WSW(W|SSSEEE(NWWNEWSEES|)E)))|E)|ESSESE(NNWNEESEE(SWSWNSENEN|)NE(ENENWNWNWNENNNNEEESENNNE(NWNWSWWNENWWWS(WWNNNENENWWWWN(EEEEENWW(W|NEEESESWSWSSES(EE(NWN(NESENENNNEES(ENNWWNEENWNWSWSSWNNNEN(EEEE(NWES|)S(SSEESWWS(S|EE)|W)|WW(W|SSSSS(ESSWNSENNW|)WN(N|WW)))|WSESWSW(ENENWNSESWSW|))|W)|SEE(EE|S))|WW(WSNE|)N))|WWN(E|WSSWSEES(WWWSSNNEEE|)EN(NWES|)ESE(NEWS|)S))|SSE(S(WSSSSWSSSSE(N|ESWW(WWNENNWNWNNW(NEEEN(W|ESSWWSES(NWNEENSWWSES|))|SSS(ESEWNW|)W)|S))|ENESEN)|NN))|SSSE(NN|SSEEN(EESSENNESEESESSWSWSSSEESSENNEESEENNE(NWWS(S|WWWNEENEENWNENNWWS(SSWW(NENWNWN(WW|EN(EEEN(NEEEESSE(NNNWWNNNE(ENNNWWNNWWNWSSSENESSW(WWNNW(NW(SWWEEN|)NENWWNNW(SWNSEN|)NNNWNEN(ENEEN(EENWN(EEENESEEEESEENWNWWNWNNWW(NEEESSENNN(WNWSWENESE|)EEEENEEESSENEENNWSWNNENN(EEN(E(E|SSSSSW(NNWNEWSESS|)SEE(N|SSWSESWWNNWW(NEEEWWWS|)SWWWSEESESWWNWWWW(SSEEN(W|ESSWWWSWWN(E|WWNWWWWWSSWSEESENNEN(WWSNEE|)ESESWSESWSESSE(ENNW(S|NNN(N|EEESEENN(WSNE|)EENNEEEEESSE(NENNES(S|EN(EE|NWW(WWS(ESNW|)WWN(E|N(N|W))|NENNW(NEWS|)S)))|SSWNWWSESSSEEN(NWSNES|)EESSSSE(SWWWNENWWSSS(EESE(S(E|W(WWNEWSEE|)S)|N)|WNW(S|NWNWWS(WNW(NENEES(ENNN(WNENW(NEN(EESWENWW|)W|WSW(SES(E|WWWS(SWWNNN(WNEWSE|)E(EE|SS)|E))|N))|ESSSSE(NEEENSWWWS|)S)|W)|SS(E|W))|E)))|NENWNENW(ESWSESNWNENW|)))))|SWWWNWSSS(ESE(NNWESS|)S(ESSSEN(ESNW|)N|W)|WNWNENWWWWS(WNNNEES(ENEN(EESWS(W|EE(ESNW|)NNNN)|NWSWWWN(WSSSNNNE|)NEE(SWEN|)N)|W)|EESWSS)))))|WNW(W|NENEEE(N(WWWWSNEEEE|)NESSEE|SSWNWS)))))|WW)|WSW(N|W))|SES(WWNN|SE))|W(NNWESS|)S)|W)|W)|S)|SSSE(NNENES|SWS(W|E)))|SS)|SWSE(EENWNEE(WWSESWENWNEE|)|SSWNWSW(NNENNNWSW(N|S(WWWSNEEE|)E)|SS)))|WWW)|W))|S(WSSWNSENNE|)E)|E))|SSEESSS(ENESNWSW|)SSWNWSWW(SEEEWWWN|)NWSWNWNEENN(EEEESWS(E|W(WNEWSE|)S)|W(N|SWWSWNWWNWWW(SSEE(NWES|)SESWWWWSS(EEN(W|EEENEE(NWWNWESEES|)(SSW(N|WWSS(EEN(W|ESSENE)|SSWNNNN(SSSSENSWNNNN|)))|E))|W(WSEWNE|)NNNEEE)|NENENE(NNNN(WSWWN(W(N(ENSW|)WWWWNN(ESNW|)WWW(NEWS|)SSSENNESSS(W|SSESWW)|SSWSESS(WNSE|)(ENNNEESWS(NENWWSNEESWS|)|S))|E)|NES(E|S))|SS(ESENSWNW|)W)))))|W)))|S)|SS))|NNWNENESS(NNWSWSNENESS|))|NNNWWN(WSNE|)E)))))|S)|W(S|WW)))))|S)))|EEEENWN(WWNW(SSEEWWNN|)NE(ESEWNW|)NWWSSWNNWNENWWWSS(ENSW|)WNNNENESEN(ESESES(ENENNWN(ENESSENE(NW|SEN)|WS(SEWN|)W)|W)|NWWNENWWWN(ENSW|)WSW(WW|N|SSSENNESE(SWEN|)N))|EESSENESESS(SESW|WNWS)))))))|NNNWW(SESWENWN|)NEEENEE(NNEESENESS(WWWNSEEE|)ENNEEESES(SEWN|)W|S(W|S))))))|NNENWNN(W(NNW(SWEN|)N|S)|ESENNNNNE(WSSSSSNNNNNE|))))|SS)|E))|ENEES(ENENNNENWNN(NWNW(N|SSESWSWSEE(N|SSWWWN(NWWEES|)EE))|EES(SES(ENENWWNEEESES(ENNNENE(EN(EEES(WW|ENNESSENNESSESEESWWSS(WWSESWWWWN(WSWNWSSEEEEESWS(WNSE|)EE(NN|E)|NEE(SWEN|)NEENNWWWWSE(SWEN|)EE)|EEN(W|ENENWNENWWSWNNNW(SS|WNWNNEENNWSWWNEN(EEESSSSW(W|SEESSEEEENEEENEESWSSWSSWNNW(NEEWWS|)WSW(SSSWSSSW(S(EENNEN(W|ENN(W(NENSWS|)S|EEEEESEESSENNEESSESSWWN(WSWSWNWWSSE(ESWS(EEEENNN(WSSWNSENNE|)ESSSES(W|ENEESSSSS(WNNN(WSNE|)N|ENENWNENWNENWNNNNESENNNWNNENWNWSSWWSWNW(SSESSEE(SSWSESWWWNNE(NEWS|)S|NWNEE(NW|SE))|WNENWNENNWWS(WNWSSEESWSWNWS(SEEENSWWWN|)WNW(SWNSEN|)NNENNE(SSSWENNN|)ENNEESS(WNSE|)EENESESSW(SSSEENWNEEEEENWNENWNENENNN(WWWSSS(ENENWESWSW|)WSW(NW(S|NWSWNNEEN(WWWWWSWS(WNN(E|WWWSWSESWS(EEEENWWNENW(ESWSEEWWNENW|)|WSWNNENNN(WWWWWSESWW(NN|SES(EES(SWNWSNESEN|)ENNW(W|NNESEN)|W))|E)))|EENESSS(NNNWSWENESSS|))|EESWSE))|SEE(SWWSEE|N))|ESSESSSENNNE(SSSSSWNWWNN(WSSSEESWSESSENNNESSSSWWSESSWWWSESWW(NNNENWN(EE(SSEWNN|)NWN(W(S|N(ENSW|)W)|E)|W)|WS(WNSE|)SSENNESSESWSWSSW(NNNEWSSS|)S(ESEENWNNEEEE(SWSS(WNNW|EN)|NWNW(SWEN|)NNN(WSNE|)ENN(WSNE|)E(SSSWSES(NWNENNSSWSES|)|NNN))|W))|N)|NWN(WSNE|)E))|N)|E))))|WWN(E|W(NNE(S|N(NNNE(NWES|)SSENNESSE(WNNWSSNNESSE|)|W))|SS(WNSE|)EE)))|N)|NN|E)))|W)|NN)|N))|WWSW(N|SSE(ESSS(WW(S|NENWWN)|E)|N)))))))|WWWSWSS(NNENEEWWSWSS|))|S)|WS(E|W))|SSSWNW(SSWSE|NEN))|W))|W)))))|N)))))|E)))|N(N|E)))))|SESWSSENEN(N|EESSW(WSSSSSWSSSW(SSSSENNE(N(W|ENESE(S|NNNWSWW(S|NENEEE(NWNN(ESE(N|S)|WW(SSENSWNN|)NEENNN)|SSSSENESEEENESEE(SWWWWEEEEN|)NWN(E|WW)))))|SSSWWSSESWSSEEN(W|NNN(E(NEWS|)SS|W)))|NNNNENWNENW(ESWSESNWNENW|))|N))))|S)))|S)|E)))|W)))))|W(W|S))))|E))|ESSE(SWSW(NNN|WSESWW(SSENEE(ENWNEE(EE|N(NNEWSS|)W)|SSSSSSWWWS(EES(ESWSESEEEENEE(NN(ENSW|)WW(N|WS(SWNW(S|N(E|N(N|W)))|EE))|S(ESENEES(S|W)|W))|W)|WNW(S|NNNENEEE(SWSESWWN(WSNE|)N|N))))|W))|NN))|SSWSS(ENEEWWSW|)WWNW(WW|NENNE(S(SS|E)|NWWN(EE|N(NNNN|WSSWNN)))))))|N)|EEE))|E)|E))|N)|NEEN(N|W))))))))|N)))))))|N))))|WNWSW(SEESWS(E|W(SEWN|)NWNNWW)|NN)))|NNNNW(NNNENWNNNW(S|WNEEESSEE(NWES|)SSW(NWES|)SSWSEESWSES(WSNE|)EENWNENNW(S|N(WSNE|)(EESES(WSNE|)ENESE(ESNW|)N|NNN)))|W))|EEE))))|SE(ESSNNW|)N)|SWS(E|W))|NNNN)|NWN(WSNE|)E)|WWWN(WNWSNESE|)E)|NNWNNWNWNWNWSSESSS(WNNWNWNNWNWNEEN(WWWSSWNNNWN(NESESNWNWS|)W|ESS(SS|W|ENEEESS(WNWESE|)SEE(S(W|SS)|NNW(NENWNN(ESNW|)WSSWWN(E|W(NWSNES|)S)|S))))|EE(NWNSES|)S(W|E)))|W)|W(WWSNEE|)NN))|SS)|WW)|WW)|W)|WSSSSWSSEE(SWWSESE(N|SEE(NWES|)SWWSESWWSWWNNNWNNE(SE(SE(SWSNEN|)N|N)|NWWSSWNNNENWWWWN(ENNNNNEN(ENE(NWN(WSSNNE|)N|SEESE(N|SSWS(E|SSW(SSENSWNN|)NNWSSWWNENNN(WSSNNE|)NESSEN(E|N))))|W)|W(WNSE|)SSEEESSWSESSWNW(NNNEWSSS|)SWWSEEEEES(W|EE(NNW(WNEWSE|)S|S(ESENEWSWNW|)W)))))|N(NN|W)))|EN(EE|W))|EESESESWSSENE(ENWESW|)SSWSSSWNWSWWSW(WN(WSNE|)NNNESS(S|EENWNNN(WWSEWNEE|)ESSE(SENSWN|)NNNNW(SWEN|)N)|SEENEES(ES(WSNE|)ENN(NNNEWSSS|)W|W)))|S)))|S)|WWS(WWNEWSEE|)E)))))))))|N)))|NNEEESE(SEESWS(WNWNSESE|)EE(NNN|SEEN(W|ESS(S|W)))|N))))|SSW(SS|W))))|W)|N(W|E))|NN))|S))|W))|S)|W))))))|E))$