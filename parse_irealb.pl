#!/usr/bin/perl

use strict ;
use MIME::Base64 ;


while (<STDIN>) {
	my $line = $_ ;
	chomp($line) ;

	my ($title, $composer, $style, $key, $s) = split(/;/, $line, 5) ;

	print "IREALB;$title;$composer;$style;$key\n" ;

	# Save comments
	my @comments = ($s =~ /<(.*?)>/g) ;
	$s =~ s/(<.*?>)/<>/g ;
	# Save alt since it contains 'l'
	$s =~ s/alt/~/g ;

	# Remove some iRealB formatting codes
	$s =~ s/[lsfY]//g ;
	# Replace some iRealB codes by more standard symbols
	$s =~ s/S/\$/g ;
	$s =~ s/Q/@/g ;
	$s =~ s/W/ /g ;
	$s =~ s/\|([^\|]*?)r/|%%$1/g ;
	$s =~ s/\|([^\|]*?)x/|%$1/g ;
	$s =~ s/p/\//g ;
	$s =~ s/n/NC/g ;
	$s =~ s/N(\d)/$1./g ;
	$s =~ s/u/sus/g ;
	$s =~ s/Z\s*/Z/g ;
	
	# Normalize some formatting
	$s =~ s/,?\*([a-zA-Z]),?/$1:/g ;
	$s =~ s/([a-zA-Z]:)([{\[|])/$2$1/g ;
	$s =~ s/(T\d\d)([{\[|])/$2$1/g ;
	$s =~ s/\*//g ;

	# Place each section on it's own line
	$s =~ s/(.)([\[{])/$1\n$2/g ;

	$s =~ s/^([\[][^\]]*Z)$/$1]/mg ;
	$s =~ s/^([{][^\}]*Z)$/$1}/mg ;
	$s =~ s/([\]}])\s+$/$1/mg ;

	$s =~ s/^([\[][^\]]*?)$/$1]/mg ;
	$s =~ s/^([{][^}]*?)$/$1}/mg ;
	$s =~ s/\s+(\|[23]\.)/$1/g ;
	$s =~ s/\|+/|/g ;
	
	# Restore 'alt'
	$s =~ s/~/alt/g ;
	# Restore comments
	my $i = 0 ;
	$s =~ s/<>/'<' . encode_base64($comments[$i++], '') . '>'/ge ;
	

	print "$s\n" ;
	print "END\n" ;
}

