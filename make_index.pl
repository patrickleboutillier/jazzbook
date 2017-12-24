#!/usr/bin/perl

use strict ;
use File::Basename ;
use File::Copy ;


print "<HTML>\n" ;

my @files = glob("jsoned/*.json") ;
foreach my $f (@files){
	my $base = basename($f, ".json") ;
	print "<A HREF='realbook.html?t=$base'>$base</A>" ;
	print "<BR>\n" ;
}

print "</HTML>\n" ;
