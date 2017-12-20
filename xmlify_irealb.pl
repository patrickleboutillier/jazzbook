#!/usr/bin/perl

use strict ;
use Data::Dumper ;
use Getopt::Long ;


my $parsed = $ARGV[0] ;

open(PARSED, "<$parsed") or die("Can't open '$parsed' for reading: $!") ;
my @lines = <PARSED> ;
close(PARSED) ;

my $ok = 1 ;
my $meter_nb = 4 ;
my @buf = () ;

xml_irealb(@lines) ;


sub xml_irealb {
	my @lines = @_ ;

	my $tune = undef ;
	my $cur_repeat = undef ;

	foreach my $line (@lines){
		chomp($line) ;
		my $oline = $line ;

		next if !length($line) ;
		next if $line =~ /^#/ ;

		push @buf, $line ;

		if ($line =~ /^IREALB;(.*?);(.*?);(.*?);(.*?)$/){
			$tune = { e => 'tune', title => $1, composer => $2, style => $3, 
				key => $4, children => [] } ;
		}
		else {
			# Each line represents a section.
			my $section = { e => 'section', children => [] } ;

			if ($line =~ s/^\{//){
				$section->{repeat} = 1 ;
				push @{$section->{children}}, parse_bars($line) ;
				$cur_repeat = $section ;
				push @{$tune->{children}}, $section ;
			}
			elsif ($line =~ s/^\t(\d)\.//){
				# Alternate endings.
				my $no = $1 ;
				$section->{e} = 'ending' ;
				$section->{no} = $no ;
				push @{$section->{children}}, parse_bars($line) ;
				push @{$cur_repeat->{children}}, $section ;
			}
			else {
				push @{$section->{children}}, parse_bars($line) ;
				push @{$tune->{children}}, $section ;
			}
		}
	}

	warn "$tune->{title}\n" ;
	my $fname = $tune->{title} ;
	$fname =~ s/\W/_/g ;
	if ($ok){
		open(XML, ">xmled/pass/$fname.xml") or die("Can't open file out/pass/$fname.xml: $!") ;
	}
	else {
		open(XML, ">xmled/reject/$fname.xml") or die("Can't open file out/reject/$fname.xml: $!") ;
	}
	print XML "<!--\n" ;
	print XML join("\n", @buf) ;

	print XML "\n-->\n" ;
	xml_dumper(\*XML, $tune, 0) ;
	close(XML) ;
}


sub parse_bars {
	my $t = shift ;

	my @bars = map { parse_bar($_) } split(/\|/, $t) ;

	return @bars ;
}


sub parse_bar {
	my $b = shift ;

	my $ob = $b ;

	# Remove alternate chords
	# $b =~ s/\(.*?\)//g ;

	my @cs = () ;

	# Remove empty bars
	return () if $b =~ /^\s*$/ ;

	my $coda = ($b =~ s/(.)@/$1/) ;
	my @comments = ($b =~ /\<(.*?)\>/g) ;
	$b =~ s/\<(.*?)\>//g ;
	my $eat_space = 0 ;

	my $bar = { e => 'bar', beats => $meter_nb, children => \@cs } ;

	my $len = 0 ;
	my $err = 0 ;
	while (length($b)){
		if (($eat_space)&&($b =~ s/^\s+//)){
		}
		elsif ($b =~ s/^([a-zA-Z])://){
			$bar->{label} = $1 ;
		}
		elsif ($b =~ s/^T(\d)(\d)//){
			$bar->{meter} = "$1/$2" ;
			$meter_nb = $1 ;
		}
		elsif ($b =~ s/^@//){
			$bar->{label} = 'coda' ;
		}
		elsif ($b =~ s/^\$//){
			$bar->{label} = 'segno' ;
		}
		elsif ($b =~ s/^,//){
		}
		elsif ($b =~ s/^(\/+\s*)//){
			my $units = length($1) ;
			$len += $units ;
			push @cs, { e => 'chord', name => '/', units => $units } ;
		}
		elsif ($b =~ s/^(%+)//){
			$bar->{repeat_last} = length($1) ;
			$eat_space = 1 ;
		}
		elsif ($b =~ s/^(\s*)(NC)(\s*)//){
			my $units = length($1) + length($3) + 1 ;
			$len += $units ;
			push @cs, { e => 'chord', name => 'NC', units => $units } ;
		}
		elsif ($b =~ s/^(\s*)([_A-G][^\s,]*)(,*)(\s*)//){
			my $chord = $2 ;
			my $units = length($1) + length($4) + 1 ;
			$len += $units ;
			push @cs, { e => 'chord', name => $chord, units => $units } ;
		}
		elsif ($b =~ s/^\((.*?)\)//){
			# Do nothing for now with alternate chords
		}
		else {
			problem("Unknown bar element: '$ob' at '$b'") ;
			$err = 1 ;
			last ;
		}
	}

	if (! $err){
		if (! $bar->{repeat_last}){
			if (scalar(@cs) == 1){
				# There is only one chord in the bar, the chord beats equals the bar beats.
				delete $cs[0]->{units} ;
				$cs[0]->{beats} = $meter_nb ;
			}
			else {
				my $mul = 1 ;
				# if (!(($len == $meter_nb)||($len == (2 * $meter_nb))||($len == ($meter_nb / 2)))){
				if (!(($len == 2)||($len == 4)||($len == $meter_nb)||($len == (2 * $meter_nb)))){
					problem("Incorrect logical bar length: '$len' ($meter_nb) for '$ob'") ;
				}
				else {
					$mul = $len / $meter_nb ;
					foreach my $e (@cs){
						if (exists($e->{units})){
							my $u = delete $e->{units} ;
							$e->{beats} = $u * $mul ;
						}
					}
				}
			}
		}
	}
	
	foreach my $c (@comments){
		push @cs, { e => 'comment', value => "$c" } if $c ;
	}
	$bar->{coda} = 1 if ($coda) ;

	
	return $bar ;
}


sub xml_dumper {
	my $fh = shift ;
	my $tag = shift ;
	my $level = shift ;

	my $indent = '  ' x $level ;
	my $e = delete $tag->{e} ;
	my $children = delete $tag->{children} ;
	print $fh "$indent<$e" ;
	my @attrs = keys %{$tag} ;
	foreach my $a (keys %{$tag}){
		print $fh " $a='$tag->{$a}'" ;
	}
	if ((ref($children))&&(scalar(@{$children}))){
		print $fh ">\n" ;
		foreach my $c (@{$children}){
			# warn Dumper($c) ;
			xml_dumper($fh, $c, $level + 1) ;
		}
		print $fh "$indent</$e>\n" ;
	}
	else {
		print $fh "/>\n" ;
	}
}


sub problem {
	my $msg = shift ;

	warn "$msg\n" ;
	$ok = 0 ;
	push @buf, $msg ;
}


__DATA__
IREALB;26-2;Coltrane John;Medium Up Swing;F
A:[T44F^7 Ab7 |Db^7 E7 |A^7 C7 |C-7 F7 |Bb^7 Db7 |Gb^7 A7 |D-7 G7 |G-7 C7 ]
A:[F^7 Ab7 |Db^7 E7 |A^7 C7 |C-7 F7 |Bb^7 Ab7 |Db^7 E7 |A^7 C7 |F^7   ]
B:[C-7 F7 |E-7 A7 |D^7 F7 |Bb^7   |Eb-7   |Ab7   |Db^7   |G-7 C7 ]
A:[F^7 Ab7 |Db^7 E7 |A^7 C7 |C-7 F7 |Bb^7 Ab7 |Db^7 E7 |A^7 C7 |F^7   Z
END
IREALB;500 Miles High;Corea Chick;Bossa Nova;E-
[T44E-7   | %  |G-7   | %  |Bb^7   | %  |Bh7   |E7#9   |A-7   | %  |F#h7   | %  |F-7   | % @ |C-7   | %  |B7#9   | %  Z
{@C-7   | %  |Ab^7   | %  }
END
