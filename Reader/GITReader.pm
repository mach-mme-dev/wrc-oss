#!/usr/bin/perl
package WRC;
use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname($0) . '/..';
use Utility::Util;
use Data::Dumper;

### Read the config file ###

sub get_git_log {

  my ( $user, $weekOfYear, $timespan, $project, $host, $repo ) = @_;
  my $startDate;
  my $endDate;

  my $dates = get_dates_cvs( \$weekOfYear, \$timespan );
  $startDate = ${$dates}{'start'};
  $endDate   = ${$dates}{'end'};
  my $clone_cmd;
  $clone_cmd = "cd /tmp; git clone -q ssh://$user@" . "$host$repo";
  my $log_cmd =
"cd /tmp/$project; git log --since='$startDate' --until='$endDate' --pretty=medium --date=iso |";
  my $date;
  my $comment;
  my %temp;
  system($clone_cmd );

  return $log_cmd;

}

sub read_git_log {

  my ( $log_cmd, $project, $user ) = @_;
  my $cleanup_cmd = "rm -rf /tmp/$project";
  open( LOG, $log_cmd );
  ### Read commit notes vom git log ###
  my $line;
  my $current_line;
  my $commit_date;
  my $commit_author;
  my $is_comment = 0;
  my %commitnotes;
  my $committext;
  my $delimiter1;
  my $check_commit_author = "(Author:).*?";
  my $check_commit_date   = "(Date:).*?";

  while (<LOG>) {
    $current_line = $_;
    chomp($current_line);
    if ( $current_line =~ m/$check_commit_author/is ) {
      $is_comment = 0;
      $commit_author = substr( $current_line, 8, 4 );
    }
    elsif ( $current_line =~ m/$check_commit_date/is ) {
      $is_comment = 1;
      $commit_date = substr( $current_line, 0, 5 );
    }
    elsif ( $is_comment && ( substr( $current_line, 0, 7 ) eq 'commit ' ) ) {
      $is_comment                               = 0;
      $commitnotes{$commit_date}->{$committext} = $commit_author;
      $committext                               = 0;
    }
    elsif ($is_comment) {
      $committext .= "<br>$current_line"
        if ( $committext && $current_line =~ m/((?:[a-z]+))/is );
      $committext = $current_line if !$committext;
    }
  }

  $commitnotes{$commit_date}->{$committext} = $commit_author;
  system($cleanup_cmd);
  my $output = filtering_commits( $user, \%commitnotes);
  return ($output);
}
1;
__END__
