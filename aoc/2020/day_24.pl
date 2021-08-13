#!/bin/perl -w
#
# https://adventofcode.com/2020/day/24

use strict;
use POSIX;

print "2020 Day 24\n\n";
my $puzzle = do { local $/; <DATA> }; # slurp it
my @lines = split("\n", $puzzle);

# Originally used a cube coordinate system but have switched to axial with no z for a bit more efficiency.
# Ref: <https://www.redblobgames.com/grids/hexagons/>
my %delta = ('w' => [-1, 1], 'nw' => [0, 1], 'ne' => [1, 0], 'sw' => [-1, 0], 'se' => [0, -1], 'e' => [1, -1]);
# When we walk along the radius we will start at the eastern tile, so need the directions to go around the ring.
my @dirs = qw(nw w sw se e ne);

my %grid = ();
my $max_dist = 0;
for (my $line = 0; $line <= $#lines; $line++) {
	my $x = 0;
	my $y = 0;
	my @moves = $lines[$line] =~ /([ns]?[ew])/g;
	while (my $m = shift @moves) {
		$x += $delta{$m}[0];
		$y += $delta{$m}[1];
	}
	my $dist = calc_dist($x, $y);
	$max_dist = $dist if ($dist > $max_dist);
	$grid{"$x,$y"} = 'w' unless (exists $grid{"$x,$y"});
	$grid{"$x,$y"} = ($grid{"$x,$y"} eq 'w') ? 'b' : 'w';
}
my $count = count_black(\%grid);
print "P1: Total black tiles is $count\n";

my $day_limit = 100;
foreach my $day (1 .. $day_limit) {
	$max_dist++;
	my @to_white = ();
	my @to_black = ();
	# The way we iterate will skip over the center tile, so we check origin first.
	my $adj = 0;
	foreach my $d (keys %delta) {
		my $dx = $delta{$d}[0];
		my $dy = $delta{$d}[1];
		$adj++ if (exists $grid{"$dx,$dy"} and $grid{"$dx,$dy"} eq 'b');
	}
	if ($grid{"0,0"} eq 'w' and $adj == 2) {
		push @to_black, "0,0";
	} elsif ($grid{"0,0"} eq 'b' and ($adj == 0 or $adj > 2)) {
		push @to_white, "0,0";
	}
	for (my $r = 1; $r <= $max_dist; $r++) {
		my $x = $r;
		my $y = -$r;
		foreach my $dir (@dirs){
			foreach (1 .. $r) {
				$x = $x + $delta{$dir}[0];
				$y = $y + $delta{$dir}[1];
				$adj = 0;
				$grid{"$x,$y"} = 'w' unless (exists $grid{"$x,$y"});
				foreach my $d (keys %delta) {
					my $dx = $x + $delta{$d}[0];
					my $dy = $y + $delta{$d}[1];
					$adj++ if (exists $grid{"$dx,$dy"} and $grid{"$dx,$dy"} eq 'b');
				}
				if ($grid{"$x,$y"} eq 'w' and $adj == 2) {
					push @to_black, "$x,$y";
				} elsif ($grid{"$x,$y"} eq 'b' and ($adj == 0 or $adj > 2)) {
					push @to_white, "$x,$y";
				}
			}
		}
	}
	while (my $t = shift @to_white) { $grid{"$t"} = 'w'; }
	while (my $t = shift @to_black) { $grid{"$t"} = 'b'; }
}
$count = count_black();
print "P2: Total black tiles on day $day_limit is $count\n";

sub count_black {
	my $count = 0;
	foreach my $t (keys %grid) {
		$count++ if ($grid{$t} eq 'b');
	}
	return $count;
}

sub calc_dist {
	my $x = shift;
	my $y = shift;
	my $z = shift;
	
	$z = (0 - $x - $y) unless (defined $z);

	return ( (abs($x) + abs($y) + abs($z)) / 2 );
}

__DATA__
neswsewswseswseenwseneswseswswswseswse
nwnenwwnwnwneswnenweswnwnwnwnenwswnese
wnewwwwwwwwswwwsewnwwswnee
wseeeeeeesesenesenweseseeseesw
nenenenwneenwnenenwnwswnenwseswsenwenw
sesenwsesesenweseeseseesesesesenwsesesw
sesesewseswsewesenwneseswswwsesesesenese
ewnenenenenewwneeneneneneseneenew
eswswswwseswswsesese
ewnwnwnwnwnwnwwswwwnwnwew
swswswswswesewswswsweeswswswneswwsww
nwwwesesewnwwwnewwwwwwenwsew
wnesenwneeneneswnesenewnenwnesenwnenw
swseswweseswswswswswseewse
nenewnwsenwnwnenwnwnwnwnwnwnwnw
neneneswnwnwnenenwwsenenenenenenenwsenenw
eeseeeeneneseenwseeweseeeeswe
seneswesesesesewsw
swswwsweswseneswswswseswnweswsesenwwswsw
swnwnwsenwwnwnwnwwenwnwwnwwwnwnenw
sesewseseseseseesesenwse
neneneneenenenwneswneenene
swswswewswnwsewswswseswseswswseswswswne
nenwnwnewneeenenwswneneneseneswneesw
neswwseswnwswswsesewesenwnwswsenewe
neeneneenesenwneswnenenwnwwnwnenesenesw
seseswswswneswswswswnwswneswsewseseesw
wnwwseswnwenewenwnweewswswswsenw
eswwenweseewesenw
swsewneenewnwseseweeswneeseneew
eeeeeseenweeee
eseswenwwseseseese
sesesesenesesesesewseesewseneeweesese
wwnwnwnwnwesenwnwwnwwsw
eeswnwnweesweeenwsewswswenewnesw
swswswswswswnweswswswsweswnwswswswneswsw
wwnwwnwnwwnwnwenwsenwsewwnwswnwnenw
seseeseseseseswneswsenwsenwsesesesesw
enwnwwnwnwsweneseswsenwwenwnwnwenw
seeenenwewweseseseswseewenesesee
weswswwswwswwswwswwnwswseneswwwnw
eeeeneseeneeeswneenweneneeewnesw
nwwswswnweswswwwesewswswswwsw
seeseneswneswswnwenwenwnwwneseswneee
neneneseneneswneenenenenwnenene
enenenewneswenesenwneneseneenenewne
senwseseseesweseesenwnesesesesesenesesew
seesesesewsewnweseeeeneeseseeese
wneseswenwswnenwnwwswseseswneesenew
nesenwswwnwwseewnewwwsewwnwwsw
seseeswswneswneesewnwnwenesewse
wswnwswswwwweswswswwsw
eeeeweeseeneee
swnwswnwseeeswenwnweswnwswswsewswswswne
nenesenwnweenwneeneswneneeneeneeswnesw
senenenwwnweneswnwnwwnwnwnwenwnwnenenwne
swewseeneswneweneeneeeswnwneneeee
nenwwwswwnesweewwseswswswswewwew
sesesewnwseneseswsenesesesenesewesesesese
nwnenenwwnwwswsewswewswnwseeeew
nwwweeseneeesweeeeeewew
wwnwwwewwwwnwsewwwsew
neewnwnwnwswswnwnwnwswnwnwnwnwnwnenwnw
eeeeenweeseeswseeeseesweneew
wwwseswswswnewwwswwseneswswswsww
nenesweneweeswswwnewnwnenweenee
nwwwswwwwsenwwwnwwwwwenwsenww
nwnwnwewnwnwwseenwnwseneenwwnwnwnwse
wnwnwsewnwnwsenenw
wwesewnwswenwswseenwneswswseswnwwww
nwnwsewwwwwswwenwnwwnewsewwewnw
wnewsenwsewseneseseeseseseseseneesee
neneneneneeneswneswswnenenenenenenenwnw
enwnwnwsenewnenenwnwnwnwewnwnwwnenw
wwwseneseswseeneesenesenewseswenwsw
newneeneneneswnenwneneeseneneenenee
neeswnwswswnewwnwewwswnwseewseswe
seseesesewsesenwweweswesese
wsewnwswswswswswswswnwseswswseeneneswwsw
senewneseswseseswswenesenwswswswswswswsesw
wswneswwwswswwwwswswneswseewwe
newwwwswwwwwwnwsewewwww
sesewsenewseneswwnewswswswseswnenene
nwneneneewnwswnenwnenwneseneenwneneswsenw
eweeesweseseneneseeeeeenwsee
wswenwenwswswseswsw
sweenweeseneenweeeene
nenwseneeeeseswnweeeeeswwneenee
wewnweswwwwswwsewswnewwwswwswsw
swseneeswwswwswwwswswswseswswswswne
wneneneneneswnwwneeenwneneneenwnenw
swnwnenwnwnwenwnenwnenwnwswnenwswnwenwnenw
nenwnenwwnwnwweswneseneseneneneswnwnwsw
weenwswnwnwwwnwnenwsenwnenw
seseseeneeswseseeseesewswswsewsenwnwne
nwwswwswwswwseswnewweseseswswwne
newwenwewnwnwnwswnwswwenwnwsewnwnw
seswneswswswwswswswnwswswesweeswswswnwsw
swswswseswswseneewsewwwneswwswneseswne
eenwseeeeneeeeeseewswseewe
wwwwwwwwwnesww
senwewenwseseeeeseswseseseeesee
neswnwnwnwwenwnwwwsewnenwnesesewswne
ewesweseneneeeseesewsewewsenwnenw
newwswwweswsweswwwswwwwwwwe
nweeenesweseneweenesewene
enenweseseneneswwneswewseswseeew
seneswsenwnenwseseswsenwseseseswsesesew
seswnenwwnwswnweeeweseswnwnweesw
wwnwwwwenwenwwnwwewnwnwnwnwnwsw
swswnwswnewswswswswwwswsweeswswnwswswsw
nenenenenenewenenenenenenesene
swseeseswneseswneswswseswswswwswnwneswsw
sewseneseseeeeseneew
nwenenwsweeswwnwnweenwswswswenwnww
eeeseseswsenwwweeswnesenwswswneww
nwnenenenenenenenenwneseneneswneneenwsene
seneseesweeeesee
eneswseeeseseswseeeewnweesewenee
wwsewswswswneswswswnew
neseeswneneswneneneenwnenwnew
eseseewsewewneseeenwenwesesese
nenenenenenewneneeneneenee
sewewsesenwwwseeneneswnenesesesenw
nenenwneswneswwneseswneenwnwneeswnwnwe
seeeenwseeseeseeeswneeneweewsee
nwenwswnwnwenwswnenwnwnwswnenwnewneenw
eswwnwneswswsenwwenenwseswseseesene
eesewswseseeenwwnweseewwnese
neneseneneswneneenewnwneneneswnwneneene
esesenwswesesewwnesenwewswswsenwswse
sesewnwnwwnenewnwwwswsewne
wnenwnwnwneenwnweswwnwswsenweswsesene
wnwneneseeesewsesenwnesw
esesenwnwswsewswnwseneeseseseesesenwse
swnwnweseeeeeeeeesenwsewnwsese
nwswnwswsweswseseseseswswswswswwneseeswsw
wneenwseewsenwsesesewneswsesweesee
wnewswwsenenwnwsewnwnwnwnenwnwsww
swewswnewwneswwnweeenweenenesene
sewneswseneseseswswswseseseseswneseswse
eeeenweeeneeseseewneeesweese
wnwneswswnwnwnenwsenenwsenwnenwnwnenesw
weneswnweneeneeesesweeneenenww
seswneseseseswsesesesese
neeeneneswneneweenenwnenwswneesene
swswswsewnwnwseseeswswswnwswswsweswnene
seseswseswwnenesese
nwneswwseneneneeewwseneneenwesww
wnwnenenenwsenwnwe
nwwenenwenwswsenwwwsewswwnenwnwesw
nwnesenwnwswsenwnwwnwwnenwwnewnwww
sweeenweeeeenwsweeeeeeswneee
eeseseswnwnweeeeneeseeesewnwee
seswsesewweneswseswnweswneswsewneswsw
wwwwsenewnwwwwwnesewswwneww
swwnwnwseseswewsenwswswewnw
wenwwnenwsweswnewsewswwsewnwweesw
seeseeneeeeswwenwseeeswseeeee
nenwneswnewseswnenenwsenewnenenenwsene
neneneneswenenenwwneeswneenenenenenene
enwnwnwnenwwsenenewnwnene
nenenwneswnwseeswnenwneseeneneeswnene
nenenesenwnewnwnwnesenwnenwnwnwwnwnene
wwwseseeneswseswnwsewswswseneeene
wwwseesesenwwwwwnwwnewwswsw
wwswswwnwnwesewseswwnweswnwseeww
neswnwswnwswenesewnew
wewsewnwnwnwnwnwnenwnwwnwnwnw
swsesweswneswnwneneeswswwwswswswsesenw
wwweswwwswwwswswwswnw
seseswseswsweswnwseswswsweseswseseswnw
eswwneswswswneeswseswwwswswewene
swsewnwneswnwswswseeswsewnwseswnwseese
neweswswswswswsweseswnwnwnesenwswneswsew
nenenenenewneneneneneeneswnwwnenenee
newnwwsesenwseeseseseeeesweneseee
eneeeeeseeeeeswee
wswweneneseseswswseseneswswseswswwsw
ewnenwneeseneeneneneseeneneweneee
swwwswwenwnewswseneswswswswwwwsw
eeneesweenweeeeeneweeeesew
nwwsenwnwnenweseeweewsewsenewswnesw
nwwnwnwnwnwnwnwwenwnwnwnwnwnewswsenw
nwnenwnenwnenenweswnwnenwnwne
sesenenwenwnenweseneneeneneseenenew
seseeeeseeswenwse
seseseeenwseseeeewsweseesenwee
seseseseeseswnwsesweneseswsenwsesesesese
swwseswswseswswwwneswswwwswnesw
nwnwswwneeswnwnwwnwnwwsewnwwnwew
newneswseswwwswwwwnewwsenwwswswswse
nwwnwnwswenwnwwwnwnweswnwwewnwswnw
wwsewwwwwneewwwwswswnwweww
nwnwnwswnwnwnwnwnenwnwnwnwnwnw
nwnwnwnwwnwswswwewwnewwne
swwneeswwnwnenenenenenenenenenenenwnese
eeneeneeeweeeewnesenweeeesw
eseewwswwwnewwwnewwsewwwew
eswwsenenwsenewesesesewesesesenenwse
swswswswswswwwnwswseswsw
eeseenewswwnesewweneeeenweseese
wneseswswneswnwnewnewsenewnesewwsww
swsenwseneswneswswswswnwswseswwwswswwsw
nwnwnwsenwnwnwnwnwnwnwnwnwnwnwseswswnene
nwsweseeseseswsenwenwseenwsw
seswseneseswseswnwnwsewswe
swsweeenwnweneswe
enwwnwwnenwnwwewnwwwswsewnwnww
nwewwsweewswsweswnwewneswnw
wnenenwnenwnwwseneneneeneswnenesenene
enwwswesewesene
nenenwneneswnewenwnenenwswseenwwnwwsesw
senwnwseswswswswswseseswswsenwwswswswseee
eeeseeseeeewee
neeswnweenweeswnwswwenenwneswneeene
neseenenwseeeenwesweswwwswenenene
nwnwwnwnwswseneneswwnenwsenwnwnwewnwswne
sesesenwseseseseesenwseseswsesenwsesese
nwesewseswsesesese
wwswseswnwswwswnwsenesewsenwwwnene
swnwwnenenwnwnwnenwnwnenwnwsenwnwne
nenesenesenenenwneenenenwsesenwnesewnw
senwwwswwnwwnwwnwwnwwnewsewsew
eswnwswswwswswswwswsww
wneneseneewnenene
sewesweeeeeeseneweseseseneese
eeeseenwesweweewseenweee
sesesenesenwsesewseswsesweseswsenenwsw
eenwnwwswswneewswnwnwswwswenewne
senwnwenenewwnwnwwwesenwnwnwnwnwew
seewwseneswenweeeseseseseeeseenw
swwswswsenwswswwswneswwswwenwswnesesw
esenenwseeneenenenwenenewneeewnene
wwswseswsenwwwswnwswenewnewswsw
neeeeeeswenwseeneeneseeeenew
nwswswnwnwswsesewswswswneswnweseseseese
swseseewseseneeseseseeseneswsesenwe
swwswwnwneseneeswswseswswwnwswnenwew
seswsewseneneseseswwsesewseswseesenesw
swseswswseswswnweswswswesewwswswenw
wswnwnwsweneswenwnwsenewsenwwswnew
swewwwnwnwwwwwnwww
seeseseenesewseeeeeenesewneswesw
sewseseswseswswseswsesesesweswwne
nwnwwnwesewseswneswnwnwswnewwwneww
nenenewneenenenenenenewenenene
eeeesewswneeeseeeeeswwenwnene
esweenweeeeenee
swesesewswsenewsesese
seseswseswseswswseswswwnenweswseswswsw
swswswseswwswswneswswnweswswewwwww
sweeeeswneeeeeenweee
swnenwnwenwnenwnwneswnwswnwneneenenwe
sweseswswnwswseswwswswswswswswswswnww
wwswswwswwneneswwwwwwnewseww
seseesenweseswnwseseseswswseenwesese
nenenenenenenwnewneseenenenenenene
neeswnenwnwnewnwsweneeswnwnenwnwnenwnw
eewneeeeeeeneeenenwneneeswswne
wseswswesesesenwsenewseseeseswswsesese
nwewnwwwseswnwnenewswneseseneenwswsww
newwwnwnwwnenwwwwwsenenwwnwsesese
newwwwenwnwnwwwwwwewwwwsw
wneseneswenwswneswneswwnesewswswswew
esenwswsewsesesewsenesewseeneesese
nwswwnwnwwnwewnwwwwnwwewwse
eeswnwnwnwnenwneneseswseswewsewseseswsw
eseenenwseeswswseseweneswswnewenene
nenewsenwnenenenwneneswnweeeseneneswsw
nweswswnwesewnewsewwwwwnwwnenwnww
neeseenweneneneneeneesenewswwnee
swesenwseneeesesesesesewsewsenwese
wnwnewwwneewwwwwwwswwwwse
nwwnwnwnwnwswnwnwnwnwenwnwnwseesewnwnw
eneswswenwneneseswwseneeenwewnenw
neswnenwneneenenwnenenenwswneswnesesew
sesesesesesenwswnwseseswsewseseswsesene
wseswnwswseseenwnwswe
wsenwsenwnwnwneewwwswenewnwwnwsw
nwnwneswnenewnweswnwsenewneenwnwsene
newneewewnewneswwseeenewnwsesesew
eeseeswneseseswnwseswesenwswwenenwne
esenwswswsweswswseneseseswsewsenwsese
eswneneneswnenenenwswnesweeeneenenw
sweseseenwsewswseseseeseenesenwseesee
ewnwwwwwwswsewwwswswnewwnesw
neeweenwnesweeswneeswneneenenee
wsewwnwswwnwwseesewwswnenewwwe
sweswenwswnwwnenwnwnwneswnwenwnw
swnenewenwswsesewswnwwswwswwwww
senenwewsesesenwsesewnewnesw
wnenwseneswwnenenwswnwnenenesesenewneene
swnenwewswswswwwswseswneswswswwswswsw
wneeswnewwsewnwwwnwsenwwwwsenwnw
seseneenewwnenwenwnwsewwswsenewsene
eeeswseseseewneseesenwewswsenenesw
nesenenenewnwnwnenwnenw
neswewnwsewwewswsewwwwnwwwwne
nwnenenenenenesewneneneneneswne
swseswsesenwnenewnwwwwswswwwnenesesesw
swseseesesewsenwswseswsenwesenewwnew
seseneenweenwseeneenweneeeewnene
wneenwseseeenewnweneneesewsenewee
eewesenweeewneeeeeseeeeee
seswneseenwsesesenwsesesesesesesewswswse
seswnweswnwseswswswseswswseeenwswswswsese
eneswenenenewnenenenenwneneswneneswnwse
wsenewwwsewnwwwwwswneseswwww
nenenwswenwsenwswneweweswnewsenewe
esweeneeeswneneenenwneseneenwe
neseseswesewswsenwswseneswseswswswseswsesw
nwnenwseneneeneseenee
nenewneeeneeswewswwsenenenweenesw
nwnwseswnenwnwenwwseeneswwwnwnwwswse
seswswswseseseswnenwsesesesesenwswsweswsw
ewneswwwswnwwnwnwswwwesewenww
nwsenwnwnwnwwnenenenenenwnwne
wnwsenwnwwnwenwsesenenewnewwnwwnw
wsenwnwswsenwnwsewsenwnwwnenwenwsenw
esewsewenweswenesesenweseeseseswese
nwenwseenenwneneneewneneswnwnewnwwne
neenenwswneswneenenenenwnenwswwnenenenw
esenesweneesweswwenwneswnweswnene
ewwwwewswwnewwwwnwwwsw
esenesenwnewneseneneneenenenenwweene
swneeswseswwsewwwwewenenwswwnwe
sesesenweeseenwseswsesesewene
wswsenwseseswseeseseswnwwswsesenesesese
enweeeeeeeeeewsweenweswe
swswseswswneswnewswswswswneswswseswsesw
eseswenweneeseswswnwwweneeeee
sweswswswwswneswswswswswnesewswwswsw
swnenwnwnwnenwneenenenwnwnweswnenwnwnesw
eseweneneenenwnewswnwnenwswswswenw
newnenesenwneenenenew
ewswswswneenwnenenenenwnwnenenenenwsw
neneneswswenwenenenenenesenewnenesenenene
wnwwwsenwwwwwwwwnesewnwwsewnw
neeneeenwewneenweeswswesenene
seseneswswsenesesesenwswseswsesesesesewse
nwnenwswseeeswnenwnwnwnwwnwnwnesenwne
seswswswsweneswseswswswswswseswnwsw
swwnwnwwnwnwnwnwnwnwsesenwnwnwnwenwnww
enwnwnwneswnenwnwnwswnwnwnwenenwnwnwnwsesw
nwswswswswswseswneswswswswseswswswswsenw
wnweswneeeneeswswneeneewseneenee
seneesenwnwnesewnwwnwnwnenw
nwenwnenenwnwswnwnwnwnenenwswsenwnwenw
nenwnwnwnenwnwnesweseneneswnenenwnwswswne
wnwwwwnwwnwsenwnese
nwwswwwnwwwnwwswenenwwwsenwww
eswswnenenenwswenewneeesweeenenene
sweseneesesewsewweneeeeseewsew
eeneeeneeeeeeweseeeneeswsw
senwnwswnwenwnwwnwswnwenwnwnwnwnwnwwnw
eeswnenenweswneswwnwenwneeenwswsw
eeswswweeenweeeenweeneeee
nenwnwnwnwnwnwnwneswnenenenenw
seeseeenenweseeewsweewesesee
sweseswseseswneswswswnwsenwnwswsweswesese
nwwesewwwwwnwwnwwwwnenwswwnw
wseswwswwwwneswswwweewwswswwe
sewnwnwweseswnwswewswwswwnewsww
swwwwswwswnwswswwwswe
nwewneneswnwswswneswsewseeseewswse
swswnwswswseswswswsenwnwsweneneneseswwsw
eenenenwseeewseneenwseneneneenee
swswswseswswwneswnwswwswsweswswswswnew
sewnesweewnenewneneneseswneweneese
senwsewnwsenwnenwenwsenwnwnwnwnwwnwnwnw
senwneswnenwnwnwwnwnwsewnwnwsewwnwnw
swneneeneenwneeneeee
swwswwswnwswswswswwswswswsesw
nenwswnwnenwnwnwnenwenwnesweeswnenenene
sweeenwnewenwsenwneeeneswneneeseee
swenwenwsweswnweeeee
nwwnwnwnwwenwnwnwnwnwnwseswnwnwnwwneenw
nwnewnenwnwnwnwnwnwnwsenenwsenwnwnwnwnwse
swseweswswswesewnwwwnwwwseewnew
senwswnewnwnesenwwsewesesewnwseneswnw
eneeneeneneeenwneesweenwesewsee
sweenwswwwwwwwswswswswnw
eeseeseneweesewseseeneseswnwnew
wswnwseewnwwsenwwnewwwwsweseswne
nenwnwswnwnwneneneneenenenewnwnwsenene
wwswseswseswseswsewneswseseeswneswseswse
nwnwswwnwenwnwsweenwewswnwswnwnwne
senenenwwnenenenenenwsenewneneneswenwne
eeeseeneweneweenweneeeeesee
swneswswseswswwswswswswsenewswswswswwne
swneswswnwnwnwnenwenesweesewneenwswnenw
wwnenwnewsenwsesesenwwnwneswwewne
newenwwnwsewseneewseneeeneeneesw
enesewwnwnwnwswneenwnwswnwwwwnwwe
senwwwwwswwnewsweswww
nwswswwnewwswwwwwswwwsesew
nesweneewenwsweneseeneeenwnesww
seseswwseseswseseseswsesewneseswswnese
wseswnenwnewnwswneewnwwseenwenwene
nwnwwwwweseswwwnwwwwsenwnwneew
nwnwswnwnwnwswenenwnenwnenwnwnwne
seeeeeswwsewewnwwwenwwsenwne
neswnenwnwwwnenwenwnwnwneseneenwnenwnene
swseswseseswenwneenwswswswsewewswsw
nenwnwnenenwswnwnwnwnwnenwnw
seneneseswseswsesesesesesesenwwseseswsese
swwewewsewwswnwwneswswwwswwwsw
neeewseseeswesesenwnweewnwseswsesesw
ewsweneesenwnesewneseeneeneenee
nwnwnwnwnenwnwnenewnwenenwnw