#!/usr/bin/perl

use strict ;
use File::Basename ;


my @files = glob("decoded/*.irealb") ;
foreach my $f (@files){
	my $dest = basename($f, ".irealb") ;
	my $cmd = "cat $f | ./parse_irealb.pl > parsed/$dest.parsed" ;
	print "Parsing '$dest'...\n" ;
	system($cmd) ;
}

