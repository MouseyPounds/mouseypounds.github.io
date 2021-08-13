#!/bin/perl -w
#
# https://adventofcode.com/2020/day/10

use strict;
use List::Util qw(max min);

print "2020 Day 10\n";
my %adapters = ();
while (<DATA>) {
	chomp;
	$adapters{$_} = 0;
}

my %diffs = ( 1 => 0, 2 => 0, 3 => 1 );
my $limit = max keys %adapters;
my $charge = 0;
while ($charge < $limit) {
	print "Checking charge $charge\r";
	if (exists $adapters{$charge + 1}) {
		$charge += 1;
		$diffs{1}++;
	} elsif (exists $adapters{$charge + 2}) {
		$charge += 2;
		$diffs{2}++;
	} elsif (exists $adapters{$charge + 3}) {
		$charge += 3;
		$diffs{3}++;
	} 
}

print "\n";
foreach my $d (sort keys %diffs) {
	print "$d => $diffs{$d}\n";
}
print "P1: Product of 1-dff * 3-diff is " . ($diffs{1} * $diffs{3}) . "\n";

# To count arrangements we first notice from pt 1 that there is never a difference of 2 numbers; it is always 1 or 3.
# Next we start looking at how many arrangements happen from different length sequences:
# A sequence of 1 number  e.g. 1, 4 has only 1 possible path
# A sequence of 2 numbers e.g. 1, 2, 5 also has only 1 possible path
# A sequence of 3 numbers e.g. 1, 2, 3, 6 has 2 possible paths 1-2-3 or 1-3
# A sequence of 4 numbers e.g. 1, 2, 3, 4, 7 has 4 possible paths 1-2-3-4, 1-3-4, 1-2-4, 1-4 as seen in example 1
# A sequence of 5 numbers e.g. 1, 2, 3, 4, 5, 8 has 7 possible paths 1-2-3-4-5, 1-2-3-5, 1-2-4-5, 1-2-5, 1-3-4-5, 1-3-5, 1-4-5
# A sequence of 6 numbers would have 13 possible paths, but the input does not appear to have sequences this large
# The result is that we can divide our input list into sequences of various lengths and multiply by the number of paths for each
$charge = 0;
my $count = 1;
my $seq = 1;
my @multipliers = (0,1,1,2,4,7,13);
while ($charge <= $limit) {
	if (exists $adapters{$charge + 1}) {
		$charge++;
		$seq++;
	} else {
		# sequence ended, do multiplier and skip ahead
		$count *= $multipliers[$seq];
		$seq = 1;
		$charge += 3;
	}
}
print "\nP2 (math): There are $count possible arrangements.\n";

$adapters{0} = 1;
my @sorted = (sort { $a <=> $b } keys %adapters);
# start at socket with path count 1. 
# add path count of current item to whatever it leads to.
for (my $i = 0; $i <= $#sorted; $i++) {
	my $n = $sorted[$i];
	for (my $j = 1; $j <= 3; $j++) {
		if (exists $adapters{$n+$j}) {
			$adapters{$n+$j} += $adapters{$n};
		}
	}
}
print "\nP2 (algorithm): There are $adapters{$limit} possible arrangements.\n";

__DATA__
165
78
151
15
138
97
152
64
4
111
7
90
91
156
73
113
93
135
100
70
119
54
80
170
139
33
123
92
86
57
39
173
22
106
166
142
53
96
158
63
51
81
46
36
126
59
98
2
16
141
120
35
140
99
121
122
58
1
60
47
10
87
103
42
132
17
75
12
29
112
3
145
131
18
153
74
161
174
68
34
21
24
85
164
52
69
65
45
109
148
11
23
129
84
167
27
28
116
110
79
48
32
157
130