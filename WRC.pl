#!/usr/bin/perl
package WRC;
use strict;
use warnings;
use Getopt::Std;
use Config::General;
use Reader::CVSReader;
use Reader::GITReader;
use Reader::SVNReader;
use Reader::CalendarReader;
use Writer::OpenDocWriter;
use Writer::MSWordWriter;
use Utility::Util;
use DateTime;
use Date::Calc;
use Data::Dumper;
our ( $opt_w, $opt_t, $opt_r, $opt_c, $opt_o, $opt_f, $opt_h );
getopt("wtrcaof");
my $conf;
my %config;

#### help option -h

if ($opt_h) {
	print "\nWRC.pl [options]
\n\n-c = expects your config file  (required)
\n-r = number of weeks since start date \n     (default = calculated out of the config parameter startDate)
\n     Examples:\n     -r 1 (you get the report nr.1),\n     -r 1,4,6 (you get the report nr.1,4,6),\n     -r 1-3 (you get the report nr.1,2,3)
\n-w = number of calendar week (default = current calendar week)
\n-t = timespan (default = 1)
\n-o = outputpath (default = parameter outputpath in the config
     if it's not configured , it would be the path /tmp)
\n-f = outputformat (default = parameter outputformat in the config
     if it's not configured , it would be .odt)
\n\nMore information:
https://github.com/mach-mme-dev/wrc-oss\n";

	exit;
}

### Read the config file ###
if ($opt_c) {
	$conf   = new Config::General($opt_c);
	%config = $conf->getall();
}
else {
	print "\nYou need a config! Your command should look like 'perl WRC.pl -c your.conf'\n
For more information use -h \n";
	exit;
}
my $dt           = DateTime->now();
my $current_week = $dt->week_number();
### Parameters ###
my $input_week    = $opt_w || $current_week;
my $user          = $config{"user"};
my $name          = $config{"name"};
my $team          = $config{"team"};
my $timespan      = $opt_t || 1;
my $outputformat  = $opt_f || $config{"outputformat"} || "odt";
my $outputpath    = $opt_o || $config{"outputpath"} || "/tmp/";
my $calendar_file = $config{"calendarfile"};
my $current_report_number;
my $choosen_report_number;
my $vcs_type;
my $host;
my $repo;
my $project;
my @report_numbers;

### Determine year of traineeship and get report number ###
my $year;
my $year2;
my $start_day = ( substr( $config{'startDate'}, 0, 2 ) );
$start_day = int($start_day);
my $start_month = ( substr( $config{'startDate'}, 3, 2 ) );
$start_month = int($start_month);
my $start_year = substr( $config{'startDate'}, 6 );
$year2 = $start_year + 1;

$current_report_number = counter( $start_year, $start_month, $start_day, $input_week );

### Check parameters ###

if ( $opt_r && $opt_w ) {
	print "\nYou can only use -r OR -w !\n\nFor more information use -h \n";
	exit;
}

### check $opt_r ###

if ($opt_r) {
	if ( $opt_r =~ m/-/ ) {
		$opt_r =~ s/-/../;
		foreach my $nr ( eval($opt_r) ) {
			push( @report_numbers, $nr );
		}
	}

	elsif ( $opt_r =~ m/,/ ) {
		@report_numbers = split( /,/, $opt_r );
	}
	else {
		print "\nWrong form at parameter -r\n\nFor more information use -h\n";
	}
}
else {
	@report_numbers = $current_report_number;
}

foreach (@report_numbers) {
	$choosen_report_number = $_;

### change $input_week if -r is given ###

	if ($choosen_report_number) {
		$input_week -= ( $current_report_number - $choosen_report_number );
		$current_report_number = $choosen_report_number;
	}

	$year = get_traineeship_year( $start_year, $year2, $start_day, $current_report_number );
### Check required parameters ###
	if (   !$user
		or !$name
		or ( !$project && !$config{'projects'} )
		or !$current_report_number )
	{
		print
"Missing required information. User, full name and project must be provided either by command line or config file\n";
		exit;
	}
### Read the commit notes for every project ###
	my $checkout_folder                  = get_checkout_folder();
	my $create_temporary_checkout_folder = "mkdir ./$checkout_folder";
	system($create_temporary_checkout_folder);

	my $log_cmd;
	my $all_commitnote_href;
	foreach my $key ( keys %{ $config{'projects'} } ) {
		my $current_project = $config{'projects'}{$key};
		$project  = $current_project->{'name'};
		$vcs_type = $current_project->{'vcs'};
		$host     = $current_project->{'host'};
		$repo     = $current_project->{'repo'};
		my $project_commitnotes_href;
		if ( !( $vcs_type && $repo && $host && $project ) ) {
			print "Missing required information in config file $opt_c\n";
			exit;
		}
		if ( $vcs_type eq 'cvs' ) {
			$log_cmd = get_cvs_log( $input_week, $user, $timespan, $project, $host, $repo );
			$project_commitnotes_href = read_cvs_log( $log_cmd, $project, $user );
		}
		elsif ( $vcs_type eq 'git' ) {
			$log_cmd = get_git_log( $user, $input_week, $timespan, $project, $host, $repo );
			$project_commitnotes_href = read_git_log( $log_cmd, $project, $user );
		}
		elsif ( $vcs_type eq 'svn' ) {
			$log_cmd = get_svn_log( $input_week, $user, $timespan, $project, $host, $repo );
			$project_commitnotes_href = read_svn_log( $log_cmd, $project, $user );
		}
		else {
			print "VCS not supported: " . $vcs_type . ". Skipping project " . $project . "!\n";
		}
		$all_commitnote_href = merge_hashes( $all_commitnote_href, $project_commitnotes_href );
	}
	print "No commits available\n" unless $all_commitnote_href;
	my $cleanup_cmd = "rm -rf ./temporary_checkout_folder";
	system($cleanup_cmd);
### Get meetings ###
	my @regularmeetings    = get_regular_meetings( $calendar_file,   $team );
	my @knowledgetransfers = get_knowledgetransfers( $calendar_file, $team );
### Create the document ###
	if ( $outputformat eq 'odt' ) {
		create_odt_document(
			$all_commitnote_href, $input_week,            $timespan,
			$name,                $current_report_number, $year,
			$outputpath,          \@regularmeetings,      \@knowledgetransfers
		);
	}
	elsif ( $outputformat eq 'doc' ) {
		create_doc_document(
			$all_commitnote_href, $input_week,            $timespan,
			$name,                $current_report_number, $year,
			$outputpath,          \@regularmeetings,      \@knowledgetransfers
		);
	}
	else {
		print
"Output format not supported: $outputformat! Choose either odt or doc. (No input defaults to odt)\n";
	}
}
