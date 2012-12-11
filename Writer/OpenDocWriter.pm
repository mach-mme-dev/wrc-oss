#!/usr/bin/perl
package WRC;
use strict;
use warnings;
use OpenOffice::OODoc;
use File::Basename;
use lib File::Basename::dirname($0) . '/..';
use Format::WRFormat;
use Utility::Util;
use Data::Dumper;

sub create_odt_document {
  ### Parameters ###
  my (
       $cTextRef, $weekOfYear, $weeks,    $name, $report_number,
       $year,     $outputpath, $meetings, $knowledgetransfers
  ) = @_;
  ### The document handler ###

  my $dates = get_dates( \$weekOfYear, \$weeks, "dmy", "." );
  my $filename = $name . " " . $report_number . " " . substr( ${$dates}{'start'}, 6 ) . ".odt";
  my $document = odfDocument(
                              file          => $filename,
                              template_path => "Writer/template",
                              create        => 'text'
  );
  ### All the styles we need ###
  $document->createStyle(
                          'title',
                          family     => 'paragraph',
                          parent     => 'Standard',
                          properties => {
                                          'fo:text-align'  => 'from-left',
                                          'fo:margin-top'  => '0.9cm',
                                          'fo:margin-left' => '0cm'
                          }
  );
  $document->createStyle(
                          'head_margin',
                          family     => 'paragraph',
                          parent     => 'Standard',
                          properties => {
                                          'fo:margin-bottom' => '0.5cm',
                                          'fo:margin-left'   => '0cm'
                          }
  );
  $document->createStyle(
                          'head',
                          family     => 'paragraph',
                          parent     => 'Standard',
                          properties => {
                                          'fo:margin-bottom' => '0cm',
                                          'fo:margin-left'   => '0cm'
                          }
  );
  $document->createStyle(
                          'tb',
                          family     => 'graphic',
                          parent     => 'objectwithshadow',
                          properties => {
                                          'style:vertical-pos'   => 'from-top',
                                          'style:horizontal-pos' => 'from-left',
                                          'style:vertical-rel'   => 'page',
                                          'style:horizontal-rel' => 'page'
                          }
  );
  $document->createStyle(
                          'tb_heading',
                          family     => 'paragraph',
                          parent     => 'Standard',
                          properties => { 'fo:margin-bottom' => '0.25cm' }
  );
  $document->createStyle(
                          'cn_heading',
                          family     => 'paragraph',
                          parent     => 'Standard',
                          properties => { 'fo:margin-left' => '0.25cm' }
  );
  $document->createStyle(
                          'cn_content',
                          family     => 'paragraph',
                          parent     => 'Standard',
                          properties => { 'fo:margin-left' => '0.75cm' }
  );
  $document->createStyle(
                          'textSmall',
                          family => 'paragraph',
                          parent => 'Standard'
  );
  ### All the style properties ###
  $document->styleProperties(
                              'title',
                              '-area'           => 'text',
                              'fo:font-weight'  => 'bold',
                              'style:font-name' => 'Arial',
                              'fo:font-size'    => '14pt'
  );
  $document->styleProperties(
                              'head_margin',
                              '-area'           => 'text',
                              'style:font-name' => 'Arial',
                              'fo:font-size'    => '11pt'
  );
  $document->styleProperties(
                              'head',
                              '-area'           => 'text',
                              'style:font-name' => 'Arial',
                              'fo:font-size'    => '11pt'
  );
  $document->styleProperties(
                              'tb_heading',
                              '-area'           => 'text',
                              'fo:font-weight'  => 'bold',
                              'style:font-name' => 'Arial',
                              'fo:font-size'    => '10pt'
  );
  $document->styleProperties(
                              'cn_heading',
                              '-area'           => 'text',
                              'fo:font-size'    => '9pt',
                              'style:font-name' => 'Arial',
  );
  $document->styleProperties(
                              'cn_content',
                              '-area'           => 'text',
                              'style:font-name' => 'Arial',
                              'fo:font-size'    => '9pt'
  );
  $document->styleProperties(
                              'textSmall',
                              '-area'           => 'text',
                              'style:font-name' => 'Arial',
                              'fo:font-size'    => '8pt'
  );
  ### We start creating the document here ###
  ### Header ###
  $document->appendTable( 'tHead', 1, 2 );
  $document->appendParagraph(
                              text       => 'Ausbildungsnachweis Nr. ' . $report_number,
                              style      => 'title',
                              attachment => $document->getTableCell( 'tHead', 0, 0 )
  );
  $document->appendParagraph(
                              text       => 'Name: ' . $name,
                              style      => 'head_margin',
                              attachment => $document->getTableCell( 'tHead', 0, 1 )
  );
  $document->appendParagraph(
                    text => 'für die Woche vom ' . ${$dates}{"start"} . ' bis ' . ${$dates}{"end"},
                    style      => 'head_margin',
                    attachment => $document->getTableCell( 'tHead', 0, 1 )
  );
  $document->appendParagraph(
                              text       => 'Ausbildungsjahr ' . $year,
                              style      => 'head',
                              attachment => $document->getTableCell( 'tHead', 0, 1 )
  );
  ### The first big textbox ###
  my $box = $document->createTextBox(
                                      page     => 'AnyPageName',
                                      name     => 'Textbox1',
                                      size     => '17.875cm, 9.75cm',
                                      position => '1cm, 3.5cm',
                                      style    => 'tb',
                                      content  => ''
  );
  $document->appendParagraph(
                              text       => 'Betriebliche Tätigkeit',
                              style      => 'tb_heading',
                              attachment => $box
  );
  ### Fill in the commit note text ###
  ### Maximum of 24 lines fit in the textbox ###
  my $lines_total = 0;
  my $lines;
  for my $date ( keys %{$cTextRef} ) {
    for my $comment ( @{ $cTextRef->{$date} } ) {
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
  }
  calendar_entries( $meetings, $box, $document );
  ### The second big textbox ###
  $box = $document->createTextBox(
                                   page     => 'AnyPageName',
                                   name     => 'Textbox2',
                                   size     => '17.875cm, 9.75cm',
                                   position => '1cm, 13.25cm',
                                   style    => 'tb',
                                   content  => ''
  );
  $document->appendParagraph(
     text =>
       'Unterweisungen, Lehrgespräche,betrieblicher Unterricht, sonstige Schulungsveranstaltungen',
     style      => 'tb_heading',
     attachment => $box
  );
  calendar_entries( $knowledgetransfers, $box, $document );
  ### The left textbox for signature ###
  $box = $document->createTextBox(
                                   page     => 'AnyPageName',
                                   name     => 'Textbox4',
                                   size     => '8.875cm, 3cm',
                                   position => '1cm, 24cm',
                                   style    => 'tb',
                                   content  => 'Für die Richtigkeit:'
  );
  $document->appendParagraph( text       => '',
                              attachment => $box );
  $document->appendParagraph( text       => '',
                              attachment => $box );
  my $para = $document->appendParagraph( text       => '__________',
                                         attachment => $box );
  $document->appendSpaces( $para, 2 );
  $document->extendText( $para, '___________________________' );
  $para = $document->appendParagraph(
                                      text       => 'Datum',
                                      attachment => $box,
                                      style      => 'textSmall'
  );
  $document->appendSpaces( $para, 23 );
  $document->extendText( $para, 'Unterschrift des Auszubildenden' );
  ### The right textbox for signature ###
  $box = $document->createTextBox(
                                   page     => 'AnyPageName',
                                   name     => 'Textbox5',
                                   size     => '8.875cm, 3cm',
                                   position => '10.125cm, 24cm',
                                   style    => 'tb',
                                   content  => ''
  );
  $document->appendParagraph( text       => '',
                              attachment => $box );
  $document->appendParagraph( text       => '',
                              attachment => $box );
  $document->appendParagraph( text       => '',
                              attachment => $box );
  $para = $document->appendParagraph( text       => '__________',
                                      attachment => $box );
  $document->appendSpaces( $para, 2 );
  $document->extendText( $para, '___________________________' );
  $para = $document->appendParagraph(
                                      text       => 'Datum',
                                      attachment => $box,
                                      style      => 'textSmall'
  );
  $document->appendSpaces( $para, 23 );
  $document->extendText( $para, 'Unterschrift des Ausbildenden' );

  if ( $document->save( $outputpath . $filename ) ) {
    return 1;
  }
  else {
    return 0;
  }

}
1;
__END__
