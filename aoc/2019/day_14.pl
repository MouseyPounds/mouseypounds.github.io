#!/bin/perl
#
# https://adventofcode.com/2019/day/14

use strict;
use POSIX;
use List::Util qw(max min);

my %reactions = ();
my %endpoints = ();
my %waste = ();
my %need = ();
my %trueneed = ();
my $tracing = 0;
my $indent = "";

my $examples = readexamples();
my $i = 0;

foreach my $e (@$examples) {
	$i++;
	my @lines = split/\n/, $e->{'ex'};
	%reactions = ();
	%endpoints = ();
	while ($_ = shift @lines) {
		parseline($_);
	}
	print "Example $i, expected answer: $e->{'ans'}\n";
	my $f = calc_fuel(0);
	print "My answer: $f -- " . ( ($f == $e->{'ans'}) ? "correct!" : "WRONG" ) . "\n";
	$f = max_fuel($f);
	print "1 trillion ORE could produce $f FUEL\n\n";
}

%reactions = ();
%endpoints = ();
while (<DATA>) {
	chomp;
	parseline($_);
}
my $f = calc_fuel(0);
print "Part 1 Solution: 1 FUEL requires $f ORE.\n";
$f = max_fuel($f);
print "Part 2 Solution: 1 trillion ORE could produce $f FUEL\n";


exit;

sub parseline {
	$_ = shift;
	my ($r, $p) = /(.*) => (.*)/;
	my @reactants = split /,\s*/, $r;
	my ($qp, $ip) = split /\s+/, $p;
	$reactions{$ip} = { 'qty' => $qp, 'ingr' => [] };
	foreach $r (@reactants) {
		my ($qr, $ir) = split /\s+/, $r;
		push @{$reactions{$ip}{'ingr'}}, { 'qty' => $qr, 'item' => $ir };
		$endpoints{$ip} = { 'qty' => $qp, 'ore' => $qr } if ($ir eq 'ORE');
	}
}	

sub calc_fuel {
	$tracing = shift;
	%trueneed = ();
	%need = ();
	%waste = ();
	countem('FUEL', 1);
	my $amt = 0;
	foreach my $n (keys %need) {
		my $inc = $endpoints{$n}{'ore'} * POSIX::ceil($need{$n}/$endpoints{$n}{'qty'});
		my $waste = $inc*$endpoints{$n}{'qty'}/$endpoints{$n}{'ore'} - $need{$n};
		$amt += $inc;
		print "Making $need{$n} $n from $inc ORE (wasting $waste $n); ORE total now $amt\n" if $tracing;
		# reuse %waste & need to help with max calc
		$waste{$n} = $waste;
	}
	return $amt;
}

sub countem {
	my $goal = shift;
	my $multiplier = shift;
	my $truemultiplier = shift;
	$truemultiplier = $multiplier if (not defined $truemultiplier);
	print "${indent}Counting $multiplier $goal\n" if $tracing;
	if (not exists $reactions{$goal}) {
		if ($goal eq 'ORE') {
			return 1;
		} else {
			warn "Dead end on $goal\n";
			return 0;
		}
	}
	my $extra = 0;
	if (exists $waste{$goal}) {
		$extra = $waste{$goal};
	} else {
		$waste{$goal} = 0;
	}
	$indent .= "  ";
	print "${indent}Have $extra extra $goal\n" if ($extra > 0 and $tracing);
	my $recycle = min $multiplier, $extra;
	if ($recycle) {
		print "${indent}Recycling $recycle\n" if ($tracing);
		$multiplier -= $recycle;
		$waste{$goal} -= $recycle;
	}
	my $reaction_count = POSIX::ceil($multiplier/$reactions{$goal}{'qty'});
	print "${indent}Running reaction $reaction_count times\n" if ($tracing);
	my $waste = $reaction_count * $reactions{$goal}{'qty'} - $multiplier;
	print "${indent}This will waste $waste $goal\n" if ($waste > 0 and $tracing);
	$waste{$goal} += $waste;
	foreach my $i (@{$reactions{$goal}{'ingr'}}) {
		if (exists $endpoints{$i->{'item'}}) {
			$need{$i->{'item'}} = 0 if (not exists $need{$i->{'item'}});
			$trueneed{$i->{'item'}} = 0 if (not exists $trueneed{$i->{'item'}});
			my $inc = $i->{'qty'} * $reaction_count;
			$need{$i->{'item'}} += $inc;
			$trueneed{$i->{'item'}} += $i->{'qty'}*$truemultiplier/$reactions{$goal}{'qty'};
			print "${indent}Need $reaction_count * $i->{'qty'} = $inc more $i->{'item'}; total needed now $need{$i->{'item'}}\n" if $tracing;
		} else {
			countem($i->{'item'}, $reaction_count*$i->{'qty'}, $i->{'qty'}*$truemultiplier/$reactions{$goal}{'qty'});
		}
	}
	chop $indent;
	chop $indent;
}
	
sub max_fuel {
	# Calculations for pt 1 had to be done as integers and created small amounts of waste.
	# For part 2 because the amount of reactions is so large, we can simply use the "true" unrounded values.
	# calc_fuel & countem were adjusted to track these values alongside the pt 1 calculations.
	my $true_ore_per_fuel = 0;
	foreach my $n (keys %trueneed) {
		$true_ore_per_fuel += $endpoints{$n}{'ore'} * $trueneed{$n}/$endpoints{$n}{'qty'};
	}
	return POSIX::floor(1e12/$true_ore_per_fuel);
}

sub readexamples {
	my $e1 = <<"END_QUOTE";
10 ORE => 10 A
1 ORE => 1 B
7 A, 1 B => 1 C
7 A, 1 C => 1 D
7 A, 1 D => 1 E
7 A, 1 E => 1 FUEL
END_QUOTE
	my $e2 = <<"END_QUOTE";
9 ORE => 2 A
8 ORE => 3 B
7 ORE => 5 C
3 A, 4 B => 1 AB
5 B, 7 C => 1 BC
4 C, 1 A => 1 CA
2 AB, 3 BC, 4 CA => 1 FUEL
END_QUOTE
	my $e3 = <<"END_QUOTE";
157 ORE => 5 NZVS
165 ORE => 6 DCFZ
44 XJWVT, 5 KHKGT, 1 QDVJ, 29 NZVS, 9 GPVTF, 48 HKGWZ => 1 FUEL
12 HKGWZ, 1 GPVTF, 8 PSHF => 9 QDVJ
179 ORE => 7 PSHF
177 ORE => 5 HKGWZ
7 DCFZ, 7 PSHF => 2 XJWVT
165 ORE => 2 GPVTF
3 DCFZ, 7 NZVS, 5 HKGWZ, 10 PSHF => 8 KHKGT
END_QUOTE
	my $e4 = <<"END_QUOTE";
2 VPVL, 7 FWMGM, 2 CXFTF, 11 MNCFX => 1 STKFG
17 NVRVD, 3 JNWZP => 8 VPVL
53 STKFG, 6 MNCFX, 46 VJHF, 81 HVMC, 68 CXFTF, 25 GNMV => 1 FUEL
22 VJHF, 37 MNCFX => 5 FWMGM
139 ORE => 4 NVRVD
144 ORE => 7 JNWZP
5 MNCFX, 7 RFSQX, 2 FWMGM, 2 VPVL, 19 CXFTF => 3 HVMC
5 VJHF, 7 MNCFX, 9 VPVL, 37 CXFTF => 6 GNMV
145 ORE => 6 MNCFX
1 NVRVD => 8 CXFTF
1 VJHF, 6 MNCFX => 4 RFSQX
176 ORE => 6 VJHF
END_QUOTE
	my $e5 = <<"END_QUOTE";
171 ORE => 8 CNZTR
7 ZLQW, 3 BMBT, 9 XCVML, 26 XMNCP, 1 WPTQ, 2 MZWV, 1 RJRHP => 4 PLWSL
114 ORE => 4 BHXH
14 VRPVC => 6 BMBT
6 BHXH, 18 KTJDG, 12 WPTQ, 7 PLWSL, 31 FHTLT, 37 ZDVW => 1 FUEL
6 WPTQ, 2 BMBT, 8 ZLQW, 18 KTJDG, 1 XMNCP, 6 MZWV, 1 RJRHP => 6 FHTLT
15 XDBXC, 2 LTCX, 1 VRPVC => 6 ZLQW
13 WPTQ, 10 LTCX, 3 RJRHP, 14 XMNCP, 2 MZWV, 1 ZLQW => 1 ZDVW
5 BMBT => 4 WPTQ
189 ORE => 9 KTJDG
1 MZWV, 17 XDBXC, 3 XCVML => 2 XMNCP
12 VRPVC, 27 CNZTR => 2 XDBXC
15 KTJDG, 12 BHXH => 5 XCVML
3 BHXH, 2 VRPVC => 7 MZWV
121 ORE => 7 VRPVC
7 XCVML => 6 RJRHP
5 BHXH, 4 VRPVC => 5 LTCX
END_QUOTE

return [{'ex' => $e1, 'ans' => 31},{'ex' => $e2, 'ans' => 165},{'ex' => $e3, 'ans' => 13312},{'ex' => $e4, 'ans' => 180697},{'ex' => $e5, 'ans' => 2210736},];
}
	
__DATA__
4 JWXL => 8 SNBF
23 MPZQF, 10 TXVW, 8 JWXL => 6 DXLB
1 SNZDR, 5 XMWHC, 1 NJSC => 7 MHSB
2 TDHD, 11 TXVW => 4 RFNZ
2 VRCD, 1 FGZG, 3 JWXL, 1 HQTL, 2 MPZQF, 1 GTPJ, 5 HQNMK, 10 CQZQ => 9 QMTZB
3 SRDB, 2 ZMVLP => 3 DHFD
1 DFQGF => 1 CVXJR
193 ORE => 3 TRWXF
23 MFJMS, 4 HJXJH => 1 WVDF
5 TRWXF => 5 RXFJ
4 GZQH => 7 SNZDR
160 ORE => 4 PLPF
1 PLPF => 5 NJSC
2 QKPZ, 2 JBWFL => 7 HBSC
15 DXLB, 1 TDHD, 9 RFNZ => 5 DBRPW
7 PLPF, 4 GMZH => 7 PVNX
3 JWXL, 1 XWDNT, 4 CQZQ => 2 TPBXV
2 SNZDR => 9 WQWT
1 WMCF => 2 XWDNT
1 DFQGF, 8 FGZG => 5 LMHJQ
168 ORE => 9 GMZH
18 PVNX, 3 RXFJ => 4 JBWFL
5 WQWT => 1 CQZQ
6 QMTZB, 28 NVWM, 8 LMHJQ, 1 SNBF, 15 PLPF, 3 KMXPQ, 43 WVDF, 52 SVNS => 1 FUEL
164 ORE => 9 RXRMQ
2 MFJMS, 1 HJXJH, 7 WVDF => 7 NXWC
8 QDGBV, 1 WMCF, 2 MHSB => 6 HQTL
1 XMWHC => 8 MLSK
2 GMZH, 1 RXRMQ => 2 GZQH
4 MPZQF, 7 WVDF => 9 KHJMV
4 ZMVLP, 19 MLSK, 1 GZQH => 8 MFJMS
1 HQTL, 1 SXKQ => 2 PWBKR
3 SXKQ, 16 TXVW, 4 SVNS => 5 PSRF
4 MPZQF, 3 SVNS => 9 QDGBV
7 NXWC => 8 FGZG
7 TDHD, 1 WQWT, 1 HBSC => 9 TXVW
14 JBWFL => 5 LMXB
1 VRCD, 3 KHJMV => 3 RTBL
16 DHFD, 2 LBNK => 9 SXKQ
1 QDGBV, 1 NJSC => 6 JWXL
4 KHJMV => 3 HQNMK
5 GZQH => 6 LBNK
12 KHJMV, 19 FGZG, 3 XWDNT => 4 VRCD
5 DHFD, 3 MLSK => 8 QKPZ
4 KHJMV, 1 CQDR, 3 DBRPW, 2 CQZQ, 1 TPBXV, 15 TXVW, 2 TKSLM => 5 NVWM
2 KHJMV => 5 CQDR
1 CVXJR => 8 SVNS
35 RXFJ, 5 NJSC, 22 PVNX => 9 HJXJH
5 LMXB => 3 DFQGF
1 RXFJ => 2 SRDB
20 TPBXV, 1 RTBL, 13 PWBKR, 6 RFNZ, 1 LMXB, 2 CVXJR, 3 PSRF, 25 MPZQF => 9 KMXPQ
1 MHSB, 8 MPZQF => 3 TDHD
6 DHFD, 3 LBNK => 7 WMCF
1 SRDB => 7 ZMVLP
3 RXFJ => 8 XMWHC
1 MPZQF => 8 TKSLM
9 JBWFL, 22 WQWT => 8 MPZQF
12 HBSC, 15 TKSLM => 1 GTPJ