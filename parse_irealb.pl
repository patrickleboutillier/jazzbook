#!/usr/bin/perl

use strict ;
use MIME::Base64 ;


my $irealb = $ARGV[0] ;

open(IREALB, "<$irealb") or die("Can't open '$irealb' for reading: $!") ;
my $line = <IREALB> ;
close(IREALB) ;
chomp($line) ;

parse_irealb($line) ;


sub parse_irealb {
	my $line = shift ;

	my ($title, $composer, $style, $key, $s) = split(/;/, $line, 5) ;

	my $fname = $title ;
        $fname =~ s/\W/_/g ;

	print "Parsing '$title'...\n" ;
	open(PARSED, ">parsed/$fname.parsed") or die("Can't open 'parsed/$fname.parsed' for writing: $!") ;

	print PARSED "#$line\n" ;
	print PARSED "IREALB;$title;$composer;$style;$key\n" ;

	# Save comments
	my @comments = ($s =~ /<(.*?)>/g) ;
	$s =~ s/(<.*?>)/<>/g ;
	# Save alt since it contains 'l'
	$s =~ s/alt/~/g ;

	# Remove some iRealB formatting codes
	$s =~ s/[lsfYU]//g ;
	# Replace some iRealB codes by more standard symbols
	$s =~ s/S/\$/g ;
	$s =~ s/Q/@/g ;
	$s =~ s/W/_/g ;
	$s =~ s/\|([^\|]*?)r\|/|%%$1$2/g ;
	$s =~ s/\|([^\|]*?)x/|%$1/g ;
	$s =~ s/\|([^\|]*?)n/|NC$1/g ;
	$s =~ s/n/NC/g ;
	$s =~ s/p/\//g ;
	$s =~ s/N(\d)/$1./g ;
	$s =~ s/u/sus/g ;
	$s =~ s/Z\s*/]/g ;
	
	# Normalize some formatting
	$s =~ s/,?\*([a-zA-Z]),?/$1:/g ;
	$s =~ s/([a-zA-Z]:)(T\d\d)?([{\[|]|\d\.)/$3$1/g ;
	$s =~ s/(T\d\d)([{\[|])/$2$1/g ;
	$s =~ s/(\@)([{\[|])/$2$1/g ;
	$s =~ s/\*//g ;
	$s =~ s/\|+/|/g ;

	$s =~ s/(\d\.)/!\t$1/g ;
	$s =~ s/([\[\]]+)/!/g ;
	$s =~ s/([{])/!$1/g ;

	# Make stuff neater
	# $s =~ s/([\]}])\s+/$1/g ;
	# $s =~ s/\s+(\|[23]\.)/$1/g ;

	my $s = split_sections($s) ;
	# Place each section on it's own line
	# $s =~ s/(.)([\[{])/$1\n$2/g ;

	# Restore 'alt'
	$s =~ s/~/alt/g ;
	# Restore comments
	my $i = 0 ;
	$s =~ s/<>/'<' . encode_base64($comments[$i++], '') . '>'/ge ;
	
	print PARSED "$s\n" ;
	print PARSED "END\n\n" ;
	close(PARSED) ;
}


sub split_sections {
	my $s = shift ;

	my @sections = split(/!+/, $s) ;

	my @s = () ;
	foreach my $sec (@sections){
		$sec =~ s/^\|// ;
		$sec =~ s/\|$// ;
		$sec =~ s/\}\s*$// ;

		if ($sec !~ /^\s*$/){
			push @s, "$sec" ;
		}
	}

	return join("\n", @s) ;
}
