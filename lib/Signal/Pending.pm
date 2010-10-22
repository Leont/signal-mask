package Signal::Pending;

use strict;
use warnings FATAL => 'all';

our $VERSION = '0.004';

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

__END__

=head1 NAME

Signal::Pending - Signal pending status made easy

=head1 VERSION

Version 0.004

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

=head1 EXPORT

When importation is given an argument, this module exports a B<HASH> by that name. It can also be accessed as %Signal::Pending::SIG_PENDING. Any true value for a hash entry will correspond with that signal awaiting being handled.

=head1 AUTHOR

Leon Timmermans, C<< <leont at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-signal-mask at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Signal-Mask>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Signal::Pending

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
