#!perl -T

use Test::More tests => 15;
use Signal::Mask 'SIG_MASK';
use Signal::Pending 'SIG_PENDING';
our (%SIG_MASK, %SI_PENDING);
use POSIX qw/SIGUSR1 SIGUSR2/;

my $counter1 = 0;
my $counter2 = 0;

$SIG{USR1} = sub { $counter1++ };
$SIG{USR2} = sub { $counter2++ };

is $counter1, 0, 'Counter1 starts at zero';
is $counter2, 0, 'Counter2 starts at zero';

ok kill(SIGUSR1, $$), 'Sent usr1 signal';

is +(grep { $_ } values %SIG_PENDING), 0, 'No pending signals';

is $counter1, 1, 'Counter1 is 1 now';
is $counter2, 0, 'Counter2 is still 0';

{
	local $SIG_MASK{USR1} = 1;

	ok kill(SIGUSR1, $$), 'Sent usr1 signal';
	ok kill(SIGUSR2, $$), 'Sent usr2 signal';

	is +(grep { $_ } values %SIG_PENDING), 1, 'One pending signal';
	ok $SIG_PENDING{USR1}, 'SIGUSR1 pending';

	is $counter1, 1, 'Counter1 is still 1';
	is $counter2, 1, 'Counter2 is now 1';
}

is +(grep { $_ } values %SIG_PENDING), 0, 'No pending signals';

is $counter1, 2, 'Counter1 is 2 now';
is $counter2, 1, 'Counter2 is still 1';
