package WRC;

use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 12;
use File::Basename;
use lib File::Basename::dirname($0) . "/..";

BEGIN { use_ok 'Reader::CalendarReader' }

my $team          = "teamname";
my $calendar_file = "./t/test.CSV";

### Check values of regular meetings ###

my @regularmeetings = get_regular_meetings( $calendar_file, $team );

my @expected_regular_meetings = ( '- Meeting', '- Little Meeting' );
is_deeply( \@regularmeetings, \@expected_regular_meetings,
           'comparing regular meetings datastructure' );
ok( $regularmeetings[0], 'searching for regular meetings' );
ok( $regularmeetings[0] eq '- Meeting', 'detecting of meeting subject with upper case team name' );
ok( $regularmeetings[1] eq '- Little Meeting',
    'detecting of meeting subject with lower case team name' );
isnt( $regularmeetings[1], '- Daily Scrum', 'cutting out Daily Scrums' );
ok( !$regularmeetings[2],    'cutting of invalid regular meetings' );

### Check values of knowledge transfers ###

my @knowledgetransfers = get_knowledgetransfers( $calendar_file, $team );

my @expected_knowledgetransfers = ( '- Knowledge transfer: Perl', '- Knowledge transfer PHP' );
is_deeply( \@knowledgetransfers,
           \@expected_knowledgetransfers,
           'comparing knowledge transfers datastructure' );

ok( $knowledgetransfers[0], 'searching for knowledge transfers' );
ok( $knowledgetransfers[0] eq '- Knowledge transfer: Perl',
    'detecting of meeting subject with KT' );
ok( $knowledgetransfers[1] eq '- Knowledge transfer PHP',
    'detecting of meeting subject with knowledge transfer' );
ok( !$knowledgetransfers[2], 'cutting of invalid knowledge transfers' );
