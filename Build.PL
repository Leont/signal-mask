use 5.006;
use strict;
use warnings;
use Module::Build;

if ($^O eq 'MSWin32') {
	print "No support for OS\n";
	exit;
}

my $builder = Module::Build->new(
	module_name         => 'Signal::Mask',
	license             => 'perl',
	dist_author         => q{Leon Timmermans <leont@cpan.org>},
	dist_version_from   => 'lib/Signal/Mask.pm',
	configure_requires  => {
		'Module::Build' => 0.28,
	},
	build_requires      => {
		'Module::Build' => 0.28,
		'Test::More'    => 0,
	},
	requires            => {
		perl            => 5.006,
		'Const::Fast'   => 0,
		'IPC::Signal'   => 0,
		'Thread::SigMask' => 0.002,
	},
	add_to_cleanup      => [ 'Signal-Mask-*' ],
	create_makefile_pl  => 'traditional',
	sign                => 1,
);

$builder->create_build_script();
