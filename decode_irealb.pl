#!/usr/bin/perl

use strict ;
use URI::Escape ;


my $url = <STDIN> ;
chomp($url) ;
$url = uri_unescape($url) ;
$url =~ s|irealb://|| ;

my @songs = split(/===/, $url) ;
foreach my $s (@songs){
	my ($title, $composer, $unk1, $style, $key, $unk2, $changes, $rest) = split(/=/, $s) ;

	my $s = decode($changes) ;

	my $fname = $title ;
	$fname =~ s/\W/_/g ;
	open(IREALB, ">decoded/$fname.irealb") or die("Can't open file out/pass/$fname.xml: $!") ;
	print IREALB "$title;$composer;$style;$key;$s\n" ;
	close(IREALB) ;
}


sub decode {
    my $s = shift ;

    return $s if (($s !~ /^1r34LbKcu7/)||(length($s) < 11)) ;
    $s = substr($s, 10) ;

    for (my $i = 0 ; ; $i += 50){
        if ($i + 51 >= length($s)){
            last ;
        }

        $s = flip($s, $i + 10, 29) ;
        $s = flip($s, $i + 5, 39) ;
        $s = flip($s, $i, 49) ;
    }

    $s =~ s/XyQ/   /g ;
    $s =~ s/Kcl/| x/g ;
    $s =~ s/LZ/ |/g ;
    
    return $s ;
}


sub flip {
    my $s = shift ;
    my $a = shift ;
    my $b = shift ;

    my $i = int($b / 2) ;
    for (my $j = 0 ; ; $j++){
        return $s if ($j >= $i) ;

        my $t = substr($s, $a + $j, 1) ;
        substr($s, $a + $j, 1) = substr($s, $a + $b - $j, 1) ;
        substr($s, $a + $b - $j, 1) = $t ;
    }
}



__DATA__
irealb://Blues%20-%20Simple%3DExercise%3D%3DShuffle%3DA%3D%3D1r34LbKcu7X7EZL7XyQKyX7AZL%20lcKQyX7ZDL%20x%20ZL%20x%20ZL%20lcQKcl%20A44T%5ByQ%7CD7XyQ%7CA7XyQKcl%20%20Z%20%3D%3D0%3D0/

  public static String g(String paramString)
  {
    if ((!paramString.startsWith("1r34LbKcu7")) || (paramString.length() < 11))
      return paramString;
    String[] arrayOfString1 = i(paramString.substring(10));
    int j;
    for (int i = 0; ; i += 50)
    {
      if (i + 51 >= arrayOfString1.length)
      {
        j = 0;
        if (j < -4 + arrayOfString1.length)
          break ;
        paramString = concat(arrayOfString1);
        break;
      }
      a(arrayOfString1, i + 10, 29);
      a(arrayOfString1, i + 5, 39);
      a(arrayOfString1, i, 49);
    }
    label93: {
    String[] arrayOfString2 = new String[3];
    arrayOfString2[0] = arrayOfString1[j];
    arrayOfString2[1] = arrayOfString1[(j + 1)];
    arrayOfString2[2] = arrayOfString1[(j + 2)];
    if (a(new String[] { "X", "y", "Q" }, arrayOfString2))
    {
      a(new String[] { " ", " ", " " }, j, arrayOfString1);
      j += 2;
    }
    while (true)
    {
      j++;
      break;
      if (a(new String[] { "K", "c", "l" }, arrayOfString2))
      {
        a(new String[] { "|", " ", "x" }, j, arrayOfString1);
        j += 2;
      }
      else if (a(new String[] { "L", "Z" }, arrayOfString2))
      {
        a(new String[] { " ", "|" }, j, arrayOfString1);
        j++;
      }
    }
    }
  }


Use space:
p: Continue previous chords for for the current beat ()
n: No Chord
x: repeat last bar
r: repeat last 2 bars
W: white

Don't use space:
s,l: Text Size specifiers
U: END
N\d: Alternate ending
(): Alternate chord
Y: Newline
f: Fermata
Q: Coda
S: Dal Segno
