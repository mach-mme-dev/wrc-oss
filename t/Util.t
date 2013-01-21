package WRC;

use strict;
use warnings;
use Test::More tests => 8;
use File::Basename;
use lib File::Basename::dirname($0) . "/..";
use DateTime;
use POSIX qw( ceil );
use Date::Calc qw(:all);
use Data::Dumper;

BEGIN { use_ok 'Utility::Util' }

my $start_month;
my $start_year;
my $year2;
my $start_day;
my $report_number;
my $input_week;
my $date_form;

##### check sub get_traineeship_year #####

subtest "get_traineeship_year" => sub {

  $start_year    = 2012;
  $year2         = 2012;
  $start_day     = 01;
  $report_number = 01;

  my $year_check = get_traineeship_year( $start_year, $year2, $start_day, $report_number );

  ok( $year_check == 1, "correct traineeship year calculated for the first year" );

  $start_year    = 2012;
  $year2         = 2013;
  $start_day     = 01;
  $report_number = 53;

  $year_check = get_traineeship_year( $start_year, $year2, $start_day, $report_number );

  ok( $year_check == 2, "correct traineeship year calculated for the second year" );

  $start_year    = 2012;
  $year2         = 2013;
  $start_day     = 01;
  $report_number = 105;

  $year_check = get_traineeship_year( $start_year, $year2, $start_day, $report_number );

  ok( $year_check == 3, "correct traineeship year calculated for the third year" );

};

##### check sub counter #####

subtest "counter" => sub {

  my @datum = localtime();
  $start_year  = $datum[5] + 1900;
  $start_month = $datum[4] + 1;
  $start_day   = $datum[3];
  my $dt         = DateTime->now();
  my $input_week = $dt->week_number();

  my $counter_check = counter( $start_year, $start_month, $start_day, $input_week );
  print $counter_check;
  ok( $counter_check == 1, "right report number calculated" );

};

##### check sub get_dates #####

subtest "get_dates" => sub {
  my $weekOfYear = 1;
  my $weeks      = 1;
  my $expected_dates =
'((?:[0]?[1-9]|[1][012])[-:\\/.](?:(?:[0-2]?\\d{1})|(?:[3][01]{1}))[-:\\/.](?:(?:[1]{1}\\d{1}\\d{1}\\d{1})|(?:[2]{1}\\d{3})))(?![\\d])';

  my $get_dates_cvs_check = get_dates( \$weekOfYear, \$weeks, "mdy", "/" );

  if (     ( $get_dates_cvs_check->{'start'} =~ m/$expected_dates/is )
       and ( $get_dates_cvs_check->{'end'} =~ m/$expected_dates/is ) )
  {
    $date_form = 1;
  }
  else {
    $date_form = 0;
  }
  ok( $date_form == 1, "correct date form created (mm/dd/yyyy - cvs and git)" );

  $expected_dates =
'((?:(?:[1]{1}\\d{1}\\d{1}\\d{1})|(?:[2]{1}\\d{3}))[-:\\/.](?:[0]?[1-9]|[1][012])[-:\\/.](?:(?:[0-2]?\\d{1})|(?:[3][01]{1})))(?![\\d])';
  $get_dates_cvs_check = get_dates( \$weekOfYear, \$weeks, "ymd", "-" );

  if (     ( $get_dates_cvs_check->{'start'} =~ m/$expected_dates/is )
       and ( $get_dates_cvs_check->{'end'} =~ m/$expected_dates/is ) )
  {
    $date_form = 1;
  }
  else {
    $date_form = 0;
  }
  ok( $date_form == 1, "correct date form created (yyyy-mm-dd - svn)" );

  $expected_dates =
'((?:[0]?[1-9]|[1][012])[-:\\/.](?:(?:[0-2]?\\d{1})|(?:[3][01]{1}))[-:\\/.](?:(?:[1]{1}\\d{1}\\d{1}\\d{1})|(?:[2]{1}\\d{3})))(?![\\d])';
  $get_dates_cvs_check = get_dates( \$weekOfYear, \$weeks, "mdy", "/" );

  if (     ( $get_dates_cvs_check->{'start'} =~ m/$expected_dates/is )
       and ( $get_dates_cvs_check->{'end'} =~ m/$expected_dates/is ) )
  {
    $date_form = 1;
  }
  else {
    $date_form = 0;
  }

  ok( $date_form == 1, "correct date form created (dd.mm.yyyy - writer)" );
};

##### check sub merge_hashes #####

subtest "merge_hashes" => sub {

  my $hash1_href = { 'test1:' => [ 'hash1', ] };
  my $hash2_href = { 'test2:' => [ 'hash2', ] };

  my $exptected_hash = {
                         'test1:' => ['hash1'],
                         'test2:' => ['hash2']
  };

  $hash1_href = merge_hashes( $hash1_href, $hash2_href );

  is_deeply( $hash1_href, $exptected_hash, 'merge_hashes extends 1st hash by 2nd hash' );
  is_deeply( $hash2_href, { 'test2:' => ['hash2'] }, 'merge_hashes does not change 2nd hash' );

};

##### check sub get_lines_odt #####

subtest "get_lines_odt" => sub {

  my $lines_total = 0;
  my $lines       = 0;

  my $test_comment = {
    'Date:' => [
'    *US366 - Optimize week number calculation<br>     adjusted the calculation of the report_number for past logs<br>    [[pair-programming: test]]<br>    [[review: test, test]]',
    ]
  };

  my $formatted_comment = {
              'text' => [
                          '  *WRC - general improvement',
                          '   change the order of pair-programming and reviewing at the git reader',
                          '   and the cvs reader',
                          '   change die command to print command in the calendar reader if no',
                          '   meetings available',
                          '   remove an unused subroutine (get_week_of_year) in Util.pm',
                          '  *US361 - Write testcases for reader modules',
                          '  *US362 - Write testcases for writer modules',
                          '  *US363 - Write testcases for WRC script',
                          '  *US502 - Write testcases for the Util.pm , WRFormat.pm'
              ]
  };

  $lines = get_lines_odt($formatted_comment);
  is( $lines, 11, "correct line amount calculated (.odt)" );

};

##### check sub get_lines_doc #####

subtest "get_lines_doc" => sub {

  my $lines_total = 0;
  my $lines       = 0;

  my $test_comment = {
    'Date:' => [
'    *US366 - Optimize week number calculation<br>     adjusted the calculation of the report_number for past logs<br>    [[pair-programming: test]]<br>    [[review: test, test]]',
    ]
  };

  my $formatted_comment = {
              'text' => [
                          '  *WRC - general improvement',
                          '   change the order of pair-programming and reviewing at the git reader',
                          '   and the cvs reader',
                          '   change die command to print command in the calendar reader if no',
                          '   meetings available',
                          '   remove an unused subroutine (get_week_of_year) in Util.pm',
                          '  *US361 - Write testcases for reader modules',
                          '  *US362 - Write testcases for writer modules',
                          '  *US363 - Write testcases for WRC script',
                          '  *US502 - Write testcases for the Util.pm , WRFormat.pm'
              ]
  };

  $lines = get_lines_doc($formatted_comment);
  is( $lines, 11, "correct line amount calculated (.odt)" );

};

##### check sub filtering_commits #####

subtest "filtering_commits" => sub {
  my $user = "test";
  my $commitnotes = {
     'Date:' => {
       '    *WRC - deleted useless files' => 'test',
       '    *WRC - renamed files'         => 'other user',
       '    *WRC - general improvement<br>    [[pair-programming: test]]<br>    [[review: test]]' =>
         'other user',
       '    *BLI361<br>     created test for CVSreader.pm<br>     created test for GITreader.pm' =>
         'other user',
       '    *WRC - merged from other user' => 'test',
     }
  };
  my $expected_commitnotes = {
    'Date:' => [
      '    *WRC - merged from other user',
      '    *WRC - deleted useless files',
'    *WRC - general improvement<br>    [[pair-programming: test]]<br>    [[review: test]](Pair programming)'
    ]
  };

  my $output = filtering_commits( $user, $commitnotes );

  is_deeply( $output, $expected_commitnotes, 'right commits are filtered' );

};

