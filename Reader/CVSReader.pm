#!/usr/bin/perl
package WRC;
use strict;
use warnings;
use File::Basename;
use lib File::Basename::dirname($0) . '/..';
use Utility::Util;
use Data::Dumper;

sub get_cvs_log {
  ### Input from function call ###
  my ( $input_week, $user, $timespan, $project, $host, $repo ) = @_;
  my $dates      = get_dates( \$input_week, \$timespan, "mdy", "/");
  my $start_date = ${$dates}{'start'};
  my $end_date   = ${$dates}{'end'};
  my $checkout_folder = get_checkout_folder();
  $ENV{CVSROOT} = ":ext:$user@" . $host . "$repo";
  my $checkout_cmd = "cd ./$checkout_folder; cvs -Q checkout $project";
  my $log_cmd      = "cd ./$checkout_folder/$project; cvs -q log -d '$start_date<$end_date' ";

  system($checkout_cmd );

  return $log_cmd;
}

sub read_cvs_log {

  ### Read commit notes vom cvs log ###

  my ( $log_cmd, $project, $user ) = @_;

  open( LOG_CMD, "$log_cmd |" ) or die "Can't run '$log_cmd'\n$!";
  my $current_line;
  my $commit_date;
  my $commit_author;
  my $is_comment = 0;
  my %commitnotes;
  my $committext;
  my $delimiter1 = "----------------------------";
  my $delimiter2 = "=============================================================================";
  my $check_commit_headline = "(date:).*?(author:).*?(state:).*?(commitid:)";

  while (<LOG_CMD>) {
    $current_line = $_;
    chomp($current_line);
    if ( $current_line =~ m/$check_commit_headline/is ) {
      $is_comment    = 1;
      $commit_date   = substr( $current_line, 6, 10 );
      $commit_author = substr( $current_line, 42, 4 );
    }
    elsif ( $is_comment
            && ( $current_line eq $delimiter1 || $current_line eq $delimiter2 ) )
    {
      $is_comment                               = 0;
      $commitnotes{$commit_date}->{$committext} = $commit_author;
      $committext                               = 0;
    }
    elsif ($is_comment) {
      $committext .= "<br>$current_line" if $committext;
      $committext = $current_line if !$committext;
    }
  }

  my $output = filtering_commits( $user, \%commitnotes);

  return ($output);
}
1;
__END__
