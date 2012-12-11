#!/usr/bin/perl
package WRC;
use strict;
use warnings;
use MsOffice::Word::HTML::Writer;
use File::Basename;
use lib File::Basename::dirname($0) . '/..';
use Format::WRFormat;
use Utility::Util;
use Data::Dumper;

sub create_doc_document {
  my (
       $href, $weekOfYear, $timespan, $name, $report_number,
       $year, $outputpath, $meetings, $knowledgetransfers
  ) = @_;
  if ( !$year ) {
    $year = 1;
  }
  my $dates = get_dates( \$weekOfYear, \$timespan, "dmy", "." );
  my $filename = $name . " " . $report_number . " " . substr( ${$dates}{'start'}, 6 ) . ".doc";
  my %params;
  $params{'title'} = 'MsWord Test';
  $params{'head'}  = '<meta http-equiv="content-type" content="text/html; charset=utf-8">
    <style type="text/css">
       body {
         font-family: Arial, sans-serif;
       }
       td.left {
         width: 370px;
         font-size: 22px;
         font-weight: bold;
       }
       td.right {
         width: 370px;
         font-size: 16px;
       }
       td.mbot {
         margin-bottom: 8px;
       }
       h2 {
         font-size: 18px;
         font.weight: bold;
         text-decoration: none;
         text-align: left;
         margin: 0 0 5px 0;
       }
       td.content {
         width: 740px;
         height: 375px;
         border: 1px solid black;
         vertical-align: top;
       }
       h3.content {
         font-size: 18px;
         font-weight: normal;
         margin: 0 0 0 15px;
       }
       p.content {
         font-size: 16px;
         margin: 0 0 10 40px;
       }
       #signature {
         margin: 10px 0 0 0;
       }
       td.signature {
         width: 370px;
         height: 140px;
         border: 1px solid black;
       }
       h2.signature {
         margin-left: 6px;
       }
       table.signature {
         margin-left: 10px;
       }
       td.mright {
         margin-right: 6px;
       }
       p.small {
         font-size: 14px;
         margin: 0;
       }
       .mtop {
         margin-top: 5px;
       }
     </script>';
  my $linesTotal = 0;
  my $lines;
  my $text_internal = "";

  for my $date ( keys %{$href} ) {
    for my $comment ( @{ $href->{$date} } ) {
      my $formatted_comment = format_comment($comment);
      $lines = get_lines_doc($formatted_comment);
      if ( ( $linesTotal + $lines ) <= 24 ) {
        $linesTotal += $lines;
        if ( ${$formatted_comment}{'heading'} ) {
          $text_internal .= '<h3 class="content">' . ${$formatted_comment}{"heading"} . '</h3>';
        }
        $text_internal .= '<p class="content">';
        for my $line ( @{ ${$formatted_comment}{'text'} } ) {
          $text_internal .= $line . "<br />\n";
        }
        $text_internal .= '</p>';
      }
    }
  }
  my $comment;
  my $lines_total = 0;
  foreach $comment (@$meetings) {
    my $formatted_comment = format_comment($comment);
    $lines = get_lines_doc($formatted_comment);
    if ( ( $lines_total + $lines ) <= 24 ) {
      $lines_total += $lines;
      if ( ${$formatted_comment}{'heading'} ) {
        $text_internal .= '<h3 class="content">' . ${$formatted_comment}{"heading"} . '</h3>';
      }
      $text_internal .= '<p class="content">';
      for my $line ( @{ ${$formatted_comment}{'text'} } ) {
        $text_internal .= $line . "<br />\n";
      }
      $text_internal .= '</p>';
    }
  }
  $comment     = 0;
  $lines_total = 0;
  my $text_instruction = "";
  foreach $comment (@$knowledgetransfers) {
    my $formatted_comment = format_comment($comment);
    $lines = get_lines_doc($formatted_comment);
    if ( ( $lines_total + $lines ) <= 24 ) {
      $lines_total += $lines;
      if ( ${$formatted_comment}{'heading'} ) {
        $text_instruction .= '<h3 class="content">' . ${$formatted_comment}{"heading"} . '</h3>';
      }
      $text_instruction .= '<p class="content">';
      for my $line ( @{ ${$formatted_comment}{'text'} } ) {
        $text_instruction .= $line . "<br />\n";
      }
      $text_instruction .= '</p>';
    }
  }
  my $doc = MsOffice::Word::HTML::Writer->new(%params);
  $doc->create_section(
                        page => {
                                  size   => '21.0cm 29.7cm',
                                  margin => '1.2cm 2.4cm 2.0cm 1.2cm'
                        },
                        header   => '',
                        footer   => '',
                        new_page => 1
  );
  $doc->write(
    '<table border="0">
      <tr>
        <td class="left" rowspan="3">Ausbildungsnachweis Nr. '
      . $report_number . '</td>
        <td class="right mbot">Name: ' . $name . '</td>
      </tr>
      <tr>
        <td class="right mbot">für die Woche vom '
      . ${$dates}{"start"} . ' bis ' . ${$dates}{"end"} . '</td>
      </tr>
      <tr>
        <td class="right mbot">Ausbildungsjahr ' . $year . '</td>
      </tr>
    </table>
    <table>
      <tr>
        <td class="content">
          <h2>Betriebliche Tätigkeit</h2>
          ' . $text_internal . '
        </td>
      </tr>
      <tr>
        <td class="content">
          <h2>Unterweisungen, Lehrgespräche, betrieblicher Unterricht, sonst. Schulungsveranstaltungen</h2>
          ' . $text_instruction . '
        </td>
      </tr>
    </table>
    <table id="signature">
      <tr>
        <td class="signature">
          <h2 class="signature">Für die Richtigkeit:</h2>
          <br />
          <br />
          <br />
          <table class="signature">
            <tr>
              <td class="mright">
                __________
              </td>
              <td>
                _______________________
              </td>
            </tr>
            <tr>
              <td class="mright">
                <p class="small">Datum</p>
              </td>
              <td>
                <p class="small">Unterschrift des Auszubildenden</p>
              </td>
            </tr>
          </table>
        </td>
        <td class="signature">
          <h2 class="signature">&nbsp;</h2>
          <br />
          <br />
          <br />
          <table class="signature">
            <tr>
              <td class="mright">
                __________
              </td>
              <td>
                _______________________
              </td>
            </tr>
            <tr>
              <td class="mright">
                <p class="small">Datum</p>
              </td>
              <td>
                <p class="small">Unterschrift des Ausbildenden</p>
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>'
  );
 $doc->save_as( $outputpath . $filename );

}
1;
__END__
