#!/usr/bin/perl

package WRC;

use strict;
use warnings;

sub format_comment {
  my %text_formatted;
  my ($text) = @_;

  if ($text) {
    $text =~ s/\[\[.*\]\]//g;

    for my $line ( split( '<br>', $text ) ) {
      if ( substr( $line, 0, 1 ) eq '*' ) {
        $text_formatted{'heading'} = substr( $line, 1 );
      }
      elsif ( substr( $line, 0, 2 ) eq '  ' ) {
        push( @{ $text_formatted{'text'} }, substr( $line, 2 ) );
      }
      else {
        push( @{ $text_formatted{'text'} }, $line );
      }
    }

    ### Remove empty lines at the beginning of the text

    while ( ${ $text_formatted{'text'} }[0] =~ m/^\s*$/ ) {
      shift( @{ $text_formatted{'text'} } );
    }

    ### Remove empty lines at the end of the text

    while ( ${ $text_formatted{'text'} }[-1] =~ m/^\s*$/ ) {
      pop( @{ $text_formatted{'text'} } );
    }

    return ( \%text_formatted );
  }
}

1;
