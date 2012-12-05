#!/usr/bin/perl

package WRC;

use strict;
use warnings;

use Data::Dumper;
use Config::General;
use File::Basename;
use lib File::Basename::dirname($0) . '/..';
use lib File::Basename::dirname($0) . "/../Reader/";
use Utility::Util;
use Test::More tests => 8;


# zu testendes Modul suchen [ ok 1 ]
BEGIN { use_ok 'CVSReader' }

# config auslesen
my $opt_c  = './t/test.conf';
my $conf   = new Config::General($opt_c);
my %config = $conf->getall();

# user daten
my $user = $config{'user'};
my $team = 'teamname';

# project daten
my $current_project = $config{'projects'}{'testcvs'};
my $repo            = $current_project->{'repo'};
my $project         = $current_project->{'name'};
my $vcs_type        = $current_project->{'vcs'};
my $host            = $current_project->{'host'};

# log Zeitraum
my $weekOfYear = 0;
my $timespan   = 1;
my $dates = get_dates_cvs( \$weekOfYear, \$timespan );
my $startDate = ${$dates}{'start'};
my $endDate   = ${$dates}{'end'};

# richtige config-Daten überprüfen, [ ok 2 bis 7 ]
ok( $user eq "test", 'user_name' );
ok( $team eq "teamname" , "team_name" );
ok( $repo eq "/tmp/testfolder_cvs" , "repository_path" );
ok( $project  eq "testfolder_cvs" , "project_name" );
ok( $vcs_type eq "cvs", "vcs_type" );
ok( $host     eq "local" , "server");

### cvs root folder erstellen ###
my $create_cvsrootfolder_cmd = "mkdir /tmp/cvs_test; mkdir /tmp/testfolder_cvs";
system($create_cvsrootfolder_cmd);

$ENV{'CVSROOT'} = "/tmp/cvs_test";

### cvs repo erstellen ###
my $create_cvs_repo_cmd = "cd /tmp/cvs_test; cvs init";
system($create_cvs_repo_cmd);

### import ###
my $import_cmd = "cd /tmp/testfolder_cvs; cvs import -m 'firststructure' testfolder_cvs $user start";
system($import_cmd);

### checkout ###
my $checkout_cmd = "cd /tmp/testfolder_cvs; cvs checkout testfolder_cvs";
system($checkout_cmd);

### create test file for commiting###
 my $create_testfile_cmd = "cd /tmp/testfolder_cvs/testfolder_cvs; touch cvstest.txt";
 system($create_testfile_cmd);


### add testfile to index ###
my $add_testfile_toindex_cmd = "cd /tmp/testfolder_cvs/testfolder_cvs; cvs add cvstest.txt";
system($add_testfile_toindex_cmd);

### cvs commit auf erstelltes repo ###
my $test_commit = "'*WRC - Bug Fixed\n fixed cvsReader.pm the last commit was ignored\n [[Review: $user]]'";
my $cvs_commit_cmd =
"cd /tmp/testfolder_cvs/testfolder_cvs; cvs commit -m $test_commit";
system($cvs_commit_cmd);

### sub read cvs log aufrufen ###
my $expected_cvs_result = [
           '*WRC - Bug Fixed<br> fixed cvsReader.pm the last commit was ignored<br> [[Review: test]](Code review)'
         ];

my $log_cmd = "cd /tmp/$project/$project; cvs log";

my $current_cvs_result = read_cvs_log( $log_cmd, $project, $user );

is_deeply (Dumper(values(%$current_cvs_result)),Dumper($expected_cvs_result), "cvs_log_output is correct" );
### erstelltes cvs repo löschen ###
my $delete_cvs_repo_cmd = "rm -rf /tmp/testfolder_cvs; rm -rf /tmp/cvs_test";
system($delete_cvs_repo_cmd);


