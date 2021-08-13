#!/bin/perl -w
#
# https://adventofcode.com/2018/day/4

use strict;

print "2018 Day 4\n\n";
my $puzzle = do { local $/; <DATA> }; # slurp it
my @obs = sort split "\n", $puzzle;

my %sleep = ();
my $guard = -1;
my $start = -1;
foreach (@obs) {
	if (/(\d+) begins shift/) {
		$guard = $1;
	} elsif (/falls asleep/) {
		($start) = /:(\d+)/;
	} elsif (/wakes up/) {
		(my $end) = /:(\d+)/;
		foreach my $min ($start .. $end - 1) {
			$sleep{$guard}{$min}++;
		}
		$sleep{$guard}{'total'} += ($end - $start);
		$start = -1;
	} else {
		warn "Unknown log entry: $_\n";
	}
}

my $max = -1;
my $sleepiest = -1;
foreach $guard (keys %sleep) {
	if ($sleep{$guard}{'total'} > $max) {
		$max = $sleep{$guard}{'total'};
		$sleepiest = $guard;
	}
}
$max = -1;
my $min = -1;
foreach my $k (keys %{$sleep{$sleepiest}}) {
	next if ($k eq 'total');
	if ($sleep{$sleepiest}{$k} > $max) {
		$max = $sleep{$sleepiest}{$k};
		$min = $k;
	}
}
print "P1: Guard $sleepiest spent $sleep{$sleepiest}{'total'} minutes asleep with a max of $max times on minute $min (solution = ", ($sleepiest * $min), ").\n";

$min = -1;
$max = -1;
$sleepiest = -1;
foreach $guard (keys %sleep) {
	foreach my $k (keys %{$sleep{$guard}}) {
		next if ($k eq 'total');
		if ($sleep{$guard}{$k} > $max) {
			$max = $sleep{$guard}{$k};
			$sleepiest = $guard;
			$min = $k;
		}
	}
}
print "\nP2: Guard $sleepiest slept $max times on minute $min (solution = ", ($sleepiest * $min), ").\n";

__DATA__
[1518-06-23 00:43] wakes up
[1518-06-01 00:26] wakes up
[1518-08-29 00:02] falls asleep
[1518-03-06 00:02] Guard #1783 begins shift
[1518-04-28 00:01] Guard #1553 begins shift
[1518-06-19 00:51] wakes up
[1518-03-20 00:30] wakes up
[1518-04-03 00:53] wakes up
[1518-04-09 00:23] wakes up
[1518-04-12 00:35] wakes up
[1518-07-07 00:00] falls asleep
[1518-10-08 23:51] Guard #751 begins shift
[1518-08-07 00:03] Guard #3023 begins shift
[1518-09-20 23:56] Guard #827 begins shift
[1518-04-18 00:58] wakes up
[1518-04-11 00:45] falls asleep
[1518-02-23 00:41] falls asleep
[1518-02-24 00:41] falls asleep
[1518-10-31 00:43] falls asleep
[1518-09-19 00:00] falls asleep
[1518-11-22 00:32] wakes up
[1518-05-03 00:05] falls asleep
[1518-10-29 00:58] wakes up
[1518-08-29 23:57] Guard #283 begins shift
[1518-09-16 00:03] Guard #2207 begins shift
[1518-09-12 00:38] falls asleep
[1518-11-06 00:03] Guard #3499 begins shift
[1518-10-01 00:12] falls asleep
[1518-08-11 23:56] Guard #2411 begins shift
[1518-07-05 00:03] falls asleep
[1518-11-12 00:30] wakes up
[1518-04-01 00:42] falls asleep
[1518-11-11 00:50] falls asleep
[1518-09-26 00:06] falls asleep
[1518-03-08 00:00] Guard #283 begins shift
[1518-10-28 00:04] falls asleep
[1518-03-24 00:37] wakes up
[1518-06-17 00:40] falls asleep
[1518-07-15 00:04] Guard #1669 begins shift
[1518-04-12 00:04] Guard #1193 begins shift
[1518-08-24 23:58] Guard #101 begins shift
[1518-08-11 00:48] wakes up
[1518-09-22 00:02] falls asleep
[1518-06-07 00:35] wakes up
[1518-06-03 00:02] Guard #691 begins shift
[1518-03-24 00:01] Guard #449 begins shift
[1518-07-12 00:15] falls asleep
[1518-11-11 00:38] wakes up
[1518-09-20 00:30] wakes up
[1518-11-22 00:16] falls asleep
[1518-08-06 00:26] falls asleep
[1518-08-09 00:38] falls asleep
[1518-04-11 00:00] Guard #2383 begins shift
[1518-05-06 00:54] falls asleep
[1518-08-16 00:47] wakes up
[1518-03-28 00:43] falls asleep
[1518-10-17 00:18] falls asleep
[1518-03-11 00:00] Guard #2383 begins shift
[1518-05-05 00:57] wakes up
[1518-07-26 00:59] wakes up
[1518-11-23 00:47] wakes up
[1518-03-06 00:47] wakes up
[1518-02-28 00:38] falls asleep
[1518-02-23 00:33] falls asleep
[1518-04-06 00:27] falls asleep
[1518-10-24 00:55] wakes up
[1518-08-30 00:58] wakes up
[1518-02-22 00:40] wakes up
[1518-08-19 23:47] Guard #2857 begins shift
[1518-10-24 00:53] falls asleep
[1518-04-18 00:50] wakes up
[1518-05-30 00:19] wakes up
[1518-06-21 23:57] Guard #449 begins shift
[1518-09-04 00:43] falls asleep
[1518-11-01 00:54] wakes up
[1518-06-23 00:31] falls asleep
[1518-03-05 00:27] wakes up
[1518-05-10 00:33] wakes up
[1518-02-26 00:23] wakes up
[1518-07-03 23:57] Guard #1783 begins shift
[1518-03-21 00:06] falls asleep
[1518-04-06 00:52] wakes up
[1518-10-02 00:40] falls asleep
[1518-03-28 00:03] Guard #283 begins shift
[1518-09-26 00:00] Guard #2411 begins shift
[1518-06-29 00:56] falls asleep
[1518-05-13 00:02] falls asleep
[1518-09-10 00:15] falls asleep
[1518-04-14 00:47] wakes up
[1518-03-03 00:30] falls asleep
[1518-04-16 00:23] falls asleep
[1518-07-01 00:48] falls asleep
[1518-02-28 00:51] wakes up
[1518-10-10 00:51] falls asleep
[1518-06-16 00:22] falls asleep
[1518-05-24 00:26] falls asleep
[1518-05-18 00:38] falls asleep
[1518-02-28 00:00] Guard #1783 begins shift
[1518-10-19 00:01] Guard #101 begins shift
[1518-04-03 00:47] falls asleep
[1518-06-15 00:04] Guard #3499 begins shift
[1518-09-18 00:23] falls asleep
[1518-09-18 00:01] falls asleep
[1518-04-16 00:34] wakes up
[1518-06-05 00:28] wakes up
[1518-06-05 23:58] Guard #283 begins shift
[1518-05-01 00:59] wakes up
[1518-03-14 00:41] falls asleep
[1518-06-20 00:56] wakes up
[1518-11-13 00:53] falls asleep
[1518-09-15 00:00] falls asleep
[1518-09-26 00:49] wakes up
[1518-07-15 00:57] wakes up
[1518-05-30 00:09] falls asleep
[1518-05-23 23:59] Guard #2273 begins shift
[1518-05-07 00:02] Guard #1229 begins shift
[1518-07-02 00:59] wakes up
[1518-08-10 00:15] falls asleep
[1518-04-22 00:58] wakes up
[1518-04-06 00:31] wakes up
[1518-04-13 00:03] Guard #2857 begins shift
[1518-03-22 00:49] wakes up
[1518-11-14 00:57] falls asleep
[1518-06-04 00:02] Guard #691 begins shift
[1518-05-22 00:28] falls asleep
[1518-11-20 00:22] falls asleep
[1518-04-02 00:31] falls asleep
[1518-10-10 00:57] wakes up
[1518-03-27 00:58] wakes up
[1518-10-06 00:04] falls asleep
[1518-03-28 00:59] wakes up
[1518-03-01 00:21] falls asleep
[1518-08-18 00:13] falls asleep
[1518-03-31 00:47] falls asleep
[1518-05-08 00:10] falls asleep
[1518-07-02 00:57] falls asleep
[1518-05-24 00:38] wakes up
[1518-04-24 23:57] Guard #3499 begins shift
[1518-03-10 00:09] falls asleep
[1518-08-27 00:30] wakes up
[1518-08-08 00:51] wakes up
[1518-05-23 00:33] falls asleep
[1518-06-15 00:59] wakes up
[1518-07-18 00:12] wakes up
[1518-03-14 23:56] Guard #1193 begins shift
[1518-09-07 00:52] wakes up
[1518-03-02 00:59] wakes up
[1518-05-29 23:58] Guard #449 begins shift
[1518-07-03 00:24] wakes up
[1518-05-03 00:37] wakes up
[1518-08-31 00:00] Guard #283 begins shift
[1518-10-23 00:48] wakes up
[1518-03-05 00:41] falls asleep
[1518-03-10 00:59] wakes up
[1518-08-09 00:52] wakes up
[1518-06-17 00:02] Guard #691 begins shift
[1518-04-26 00:07] falls asleep
[1518-03-06 00:16] wakes up
[1518-07-26 00:57] falls asleep
[1518-07-14 00:44] wakes up
[1518-10-27 00:55] wakes up
[1518-11-13 00:01] Guard #827 begins shift
[1518-07-26 00:43] wakes up
[1518-09-13 00:01] Guard #2411 begins shift
[1518-07-29 00:55] wakes up
[1518-07-08 00:10] wakes up
[1518-04-17 00:53] wakes up
[1518-06-20 00:00] Guard #349 begins shift
[1518-08-23 00:23] falls asleep
[1518-04-23 00:46] falls asleep
[1518-09-07 00:20] falls asleep
[1518-08-24 00:59] wakes up
[1518-03-16 00:51] wakes up
[1518-06-29 00:53] wakes up
[1518-07-12 00:56] wakes up
[1518-05-11 00:19] falls asleep
[1518-09-10 23:57] Guard #1783 begins shift
[1518-04-26 00:40] falls asleep
[1518-06-11 23:54] Guard #2273 begins shift
[1518-10-23 00:01] Guard #3023 begins shift
[1518-05-20 00:02] Guard #283 begins shift
[1518-06-27 00:36] wakes up
[1518-03-26 00:51] wakes up
[1518-08-10 23:57] Guard #827 begins shift
[1518-06-14 00:31] wakes up
[1518-10-17 00:04] Guard #2411 begins shift
[1518-09-08 23:57] Guard #283 begins shift
[1518-06-10 00:32] wakes up
[1518-11-11 00:00] falls asleep
[1518-09-19 00:59] wakes up
[1518-03-20 00:11] falls asleep
[1518-06-09 00:11] falls asleep
[1518-09-14 00:01] Guard #691 begins shift
[1518-03-01 23:59] Guard #827 begins shift
[1518-04-17 23:56] Guard #1193 begins shift
[1518-08-21 00:24] falls asleep
[1518-05-09 00:04] Guard #1783 begins shift
[1518-09-28 00:14] falls asleep
[1518-06-26 00:37] falls asleep
[1518-09-25 00:51] wakes up
[1518-10-29 00:56] falls asleep
[1518-03-18 00:57] falls asleep
[1518-05-27 00:39] falls asleep
[1518-10-14 00:54] wakes up
[1518-03-19 00:56] wakes up
[1518-10-10 00:01] Guard #691 begins shift
[1518-04-03 00:59] wakes up
[1518-04-29 00:53] wakes up
[1518-08-05 00:55] wakes up
[1518-07-09 00:03] Guard #1193 begins shift
[1518-04-17 00:52] falls asleep
[1518-03-23 00:37] falls asleep
[1518-04-28 00:13] falls asleep
[1518-10-05 00:18] wakes up
[1518-10-03 00:00] Guard #2411 begins shift
[1518-09-29 00:38] wakes up
[1518-06-06 00:44] wakes up
[1518-03-07 00:46] falls asleep
[1518-10-12 00:20] falls asleep
[1518-03-29 00:55] wakes up
[1518-02-27 00:13] falls asleep
[1518-08-10 00:04] Guard #3023 begins shift
[1518-05-26 23:57] Guard #2207 begins shift
[1518-08-09 00:17] falls asleep
[1518-05-29 00:02] Guard #1193 begins shift
[1518-06-25 00:01] Guard #691 begins shift
[1518-04-20 00:34] wakes up
[1518-02-26 00:14] falls asleep
[1518-10-29 00:52] wakes up
[1518-06-30 00:47] falls asleep
[1518-11-18 00:34] wakes up
[1518-07-18 00:02] Guard #449 begins shift
[1518-06-13 00:46] wakes up
[1518-06-30 00:49] wakes up
[1518-07-12 00:53] falls asleep
[1518-10-16 00:59] wakes up
[1518-05-29 00:42] falls asleep
[1518-07-22 00:08] falls asleep
[1518-02-22 00:38] falls asleep
[1518-06-30 00:39] wakes up
[1518-09-04 23:59] Guard #3023 begins shift
[1518-07-08 00:07] falls asleep
[1518-07-11 00:18] falls asleep
[1518-05-28 00:00] Guard #1973 begins shift
[1518-10-15 00:58] wakes up
[1518-11-06 00:39] falls asleep
[1518-07-23 00:19] falls asleep
[1518-08-05 00:06] falls asleep
[1518-08-05 00:03] Guard #2411 begins shift
[1518-04-04 00:01] Guard #1973 begins shift
[1518-10-07 00:29] falls asleep
[1518-09-22 23:59] Guard #691 begins shift
[1518-06-04 00:36] wakes up
[1518-03-29 00:39] falls asleep
[1518-08-01 00:25] wakes up
[1518-07-01 00:02] Guard #1193 begins shift
[1518-11-01 00:43] falls asleep
[1518-03-21 00:18] wakes up
[1518-02-23 00:51] wakes up
[1518-11-16 00:17] falls asleep
[1518-02-24 00:53] wakes up
[1518-09-12 00:51] wakes up
[1518-05-12 00:58] wakes up
[1518-03-23 00:47] wakes up
[1518-06-28 00:34] falls asleep
[1518-05-27 00:54] wakes up
[1518-10-26 00:57] wakes up
[1518-11-02 00:17] falls asleep
[1518-03-12 00:35] falls asleep
[1518-04-08 00:34] wakes up
[1518-07-06 00:34] falls asleep
[1518-08-19 00:55] wakes up
[1518-08-03 00:49] falls asleep
[1518-11-09 00:32] wakes up
[1518-06-06 00:14] falls asleep
[1518-11-12 00:59] wakes up
[1518-04-28 00:42] wakes up
[1518-08-11 00:52] wakes up
[1518-08-18 00:20] wakes up
[1518-07-04 00:33] wakes up
[1518-09-20 00:04] Guard #2207 begins shift
[1518-07-09 00:24] falls asleep
[1518-10-22 00:35] falls asleep
[1518-10-08 00:50] wakes up
[1518-05-25 00:00] Guard #691 begins shift
[1518-02-22 00:48] wakes up
[1518-08-07 00:53] wakes up
[1518-11-14 00:36] falls asleep
[1518-04-15 00:59] wakes up
[1518-06-13 00:24] falls asleep
[1518-07-22 00:51] falls asleep
[1518-08-19 00:19] falls asleep
[1518-03-06 00:13] falls asleep
[1518-04-25 00:46] wakes up
[1518-02-25 00:22] falls asleep
[1518-03-11 00:23] wakes up
[1518-11-14 00:54] wakes up
[1518-09-06 00:31] falls asleep
[1518-03-14 00:02] Guard #751 begins shift
[1518-04-07 00:54] wakes up
[1518-09-21 23:50] Guard #2857 begins shift
[1518-10-04 00:46] wakes up
[1518-08-08 00:49] falls asleep
[1518-08-20 00:05] falls asleep
[1518-05-29 00:08] falls asleep
[1518-07-08 00:00] Guard #3023 begins shift
[1518-06-04 00:45] falls asleep
[1518-09-20 00:24] falls asleep
[1518-05-21 00:38] falls asleep
[1518-10-15 00:01] Guard #691 begins shift
[1518-06-25 00:16] falls asleep
[1518-10-05 00:53] wakes up
[1518-03-30 23:58] Guard #3023 begins shift
[1518-10-11 00:45] falls asleep
[1518-10-31 00:00] Guard #2273 begins shift
[1518-11-17 00:02] Guard #1669 begins shift
[1518-04-21 00:01] Guard #751 begins shift
[1518-11-04 00:46] wakes up
[1518-05-05 00:02] Guard #3499 begins shift
[1518-03-14 00:42] wakes up
[1518-06-10 00:00] Guard #3499 begins shift
[1518-07-30 00:35] falls asleep
[1518-06-15 23:56] Guard #1783 begins shift
[1518-06-25 00:53] wakes up
[1518-05-18 00:09] falls asleep
[1518-09-18 00:19] wakes up
[1518-04-14 00:39] falls asleep
[1518-07-10 00:56] falls asleep
[1518-06-01 00:46] falls asleep
[1518-05-26 00:00] Guard #1193 begins shift
[1518-02-27 00:01] Guard #349 begins shift
[1518-05-08 00:36] wakes up
[1518-04-29 00:28] falls asleep
[1518-05-15 00:52] wakes up
[1518-11-22 00:48] wakes up
[1518-08-17 00:35] wakes up
[1518-04-15 00:56] falls asleep
[1518-07-27 00:00] Guard #283 begins shift
[1518-09-18 00:57] wakes up
[1518-11-15 00:03] Guard #1289 begins shift
[1518-07-30 00:46] wakes up
[1518-10-06 00:35] falls asleep
[1518-04-22 00:42] falls asleep
[1518-08-13 00:02] Guard #827 begins shift
[1518-04-12 00:50] wakes up
[1518-11-08 00:58] wakes up
[1518-03-12 00:51] wakes up
[1518-05-02 00:00] Guard #2383 begins shift
[1518-08-02 00:50] falls asleep
[1518-09-02 00:46] wakes up
[1518-07-23 00:02] Guard #349 begins shift
[1518-10-23 23:58] Guard #283 begins shift
[1518-08-08 00:02] Guard #2273 begins shift
[1518-04-19 00:01] falls asleep
[1518-04-26 00:56] wakes up
[1518-09-28 00:24] wakes up
[1518-09-23 00:59] wakes up
[1518-08-01 00:31] falls asleep
[1518-09-25 00:27] falls asleep
[1518-05-30 00:23] falls asleep
[1518-06-18 00:23] wakes up
[1518-05-13 00:59] wakes up
[1518-03-07 00:52] wakes up
[1518-08-13 23:53] Guard #283 begins shift
[1518-07-01 23:56] Guard #2411 begins shift
[1518-07-08 00:48] wakes up
[1518-10-21 00:59] wakes up
[1518-06-26 00:04] Guard #3023 begins shift
[1518-07-04 00:21] falls asleep
[1518-02-24 00:02] Guard #101 begins shift
[1518-06-27 23:57] Guard #1553 begins shift
[1518-09-03 23:58] Guard #2207 begins shift
[1518-08-11 00:51] falls asleep
[1518-08-13 00:41] falls asleep
[1518-04-26 00:51] falls asleep
[1518-11-16 00:04] Guard #2411 begins shift
[1518-09-09 00:40] falls asleep
[1518-07-28 00:00] Guard #1783 begins shift
[1518-03-13 00:05] falls asleep
[1518-10-02 00:54] wakes up
[1518-04-21 00:31] falls asleep
[1518-06-10 23:56] Guard #2273 begins shift
[1518-09-23 00:39] wakes up
[1518-08-23 00:54] wakes up
[1518-05-10 00:03] Guard #1193 begins shift
[1518-03-16 00:46] wakes up
[1518-08-19 00:45] wakes up
[1518-03-03 23:56] Guard #2207 begins shift
[1518-03-31 23:58] Guard #1723 begins shift
[1518-03-28 23:59] Guard #1553 begins shift
[1518-02-21 00:03] falls asleep
[1518-03-17 00:22] falls asleep
[1518-10-18 00:08] falls asleep
[1518-09-22 00:57] wakes up
[1518-06-27 00:10] falls asleep
[1518-10-11 00:50] wakes up
[1518-03-11 00:57] wakes up
[1518-09-14 00:33] falls asleep
[1518-05-30 00:57] wakes up
[1518-08-21 00:04] Guard #827 begins shift
[1518-04-03 00:01] Guard #2207 begins shift
[1518-10-10 23:56] Guard #3499 begins shift
[1518-08-14 00:46] wakes up
[1518-10-25 00:04] Guard #1289 begins shift
[1518-08-06 00:48] falls asleep
[1518-06-23 00:55] wakes up
[1518-05-22 00:54] wakes up
[1518-05-14 00:51] wakes up
[1518-05-04 00:04] Guard #2411 begins shift
[1518-10-13 00:59] wakes up
[1518-04-07 00:03] Guard #691 begins shift
[1518-10-05 00:50] falls asleep
[1518-05-28 00:16] wakes up
[1518-03-25 00:20] falls asleep
[1518-07-03 00:11] falls asleep
[1518-03-16 00:14] falls asleep
[1518-08-22 00:33] wakes up
[1518-04-06 00:04] Guard #349 begins shift
[1518-08-28 23:51] Guard #2207 begins shift
[1518-03-18 00:30] wakes up
[1518-09-13 00:46] falls asleep
[1518-07-10 00:47] falls asleep
[1518-04-20 00:02] falls asleep
[1518-04-27 00:06] falls asleep
[1518-05-10 00:50] wakes up
[1518-08-15 00:48] falls asleep
[1518-08-01 00:39] wakes up
[1518-07-24 00:05] falls asleep
[1518-04-16 00:51] falls asleep
[1518-04-08 00:00] Guard #349 begins shift
[1518-05-25 00:40] falls asleep
[1518-08-25 00:54] falls asleep
[1518-07-18 00:48] wakes up
[1518-10-14 00:02] Guard #751 begins shift
[1518-07-28 00:46] falls asleep
[1518-04-29 23:56] Guard #2207 begins shift
[1518-06-10 00:52] wakes up
[1518-04-09 00:03] falls asleep
[1518-09-02 00:20] falls asleep
[1518-03-12 00:08] falls asleep
[1518-07-22 00:00] Guard #1553 begins shift
[1518-03-09 00:33] falls asleep
[1518-10-22 00:40] wakes up
[1518-06-07 00:21] falls asleep
[1518-06-24 00:03] Guard #691 begins shift
[1518-09-27 00:01] falls asleep
[1518-06-01 23:59] Guard #1783 begins shift
[1518-09-30 00:03] falls asleep
[1518-10-25 23:51] Guard #827 begins shift
[1518-11-21 23:58] Guard #691 begins shift
[1518-05-14 23:58] Guard #449 begins shift
[1518-05-14 00:41] wakes up
[1518-10-23 00:33] falls asleep
[1518-06-05 00:48] falls asleep
[1518-11-18 23:56] Guard #691 begins shift
[1518-10-22 00:48] falls asleep
[1518-03-13 00:20] wakes up
[1518-06-06 23:56] Guard #2411 begins shift
[1518-03-26 00:41] falls asleep
[1518-09-25 00:06] falls asleep
[1518-03-20 23:59] Guard #1723 begins shift
[1518-06-29 00:23] falls asleep
[1518-05-25 00:31] wakes up
[1518-11-19 23:57] Guard #1193 begins shift
[1518-10-23 00:51] falls asleep
[1518-08-03 00:54] wakes up
[1518-03-04 23:57] Guard #1783 begins shift
[1518-05-16 23:58] Guard #751 begins shift
[1518-05-12 00:46] wakes up
[1518-04-21 00:55] wakes up
[1518-09-29 00:34] falls asleep
[1518-06-29 00:45] falls asleep
[1518-09-26 23:52] Guard #349 begins shift
[1518-07-19 00:57] falls asleep
[1518-03-15 00:30] falls asleep
[1518-06-03 00:45] wakes up
[1518-11-20 23:50] Guard #2857 begins shift
[1518-03-31 00:57] falls asleep
[1518-03-09 00:16] falls asleep
[1518-03-08 00:09] falls asleep
[1518-03-18 00:59] wakes up
[1518-08-26 00:55] wakes up
[1518-04-27 00:33] wakes up
[1518-09-09 00:53] wakes up
[1518-02-25 00:02] Guard #2273 begins shift
[1518-10-24 00:49] wakes up
[1518-03-22 00:01] Guard #449 begins shift
[1518-02-22 00:02] Guard #827 begins shift
[1518-03-12 00:40] wakes up
[1518-11-19 00:44] falls asleep
[1518-06-11 00:29] wakes up
[1518-04-17 00:11] falls asleep
[1518-08-31 00:41] wakes up
[1518-05-23 00:03] Guard #101 begins shift
[1518-05-28 00:09] falls asleep
[1518-02-27 00:32] wakes up
[1518-04-05 00:04] Guard #2273 begins shift
[1518-05-05 00:32] falls asleep
[1518-07-12 00:47] wakes up
[1518-11-04 00:06] falls asleep
[1518-10-28 00:37] wakes up
[1518-07-05 00:45] wakes up
[1518-05-21 00:18] falls asleep
[1518-08-12 00:48] wakes up
[1518-09-24 00:00] Guard #2411 begins shift
[1518-05-10 00:44] falls asleep
[1518-07-07 00:48] wakes up
[1518-06-28 00:46] wakes up
[1518-11-03 00:49] falls asleep
[1518-05-22 00:51] falls asleep
[1518-05-26 00:28] falls asleep
[1518-09-08 00:20] falls asleep
[1518-04-13 00:59] wakes up
[1518-03-22 23:56] Guard #101 begins shift
[1518-05-02 00:58] wakes up
[1518-03-24 23:57] Guard #2207 begins shift
[1518-04-30 00:25] falls asleep
[1518-11-18 00:52] wakes up
[1518-07-22 00:27] falls asleep
[1518-08-25 00:47] wakes up
[1518-04-03 00:57] falls asleep
[1518-09-15 00:49] wakes up
[1518-06-11 00:15] wakes up
[1518-08-24 00:03] Guard #827 begins shift
[1518-04-05 00:14] falls asleep
[1518-10-03 00:58] wakes up
[1518-06-19 00:40] wakes up
[1518-05-12 00:00] Guard #1783 begins shift
[1518-06-18 23:58] Guard #1553 begins shift
[1518-05-04 00:51] wakes up
[1518-03-26 00:02] Guard #349 begins shift
[1518-09-30 00:04] wakes up
[1518-10-30 00:08] falls asleep
[1518-04-15 23:57] Guard #2383 begins shift
[1518-05-25 00:09] falls asleep
[1518-09-13 00:26] falls asleep
[1518-08-14 23:56] Guard #283 begins shift
[1518-07-27 00:32] falls asleep
[1518-07-17 00:59] wakes up
[1518-10-15 00:41] wakes up
[1518-09-16 00:28] falls asleep
[1518-09-16 00:37] wakes up
[1518-06-28 00:11] wakes up
[1518-09-17 23:49] Guard #691 begins shift
[1518-03-22 00:10] falls asleep
[1518-08-08 00:43] wakes up
[1518-08-28 00:44] wakes up
[1518-06-17 00:50] falls asleep
[1518-09-23 00:54] falls asleep
[1518-09-21 00:31] falls asleep
[1518-03-30 00:31] falls asleep
[1518-06-07 23:59] Guard #2311 begins shift
[1518-07-15 00:37] falls asleep
[1518-08-27 00:23] falls asleep
[1518-07-31 00:00] Guard #1723 begins shift
[1518-08-16 23:59] Guard #1553 begins shift
[1518-10-13 00:00] Guard #1973 begins shift
[1518-08-01 00:23] falls asleep
[1518-09-24 00:54] wakes up
[1518-07-19 00:03] Guard #283 begins shift
[1518-03-13 00:25] falls asleep
[1518-10-08 00:23] falls asleep
[1518-09-21 00:53] wakes up
[1518-09-30 23:58] Guard #2383 begins shift
[1518-09-27 00:56] wakes up
[1518-09-28 00:03] Guard #2411 begins shift
[1518-11-13 00:54] wakes up
[1518-05-06 00:46] wakes up
[1518-05-18 00:01] Guard #2857 begins shift
[1518-08-15 23:57] Guard #283 begins shift
[1518-08-01 23:57] Guard #101 begins shift
[1518-11-14 00:41] wakes up
[1518-08-03 00:16] wakes up
[1518-05-21 00:00] Guard #449 begins shift
[1518-05-01 00:05] falls asleep
[1518-10-15 23:46] Guard #1669 begins shift
[1518-06-14 00:41] falls asleep
[1518-03-09 00:23] wakes up
[1518-09-24 00:48] falls asleep
[1518-10-19 00:38] falls asleep
[1518-10-04 00:04] falls asleep
[1518-08-25 23:56] Guard #349 begins shift
[1518-11-17 23:57] Guard #2273 begins shift
[1518-11-17 00:16] falls asleep
[1518-03-12 23:52] Guard #2857 begins shift
[1518-09-19 00:49] falls asleep
[1518-07-28 00:39] wakes up
[1518-05-12 23:50] Guard #1553 begins shift
[1518-09-23 00:45] falls asleep
[1518-06-29 00:59] wakes up
[1518-07-24 00:52] wakes up
[1518-07-26 00:27] wakes up
[1518-06-03 00:39] falls asleep
[1518-06-07 00:34] falls asleep
[1518-09-24 23:56] Guard #2273 begins shift
[1518-03-01 00:53] wakes up
[1518-10-14 00:39] falls asleep
[1518-07-17 00:54] falls asleep
[1518-06-17 00:11] falls asleep
[1518-07-25 00:19] falls asleep
[1518-06-18 00:04] falls asleep
[1518-04-12 00:41] falls asleep
[1518-11-09 00:06] falls asleep
[1518-05-08 00:51] falls asleep
[1518-10-03 00:50] falls asleep
[1518-05-10 00:11] falls asleep
[1518-11-11 23:56] Guard #2273 begins shift
[1518-07-10 00:59] wakes up
[1518-04-04 00:14] falls asleep
[1518-06-30 00:00] Guard #449 begins shift
[1518-05-09 00:50] wakes up
[1518-07-23 00:54] wakes up
[1518-03-10 00:00] Guard #3499 begins shift
[1518-08-14 00:58] wakes up
[1518-09-30 00:18] falls asleep
[1518-11-03 00:00] Guard #1723 begins shift
[1518-04-12 00:30] falls asleep
[1518-04-11 00:57] wakes up
[1518-03-15 00:49] wakes up
[1518-08-08 00:40] falls asleep
[1518-07-25 00:45] wakes up
[1518-11-09 00:56] wakes up
[1518-03-13 00:57] falls asleep
[1518-05-18 00:56] wakes up
[1518-09-02 23:49] Guard #2383 begins shift
[1518-02-20 23:47] Guard #101 begins shift
[1518-09-17 00:14] falls asleep
[1518-07-08 00:34] falls asleep
[1518-07-13 00:41] falls asleep
[1518-05-08 00:52] wakes up
[1518-09-14 00:59] wakes up
[1518-05-22 00:00] Guard #751 begins shift
[1518-06-08 23:57] Guard #283 begins shift
[1518-06-24 00:47] falls asleep
[1518-08-11 00:34] falls asleep
[1518-04-09 23:58] Guard #827 begins shift
[1518-06-04 00:06] falls asleep
[1518-09-09 23:58] Guard #1193 begins shift
[1518-04-19 00:43] wakes up
[1518-06-16 00:23] wakes up
[1518-07-23 23:49] Guard #691 begins shift
[1518-03-25 00:59] wakes up
[1518-06-05 00:53] wakes up
[1518-11-18 00:15] falls asleep
[1518-07-13 00:59] wakes up
[1518-04-15 00:44] falls asleep
[1518-03-02 23:57] Guard #3023 begins shift
[1518-11-18 00:40] falls asleep
[1518-08-06 00:49] wakes up
[1518-04-16 23:56] Guard #1669 begins shift
[1518-03-27 00:51] wakes up
[1518-07-14 00:03] wakes up
[1518-05-27 00:10] falls asleep
[1518-08-15 00:57] wakes up
[1518-09-08 00:00] Guard #1723 begins shift
[1518-11-22 00:46] falls asleep
[1518-05-20 00:51] wakes up
[1518-03-03 00:59] wakes up
[1518-02-26 00:00] Guard #2207 begins shift
[1518-03-06 00:33] falls asleep
[1518-08-21 00:52] wakes up
[1518-11-23 00:12] falls asleep
[1518-11-07 00:53] wakes up
[1518-06-09 00:59] wakes up
[1518-09-27 00:11] wakes up
[1518-03-30 00:58] wakes up
[1518-06-21 00:57] wakes up
[1518-09-30 00:47] falls asleep
[1518-11-12 00:45] falls asleep
[1518-08-25 00:57] wakes up
[1518-10-26 00:02] falls asleep
[1518-06-29 00:40] wakes up
[1518-03-16 00:03] Guard #1723 begins shift
[1518-11-09 00:36] falls asleep
[1518-06-02 00:47] falls asleep
[1518-09-06 00:54] wakes up
[1518-11-12 00:17] falls asleep
[1518-08-04 00:54] wakes up
[1518-08-14 00:05] falls asleep
[1518-08-02 23:49] Guard #751 begins shift
[1518-04-19 00:23] wakes up
[1518-11-18 00:49] falls asleep
[1518-03-18 00:06] falls asleep
[1518-08-28 00:00] Guard #449 begins shift
[1518-02-21 00:45] wakes up
[1518-05-30 23:57] Guard #2411 begins shift
[1518-07-18 00:06] falls asleep
[1518-06-02 00:49] wakes up
[1518-11-16 00:52] wakes up
[1518-07-06 00:58] wakes up
[1518-10-15 00:50] falls asleep
[1518-07-14 00:02] falls asleep
[1518-04-19 23:50] Guard #1193 begins shift
[1518-10-11 23:59] Guard #349 begins shift
[1518-11-09 23:50] Guard #1553 begins shift
[1518-04-18 00:54] falls asleep
[1518-05-15 00:48] falls asleep
[1518-08-26 00:53] falls asleep
[1518-06-21 00:00] Guard #449 begins shift
[1518-04-26 00:45] wakes up
[1518-06-17 23:52] Guard #1973 begins shift
[1518-11-09 00:00] Guard #449 begins shift
[1518-03-26 00:26] falls asleep
[1518-07-25 00:55] falls asleep
[1518-10-06 00:17] wakes up
[1518-07-04 00:54] wakes up
[1518-11-14 00:59] wakes up
[1518-07-20 00:02] Guard #1783 begins shift
[1518-04-07 00:07] falls asleep
[1518-11-21 00:23] wakes up
[1518-07-04 00:44] falls asleep
[1518-11-02 00:55] wakes up
[1518-04-18 00:06] falls asleep
[1518-08-28 00:36] falls asleep
[1518-06-10 00:36] falls asleep
[1518-11-20 00:50] wakes up
[1518-11-03 00:32] wakes up
[1518-05-15 00:32] falls asleep
[1518-04-26 00:36] wakes up
[1518-05-27 00:30] wakes up
[1518-10-30 00:48] wakes up
[1518-07-14 00:28] falls asleep
[1518-04-23 23:59] Guard #2207 begins shift
[1518-07-10 00:50] wakes up
[1518-09-01 00:33] falls asleep
[1518-09-04 00:50] wakes up
[1518-05-14 00:17] falls asleep
[1518-05-29 00:59] wakes up
[1518-05-22 00:47] wakes up
[1518-07-31 00:51] falls asleep
[1518-03-04 00:45] wakes up
[1518-08-02 00:55] wakes up
[1518-06-23 00:54] falls asleep
[1518-04-26 23:58] Guard #1669 begins shift
[1518-06-10 00:20] falls asleep
[1518-05-20 00:17] falls asleep
[1518-08-31 00:47] falls asleep
[1518-06-04 00:56] wakes up
[1518-03-02 00:24] falls asleep
[1518-11-01 00:00] Guard #101 begins shift
[1518-05-21 00:44] wakes up
[1518-06-21 00:17] falls asleep
[1518-09-04 00:23] falls asleep
[1518-03-17 00:48] wakes up
[1518-04-17 00:22] wakes up
[1518-09-01 00:56] wakes up
[1518-02-25 00:33] wakes up
[1518-06-07 00:40] falls asleep
[1518-11-18 00:41] wakes up
[1518-09-23 00:49] wakes up
[1518-11-02 00:04] Guard #101 begins shift
[1518-09-13 00:52] wakes up
[1518-11-05 00:56] wakes up
[1518-11-10 00:03] falls asleep
[1518-07-28 00:49] wakes up
[1518-04-24 00:44] wakes up
[1518-07-10 00:03] Guard #827 begins shift
[1518-07-25 00:59] wakes up
[1518-04-30 00:55] wakes up
[1518-06-13 00:00] Guard #2207 begins shift
[1518-09-01 23:57] Guard #2273 begins shift
[1518-03-19 00:11] falls asleep
[1518-10-16 00:04] falls asleep
[1518-10-04 00:37] wakes up
[1518-06-28 00:24] falls asleep
[1518-04-10 00:30] falls asleep
[1518-07-19 00:54] wakes up
[1518-08-31 00:52] wakes up
[1518-06-11 00:20] falls asleep
[1518-10-27 00:35] falls asleep
[1518-04-08 00:14] falls asleep
[1518-11-05 00:15] falls asleep
[1518-07-31 00:46] wakes up
[1518-06-09 00:48] falls asleep
[1518-02-25 00:57] wakes up
[1518-09-29 00:00] Guard #1973 begins shift
[1518-09-03 00:04] falls asleep
[1518-08-06 00:03] Guard #1783 begins shift
[1518-03-13 00:58] wakes up
[1518-03-03 00:45] falls asleep
[1518-10-31 00:30] wakes up
[1518-03-24 00:29] falls asleep
[1518-04-19 00:33] falls asleep
[1518-10-09 00:05] falls asleep
[1518-10-15 00:08] falls asleep
[1518-05-25 00:59] wakes up
[1518-05-17 00:50] falls asleep
[1518-07-30 00:03] Guard #449 begins shift
[1518-05-16 00:09] falls asleep
[1518-02-23 00:38] wakes up
[1518-08-07 00:40] falls asleep
[1518-06-14 00:03] falls asleep
[1518-05-02 23:50] Guard #449 begins shift
[1518-10-31 00:07] falls asleep
[1518-05-21 00:33] wakes up
[1518-06-07 00:28] wakes up
[1518-08-16 00:42] falls asleep
[1518-04-06 00:46] falls asleep
[1518-06-26 23:57] Guard #449 begins shift
[1518-10-19 23:59] Guard #1229 begins shift
[1518-09-23 00:12] falls asleep
[1518-09-07 00:04] Guard #449 begins shift
[1518-04-23 00:11] wakes up
[1518-05-06 00:02] Guard #283 begins shift
[1518-07-09 00:30] wakes up
[1518-03-20 00:00] Guard #1669 begins shift
[1518-03-09 00:00] Guard #827 begins shift
[1518-08-22 00:49] wakes up
[1518-11-12 00:53] falls asleep
[1518-08-18 00:04] Guard #2207 begins shift
[1518-07-11 00:47] wakes up
[1518-07-19 00:42] falls asleep
[1518-05-11 00:53] wakes up
[1518-02-28 00:25] wakes up
[1518-08-19 00:51] falls asleep
[1518-11-07 00:09] falls asleep
[1518-04-24 00:22] falls asleep
[1518-08-09 00:33] wakes up
[1518-08-27 00:02] Guard #349 begins shift
[1518-11-07 23:58] Guard #2411 begins shift
[1518-09-20 00:56] wakes up
[1518-03-11 00:35] falls asleep
[1518-02-25 00:39] falls asleep
[1518-08-20 00:06] wakes up
[1518-06-15 00:43] falls asleep
[1518-08-25 00:39] falls asleep
[1518-07-27 00:48] wakes up
[1518-05-29 00:26] wakes up
[1518-03-04 00:38] falls asleep
[1518-10-18 00:02] Guard #3499 begins shift
[1518-05-17 00:40] wakes up
[1518-07-06 23:54] Guard #101 begins shift
[1518-07-05 23:58] Guard #449 begins shift
[1518-06-17 00:19] wakes up
[1518-06-12 00:01] falls asleep
[1518-07-22 00:44] wakes up
[1518-04-18 23:52] Guard #2207 begins shift
[1518-03-30 00:01] Guard #283 begins shift
[1518-10-18 00:41] wakes up
[1518-11-14 00:49] falls asleep
[1518-11-06 23:57] Guard #1783 begins shift
[1518-03-31 00:52] wakes up
[1518-07-13 23:53] Guard #2273 begins shift
[1518-07-26 00:25] falls asleep
[1518-10-27 00:03] Guard #1669 begins shift
[1518-04-30 23:54] Guard #827 begins shift
[1518-06-17 00:55] wakes up
[1518-08-04 00:52] falls asleep
[1518-07-31 00:52] wakes up
[1518-03-07 00:00] Guard #1193 begins shift
[1518-05-15 23:56] Guard #2207 begins shift
[1518-09-28 00:59] wakes up
[1518-08-01 00:00] Guard #1669 begins shift
[1518-11-04 00:00] Guard #1553 begins shift
[1518-06-05 00:05] falls asleep
[1518-06-19 00:10] falls asleep
[1518-04-01 00:52] wakes up
[1518-06-14 00:55] wakes up
[1518-10-04 00:41] falls asleep
[1518-03-27 00:55] falls asleep
[1518-06-12 00:04] wakes up
[1518-06-22 00:40] wakes up
[1518-10-12 00:40] wakes up
[1518-06-23 00:01] Guard #2857 begins shift
[1518-09-17 00:29] wakes up
[1518-09-11 23:59] Guard #283 begins shift
[1518-08-22 00:23] falls asleep
[1518-05-14 00:04] Guard #349 begins shift
[1518-09-03 00:32] wakes up
[1518-06-01 00:58] wakes up
[1518-05-14 00:46] falls asleep
[1518-03-26 00:37] wakes up
[1518-09-27 00:45] falls asleep
[1518-05-06 00:37] falls asleep
[1518-07-28 00:18] falls asleep
[1518-08-19 00:02] Guard #1973 begins shift
[1518-03-17 23:56] Guard #2383 begins shift
[1518-06-11 00:07] falls asleep
[1518-03-26 23:59] Guard #827 begins shift
[1518-10-06 23:59] Guard #449 begins shift
[1518-05-09 00:23] falls asleep
[1518-02-22 00:45] falls asleep
[1518-04-15 00:04] Guard #1783 begins shift
[1518-09-05 00:45] falls asleep
[1518-11-04 23:57] Guard #2857 begins shift
[1518-03-17 00:02] Guard #1553 begins shift
[1518-10-09 00:57] wakes up
[1518-10-05 00:10] falls asleep
[1518-08-30 00:42] falls asleep
[1518-09-19 00:40] wakes up
[1518-09-05 23:58] Guard #827 begins shift
[1518-08-06 00:37] wakes up
[1518-08-22 00:43] falls asleep
[1518-10-30 00:00] Guard #349 begins shift
[1518-09-16 23:59] Guard #2273 begins shift
[1518-03-08 00:57] wakes up
[1518-03-11 23:59] Guard #1783 begins shift
[1518-03-20 00:47] falls asleep
[1518-06-28 23:59] Guard #1973 begins shift
[1518-10-23 00:57] wakes up
[1518-07-11 23:58] Guard #2411 begins shift
[1518-06-24 00:52] wakes up
[1518-03-11 00:20] falls asleep
[1518-07-25 00:00] Guard #3023 begins shift
[1518-05-02 00:49] falls asleep
[1518-08-31 00:14] falls asleep
[1518-08-12 00:16] falls asleep
[1518-06-28 00:08] falls asleep
[1518-09-05 00:54] wakes up
[1518-04-22 00:53] wakes up
[1518-04-22 00:56] falls asleep
[1518-05-17 00:07] falls asleep
[1518-04-04 00:23] wakes up
[1518-10-07 23:58] Guard #449 begins shift
[1518-07-20 00:10] falls asleep
[1518-08-03 00:01] falls asleep
[1518-06-26 00:48] wakes up
[1518-10-24 00:30] falls asleep
[1518-05-15 00:37] wakes up
[1518-04-22 23:54] Guard #691 begins shift
[1518-10-07 00:33] wakes up
[1518-10-27 23:47] Guard #3023 begins shift
[1518-05-06 00:59] wakes up
[1518-09-13 00:34] wakes up
[1518-07-19 00:59] wakes up
[1518-10-31 00:47] wakes up
[1518-11-03 00:59] wakes up
[1518-04-05 00:49] wakes up
[1518-08-22 23:56] Guard #751 begins shift
[1518-07-26 00:03] Guard #2273 begins shift
[1518-10-19 00:39] wakes up
[1518-04-21 23:58] Guard #2411 begins shift
[1518-05-11 00:03] Guard #2411 begins shift
[1518-03-27 00:39] falls asleep
[1518-07-16 23:59] Guard #101 begins shift
[1518-09-29 23:50] Guard #1553 begins shift
[1518-09-08 00:50] wakes up
[1518-07-28 23:59] Guard #1723 begins shift
[1518-11-10 00:57] wakes up
[1518-11-12 00:47] wakes up
[1518-07-16 00:02] Guard #1289 begins shift
[1518-04-02 00:48] wakes up
[1518-08-09 00:00] Guard #1553 begins shift
[1518-08-24 00:45] falls asleep
[1518-03-09 00:53] wakes up
[1518-03-20 00:49] wakes up
[1518-11-13 23:59] Guard #449 begins shift
[1518-10-06 00:48] wakes up
[1518-08-13 00:51] wakes up
[1518-07-04 23:50] Guard #3023 begins shift
[1518-03-31 00:59] wakes up
[1518-11-19 00:50] wakes up
[1518-04-14 00:03] Guard #1669 begins shift
[1518-06-01 00:06] falls asleep
[1518-09-18 23:54] Guard #1669 begins shift
[1518-11-22 23:59] Guard #1553 begins shift
[1518-05-19 00:03] Guard #2311 begins shift
[1518-05-23 00:50] wakes up
[1518-06-28 00:30] wakes up
[1518-06-22 00:35] falls asleep
[1518-04-02 00:00] Guard #1783 begins shift
[1518-07-26 00:32] falls asleep
[1518-10-22 00:53] wakes up
[1518-09-20 00:45] falls asleep
[1518-10-03 23:52] Guard #3499 begins shift
[1518-07-01 00:54] wakes up
[1518-05-07 23:56] Guard #1553 begins shift
[1518-05-16 00:56] wakes up
[1518-03-21 00:36] wakes up
[1518-03-05 00:49] wakes up
[1518-06-20 00:54] falls asleep
[1518-06-17 00:41] wakes up
[1518-10-14 00:50] falls asleep
[1518-07-20 00:54] wakes up
[1518-04-10 00:52] wakes up
[1518-11-03 00:15] falls asleep
[1518-07-02 23:58] Guard #3023 begins shift
[1518-05-18 00:10] wakes up
[1518-10-22 00:00] Guard #449 begins shift
[1518-05-31 00:42] falls asleep
[1518-11-11 00:58] wakes up
[1518-07-20 23:58] Guard #1229 begins shift
[1518-11-21 00:02] falls asleep
[1518-10-05 23:47] Guard #101 begins shift
[1518-05-12 00:22] falls asleep
[1518-03-12 00:45] falls asleep
[1518-07-18 00:19] falls asleep
[1518-04-15 00:50] wakes up
[1518-08-14 00:52] falls asleep
[1518-05-17 00:55] wakes up
[1518-09-25 00:20] wakes up
[1518-03-03 00:38] wakes up
[1518-11-10 23:46] Guard #1973 begins shift
[1518-08-22 00:01] Guard #1553 begins shift
[1518-04-26 00:01] Guard #1193 begins shift
[1518-03-19 00:03] Guard #1973 begins shift
[1518-08-11 00:38] wakes up
[1518-11-17 00:37] wakes up
[1518-10-29 00:04] Guard #3023 begins shift
[1518-09-11 00:40] falls asleep
[1518-07-29 00:15] falls asleep
[1518-10-01 23:56] Guard #827 begins shift
[1518-04-23 00:53] wakes up
[1518-09-11 00:46] wakes up
[1518-04-13 00:53] falls asleep
[1518-08-17 00:30] falls asleep
[1518-06-07 00:55] wakes up
[1518-10-17 00:28] wakes up
[1518-05-04 00:33] falls asleep
[1518-04-23 00:03] falls asleep
[1518-11-06 00:45] wakes up
[1518-03-01 00:03] Guard #2273 begins shift
[1518-10-01 00:49] wakes up
[1518-04-08 23:48] Guard #3023 begins shift
[1518-10-29 00:34] falls asleep
[1518-04-25 00:29] falls asleep
[1518-04-29 00:03] Guard #101 begins shift
[1518-10-21 00:55] falls asleep
[1518-08-31 23:59] Guard #101 begins shift
[1518-10-05 00:04] Guard #691 begins shift
[1518-03-05 00:19] falls asleep
[1518-06-04 23:46] Guard #827 begins shift
[1518-06-13 23:47] Guard #283 begins shift
[1518-09-30 00:48] wakes up
[1518-05-26 00:54] wakes up
[1518-08-11 00:47] falls asleep
[1518-03-13 00:54] wakes up
[1518-06-09 00:45] wakes up
[1518-05-31 00:53] wakes up
[1518-10-13 00:51] falls asleep
[1518-07-22 00:18] wakes up
[1518-05-31 23:56] Guard #1723 begins shift
[1518-03-21 00:25] falls asleep
[1518-05-12 00:56] falls asleep
[1518-10-14 00:44] wakes up
[1518-07-22 00:57] wakes up
[1518-07-31 00:27] falls asleep
[1518-09-04 00:40] wakes up
[1518-03-12 00:09] wakes up
[1518-11-08 00:33] falls asleep
[1518-06-19 00:46] falls asleep
[1518-09-10 00:58] wakes up
[1518-09-14 23:52] Guard #2207 begins shift
[1518-08-29 00:30] wakes up
[1518-10-21 00:00] Guard #2383 begins shift
[1518-03-16 00:50] falls asleep
[1518-09-30 00:25] wakes up
[1518-08-04 00:03] Guard #2411 begins shift
[1518-04-16 00:58] wakes up
[1518-02-23 00:00] Guard #449 begins shift
[1518-09-28 00:50] falls asleep
[1518-07-13 00:00] Guard #283 begins shift
[1518-02-28 00:21] falls asleep
[1518-06-30 00:34] falls asleep
[1518-08-10 00:33] wakes up
[1518-07-11 00:03] Guard #349 begins shift