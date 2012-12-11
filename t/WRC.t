package WRC;

use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 1;
use File::Basename;
use lib File::Basename::dirname($0) . "/..";

#my $test_ok = run_without_die();
#
my $test_fail = run_expect_error();
#
#sub run_expect_ok {
#  my $cmd = 'perl WRC.pl -c t/test.conf -t 1';
#  ok( system($cmd ) == 0, "Run '$cmd' successfully" );
#  if ( $? == -1 ) {
#    diag("Run: $cmd");
#    diag($!);
#    diag("Return Code=$?");
#  }
#}

#sub run_without_die {
#  my $cmd = 'perl WRC.pl -c t/test.conf';
#
#  ok(system($cmd) != 0, "Run '$cmd' works, because a config file is given" );
#}

sub run_expect_error {
  my $cmd = 'perl WRC.pl';

  ok(system($cmd) != 1, "'$cmd' dies, because is it not allowed to run the script without a config file" );
}

#my $delete_testfile = 'rm ./t/tmp/*';
#
#system($delete_testfile);
#
#my $delete_project = 'cd /tmp; rm -r promessaging';
#
#system($delete_project);