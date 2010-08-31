#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Signal::Mask' ) || print "Bail out!
";
}

diag( "Testing Signal::Mask $Signal::Mask::VERSION, Perl $], $^X" );
