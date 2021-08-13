#!/bin/perl -w
#
# duet.pm
#
# Utility module required for an AoC 2017 puzzle. This module reuses a lot of the functionality of the AoC 2019 intcode
# module. (We did these out of order chronologically.)

package duet;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw();

use strict;
use Carp;
use POSIX;
use threads;
use threads::shared;
use Thread::Queue;
use Time::HiRes qw(usleep);
use Storable qw(dclone);

my $rcv_timeout = 3;

# Primary constructor, which creates a "controller" which will launch necessary computers and help manage I/O
#
# new ( instructions, num_computers )
# - instructions (req) should be either a single string (int,int,...) or an array of ints which provide the program code
# - num_computers (opt) how many computer instances to run; either 1 or 2 with default of 2.
#   'snd' and 'rcv' behave differently depending on this value.
sub new {
	my $class = shift;
	my $instructions = shift;
	my $num_computers = shift;
	
	if (not defined $instructions) {
		croak "No program instructions given for duet computer(s).";
	}

	my $self = {};
	bless $self, $class;
	
	my @master_program;
	if (ref $instructions eq 'ARRAY') {
		@master_program = ();
		for (my $i = 0; $i <= $#$instructions; $i++) {
			$master_program[$i] = $instructions->[$i];
		}
	} else {
		@master_program =  map { [ split(' ') ] } split("\n", $instructions);
	}
	
	if (not defined $num_computers) {
		$num_computers = 2;
	}
	
	$self->{'queue'} = { 0 => Thread::Queue->new(), 1 => Thread::Queue->new(), 'out' => Thread::Queue->new() };
	$self->{'thread'} = { };
	$self->{'thread_count'} = 1;
	my $program = dclone(\@master_program);
	$self->{'thread'}{0} = threads->create(\&computer, 0, $program, $num_computers,
		$self->{'queue'}{0}, $self->{'queue'}{1}, $self->{'queue'}{'out'});
	if ($num_computers > 1) {
		$program = dclone(\@master_program);
		$self->{'thread'}{1} = threads->create(\&computer, 1, $program, $num_computers,
			$self->{'queue'}{1}, $self->{'queue'}{0}, $self->{'queue'}{'out'});
		$self->{'thread_count'}++;
	}

	return $self;
}

# These methods should be called from user scripts
sub num_running_computers {
	my $self = shift;
	$self->update_status();
	return scalar(keys %{$self->{'thread'}});
}
sub update_status {
	# This is something of a hack as a decent implementation would be able to track this automatically
	my $self = shift;
	my @check = keys %{$self->{'thread'}};
	foreach my $t (@check) {
		if (not $self->{'thread'}{$t}->is_running()) {
			$self->{'thread'}{$t}->join();
			delete $self->{'thread'}{$t};
		}
	}
}
sub peek_output {
	my $self = shift;
	my $num = shift;

	if (not defined $num) {
		$num = 1;
	}

	return $self->{'queue'}{'out'}->peek($num);
}
sub get_output {
	my $self = shift;
	my $num = shift;
	my $timeout = shift;
	
	if (not defined $num) {
		$num = 1;
	}
	
	if (defined $timeout) {
		if ($num > 1) {
			my @r = $self->{'queue'}{'out'}->dequeue_timed($timeout, $num);
			return @r;
		} else {
			my $r = $self->{'queue'}{'out'}->dequeue_timed($timeout);
			return $r;
		}
	} else {
		if ($num > 1) {
			my @r = $self->{'queue'}{'out'}->dequeue($num);
			return @r;
		} else {
			my $r = $self->{'queue'}{'out'}->dequeue();
			return $r;
		}
	}	
}
sub send_input {
	my $self = shift;
	my $id = shift;
	carp "not enough arguments to send_input" if ($#_ < 0);
	$self->{'queue'}{$id}->enqueue(@_);
}
sub exit {
	my $self = shift;
	foreach my $t (keys %{$self->{'thread'}}) {
		$self->{'thread'}{$t}->detach();
		delete $self->{'thread'}{$t};
	}
}

# purely internal, only called by controller
sub computer {
	my $id = shift;
	my $ins = shift;
	my $num_computers = shift;
	my $in_queue = shift;
	my $out_queue = shift;
	my $user_queue = shift;
	
	my $ip = 0;
	my $done = 0;
	my $freq = 0;
	my $send_count = 0;
	my $send_to = $id ? 0 : 1;
	# Examples and inputs use a wide variety of registers and the only guidelines we have are that they are
	# "named with a single letter" and that p should store the id. So we are overkilling it.
	my %reg = ();
	map { $reg{$_} = 0 } ('a' .. 'z');
	$reg{'p'} = $id;
	my ($op, $x, $y);
	
	while(not $done) {
		#print "[$ip]: ", join(' ', @{$ins->[$ip]}), "\n";
		$op = $ins->[$ip][0];
		$x = ((exists $reg{$ins->[$ip][1]}) ? $reg{$ins->[$ip][1]} : $ins->[$ip][1]) if (scalar @{$ins->[$ip]} > 1);
		$y = ((exists $reg{$ins->[$ip][2]}) ? $reg{$ins->[$ip][2]} : $ins->[$ip][2]) if (scalar @{$ins->[$ip]} > 2);
			
		if ($op eq 'snd') {
			if ($num_computers == 1) {
				$freq = $x;
			} else {
				$out_queue->enqueue($x);
				$send_count++;
			}
			$ip++;
		} elsif ($op eq 'set') {
			$reg{$ins->[$ip][1]} = $y;
			$ip++;
		} elsif ($op eq 'add') {
			$reg{$ins->[$ip][1]} += $y;
			$ip++;
		} elsif ($op eq 'mul') {
			$reg{$ins->[$ip][1]} *= $y;
			$ip++;
		} elsif ($op eq 'mod') {
			$reg{$ins->[$ip][1]} %= $y;
			$ip++;
		} elsif ($op eq 'rcv') {
			if ($num_computers == 1) {
				if ($x != 0) {
					$user_queue->enqueue($freq);
					$done = 1;
				}
			} else {
				my $input = $in_queue->dequeue_timed($rcv_timeout);
				if (defined $input) {
					$reg{$ins->[$ip][1]} = $input;
				} else {
					$done = 1;
				}
			}
			$ip++;
		} elsif ($op eq 'jgz') {
			$ip += ($x > 0) ? $y : 1;
		} else {
			warn "Skipping invalid instruction {$ins->[$ip][0]}\n";
			$ip++;
		}
		$done = 1 if ($ip >= scalar(@$ins));
	}
	$user_queue->enqueue("$id:$send_count");
	return 1;
}

1;
