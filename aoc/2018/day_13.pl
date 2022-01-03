#!/bin/perl -w
#
# https://adventofcode.com/2018/day/13

use strict;
use List::Util qw(max);

print "2018 Day 13\n\n";
my $puzzle = do { local $/; <DATA> }; # slurp it
my @lines = split("\n", $puzzle);

my $width = length($lines[0]);
my $height = scalar(@lines);

# what track is under what cart at initialization
my %track = ( 'v' => '|', '^' => '|', '>' => '-', '<' => '-' );
# how to move (cart => [x,y])
my %move = ( '>' => [1,0], '<' => [-1,0], '^' => [0,-1], 'v' => [0,1] );
# how to turn at intersections using the L,Straight,R pattern (cart => cart);
my @turn = ({ 'v' => '>', '^' => '<', '>' => '^', '<' => 'v' },
			{ 'v' => 'v', '^' => '^', '>' => '>', '<' => '<' },
			{ 'v' => '<', '^' => '>', '>' => 'v', '<' => '^' });
# how to turn at corners (grid => {cart => cart})
my %corner = ( '/' => { '^' => '>', '<' => 'v', 'v' => '<', '>' => '^' },
				'\\' => { '^' => '<', '>' => 'v', 'v' => '>', '<', '^' });

my %grid = ();
my %cart = ();
my $num_carts = 0;

run_sim(1);
run_sim(2);
exit;

# Encapsulating into subroutines since we need to do the same basic thing for both parts but being super lazy about variables
sub init {
	%cart = ();
	%grid = ();
	$num_carts = 0;
	for (my $y = 0; $y < $height; $y++) {
		for (my $x = 0; $x < $width; $x++) {
			$grid{"$x,$y"} = substr($lines[$y], $x, 1);
			if ($grid{"$x,$y"} eq 'v' or $grid{"$x,$y"} eq '^' or $grid{"$x,$y"} eq '>' or $grid{"$x,$y"} eq '<') {
				$num_carts++;
				$cart{"$x,$y"} = {'c' => $grid{"$x,$y"}, 'i' => 0, 't' => -1};
				$grid{"$x,$y"} = $track{$grid{"$x,$y"}};
			}
		}
	}
}

sub run_sim {
	my $part = shift;
	
	init();
	my $tick = 0;
	my @last_cart = (-1,-1);
	
	tickloop: while ($num_carts > 1) {
		$tick++;
		for (my $y = 0; $y < $height; $y++) {
			for (my $x = 0; $x < $width; $x++) {
				if (defined $cart{"$x,$y"} and $cart{"$x,$y"}{'t'} < $tick) {
					#print qq(Tick $tick, found cart {$cart{"$x,$y"}{'c'},$cart{"$x,$y"}{'i'},$cart{"$x,$y"}{'t'}} at ($x, $y)\n);
					# check for turns and alter cart character appropriately
					if ($grid{"$x,$y"} eq '+') {
						$cart{"$x,$y"}{'c'} = $turn[$cart{"$x,$y"}{'i'}]{$cart{"$x,$y"}{'c'}};
						$cart{"$x,$y"}{'i'} = ($cart{"$x,$y"}{'i'} + 1) % 3;
					} elsif (defined $corner{$grid{"$x,$y"}}) {
						$cart{"$x,$y"}{'c'} = $corner{$grid{"$x,$y"}}{$cart{"$x,$y"}{'c'}};
					}
					# try to move the cart and check for crash
					my $xx = $x + $move{$cart{"$x,$y"}{'c'}}[0];
					my $yy = $y + $move{$cart{"$x,$y"}{'c'}}[1];
					#print qq(  Moving to ($xx,$yy) with orientation $cart{"$x,$y"}{'c'}\n);
					if (defined $cart{"$xx,$yy"}) {
						if ($part == 1) {
							@last_cart = ($xx, $yy);
							last tickloop;
						} else {
							delete $cart{"$xx,$yy"};
							delete $cart{"$x,$y"};
							$num_carts -= 2;
						}
					} else {
						$cart{"$xx,$yy"} = { 'c' => $cart{"$x,$y"}{'c'}, 'i' => $cart{"$x,$y"}{'i'}, 't' => $tick };
						delete $cart{"$x,$y"};
						@last_cart = ($xx, $yy);
					}
				}
			}
		}
	}

	if ($part == 1) {
		print "P1: The first crash happens at $last_cart[0], $last_cart[1] on tick $tick\n";
	} else {
		print "P2: The last remaining cart is at $last_cart[0], $last_cart[1] after tick $tick\n";
	}
}


# Example data for p1
#/->-\        
#|   |  /----\
#| /-+--+-\  |
#| | |  | v  |
#\-+-/  \-+--/
#  \------/   
__DATA__
               /-----------------------\        /---------------\  /--------------\                                                                   
               |                 /-----+--------+---------------+--+--------------+-----------------------------------------\                         
               |                 |     |        |            /--+--+--------------+-----------------------------------------+----------------\        
               |               /-+-----+--------+------------+--+--+---------\    |                                         |                |        
               |              /+-+-----+--------+------------+--+--+---------+----+-----------------------------------------+------\         |        
               |             /++-+-----+--------+------------+--+--+---------+----+-----------------------------------------+----\ |         |        
               |         /---+++-+-----+--------+------------+--+--+---------+----+---------------\                         |    | |         |        
               |         |   ||| |     |        |            |  |  |         | /--+---------------+-------------------------+----+-+-------\ |        
               |         |   ||| |     |       /+------------+--+--+---------+-+--+---------------+------------------\      |    | |       | |        
        /------+---------+---+++-+-----+-------++------------+--+--+---------+-+--+---------------+------\           |      |    | |       | |        
        |      |     /---+---+++-+-----+-------++----\       |  |  |         | |  |               |      |          /+------+----+-+-------+-+-------\
        |  /---+-----+---+---+++-+-----+-------++-\  |       \--+--+---------+-+--+---------------+------+----------++------+----+-+-------+-/       |
        |  |   |     |   |   ||| |     |       || |  |          |  |         | |  |               |      |          ||      |    | |       |         |
      /-+--+---+-----+---+---+++-+-----+-------++-+--+----------+--+---------+-+--+---\           |      |  /-------++------+----+-+-------+-------\ |
   /--+-+--+---+-----+---+---+++-+-----+-------++-+--+\         |  |         | |  |   |     /-----+------+--+-------++------+-\  | |       |       | |
   |  | |  |   |     |   |   \++-+-----+-------++-+--++---------+--+---------+-+--+---+-----+-----+------+--+-------++------+-+--/ |       |       | |
   |  | |  |   |     |   |    || |     |/------++-+--++---------+--+---------+-+--+---+-----+-----+---\  |  |      /++------+-+----+-------+---\   | |
   |  | |/-+---+-----+---+----++-+-----++------++-+--++---------+--+---------+\|  |   |     |     |   |  |  |      |||      | |    |       |   |   | |
   |  | || |   |     |   |    || |  /-<++------++-+--++---->----+--+---------+++--+---+-----+-----+---+--+--+------+++------+-+----+-------+--\|   | |
   |  | \+-+---+-----+---+----++-+--+--++------++-+--++---------+--+---------+++--+---+-----+-----+---+--/  |      |||      | |    |       |  ||   | |
   |  |  | |   |     |   |    || |  |  ||      || |  ||         |  |        /+++--+---+-----+-----+---+-----+------+++------+-+----+-------+-\||   | |
   |  |  | |   |     |   |    || |  |  ||      || |  ||         |  |        |||\--+---+-----+-----+---+-----+------+++------+-+----+-------/ |||   | |
   |  |  | |   |     |  /+----++-+--+--++------++-+--++---------+--+--------+++---+---+-----+--\  |   |     |      |||      | |    |         |||   | |
   |  |  | |   |     |  ||    || |/-+--++----\ ||/+--++---------+--+--------+++---+---+-----+--+--+---+-----+------+++------+-+----+\        |||   | |
   |  |  | |   |     |  ||    || || |  ||/---+-++++--++---------+--+--------+++---+---+\    |  |  |   |     |      |||      | |    ||        |||   | |
   |  |  | |   |     |  ||    || || |  |\+---+-++++--++---------+--+--------+++---+---++----+--+--+---/     |      |||      | |    ||        |||   | |
   |  |  | |   |     |  ||    || || |  | | /-+-++++--++-----\ /-+--+--------+++---+---++----+--+--+---------+------+++------+-+----++-----\  |||   | |
   |  |  | |   |     |  ||    || || |  | | | | |\++--++-----+-+-/  \--------+++---/   ||    |  |  |         |      |||      | |    ||     |  |||   | |
   | /+--+-+---+-----+--++----++-++-+--+-+-+-+-+-++--++-\   | |             |||   /---++----+--+--+--------\|      |||      | |    ||     |  |||   | |
   | ||  | |   |     |  ||  /-++-++-+--+-+-+-+-+-++-\|| |   | |             |||   |   ||    |  |  |        |\------+++------+-+----++-----+--+++---/ |
   | ||  | |   |     |  ||  | || || |  | | | | | || ||| |   | |           /-+++---+---++----+--+--+--------+-------+++-\    | |    ||     |  |||     |
   | ||  | |   |     |  ||  | || || |  | | | |/+-++-+++-+---+-+-----------+-+++-\ |   ||    |  |  |        |       ||| |    | |    ||     |  |||     |
   | ||  | |   \-----+--++--+-++-++-+--/ | | ||| || ||| |   | |           | ||| | |   ||    |  |  |/-------+-------+++-+\   | |    ||     |  |||     |
   | ||  | |         |  ||  | || || |    | | ||| || ||| |   | |           | ||| | |   ||  /-+--+--++-------+-------+++-++-\ | |    ||     |  |||     |
   | ||  | |         |  ||  | || || |    | |/+++-++-+++-+---+-+-----------+-+++-+-+---++--+-+\ |  ||       |       ||| || | | |    ||     |  |||     |
   | ||  | |         |  ||  | || |\-+----+-++/|| || ||| |   | |           | ||| | |   ||  | || |  ||       |       ||| || | | |    ||     |  |||     |
   | ||  | |         |  ||  v \+-+--+----+-++-++-++-+++-+---+-+-----------+-+++-+-+---++--+-++-+--++-------+-------+++-++-+-+-+----/|     |  |||     |
   \>++--+-+---------+--++--+--+-+--+----+-++-++-++-++/ |   | |        /--+-+++-+-+---++--+-++-+--++------\|       ||| || | ^ |     |     |  |||     |
     ||  | |         |  ||  |  | |  |    | || || || ||  |   |/+--------+--+-+++-+-+---++--+-++-+-\||      ||       ||| || | | |     |     |  |||     |
     ||/-+-+---------+--++--+--+-+--+----+-++-++-++-++--+---+++------\ |  | ||| | |   ||  | || | |||      ||       ||| || | | |     |     |  |||     |
     ||| | |         |  ||  |  | |  |   /+-++-++-++-++--+---+++------+-+--+-+++-+-+---++--+-++-+-+++------++--\    ||| || | | |     |     |  |||     |
     ||| | | /-------+--++--+--+-+--+---++-++-++-++-++--+---+++------+-+--+-+++-+-+---++--+-++-+-+++------++--+----+++-++\| | |     |     |  |||     |
     ||| | | |       |  ||  |  | |  |   || || || || ||  |   |||      | |  | \++-+-+---++--+-++-+-+++------++>-+----+++-++++-+-+-----+-----+--/||     |
     ||| | | |  /----+--++--+--+-+--+---++-++-++-++-++--+-\ |||      | |  |  || | |   ||  | || | |||      ||  |    ||| |||| | |     |     |   ||     |
     ||| | | |  |    |  ||  |  | |  |   || || ||/++-++--+-+-+++------+-+--+--++-+-+---++--+-++-+-+++------++--+----+++-++++-+-+-----+---\ |   ||     |
     ||| | | |/-+----+--++--+--+-+--+---++-++-+++++-++--+-+-+++------+-+--+--++-+-+---++--+-++-+-+++------++--+-\  |\+-++++-+-+-----+---+-+---++-----/
     ||| | | || |    |  ||  |  | |  |   || || ||||| ||/-+-+-+++------+-+-\|  || | |   ||  | || | |||      ||  | |  | | |||| | |     |   | |   ||      
     ||| | | || |    |  ||  |  | |  |   ||/++-+++++-+++-+-+-+++------+-+-++--++-+-+---++--+-++-+-+++------++--+-+-\| | |||| | |     |   | |   ||      
     ||| | | || |/---+--++--+--+-+--+---+++++-+++++-+++-+-+-+++------+-+-++--++-+-+---++--+-++-+-+++-\    ||  | | || | |||| | |     |   | |   ||      
     ||| | | || ||   |  ||  |  | |/-+---+++++-+++++-+++-+-+-+++------+-+-++--++-+-+---++--+-++-+-+++-+----++--+-+-++-+-++++-+-+-\   |   | |   ||      
     ||| | | || ||   |  ||  |  | \+-+---+++++-+++++-+++-+-+-+++------+-+-++--++-+-+---++--+-++-+-+++-+----++--+-+-++-+-++++-/ | |   |   | |   ||      
     ||| | | || ||   |  ||  |/-+--+-+---+++++-+++++-+++-+-+-+++---\  | | ||  || | |   ||  | || | ||| |    ||  | | || | ||||   | |   |   | |   ||      
     ||| | | || ||/--+--++--++-+--+-+---+++++-+++++-+++-+-+-+++---+--+-+-++--++-+-+\  ||  | || | ||| |    ||  | ^ || | ||||   | |   |   | |   ||      
     ||| | | ||/+++--+--++--++-+--+-+---+++++-+++++-+++-+-+-+++---+--+-+-++--++-+-++--++--+-++-+-+++-+----++--+\| || | ||||   | |   |   | |   ||      
     ||| | | ||^|||  |  || /++-+--+-+---+++++-+++++-+++-+-+-+++---+--+-+-++--++-+-++--++--+-++-+-+++-+----++--+++-++-+-++++---+-+\  |   | |   ||      
     ||| | | ||||||  |  || ||| |  | |   ||||| |||||/+++-+-+-+++---+--+-+-++--++-+-++--++--+-++-+-+++-+----++--+++-++-+-++++---+-++--+\  | |   ||      
/----+++-+-+-++++++--+--++-+++-+--+-+---+++++-+++++++++-+-+-+++---+--+-+-++--++-+-++--++--+\|| | ||| |    ||  ||| || | ||||   | ||  ||  | |   ||      
|    ||| | | ||||||  |  || ||| |  | |   ||||| ||||||||| | | |||   |  | | ||  || | \+--++--++++-+-+++-+----+/  ||| || | ||||   | ||  ||  | |   ||      
|    ||| | | ||||||  |  \+-+++-+--+-+---+++++-+++++++++-+-+-+++---+--+-+-++--++-+--+--++--++++-/ ||| |    |   ||| || | ||||   | ||  ||  | |   ||      
|    ||| | | ||||||  |   |/+++-+--+-+---+++++-+++++++++-+-+-+++---+--+-+-++--++-+--+--++--++++-\ ||| |    |   ||| || | ||||   | ||  ||  | |   ||      
|    ||| | | ||||||  |   ||||| |  | |  /+++++-+++++++++-+-+-+++---+--+-+-++--++-+--+--++--++++-+-+++-+----+---+++\|| | ||||   | ||  ||  | |   ||      
|    ||| | | \+++++--+---+++++-+--+-+--++++++-+++++++++-+-+-+++---+--+-+-++--++-+--+--++--++++-+-+++-+----+---++++++-+-++/|   | ||  ||  | |   ||      
|    ||| | |  \++++--+---+++++-+--+-+--++++++-+++++++++-+-+-+++---+--+-+-++--++-+--+--++--++++-+-+++-+----+---++/||| |/++-+---+-++--++--+-+---++-----\
|    ||| | |   \+++--+---+++++-+--+-+--++++++-+++++++++-+-+-+++---+--+-+-++--++-+--+--++--++++-+-+++-+----+---+/ ||| |||| |   | ||  ||  | |   ||     |
|    ||| | |    |||  |   ||||| \--+-+--++++++-+++++++++-+-+-+++---+--+-+-++--/| |  |  ||  ||\+-+-+++-+----+---+--+++-++++-+---/ ||  ||  | |   ||     |
|    ||| | |    |||  |   |||||    | |  |||\++-+++++++++-+-+-+++---+--+-+-++---+-+--+--++--++-+-+-+++-+----+---+--+/| |||| |     ||  || /+-+---++-\   |
|    ||| | |    |||  |   |||||    | |  ||\-++-+++++++++-+-+-+++---+--+-+-++---+-+--+--+/  || | | ||| |    |   |  | | |||| |     ||  || || |   || |   |
|    ||| |/+----+++--+---+++++----+-+--++\ || ||||||||| | | |||   |  | | ||   |/+--+--+---++-+-+-+++-+----+---+--+-+-++++-+\    ||  || || |   || |   |
|    ||| |||    |||  |   |||||  /-+-+--+++-++-+++++++++-+-+-+++---+--+-+-++---+++--+--+\  || | | ||| |    |  /+--+-+-++++-++----++--++-++-+---++-+-\ |
|    ||| |||    |||  |   ||||\--+-+-+--+++-++-+++++++++-+-+-+++---/  | | ||   |||  |  ||  || | | ||| |   /+--++--+-+-++++-++----++--++\|| |   || | | |
|    ||| |||/---+++--+--\|||\---+-+-+--+++-++-++++++/|| | | |||    /-+-+-++---+++--+--++--++-+-+-+++-+---++--++--+-+-++++-++----++--+++++-+---++-+-+\|
|    ||| ||||   |||  |  ||||    | | |  ||| || |||||| || | | |||    | | | ||   |||  |  ||  || | | ||| |   ||  ||  | \-++++-++----++--+++++-+---+/ | |||
|    ||| ||||   |||  |  ||||   /+-+-+--+++-++-++++++-++\| | |||   /+-+-+-++---+++--+--++--++-+-+-+++-+---++--++--+---++++>++----++--+++++-+-\ |  | |||
|    ||| ||||   |||  |  ||||   || \-+--+++-++-++++++-++++-+-+++---++-+-+-++---+++--+--++--++-+-+-+++-+---++--++--+---++++-++----/|  ||||| | | |  | |||
|    ||| |||| /-+++--+--++++---++---+\ |||/++-++++++-++++-+-+++---++\|/+-++---+++--+--++--++-+-+-+++-+---++--++--+---++++-++-----+--+++++-+\| |  | |||
| /--+++-++++-+-+++--+--++++---++---++-++++++-++++++-++++-+-+++---++++++-++---+++--+-\||  || | | ||| |   ||  ||  |/--++++-++-----+--+++++-+++-+\ | |||
| |  ||| |||| | |||  |  ||||   ||   || |||||| |||||| |||| | |||   |||||| ||   |||  | |||  || | | |||/+---++--++--++--++++-++-----+--+++++-+++-++\| |||
| |  ||| |||| | |||  |/-++++---++---++-++++++-++++++-++++-+\|||   |||||| ||  /+++--+-+++--++-+-+-+++++---++--++\ ||  |||| ||     |  ||^|| ||| |||| |||
|/+--+++-++++-+-+++--++-++++---++---++-++++++-++++++-++++-+++++---++++++-++--++++--+-+++--++-+-+\|||||   \+--+++-++--++++-++-----+--++/|| ||| |||| |||
|||  ||| |||| | |||  || ||||   ||   || |||||| |\++++-++++-+++++---++++++-++--++++--+-+++--++-+-+++++++----+--+++-++--/||| ||     |  || || ||| |||| |||
|||  |\+-++++-+-+++--++-++++---++---++-++++++-+-++++-++++-+++++---++++++-++--++++--+-+/|  || | |||||||    |  ||| ||   ||| ||     |  || || ||| |||| |||
|||  | | |||| | |||  || ||||   ||   || \+++++-+-++++-++++-+++++---++++++-++--++++--+-+-+--++-+-+++++++----+--+++-/|   ||| ||     |  || || ||| |||| |||
|||  | | |||| | |||  || ||||   ||   ||  ||||| | |\++-++++-+++++---++++++-++--++++--+-+-+--++-+-+++++++----+--+++--+---+++-++-----+--/| || ||| |||| |||
|||  | | |||| | |||  ||/++++---++---++--+++++-+-+-++-++++-+++++---++++++-++--++++--+-+-+--++-+-+++++++----+--+++--+---+++-++--\  |   | || ||| |||| |||
|||  | | ||\+-+-+++--+++++++---++---++--+++++-+-+-/| |||| |||||   |||||| ||  ||||  | | |  || | |||||||    |  |||  |   ||| ||  |  |  /+-++-+++-++++\|||
|||  | | || | | |||  |||||||   ||   ||  ||||| | |  | |||| |||||   |||||| ||  ||||  | | |  || | |||||\+----+--+++--+---+++-++--+--+--++-++-+++-++/|||||
|||  | | || | | |||  |||||||   ||   ||  ||||| | |  | |||| |||||   |||||| ||  ||||  | | |  || | ||||| |    |  |||  |   ||| ||  |  |  || || ||| || |||||
|||  | | || | | ||\--+++++++---++---++--+++++-+-+--+-++++-+++++---++++++-++--++++--/ | |  || | ||||| |    |  |||  |   ||| ||  |  |  || || ||| || |||||
|||  | | || | | ||   |\+++++---++---++--+++++-+-+--+-++++-+/|||   |||||| ||  ||||    | |  || | ||||| |    |  |||  |/--+++-++--+--+<-++-++\||| || |||||
|||  | | || | | ||  /+-+++++---++---++--+++++-+-+--+-++++-+-+++---++++++-++--++++----+-+--++-+-+++++-+----+--+++\ ||  ||| ||  |  |  || |||||| || |||||
|||  | |/++-+-+-++--++-+++++---++---++--+++++-+-+--+-++++-+-+++--\|||||| ||  ||||    | |  || | ||||| |    |  |||| ||  ||| ||  |  |  || |||||| || |||||
|||  | ||||/+-+-++--++-+++++--\|| /-++--+++++-+-+--+-++++-+-+++--+++++++-++--++++----+-+--++-+\||||| |    |  |||| ||  ||| ||  |  |  || |||||| || |||||
|\+--+-++++++-+-++--++-+++++--+++-+-++--+++++-+-+--+-++++-+-+++--+++++++-++--++++----+-+--++-+++/||| |    |  |||| ||  ||| ||  |  |  || |||||| || |||||
| |  | |||||| | ||  |\-+++++--+++-+-++--+++++-+-+--+-/||| | |||  ||||||| ||  ||||    | |  || ||| ||| |    |  |||| ||  ||| ||  |  |  || |||||| || |||||
| |  | |||||| | ||  |  |||||  ||| | ||  ||||| | |  |  ||| | |||  ||||||| ||  ||||    | |  || ||| ||| |    |  |||| ||  ||| ||  |  |  || |||||| || |||||
| |  | |||||| | ||  |  |||||  ||| | ||  ||||| |/+--+--+++-+-+++--+++++++-++--++++----+-+--++-+++-+++-+----+--++++-++--+++-++--+\ |  || |||||| || |||||
| |  | ||||||/+-++--+--+++++--+++-+-++-\||||| |||  |  ||| | |||  ||||||| || /++++----+-+--++-+++-+++-+--\ |  |||| ||  \++-++--++-+--++-++++++-++-++++/
| |  | |||||||| ||  |  ||||| /+++-+-++-++++++-+++--+--+++-+-+++-\||||||| |\-+++++----+-+--++-+++-+++-+--+-+--++++-++---/| ||  || |  || \+++++-++-/||| 
| |  | |||||||| ||  |  ||||| |||| | || |||||| |||  |  ||| | |\+-++++++++-+--+++++----+-+--++-+++-/|| |  | |  |||| ||    | ||  || |  ||  ||||| ||  ||| 
| |  | |||||||| ||  |  ||||| |||| | || |||||| |||  |  ||| | | | |||||||\-+--+++++----+-+--++-+++--++-+--+-/  |||| ||    | ||  || |  ||  ||||| ||  ||| 
| |  | |||||||| ||  |  ||||| |||| | || |||||| |||  |  ||| | | | |||||||  |  |||||    | |  \+-+++--++-+--+----++++-++----+-/|  || |  ||  ||||| ||  ||| 
| |  | |||||||| ||  \--+++++-++++-+-++-++++++-+++--+--+++-+-+-+-+++++++--+--+++++----+-+---+-+++--++-+--+----+++/ ^\----+--+--++-+--++--+/||| ||  ||| 
| |  | |||||||| ||     ||\++-++++-+-++-++++++-+++--+--+++-+-+-+-+++++++--+--+++++----+-+---+-+++--/| |  |    |||  |     |  |  || |  ||  | ||| ||  ||| 
| |  | |||||||| ||    /++-++-++++-+-++-++++++-+++--+--+++-+-+-+-+++++++--+--+++++----+-+---+\|||   | |  |    |||  |     |  |  || |  ||  | ||| ||  ||| 
| |  | |||||||| ||    ||| || |||| | || ||||\+-+++--+--+++-+-/ \-+++++++--+--+++++----+-+---+++++---+-+--+----+++--+-----+--+--++-+--++--+-/|| ||  ||| 
| |  | |||||||| ||    ||| || |||| | || |||| | |||  |  ||| |     |||||||  |  |||||    | |   |||||   | |  |    |||  |     |  |  || |  ||  |  || ||  ||| 
| |  | |||||||| ||    ||| || |||| | || |||| | |||  |  ||| |     |||||||  |  |||||    | |   |||||   \-+--+----+++--+-----/  |  || |  ||  |  || ||  ||| 
| |  | |||||||| || /--+++-++-++++-+-++-++++-+-+++--+--+++-+-----+++++++--+--+++++----+-+\  |||||     |  | /-<+++--+---\    |  || |  ||  |  || ||  ||| 
| |  | |||\++++-++-+--+++-++-++++-+-++-++/| | |||  |  ||| |     |||||||  |  |||||    | ||  |||||     |  | |  |||  |   |    |  || |  ||  |  || ||  ||| 
| |  | ||\-++++-++-+--+++-++-++++-+-++-++-+-+-+++--+--+++-+-----+++++++--+--++/||    | ||  |||||  /--+--+-+-\\++--+---+----+--++-+--++--+--++-++--+/| 
| |  | ||  |||| || |  ||| || |||| | || |\-+-+-+++--+--+++-+-----+++++++--+--++-++----+-++--+++++--+--+--+-+-+-/|  |   |    |  || |  ||  |  || ||  | | 
| |  | ||  |||| || |  ||| \+-++++-+-++-+--+-+-+++--+--+++-+-----+++++++--+--++-++----+-++--++++/  |  |  | | |  |  |   |    |  || |  ||  |  || ||  | | 
| |  | ||  |||| || |  |||  | |||| | \+-+--+-+-+++--+--+++-+-----+++++++--+--++-++----+-++--++++---+--+--+-+-+--+--+---+----+--++-+--++--+--++-/|  | | 
| |  | ||  |||| || |  |||  | |||\-+--+-+--+-+-+++--+--+++-+-----+++++++--+--++-++----+-/|  ||||   |  |  | | |  |  |   |    |  || |  ||  |  ||  |  | | 
| |  \-++--++++-++-+--+++--+-+++--+--+-+--+-+-+++--+--++/ |  /--+++++++--+--++-++----+--+--++++---+--+--+-+-+--+--+---+----+--++-+\ ||  |  ||  |  | | 
| |    ||  |||| || |  |\+--+-+++--+--+-+--+-+-+++--+--++--+--+--+++++++--+--++-++----+--+--++++---+--+--+-+-+--+--+---+----+--/| || ||  |  ||  |  | | 
| |    ||  |||| || |  | |  | |||  |  | |  | | ||\--+--++--+--+--+++++++--+--++-++----+--+--++++---+--+--+-+-+--+--+---+----+---+-++-++--/  ||  |  | | 
| \----++--++++-++-+--+-+--+-+++--+--+-+--+-+-++---+--++--+--+--+++++++--+--++-++----/  |  ||||   |  |  | | |  |  | /-+----+---+-++\||     ||  |  | | 
|   /--++--++++-++-+--+-+--+-+++--+--+-+--+-+-++---+--++-\|  |  |||||||  |  || ||       |  ||||   |  |  |/+-+--+--+-+-+----+--\| |||||     ||  |  | | 
|   |  ||  \+++-++-+--+-+--+-+/|  |  | |  | | ||   |  || ||  |  |||||||  |  || ||       |  ||||   |  |  ||\-+--+--+-+-/    |  || |||||     ||  |  | | 
|   |  ||   ||| || |  | |  | | |  |  | |  | | \+---+--++-++--+--+++++++--+--++-+/       |  ||||   \--+--++--/  |  | |      |  || |||||     ||  |  | | 
|   |  ||   ||| || |  | |  | | |  |  | |  | |  |   |  || ||  |  |||||||  |  || |        |  ||||      |  ||     | /+-+------+--++-+++++---\ ||  |  | | 
|   |  ||   ||| || |  \-+--+-+-+--+--+-+--+-+--+---+--++-++--+--+++++++--+--++-+--------+--+/||      |  ||     | || |      |  || |||||   | ||  |  | | 
|   |  ||   ||| || |    |  | | |  |  | |  | |  |   |  || ||  |  |||||||  |  || |        |  | ||      |  ||     | || |      |  || |||||   | ||  |  | | 
|   |  ||   |\+-++-+----+--+-+-+--+--+-/  | |  |   |  || ||  |  |||||||  |  || |        |  | ||      |  ||     | || |      |  || |||||   | ||  |  | | 
|   |  ||   | | || |    |  | | |  |  | /--+-+--+---+--++-++--+--+++++++--+--++-+--------+--+-++------+--++-----+-++-+------+--++-+++++---+-++\ |  | | 
|   |  ||   | | || |    |  | | \--+--+-+--+-+--+---+--+/ ||  \--+++++++--+--++-+--------+--+-++------+--++-----+-++-+----<-+--++-+/|||   | ||| |  | | 
|   |  ||   | | || |    |  | |    |  | |  | |  |   |  |  ||     |||||||  |  || \--------+--+-++------+--++-----+-++-+------/  || | |||   | ||| |  | | 
|   |  ||   | | || |    |  | |    |  | |  | |  |   |  |  ||     |||\+++--+--++----------+--+-++------+--++-----+-++-+---------++-+-+++---+-+++-+--+-/ 
|   |  ||   | | || |    |  | |    |  | |  | \--+---+--+--++-----+++-+++--+--++----------+--+-/|      |  ||     | || \---------++-+-/||   | ||| |  |   
|   |  |\---+-+-++-+----+--+-+----+--+-+--+----+---+--+--++-----+/| |||  |  ||          |  |  |      |  ||     | ||           || |  ||   | ||| |  |   
|   |/-+----+-+-++-+----+--+-+---\|  | |  \----+---+--+--++-----+-+-/||  |  |\----------+--+--+------+--++-----/ ||           || |  ||   | ||| |  |   
|   || |    | | || \----+--+-+---++--+-+-------+---+--+--++-----+-+--++--+--+-----------/  |  |      |  ||       ||           || |  ||   | ||| |  |   
|   || |    | | ||      |  | |   ||  | |       |   |  |  ||     | |  ||  |  |              |  |      |  ||       ||           || |  ||   | ||| |  |   
|   \+-+----+-+-++------+--+-+---++--+-+----->-+---+--+--/|     | |  ||  |  |              |  |      |  ||       ||           || |  ||   | ||| |  |   
|/---+-+----+\\-++------+--+-+---++--/ |       |   |  |   |     | |  ||  |  \--------------+--+------+--/|       ||           || |  ||   | ||| |  |   
||   | |    \+--++------/  | |   ||    |       |   |  |   |     | |  |\--+-----------------+--+------+---+-------++-----------++-+--++---+-/|| |  |   
||   | |     |  \+---------+-+---++----+-------+---+--+---/     | |  |   |                 |  |      |   \-------++-----------/| |  ||   |  || |  |   
||   | \-----+---+---------+-+---++----+-------+---+--+---------+-+--/   |                 |  |      |           ||            | |  \+---+--++-+--/   
||   |       |   |         | \---++----+-------+---+--+---------/ |      |                 |  |      |           \+------------+-+---+---/  || |      
||   \-------+---+---------+-----/|    |       |   |  |           |      |                 |  |      |            |            | |   |      || |      
|^           |   |         |      |    |       |   |  \-----------+------/                 |  |      |            \------------+-+---+------++-/      
||           |   |         |      |    |       |   \--------------+------------------------+--+------+-------------------------+-+---/      ||        
||           |   |         |      |    \-------+------------------+------------------------+--+------+-------------------------+-+----------+/        
|\-----------/   |         |      |            \------------------+------------------------+--+------+-------------------------/ |          |         
|                |         \------+-------------------------------+------------------------+--+------+---------------------------/          |         
|                |                \-------------------------------+------------------------+--/      |                                      |         
\----------------+------->----------------------------------------+------------------------/         |                                      |         
                 \------------------------------------------------+----------------------------------/                                      |         
                                                                  \-------------------------------------------------------------------------/         