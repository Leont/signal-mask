use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
	module_name         => 'Signal::Mask',
	license             => 'perl',
	dist_author         => q{Leon Timmermans <leont@cpan.org>},
	dist_version_from   => 'lib/Signal/Mask.pm',
	build_requires      => {
		'Test::More'    => 0,
	},
	requires            => {
		perl            => 5.006,
		'Const::Fast'   => 0,
		'IPC::Signal'   => 0,
	},
	add_to_cleanup      => [ 'Signal-Mask-*' ],
	create_makefile_pl  => 'traditional',
	sign                => 1,
);

$builder->create_build_script();
