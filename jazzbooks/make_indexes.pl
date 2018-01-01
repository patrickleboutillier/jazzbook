#!/usr/bin/perl

use strict ;
use Data::Dumper ;
use File::Basename ;
use File::Copy ;
use JSON ;


foreach my $book (@ARGV){
	open(INDEX, ">$book/index.html") or die("Can't open $book/index.html for writing: $!") ;

	print INDEX "<HTML>\n" ;

	my @tunes = glob("$book/*.json") ;

	print INDEX "<H1>$book</H1>\n" ;
	foreach my $f (sort @tunes){
		open(J, "<$f") or die("Can't open $f for reading: $!") ;
		my $json = new JSON() ;
		my $tune = $json->decode(join('', <J>)) ;
		my $t = basename($f, ".json") ;
		print INDEX "<A HREF='/jazzbook.html?b=$book&t=$t'>$tune->{title}</A><BR>\n" ;
	}

	print INDEX "</HTML>\n" ;
}

