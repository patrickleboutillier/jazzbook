#!/usr/bin/perl

use strict ;
use Data::Dumper ;
use File::Basename ;
use File::Copy ;


print "<HTML>\n" ;

my @files = glob("jsoned/*.json") ;
my %complex = map { chomp($_) ; (basename($_, ".parsed") => 1) } 
	`grep -l -P '([<>@\$]|T[^4]\d)' parsed/*.parsed` ;

my @basic = () ;
my @complex = () ;
foreach my $f (@files){
	my $base = basename($f, ".json") ;
	if ($complex{$base}){
		push @complex, $base ;
	}
	else {
		push @basic, $base ; 
	}
}

list("Basic", @basic) ;
list("Complex", @complex) ;


sub list {
	my $title = shift ;
	my @files = @_ ;

	my $nb = scalar(@files) ;
	print "<H2>$title ($nb tunes)</H2>\n" ;
	foreach my $f (sort @files){
		my $base = basename($f, ".json") ;
		print "<A HREF='jazzbook.html?t=$base'>$base</A>" ;
		print "<BR>\n" ;
	}
}

print "</HTML>\n" ;
