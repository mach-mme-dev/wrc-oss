package WRC;

use strict;
use warnings;
use Data::Dumper;
use Test::More tests => 2;
use File::Basename;
use lib File::Basename::dirname($0) . "/..";

BEGIN { use_ok 'Format::WRFormat' }

subtest 'check typical input line' => sub {
  my $input =
  "    *US366 Optimize week number calculation<br>     calculation by difference between current date and start date in week<br>     [[pair-programming: test]]<br>    [[review: test, test]]";

  my $expected = [
                '  *US366 Optimize week number calculation',
                '   calculation by difference between current date and start date in week'
  ];


  my $formatted_comment = format_comment($input);

  is_deeply( $formatted_comment->{text}, $expected, "commit is correct formatted" );
};

