#!/usr/bin/perl

use strict ;
use Data::Dumper ;
use MIME::Base64 ;
use JSON ;


my $rc = 0 ;
my $meter_nb = 4 ;
my @buf = () ;

my $tune = () ;
my @sections = () ;
my $cur_repeat = undef ;

while (<>){
	my $line = $_ ;
	chomp($line) ;
	my $oline = $line ;

	next if !length($line) ;
	next if $line =~ /^#/ ;
	next if $line =~ /^END/ ;

	push @buf, $line ;

	if ($line =~ /^IREALB;(.*?);(.*?);(.*?);(.*?)$/){
		$tune->{title} = $1 ;
		$tune->{composer} = $2 ;
		$tune->{style} = $3 ;
		$tune->{key} = $4 ;
	}
	else {
		# Each line represents a section.
		my $section = {} ;
		my @bars = () ;

		if ($line =~ s/^\{//){
			$section->{repeat} = 1 ;
			push @bars, parse_bars($section, $line) ;
			$cur_repeat = $section ;
			push @sections, $section ;
		}
		elsif ($line =~ s/^\t(\d)\.//){
			# Alternate endings.
			my $no = $1 ;
			$section->{no} = $no ;
			push @bars, parse_bars($section, $line) ;
			push @{$cur_repeat->{endings}}, $section ;
		}
		else {
			push @bars, parse_bars($section, $line) ;
			push @sections, $section ;
		}

		$section->{bars} = \@bars if (scalar(@bars)) ;
	}
}

$tune->{sections} = \@sections if (scalar(@sections)) ;

$tune->{metadata} = \@buf ;


my $json = new JSON() ;
print $json->pretty()->encode($tune) ;

exit($rc) ;


#################################################


sub parse_bars {
	my $section = shift ;
	my $t = shift ;

	my $i = 0 ;
	my @bars = map { parse_bar($section, $_, $i++) } split(/\|/, $t) ;

	return @bars ;
}


sub parse_bar {
	my $section = shift ;
	my $b = shift ;
	my $n = shift ;

	my $ob = $b ;

	my @cs = () ;

	# Remove empty bars
	# return () if $b =~ /^\s*$/ ;

	my $coda = ($b =~ s/(.)@/$1/) ;

	my $bar = {} ;
	my @comments = () ;

	my $len = 0 ;
	my $err = 0 ;
	my $last_chord = undef ;
	while (length($b)){
		if ($b =~ s/^([a-zA-Z])://){
			if (($n == 0)&&(! $section->{label})){
				$section->{label} = $1 ;
			}
			else {
				# TODO: Prepend to section description?
			}
		}
		elsif ($b =~ s/^T(\d)(\d)//){
			$bar->{meter} = "$1/$2" ;
			$meter_nb = $1 ;
		}
		elsif ($b =~ s/^@//){
			if (($n == 0)&&($len == 0)){
				$section->{label} = '@' ;
			}
			else {
				$bar->{coda} = 1 ;
			}
		}
		elsif ($b =~ s/^\$//){
			$bar->{segno} = 1 ;
		}
		elsif ($b =~ s/\<(.*?)\>//){
			# TODO: if first bar of section, use comment as section description.
			push @comments, $1 ;
		}
		elsif ($b =~ s/^,//){
		}

		elsif ($b =~ s/^(\/)//){
			$len++ ; 
			$last_chord = { name => '/', units => 1 } ;
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
			$last_chord = { name => 'NC', units => 1 } ;
			push @cs, $last_chord ;
		}
		elsif ($b =~ s/^([_A-G][\/\#\^\-\+\w]*)//){
			my $chord = $1 ;
			$len++ ; 
			$last_chord = { name => $chord, units => 1 } ;
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
		if ($c){
			$c = decode_base64($c) ;
			$c =~ s/"/\\"/g ;
			push @{$bar->{comments}}, $c ;
		}
	}

	$bar->{coda} = 1 if ($coda) ;

	$bar->{chords} = \@cs if (scalar(@cs)) ;
	
	return $bar ;
}


sub problem {
	my $msg = shift ;

	warn "$msg\n" ;
	$rc = 1 ;
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
