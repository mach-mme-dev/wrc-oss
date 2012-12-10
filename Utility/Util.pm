#!/usr/bin/perl
package WRC;
use strict;
use warnings;
use DateTime;
use POSIX qw( ceil );
use Date::Calc qw(:all);
use Data::Dumper;

sub get_traineeship_year {
  my ( $start_year, $year2, $start_day, $report_number ) = @_;
  my $year;
  my $weeks_start_year = Weeks_in_Year($start_year);
  my $weeks_year2      = Weeks_in_Year($year2);
  if ( $report_number <= $weeks_start_year ) {
    $year = 1;
  }
  elsif ( $report_number <= $weeks_start_year + $weeks_year2 ) {
    $year = 2;
  }
  else {
    $year = 3;
  }
  return $year;
}

sub get_checkout_folder {
  return "temporary_checkout_folder";
}

sub counter {
  my ( $start_year, $start_month, $start_day, $input_week ) = @_;
  my @datum         = localtime();
  my $current_year  = $datum[5] + 1900;
  my $current_month = $datum[4] + 1;
  my $current_day   = $datum[3];
  my $dt           = DateTime->now();
  my $current_week = $dt->week_number();

  my $difference =
    Date::Calc::Delta_Days( $start_year,   $start_month,   $start_day,
                            $current_year, $current_month, $current_day );

  my $report_number = int( $difference / 7 + 1 );

  $report_number = $report_number - ( $current_week - $input_week );

  return $report_number;
}

sub get_dates {
  my ( $weekOfYear, $weeks, $format, $seperator ) = @_;
  $weekOfYear = ${$weekOfYear};
  $weeks      = ${$weeks};
  my $dt = DateTime->now();
  $dt->set_time_zone('Europe/Berlin');
  my $currentWeek = $dt->week_number();
  my %dates;

  if ( $weekOfYear != 0 ) {

    if ( $weekOfYear > $currentWeek ) {
      $dt->add( weeks => ( $weekOfYear - $currentWeek ) );
    }
    else {
      $dt->subtract( weeks => ( $currentWeek - $weekOfYear ) );
    }
  }
  while ( $dt->day_of_week() < 7 ) {
    $dt->add( days => 1 );
  }
  if ( $format eq "mdy" ) {
    ### cvs & git
    $dates{'end'} = $dt->mdy($seperator) . ' 23:59:59 ' . $dt->time_zone_short_name();
    $dt->subtract( weeks => $weeks );
    $dt->add( days => 1 );
    $dates{'start'} = $dt->mdy($seperator) . ' 00:00:00 ' . $dt->time_zone_short_name();
  }
  elsif ( $format eq "ymd" ) {
    ### svn
    $dates{'end'} = $dt->ymd($seperator) . 'T23:59:59';
    $dt->subtract( weeks => $weeks );
    $dt->add( days => 1 );
    $dates{'start'} = $dt->ymd($seperator) . 'T00:00:00';
  }
  elsif ( $format eq "dmy" ) {
    ### writer dates
    $dates{'end'} = $dt->dmy($seperator);
    $dt->subtract( weeks => $weeks );
    $dt->add( days => 1 );
    $dates{'start'} = $dt->dmy($seperator);
  }
  return ( \%dates );
}

sub merge_hashes {
  my ( $href1, $href2 ) = @_;
  for my $key ( keys %{$href2} ) {
    for my $line ( @{ $href2->{$key} } ) {
      push( @{ $href1->{$key} }, $line );
    }
  }
  return ($href1);
}

sub get_lines_odt {
  my ($comment)     = @_;
  my $lines         = 0;
  my $lines_total   = 1;
  my $limit_heading = 110;
  my $limit_text    = 113;
  if ( ${$comment}{'heading'} ) {
    $lines = length( ${$comment}{'heading'} ) / $limit_heading;
    if ( $lines < 1 ) {
      $lines = 1;
    }
    $lines_total += ceil($lines);
  }
  for my $line ( @{ $comment->{'text'} } ) {
    $lines = length($line) / $limit_text;
    if ( $lines < 1 ) {
      $lines = 1;
    }
    $lines_total += ceil($lines);
  }
  return ($lines_total);
}

sub get_lines_doc {
  my ($comment)     = @_;
  my $lines         = 0;
  my $lines_total   = 1;
  my $limit_heading = 90;
  my $limit_text    = 100;
  if ( ${$comment}{'heading'} ) {
    $lines = length( ${$comment}{'heading'} ) / $limit_heading;
    if ( $lines < 1 ) {
      $lines = 1;
    }
    $lines_total += ceil($lines);
  }
  for my $line ( @{ $comment->{'text'} } ) {
    $lines = length($line) / $limit_text;
    if ( $lines < 1 ) {
      $lines = 1;
    }
    $lines_total += ceil($lines);
  }
  return ($lines_total);
}

sub calendar_entries {
  my ( $meetings, $box, $document ) = @_;
  my $comment;
  my $lines_total = 0;
  my $lines;
  foreach $comment (@$meetings) {
    my $formatted_comment = format_comment($comment);
    $lines = get_lines_odt($formatted_comment);
    if ( ( $lines_total + $lines ) <= 24 ) {
      $lines_total += $lines;
      if ( ${$formatted_comment}{'heading'} ) {
        $document->appendParagraph(
                                    text       => ${$formatted_comment}{'heading'},
                                    style      => 'cn_heading',
                                    attachment => $box
        );
      }
      my $p = $document->appendParagraph(
                                          text       => '',
                                          style      => 'cn_content',
                                          attachment => $box
      );
      for my $line ( @{ ${$formatted_comment}{'text'} } ) {
        $document->extendText( $p, $line, 'cn_content' );
        if ( $line ne ${ ${$formatted_comment}{'text'} }[-1] ) {
          $document->appendLineBreak($p);
        }
      }
      $document->appendLineBreak($p);
    }
  }
  return $box;
}

sub filtering_commits {

  my ( $user, $commitnotes ) = @_;
  my %output;
  my %commitnotes = %{$commitnotes};

  for my $date ( keys %{$commitnotes} ) {
    for my $comment ( keys %{ $commitnotes{$date} } ) {
      my $author = $commitnotes{$date}->{$comment};
      if ( $author eq $user ) {
        push( @{ $output{$date} }, $comment );
      }
      elsif ( $comment =~ m/\[\[.*?Pair.*?$user/is ) {
        push( @{ $output{$date} }, $comment .= "(Pair programming)" );
      }
      elsif ( $comment =~ m/\[\[.*?REVIEw.*?$user/is ) {
        push( @{ $output{$date} }, $comment .= "(Code review)" );
      }
    }
  }
  return ( \%output );
}

1;
__END__


