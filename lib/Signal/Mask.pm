package Signal::Mask;

use strict;
use warnings FATAL => 'all';

our $VERSION = '0.001';

use POSIX qw/sigprocmask SIG_BLOCK SIG_UNBLOCK SIG_SETMASK/;
use IPC::Signal qw/sig_num sig_name/;
use Carp qw/croak/;
use Const::Fast;

our %SIG_MASK;

sub import {
	my ($class, $name) = @_;
	$name ||= 'SIG_MASK';
	$name =~ s/ \A % //xm;
	my $caller = caller;
	no strict 'refs';
	*{"$caller\::$name"} = \%SIG_MASK;
	return;
}

const my $sig_max => defined &POSIX::SIGRTMAX ? &POSIX::SIGRTMAX : 32;

tie %SIG_MASK, __PACKAGE__;

sub TIEHASH {
	my $class = shift;
	my $self = { iterator => 1, };
	return bless $self, $class;
}

sub _get_status {
	my ($self, $num) = @_;
	my $mask = POSIX::SigSet->new;
	sigprocmask(SIG_BLOCK, undef, $mask);
	return $mask->ismember($num);
}

sub FETCH {
	my ($self, $key) = @_;
	return $self->_get_status(sig_num($key));
}

sub _block_signal {
	my ($self, $key) = @_;
	my $num = sig_num($key);
	croak "No such signal '$key'" if not defined $num;
	sigprocmask(SIG_BLOCK, POSIX::SigSet->new($num)) or croak "Couldn't block signal: $!";
	return;
}

sub _unblock_signal {
	my ($self, $key) = @_;
	my $num = sig_num($key);
	croak "No such signal '$key'" if not defined $num;
	sigprocmask(SIG_UNBLOCK, POSIX::SigSet->new($num)) or croak "Couldn't unblock signal: $!";
	return;
}

sub STORE {
	my ($self, $key, $value) = @_;
	if ($value) {
		$self->_block_signal($key);
	}
	else {
		$self->_unblock_signal($key);
	}
	return;
}

sub DELETE {
	my ($self, $key) = @_;
	$self->STORE($key, 0);
	return;
}

sub CLEAR {
	my ($self) = @_;
	sigprocmask(SIG_SETMASK, POSIX::SigSet->new());
	return;
}

sub EXISTS {
	my ($self, $key) = @_;
	return defined sig_num($key);
}

sub FIRSTKEY {
	my $self = shift;
	$self->{iterator} = 1;
	return $self->NEXTKEY;
}

sub NEXTKEY {
	my $self = shift;
	if ($self->{iterator} < $sig_max) {
		my $num = $self->{iterator}++;
		return wantarray ? (sig_name($num) => $self->_get_status($num)) : sig_name($num);
	}
	else {
		return;
	}
}

sub UNTIE {
	my $self = shift;
	$self->CLEAR;
	return;
}

sub DESTROY {
}

1;    # End of Signal::Mask

__END__

=head1 NAME

Signal::Mask - Signal Masks made easy

=head1 VERSION

Version 0.001

=head1 SYNOPSIS

Signal::Mask is an abstraction around your process's signal mask. It is used to fetch and/or change the signal mask of the calling thread.  The signal mask is the set of signals whose delivery is currently blocked for the caller.

 use Signal::Mask;
 
 {
     local $SIG_MASK{INT} = 1;
	 do_something;
 }
 #signal gets postponed until now

=head1 EXPORT

This module exports a B<HASH>. By default it's called %SIG_MASK, but it's name can be set on import. Any true value for a hash key will correspond with that signal being masked.

=head1 AUTHOR

Leon Timmermans, C<< <leont at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-signal-mask at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Signal-Mask>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Signal::Mask

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Signal-Mask>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Signal-Mask>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Signal-Mask>

=item * Search CPAN

L<http://search.cpan.org/dist/Signal-Mask/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Leon Timmermans.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
