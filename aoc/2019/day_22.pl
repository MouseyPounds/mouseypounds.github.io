#!/bin/perl -w
#
# https://adventofcode.com/2019/day/22
#

use strict;

use Carp;
use POSIX;

# Gather the input data into a list so that we can work with it later.
my @shuffle;
while (<DATA>) {
	chomp;
	push @shuffle, $_;
}

my $tracing = 0;

# Part 1 starts out innocuously enough with a 10007 deck size and a single implementation of the shuffle.
# Thus we can just take a straightforward approach and create & manipulate an entire deck array.
print "\nDay 22 P1 (Direct):\n";
my $target = 2019;
my $decksize = 10007;
my @deck = (0 .. $decksize-1);
for (my $i = 0; $i <= $#shuffle; $i++) {
	$_ = $shuffle[$i];
	if (/^deal into new stack/) {
		@deck = reverse @deck;
		print_deck(\@deck, "reverse", $target) if $tracing;
	} elsif (/^cut (-?\d+)/) {
		my $arg = $1;
		if ($arg < 0) {
			my @temp = splice(@deck,$arg);
			unshift @deck, @temp;
		} else {
			my @temp = splice(@deck,0,$arg);
			push @deck, @temp;
		}
		print_deck(\@deck, "cut $arg", $target) if $tracing;		
	} elsif (/^deal with increment (\d+)/) {
		my $inc = $1;
		my $i = 0;
		my @temp = @deck;
		for (my $c = 0; $c < $decksize; $c++) {
			$deck[$i] = $temp[$c];
			$i = ($i + $inc) % $decksize;
		}
		print_deck(\@deck, "deal $inc", $target) if $tracing;		
	}
}
# Then we can go through the deck and extract the card we want.
print_deck(\@deck, "full shuffle", $target);

# But part 2 ramps things up to the point where this simple approach no longer applies. Since we don't actually
# need to know the position of every single card but are instead tracking 1 card, we will develop a formula to
# do so and just apply that formula. (see create_function for details)
{
	# This part will use the BigInt library to handle modular exponentiation and multiplicative inverse which we will
	# need for later calculations. If we had to deal with these ourselves, one way is to follow the algorithms on
	# <https://cp-algorithms.com/algebra/binary-exp.html#toc-tgt-3>
	use bignum;
	# First we test the basic formula on part 1 to make sure we get the same answer
	print "\nDay 22 P1 (Modular Math):\n";
	my ($a, $b) = create_function($decksize, \@shuffle, $target);
	my $card = ($a*$target + $b) % $decksize;
	print "Position of card $target is $card\n";

	# Now we must deal with 2 complications from the actual part 2 puzzle:
	# 1) The shuffle is applied a staggeringly large number of times; thus our function needs to be applied over & over.
	#    When analyzing successive shuffles we get this pattern:
	#    n = 1: x' = Ax + B
	#    n = 2: x' = A(Ax + B) + B = A^2x + AB + B = A^2x + B(A + 1)
	#    n = 3: x' = A(A^2x + B(A+1)) + B = A^3x + A(B)(A+1) + B = A^3x + B(A^2 + A + 1)
	#    n = 4: x' = A(A^3x + B(A^2 + A + 1)) + B = A^4x + A(B)(A^2 + A + 1) + B = A^4x + B(A^3 + A^2 + A + 1)
	#    Thus what is happening is that after n shuffles, A has been raised to the n and B has been multiplied by
	#    the sum of the geometric series A^k for k=1 to n. Applying the partial sum formula for geometric series:
	#    A' = A^n
	#    B' = B*(1-A^n)/(1-A) = B*(A^n-1)/(A-1) 
	#    We can thus easily calculate a card x's final position with x' = A'x + B'.
	# 2) This time we don't have a target card, but a target final position which is a subtle distinction easily missed.
	#    We will take x' = A'x + B' and solve it for x to get x = (x' - B') * 1/A' and use that for our calculation.
	print "\nDay 22 P2 (Modular Math):\n";
	$target = 2020;
	$decksize = 119315717514047;
	my $shuffles = 101741582076661;
	($a, $b) = create_function($decksize, \@shuffle, $target);
	# Note, the bigint functions modify their first argument so we need to start with copies before using any.
	my $a_prime = $a->copy()->bmodpow($shuffles,$decksize);
	my $a_minus_1_inv = $a->copy()->bsub(1)->bmodinv($decksize);
	my $b_prime = ($b * ($a_prime - 1) * $a_minus_1_inv) % $decksize;
	my $a_prime_inv = $a_prime->copy()->bmodinv($decksize);
	$card = (($target - $b_prime) * $a_prime_inv) % $decksize;
	print "Card at position $target is $card\n";
	# Sanity check
	my $check = ($a_prime*$card + $b_prime) % $decksize;
	print "Position of card $card is $check\n";
	
}
exit;

# We will convert each base shuffle type into a linear function of the form x' = (Ax + B) % decksize
# Then we need to collapse all the various steps into a single function by composition.
# e.g. if first step applies x' = Ax + B and then second step applies x'' = Cx' + D, the end result is
# x'' = C(Ax + B) + D = CAx + (CB + D)
sub create_function {
	my $decksize = shift;
	my $actions = shift;
	my $test_value = shift;
	my $a = 1;
	my $b = 0;
	for (my $i = 0; $i <= $#$actions; $i++) {
		$_ = $actions->[$i];
		if (/^deal into new stack/) {
			# 'deal into new stack' can be thought of as x' = decksize - 1 - x = (-1)x + (decksize -1)
			# both of these will wind up in the range [0, decksize) so we don't actually need to %
			# C = -1, so CA = -A
			# D = decksize - 1, so CB + D = -B + decksize -1
			$a = -$a;
			$b = $decksize - $b - 1;
		} elsif (/^cut (-?\d+)/) {
			# 2) 'cut N' can be represented by x' = (x - N) = ((1)x + (decksize - N)) % decksize
			# Note: this assumes the % always returns a positive number for positive decksize, which is true in perl.
			# C = 1, so CA = A
			# D = decksize - N so CB + D = B + decksize - N; since we will % decksize later, we can simplify to B - N
			my $n = $1;
			$b = ($b - $n) % $decksize;
		} elsif (/^deal with increment (\d+)/) {
			# 3) 'deal with increment N' is basically just x' = x*N % decksize = ((N)x + (0)) % decksize
			# C = N, so CA = NA
			# D = 0 so CB + D = NB + 0 = NB
			my $n = $1;
			$a = ($a * $n) % $decksize;
			$b = ($b * $n) % $decksize;
		}
		if ($tracing) {
			my $extra = (defined $test_value) ? ($a * $test_value + $b) % $decksize : "";
			print "TRACE: ($a, $b) $extra\n";
		}
	}
	return ($a, $b);
}

sub print_deck {
	my $deckref = shift;
	my $desc = shift;
	my $target = shift;
	if (not defined $target) {
		print "FULL DECK ($desc): " . join(" ", @$deckref) . "\n";
	} else {
		for (my $i = 0; $i <= $#$deckref; $i++) {
			if ($deckref->[$i] == $target) {
				print "After $desc, position of card $target is $i\n";
				last;
			}
		}
	}
}

__DATA__
deal with increment 31
deal into new stack
cut -7558
deal with increment 49
cut 194
deal with increment 23
cut -4891
deal with increment 53
cut 5938
deal with increment 61
cut 7454
deal into new stack
deal with increment 31
cut 3138
deal with increment 53
cut 3553
deal with increment 61
cut -5824
deal with increment 42
cut -889
deal with increment 34
cut 7128
deal with increment 42
cut -9003
deal with increment 75
cut 13
deal with increment 75
cut -3065
deal with increment 74
cut -8156
deal with increment 39
cut 4242
deal with increment 24
cut -405
deal with increment 27
cut 6273
deal with increment 19
cut -9826
deal with increment 58
deal into new stack
cut -6927
deal with increment 65
cut -9906
deal with increment 31
deal into new stack
deal with increment 42
deal into new stack
deal with increment 39
cut -4271
deal into new stack
deal with increment 32
cut -8799
deal with increment 69
cut 2277
deal with increment 55
cut 2871
deal with increment 54
cut -2118
deal with increment 15
cut 1529
deal with increment 57
cut -4745
deal with increment 23
cut -5959
deal with increment 58
deal into new stack
deal with increment 48
deal into new stack
cut 2501
deal into new stack
deal with increment 42
deal into new stack
cut 831
deal with increment 74
cut -3119
deal with increment 33
cut 967
deal with increment 69
cut 9191
deal with increment 9
cut 5489
deal with increment 62
cut -9107
deal with increment 14
cut -7717
deal with increment 56
cut 7900
deal with increment 49
cut 631
deal with increment 14
deal into new stack
deal with increment 58
cut -9978
deal with increment 48
deal into new stack
deal with increment 66
cut -1554
deal into new stack
cut 897
deal with increment 36