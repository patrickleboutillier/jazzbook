#!/usr/bin/perl

use strict ;
use Data::Dumper ;
use File::Basename ;
use File::Copy ;


print "<HTML>\n" ;

my %tunes = map { basename($_, ".json") => {simple => 1} } glob("jsoned/*.json") ;

my %attrs = (
	coda => '[@]',
	segna => '[\$]',
	comments => '[<>]',
	oddtime => 'T[^4]\d',
	NC => 'NC',
) ;

foreach my $a (keys %attrs){
	map { delete $tunes{$_}->{simple} ; $tunes{$_}->{complex} = 1 ; $tunes{$_}->{$a} = 1 }
		map { chomp($_) ; basename($_, ".parsed") } `grep -l -P '$attrs{$a}' parsed/*.parsed` ;
}


foreach my $a (('simple', 'complex'), sort keys %attrs){
	list($a) ;
}


sub list {
	my $type = shift ;


	my @files = grep { $tunes{$_}->{$type} } keys %tunes ;
	my $nb = scalar(@files) ;
	my $title = ucfirst($type) ;
	print "<H2>$title ($nb tunes)</H2>\n" ;
	foreach my $f (sort @files){
		print "<A HREF='jazzbook.html?t=$f'>$f</A>" ;
		print "<BR>\n" ;
	}
}


__DATA__

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


print "</HTML>\n" ;
