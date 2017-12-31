#!/usr/bin/perl

use strict ;
use File::Basename ;
use File::Copy ;


my @files = glob("parsed/*.parsed") ;
foreach my $f (@files){
	my $dest = basename($f, ".parsed") ;
	my $cmd = "cat $f | ./jsonify_irealb.pl > /tmp/$dest.json" ;
	print "Converting '$dest' to JSON...\n" ;
	my $rc = system($cmd) ;
	move("/tmp/$dest.json", "jsoned/" . ($rc ? "reject/" : "")) ;
}

