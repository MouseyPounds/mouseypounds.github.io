#!/bin/perl -w
#
# intcode.pm
#
# Utility module required for various AoC 2019 puzzles.

package intcode;

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

# internal variables

# Primary constructor, which creates a "controller" which will launch necessary computers and help manage I/O
#
# new ( instructions, blocking, ascii, dump_mem, initial_inputs, num_computers )
# - instructions (req) should be either a single string (int,int,...) or an array of ints which provide the program code
# - blocking (opt) tells whether I/O should block or not; defaults to true.
# - dump_mem (opt) tells whether computers should output a memory dump when exiting; defaults to false.
# - initial_inputs (opt) should be an array ref containing the starting single input for all computers created
# - num_computers (opt) provides an explicit number of computes to create if initial_inputs is empty
#
# By default, just 1 computer will be created. If initial_inputs has multiple elements, that size will be used instead,
# and num_computers would be an explicit override and is only used if initial_inputs is empty.
sub new {
	my $class = shift;
	my $instructions = shift;
	my $blocking = shift;
	my $dump_mem = shift;
	my $initial_inputs = shift;
	my $num_computers = shift;
	
	if (not defined $instructions) {
		croak "No program instructions given for intcode computer(s).";
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
		@master_program = split(',', $instructions);
	}
	
	if (defined $initial_inputs and scalar(@$initial_inputs) > 0) {
		$num_computers = scalar(@$initial_inputs);
	} else {
		$initial_inputs = [];
	}
	if (not defined $num_computers) {
		$num_computers = 1;
	}
	
	if (not defined $blocking) {
		$blocking = 1;
	}

	if (not defined $dump_mem) {
		$dump_mem = 0;
	}

	$self->{'blocking'} = $blocking;
	$self->{'queue'} = { 'out' => Thread::Queue->new() };
	$self->{'thread'} = { };
	$self->{'thread_count'} = 0;
	for (my $i = 0; $i < $num_computers; $i++) {
		$self->{'queue'}{$i} = Thread::Queue->new();
		if ($#$initial_inputs >= $i) {
			$self->{'queue'}{$i}->enqueue($initial_inputs->[$i]);
		}
		my @program = ();
		for (my $i = 0; $i <= $#master_program; $i++) {
			$program[$i] = $master_program[$i];
		}
		# Originally we tried to pass $self to the threads as they were created, but that turned out to just be a copy of
		# $self at the time of invocation so did not work for things such as tracking how many threads were still running.
		# Instead now we will just pass references to the relevant input and output queues.
		$self->{'thread'}{$i} = 
			threads->create(\&computer, $i, \@program, $self->{'queue'}{$i}, $self->{'queue'}{'out'}, $dump_mem, $blocking);
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
sub get_all_output_as_string {
	my $self = shift;
	my $separator = shift;
	my $timeout = shift;
	
	if (not defined $separator) {
		$separator = ',';
	}

	if (not defined $timeout) {
		$timeout = 1;
	}
	
	return join("$separator", get_all_output($self, $timeout));
}
sub get_all_output {
	my $self = shift;
	my $timeout = shift;
	
	if (not defined $timeout) {
		$timeout = 1;
	}
	
	my @r = ();
	while ($self->num_running_computers > 0 or defined $self->{'queue'}{'out'}->peek()) {
		my $out = $self->{'queue'}{'out'}->dequeue_timed($timeout); 
		push @r, $out if (defined $out and $out ne '');
	}
	return @r;
}
sub send_input {
	my $self = shift;
	my $id = shift;
	carp "not enough arguments to send_input" if ($#_ < 0);
	$self->{'queue'}{$id}->enqueue(@_);
}
sub send_input_ascii {
	my $self = shift;
	my $id = shift;
	$self->{'queue'}{$id}->enqueue(map(ord,@_));
}
sub exit {
	my $self = shift;
	foreach my $t (keys %{$self->{'thread'}}) {
		$self->{'thread'}{$t}->detach();
		delete $self->{'thread'}{$t};
	}
	#$self = undef;
}

# purely internal, only called by controller
sub computer {
	my $id = shift;
	my $mem = shift;
	my $in_queue = shift;
	my $out_queue = shift;
	my $dump_mem = shift;
	my $blocking = shift;
	
	my $tracing = 0;
	
	my $ip = 0;
	my $rbase = 0;
	my $done = 0;
	my @output_buffer;

	print "Computer id $id started.\n" if $tracing;
	
	while(not $done) {
		my $opcode = $mem->[$ip]%100;
		my $modestr = sprintf("%03d", floor($mem->[$ip]/100));
		my @modes = split('', $modestr);
		
		if ($opcode == 99) {
			print ">>[$id: $ip] HALT\n" if $tracing;
			$done = 1;
		} elsif ($opcode == 1) { #add 2 params
			my $p1 = $modes[2] eq '0' ? $mem->[$mem->[$ip+1]] : $modes[2] eq '2' ? $mem->[$rbase+$mem->[$ip+1]] : $mem->[$ip+1];
			my $p2 = $modes[1] eq '0' ? $mem->[$mem->[$ip+2]] : $modes[1] eq '2' ? $mem->[$rbase+$mem->[$ip+2]] : $mem->[$ip+2];
			my $r = $p1 + $p2;
			my $loc;
			if ($modes[0] eq '0') {
				$loc = $mem->[$ip+3];
			} elsif ($modes[0] eq '2') {
				$loc = $rbase+$mem->[$ip+3];
			} else {
				$loc = $ip+3;
			}
			if ($loc > $#$mem) {
				for (my $i = $#$mem + 1; $i < $loc; $i++) {
					$mem->[$i] = 0;
				}
			}
			$mem->[$loc] = $r;
			print ">>[$id: $ip] ADD $modestr ($opcode) $p1 + $p2 = $r -> [$loc]\n" if $tracing;
			$ip += 4;
		} elsif ($opcode == 2) { #mult 2 params
			my $p1 = $modes[2] eq '0' ? $mem->[$mem->[$ip+1]] : $modes[2] eq '2' ? $mem->[$rbase+$mem->[$ip+1]] : $mem->[$ip+1];
			my $p2 = $modes[1] eq '0' ? $mem->[$mem->[$ip+2]] : $modes[1] eq '2' ? $mem->[$rbase+$mem->[$ip+2]] : $mem->[$ip+2];
			my $r = $p1 * $p2;
			my $loc;
			if ($modes[0] eq '0') {
				$loc = $mem->[$ip+3];
			} elsif ($modes[0] eq '2') {
				$loc = $rbase+$mem->[$ip+3];
			} else {
				$loc = $ip+3;
			}
			if ($loc > $#$mem) {
				for (my $i = $#$mem + 1; $i < $loc; $i++) {
					$mem->[$i] = 0;
				}
			}
			$mem->[$loc] = $r;
			print ">>[$id: $ip] MULT $modestr ($opcode) $p1 * $p2 = $r -> [$loc]\n" if $tracing;
			$ip += 4;
		} elsif ($opcode == 3) { #store input
			my $input = "";
			if ($blocking) {
				$input = $in_queue->dequeue();
			} else {
				# This is only used for day 23
				$input = $in_queue->dequeue_nb();
				$input = -1 if (not defined $input);
			}
			my $loc;
			if ($modes[2] eq '0') {
				$loc = $mem->[$ip+1];
			} elsif ($modes[2] eq '2') {
				$loc = $rbase+$mem->[$ip+1];
			} else {
				$loc = $ip+1;
			}
			if ($loc > $#$mem) {
				for (my $i = $#$mem + 1; $i < $loc; $i++) {
					$mem->[$i] = 0;
				}
			}
			$mem->[$loc] = $input;
			$ip += 2;
			print ">>[$id: $ip] INPUT $modestr ($opcode) $input -> [$loc]\n" if $tracing;
		} elsif ($opcode == 4) { #output
			my $p1 = $modes[2] eq '0' ? $mem->[$mem->[$ip+1]] : $modes[2] eq '2' ? $mem->[$rbase+$mem->[$ip+1]] : $mem->[$ip+1];
			if (not $blocking) {
				# This is a hack for day 23 to force output packets to all be sent at once
				push @output_buffer, $p1;
				if ($#output_buffer > 1) {
					$out_queue->enqueue(splice(@output_buffer,0,3));
				}
			} else {
				$out_queue->enqueue($p1);
			}
			print ">>[$id: $ip] OUTPUT $modestr ($opcode) outputting $p1\n" if $tracing;
			$ip += 2;
		} elsif ($opcode == 5) { #jump-if-true
			my $p1 = $modes[2] eq '0' ? $mem->[$mem->[$ip+1]] : $modes[2] eq '2' ? $mem->[$rbase+$mem->[$ip+1]] : $mem->[$ip+1];
			my $p2 = $modes[1] eq '0' ? $mem->[$mem->[$ip+2]] : $modes[1] eq '2' ? $mem->[$rbase+$mem->[$ip+2]] : $mem->[$ip+2];
			if (not defined $p1 or $p1 eq '') { $p1 = 0; }
			if (not defined $p2 or $p2 eq '') { $p2 = 0; }
			print ">>[$id: $ip] JIT $modestr ($opcode) $p1 $p2\n" if $tracing;
			if ($p1 != 0) {
				$ip = $p2;
			} else {
				$ip += 3;
			}
		} elsif ($opcode == 6) { #jump-if-false
			my $p1 = $modes[2] eq '0' ? $mem->[$mem->[$ip+1]] : $modes[2] eq '2' ? $mem->[$rbase+$mem->[$ip+1]] : $mem->[$ip+1];
			my $p2 = $modes[1] eq '0' ? $mem->[$mem->[$ip+2]] : $modes[1] eq '2' ? $mem->[$rbase+$mem->[$ip+2]] : $mem->[$ip+2];
			if (not defined $p1 or $p1 eq '') { $p1 = 0; }
			if (not defined $p2 or $p2 eq '') { $p2 = 0; }
			print ">>[$id: $ip] JIF $modestr ($opcode) $p1 $p2\n" if $tracing;
			if ($p1 == 0) {
				$ip = $p2;
			} else {
				$ip += 3;
			}
		} elsif ($opcode == 7) { #less than
			my $p1 = $modes[2] eq '0' ? $mem->[$mem->[$ip+1]] : $modes[2] eq '2' ? $mem->[$rbase+$mem->[$ip+1]] : $mem->[$ip+1];
			my $p2 = $modes[1] eq '0' ? $mem->[$mem->[$ip+2]] : $modes[1] eq '2' ? $mem->[$rbase+$mem->[$ip+2]] : $mem->[$ip+2];
			if (not defined $p1 or $p1 eq '') { $p1 = 0; }
			if (not defined $p2 or $p2 eq '') { $p2 = 0; }
			my $r = $p1 < $p2 ? 1 : 0;
			my $loc;
			if ($modes[0] eq '0') {
				$loc = $mem->[$ip+3];
			} elsif ($modes[0] eq '2') {
				$loc = $rbase+$mem->[$ip+3];
			} else {
				$loc = $ip+3;
			}
			if ($loc > $#$mem) {
				for (my $i = $#$mem + 1; $i < $loc; $i++) {
					$mem->[$i] = 0;
				}
			}
			$mem->[$loc] = $r;
			print ">>[$id: $ip] LT $modestr ($opcode) $p1 < $p2 = $r -> [$loc]\n" if $tracing;
			$ip += 4;
		} elsif ($opcode == 8) { #equals
			my $p1 = $modes[2] eq '0' ? $mem->[$mem->[$ip+1]] : $modes[2] eq '2' ? $mem->[$rbase+$mem->[$ip+1]] : $mem->[$ip+1];
			my $p2 = $modes[1] eq '0' ? $mem->[$mem->[$ip+2]] : $modes[1] eq '2' ? $mem->[$rbase+$mem->[$ip+2]] : $mem->[$ip+2];
			if (not defined $p1 or $p1 eq '') { $p1 = 0; }
			if (not defined $p2 or $p2 eq '') { $p2 = 0; }
			my $r = $p1 == $p2 ? 1 : 0;
			my $loc;
			if ($modes[0] eq '0') {
				$loc = $mem->[$ip+3];
			} elsif ($modes[0] eq '2') {
				$loc = $rbase+$mem->[$ip+3];
			} else {
				$loc = $ip+3;
			}
			if ($loc > $#$mem) {
				for (my $i = $#$mem + 1; $i < $loc; $i++) {
					$mem->[$i] = 0;
				}
			}
			$mem->[$loc] = $r;
			print ">>[$id: $ip] EQ $modestr ($opcode) $p1 == $p2 = $r -> [$loc]\n" if $tracing;
			$ip += 4;
		} elsif ($opcode == 9) { #change relative base
			my $p1 = $modes[2] eq '0' ? $mem->[$mem->[$ip+1]] : $modes[2] eq '2' ? $mem->[$rbase+$mem->[$ip+1]] : $mem->[$ip+1];
			if (not defined $p1 or $p1 eq '') { $p1 = 0; }
			$rbase += $p1;
			print ">>[$id: $ip] RBASE $modestr ($opcode) $p1 ; rbase now $rbase\n" if $tracing;
			$ip += 2;
		} else {
			carp "??[$id: $ip] WARN unknown opcode $opcode";
			$done = 1;
		}
	}
	print "Computer id $id finished.\n" if $tracing;
	if ($dump_mem) {
		$out_queue->enqueue(join(',', @$mem));
	}
	return 1;
}

1;
