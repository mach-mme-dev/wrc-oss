package WRC;

use strict;
use warnings;
use Test::More tests => 4;
use Test::File;
use File::Basename;
use lib File::Basename::dirname($0) . "/..";
use Writer::OpenDocWriter;
use Data::Dumper;

BEGIN { use_ok 'Writer::OpenDocWriter' }

my $input_week         = 1;
my $timespan           = 1;
my $name               = "Max Mustermann";
my $report_number      = 10;
my $year               = 2012;
my $outputpath         = "/tmp/";
my @regularmeetings    = ( 'Test regular meeting', 'Test regular meeting 2' );
my @knowledgetransfers = ( 'Test knowledgetransfer', 'Test knowledgetransfer 2' );

my $all_commitnote_href = {
  'Date:' => [
'    *US366 - Optimize week number calculation<br>     adjusted the calculation of the report_number for past logs<br>    [[pair-programming: test]]<br>    [[review: test, test]]',
'    *WRC - Bug Fixed<br>     fixed GITReader.pm (the last commit was ignored)<br>    [[review: test]]',
'    *US366 Optimize week number calculation<br>     calculation by difference between current date and start date in week<br>    *WRC<br>     added parameter \'team\' to the config file<br>     implemented calendar reader output to the WordWriter<br>     optimized calendar reader<br>     replaced Sequencer.pm with Counter.pm<br>     new calculation of the current year of traineeship<br>    *US371<br>     adjusted Wiki<br>     created a wiki page with conventions for scheduling new meetings<br>    [[pair-programming: test]]<br>    [[review: test, test]]'
  ]
};

my $odt = create_odt_document(
                               $all_commitnote_href, $input_week,
                               $timespan,            $name,
                               $report_number,       $year,
                               $outputpath,          \@regularmeetings,
                               \@knowledgetransfers
);

ok( $odt == 1, 'outputpath works' );
file_exists_ok( '/tmp/Max Mustermann 10 2012.odt',
                "/tmp/Max Mustermann 10 2012.odt exists and the given outputpath works" );
file_size_ok( '/tmp/Max Mustermann 10 2012.odt', 9260 );

my $delete_file = 'rm /tmp/Max\ Mustermann\ 10\ 2012.odt;';
system($delete_file);
