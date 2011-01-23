package Signal::Pending;

use strict;
use warnings FATAL => 'all';

use POSIX qw/sigpending/;
use IPC::Signal qw/sig_num sig_name/;
use Carp qw/croak/;
use Const::Fast;

our %SIG_PENDING;

sub import {
	my ($class, $name) = @_;
	if (defined $name) {
		$name =~ s/ \A % //xm;
		my $caller = caller;
		no strict 'refs';
		*{"$caller\::$name"} = \%SIG_PENDING;
	}
	return;
}

const my $sig_max => defined &POSIX::SIGRTMAX ? &POSIX::SIGRTMAX : 32;

tie %SIG_PENDING, __PACKAGE__;

sub TIEHASH {
	my $class = shift;
	my $self = { iterator => 1, };
	return bless $self, $class;
}

sub _get_status {
	my ($self, $num) = @_;
	my $mask = POSIX::SigSet->new;
	sigpending($mask);
	return $mask->ismember($num);
}

sub FETCH {
	my ($self, $key) = @_;
	return $self->_get_status(sig_num($key));
}

sub STORE {
	my ($self, $key, $value) = @_;
	croak 'Can\'t assign to %SIG_PENDING';
}

sub DELETE {
	my ($self, $key) = @_;
	croak 'Can\'t delete from %SIG_PENDING';
}

sub CLEAR {
	my ($self) = @_;
	croak 'Can\'t clear %SIG_PENDING';
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
	if ($self->{iterator} <= $sig_max) {
		my $num = $self->{iterator}++;
		return wantarray ? (sig_name($num) => $self->_get_status($num)) : sig_name($num);
	}
	else {
		return;
	}
}

sub SCALAR {
	my $self = shift;
	my $mask = POSIX::SigSet->new;
	sigpending($mask);
	return scalar grep { $mask->ismember($_) } 1 .. $sig_max;
}

sub UNTIE {
}

sub DESTROY {
}

1;    # End of Signal::Mask

# ABSTRACT: Signal pending status made easy

__END__

=head1 SYNOPSIS

Signal::Pending is an abstraction around your process'/thread's pending signals. It can be used in combination with signal masks to handle signals in a controlled manner.

 use Signal::Mask 'SIG_MASK';
 use Signal::Pending 'SIG_PENDING';
 
 {
     local $SIG_MASK{INT} = 1;
     do {
		 something();
     } while (not $SIG_PENDING{INT})
 }
 #signal delivery gets postponed until now

=for Pod::Coverage SCALAR
