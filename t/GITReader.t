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
use Test::More;


# zu testendes Modul suchen [ ok 1 ]
BEGIN { use_ok 'GITReader' }

# config auslesen
my $opt_c  = './t/test.conf';
my $conf   = new Config::General($opt_c);
my %config = $conf->getall();

# user daten
my $user = $config{'user'};
my $team = 'teamname';

# project daten
my $current_project = $config{'projects'}{'testgit'};
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
ok( $user     eq "test",                           'user_name' );
ok( $team     eq "teamname",                          "team_name" );
ok( $repo     eq "./t/tmp",                        "repository_path" );
ok( $project  eq "tmp",                            "project_name" );
ok( $vcs_type eq "git",                            "vcs_type" );
ok( $host     eq "local",                            "server" );

### git repo erstellen ###
my $create_git_repo_cmd = "cd ./t/tmp; git init -q";
system($create_git_repo_cmd);
### create test file for commiting###
my $create_testfile_cmd = "cd ./t/tmp; touch gittest.txt";
system($create_testfile_cmd);
### add testfile to index ###
my $add_testfile_toindex_cmd = "cd ./t/tmp; git add gittest.txt";
system($add_testfile_toindex_cmd);

### git commit auf erstelltes repo ###
my $git_commit_cmd =
"cd ./t/tmp; git commit -q -m '*WRC - Bug Fixed\n fixed GITReader.pm (the last commit was ignored)\n [[this is a comment]]' --author='test <testtest.de>'
";
system($git_commit_cmd);

### sub read git log aufrufen ###
my $expected_git_result = {
  'Date:' => [
'    *WRC - Bug Fixed<br>     fixed GITReader.pm (the last commit was ignored)<br>     [[this is a comment]]'
  ]
};
my $log_cmd = "cd t/$project; git log --since='$startDate' --until='$endDate' --pretty=medium --date=iso |";
my $current_git_result = read_git_log( $log_cmd, $project,$user );


is_deeply( $current_git_result, $expected_git_result, "git_log_output is correct" );
### erstelltes git repo löschen ###
my $delete_git_repo_cmd = "rm -rf ./t/tmp; mkdir ./t/tmp";
system($delete_git_repo_cmd);

done_testing();