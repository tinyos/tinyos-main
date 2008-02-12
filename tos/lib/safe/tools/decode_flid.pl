#!/usr/bin/perl -w

use strict;

sub decode ($$) {
    my $a = shift;
    my $b = shift;
    die if ($a<0 || $a>3);
    die if ($b<0 || $b>3);
    my $c = ($a << 2) + $b;
    my $h = sprintf "%X", $c;
    return $h;
}

sub make_flid () {

    my $flid = $ARGV[0];
    die "expected 8 characters" if (length($flid) != 8);
    
    my $flidstr =
	"0x" .
	decode(substr($flid,0,1),substr($flid,1,1)) .
	decode(substr($flid,2,1),substr($flid,3,1)) .
	decode(substr($flid,4,1),substr($flid,5,1)) .
	decode(substr($flid,6,1),substr($flid,7,1));
}

my $flidstr = make_flid();

my $fn = $ARGV[1];
my $found = 0;

if (defined ($fn)) {
    open INF, "<$fn" or die;
    while (my $line = <INF>) {
	chomp $line;

	my @fields = split /\#\#\#/, $line;
	foreach (@fields) {
	    (s/^\s*//g);
	    (s/\s*$//g);
	    (s/^\"//g);
	    (s/\"$//g);
	}
	if (hex($fields[0]) == hex($flidstr)) {
	    $found = 1;
	    my $text = $fields[2];
	    my $check = $fields[3];
	    my $file = $fields[5];
	    my $line = $fields[6];
	    my $func = $fields[7];

	    print "\n$line\n\n";

	    print "Deputy error message for flid $flidstr:\n\n";

	    printf "%s:%d: %s: Assertion failed in %s:\n  %s\n", 
	    $file, $line, $func, $check, $text;
	    
	    print "\n";
	}
    }
    close INF;
}

if (!$found) {
    print "oops -- flid $flidstr not found in file\n";
}
