#!/usr/bin/perl
package WRC;
use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname($0) . '/..';
use Utility::Util;
use Text::CSV;
### Read commit notes vom calendar csv file ###
sub get_regular_meetings {
  my ( $calendarfile, $team ) = @_;
  my @meetings;
  my $csv = Text::CSV->new( { binary => 1 } )    # should set binary attribute.
    or print "No CSV-file: " . Text::CSV->error_diag();
  open my $csv_file, "<", "$calendarfile" or print "no regular meetings avaiable\n";
  while ( my $row = $csv->getline($csv_file) ) {
    if (     !( $row->[0] =~ m/Daily/i )
         and !( $row->[0] =~ m/Scrum/i )
         and !( $row->[0] =~ m/knowledge/i )
         and !( $row->[0] =~ m/KT/ ) )
    {
      $row->[0] =~ m/$team/is or next;
      my $count_teamname_length = length($team) + 1;
      substr( $row->[0], 0, $count_teamname_length, "-" );
      push @meetings, $row->[0];
    }
  }
  close $csv_file;
  return @meetings;
}

sub get_knowledgetransfers {
  my ( $calendarfile, $team ) = @_;
  my @knowledgetransfers;
  my $csv = Text::CSV->new( { binary => 1 } )    # should set binary attribute.
    or print "No CSV-file: " . Text::CSV->error_diag();
  open my $csv_file, "<", "$calendarfile" or print "no knowledgetransfers avaiable\n";
  while ( my $row = $csv->getline($csv_file) ) {
    if ( $row->[0] =~ s/\bKT\b/Knowledge transfer/g ) {
      if ( $row->[0] =~ m/$team/i ) {
        my $count_teamname_length = length($team) + 1;
        substr( $row->[0], 0, $count_teamname_length, "" );
      }
      my $new_row = "- $row->[0]";
      push @knowledgetransfers, $new_row;
      next;
    }
    elsif ( $row->[0] =~ m/Knowledge/i ) {
      if ( $row->[0] =~ m/$team/i ) {
        my $count_teamname_length = length($team) + 1;
        substr( $row->[0], 0, $count_teamname_length, "" );
      }
      my $new_row = "- $row->[0]";
      push @knowledgetransfers, $new_row;
      next;
    }
    else {
      next;
    }
  }
  close $csv_file;
  return @knowledgetransfers;
}
1;
__END__
