#!/bin/perl -w
#
# https://adventofcode.com/2021/day/16
#

use strict;
use bigint;
use List::Util qw(sum product min max);

print "2021 Day 16\n";
my $input = do { local $/; <DATA> }; # slurp it

my $bitstring = join('', map { sprintf("%04b", hex($_)) } split('', $input));
#print "INPUT $input\nBITSTRING $bitstring\n";

my $pos = 0;
(my ($version_sum, $value)) = parse_bits($bitstring, \$pos);
print "Part 1: Sum of version numbers is $version_sum\n";
print "Part 2: Value of the packet is $value\n";

sub parse_bits {
	my $b = shift;
	my $p = shift;
	
	my $version = oct("0b" . read_next($b, $p, 3));
	my $version_sum = $version;
	my $type = oct("0b" . read_next($b, $p, 3));
	my $value = 0;
	
	if ($type == 4) {
		#Literal Value
		my $not_last = 1;
		my $string = "";
		while ($not_last) {
			$not_last = 0 + read_next($b, $p, 1);
			$string .= read_next($b, $p, 4);
		}
		$value = oct("0b$string");
	} else {
		#Operator
		my $length_type_id = read_next($b, $p, 1);
		my @subpacket = ();
		if ($length_type_id eq '0') {
			my $bit_count = oct("0b" . read_next($b, $p, 15));
			my $start_pos = $$p;
			while ($$p < $start_pos + $bit_count) {
				(my ($vs, $val)) = parse_bits($b, $p);
				$version_sum += $vs;
				push @subpacket, $val;
			}
		} else {
			my $subpacket_count = oct("0b" . read_next($b, $p, 11));
			for (my $sub = 0; $sub < $subpacket_count; $sub++) {
				(my ($vs, $val)) = parse_bits($b, $p);
				$version_sum += $vs;
				push @subpacket, $val;
			}
		}
		if ($type == 0) {
			$value = sum(@subpacket);
		} elsif ($type == 1) {
			$value = product(@subpacket);
		} elsif ($type == 2) {
			$value = min(@subpacket);
		} elsif ($type == 3) {
			$value = max(@subpacket);
		} elsif ($type == 5) {
			$value = ($subpacket[0] > $subpacket[1]) ? 1 : 0;
		} elsif ($type == 6) {
			$value = ($subpacket[0] < $subpacket[1]) ? 1 : 0;
		} elsif ($type == 7) {
			$value = ($subpacket[0] == $subpacket[1]) ? 1 : 0;
		}
	}
	return $version_sum, $value;
}

# Helper that extracts the next $num characters from a string and updates a position variable.
sub read_next {
	my $str = shift;
	my $p = shift;
	my $num = shift;
	die "substr out of bounds" if ($$p + $num > length $str);
	my $ret = substr($str, $$p, $num);
	$$p += $num;
	return $ret;
}

__DATA__
420D4900B8F31EFE7BD9DA455401AB80021504A2745E1007A21C1C862801F54AD0765BE833D8B9F4CE8564B9BE6C5CC011E00D5C001098F11A232080391521E4799FC5BB3EE1A8C010A00AE256F4963B33391DEE57DA748F5DCC011D00461A4FDC823C900659387DA00A49F5226A54EC378615002A47B364921C201236803349B856119B34C76BD8FB50B6C266EACE400424883880513B62687F38A13BCBEF127782A600B7002A923D4F959A0C94F740A969D0B4C016D00540010B8B70E226080331961C411950F3004F001579BA884DD45A59B40005D8362011C7198C4D0A4B8F73F3348AE40183CC7C86C017997F9BC6A35C220001BD367D08080287914B984D9A46932699675006A702E4E3BCF9EA5EE32600ACBEADC1CD00466446644A6FBC82F9002B734331D261F08020192459B24937D9664200B427963801A094A41CE529075200D5F4013988529EF82CEFED3699F469C8717E6675466007FE67BE815C9E84E2F300257224B256139A9E73637700B6334C63719E71D689B5F91F7BFF9F6EE33D5D72BE210013BCC01882111E31980391423FC4920042E39C7282E4028480021111E1BC6310066374638B200085C2C8DB05540119D229323700924BE0F3F1B527D89E4DB14AD253BFC30C01391F815002A539BA9C4BADB80152692A012CDCF20F35FDF635A9CCC71F261A080356B00565674FBE4ACE9F7C95EC19080371A009025B59BE05E5B59BE04E69322310020724FD3832401D14B4A34D1FE80233578CD224B9181F4C729E97508C017E005F2569D1D92D894BFE76FAC4C5FDDBA990097B2FBF704B40111006A1FC43898200E419859079C00C7003900B8D1002100A49700340090A40216CC00F1002900688201775400A3002C8040B50035802CC60087CC00E1002A4F35815900903285B401AA880391E61144C0004363445583A200CC2C939D3D1A41C66EC40