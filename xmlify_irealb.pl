#!/usr/bin/perl

use strict ;
use Data::Dumper ;
use Getopt::Long ;


my $parsed = $ARGV[0] ;

open(PARSED, "<$parsed") or die("Can't open '$parsed' for reading: $!") ;
my @lines = <PARSED> ;
pop @lines, pop @lines ;
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

	my @cs = () ;

	# Remove empty bars
	return () if $b =~ /^\s*$/ ;

	my $coda = ($b =~ s/(.)@/$1/) ;
	my @comments = ($b =~ /\<(.*?)\>/g) ;
	$b =~ s/\<(.*?)\>//g ;

	my $bar = { e => 'bar', children => \@cs } ;

	my $len = 0 ;
	my $err = 0 ;
	my $last_chord = undef ;
	while (length($b)){
		if ($b =~ s/^([a-zA-Z])://){
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

		elsif ($b =~ s/^(\/)//){
			$len++ ; 
			$last_chord = { e => 'chord', name => '/', units => 1 } ;
			push @cs, $last_chord ;
		}
		elsif ($b =~ s/^(%%\s*)//){
			$bar->{repeat_last} = 2 ;
			$last_chord = undef ;
		}
		elsif ($b =~ s/^(%\s*)//){
			$bar->{repeat_last} = 1 ;
			$last_chord = undef ;
		}
		elsif ($b =~ s/^(NC\s*)//){
			$len++ ; 
			$last_chord = { e => 'chord', name => 'NC', units => 1 } ;
			push @cs, $last_chord ;
		}
		elsif ($b =~ s/^([_A-G][\/\#\^\-\+\w]*)//){
			my $chord = $1 ;
			$len++ ; 
			$last_chord = { e => 'chord', name => $chord, units => 1 } ;
			push @cs, $last_chord ;
		}
		elsif ($b =~ s/^\((.*?)\)//){
			# Do nothing for now with alternate chords
		}
		elsif ($b =~ s/^\s//){
			$len++ ;
			$last_chord->{units}++ ;
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
				# $cs[0]->{beats} = $meter_nb ;
			}
			else {
				my $mul = 1 ;
				# if (!(($len == $meter_nb)||($len == (2 * $meter_nb))||($len == ($meter_nb / 2)))){
				if (!(($len == 2)||($len == 4)||($len == $meter_nb)||($len == (2 * $meter_nb)))){
					problem("Incorrect logical bar length: '$len' ($meter_nb/) for '$ob'") ;
					warn Dumper(\@cs) ;
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
	print $fh "$indent\{ " ;
	my @attrs = keys %{$tag} ;
	if (scalar(@attrs)){
		print $fh join(", ", map { "\"$_\": \"$tag->{$_}\"" } sort @attrs) ;
	}
	if ((ref($children))&&(scalar(@{$children}))){
		if (scalar(@attrs)){
			print $fh ", " ;
		}
		print $fh "\"", $children->[0]->{e}, "s\": [\n" ;
		foreach my $c (@{$children}){
			# warn Dumper($c) ;
			xml_dumper($fh, $c, $level + 1) ;
		}
		print $fh "$indent] },\n" ;
	}
	else {
		print $fh " \},\n" ;
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
