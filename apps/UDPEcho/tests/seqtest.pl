#!/usr/bin/perl

# make sure we don't break on any length boundaries

use strict;
use warnings;
use FileHandle;
use IPC::Open2;

if (@ARGV != 1) {
    print "Usage: seqtest.pl <target ipv6>\n";
    exit(1);
}

my $alpha = "abcdefghijklmnopqrstuvwxyz1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZ";
my $testbuf = "";
while (length($testbuf) < 1280 - 40 - 8) {
    $testbuf .= $alpha;
}

open2(*READER, *WRITER, "nc6 -u $ARGV[0] 7");

my $trials = 0;
while (1) {
    my $len;
    for ($len = 1; $len < 1000; $len++) {
        print $len . "\n";
        print WRITER substr($testbuf, 0, $len) . "\n";
        
        my $rin = '';
        vec($rin,fileno(READER),1) = 1;
        my $found = select($rin, undef, undef, "6");
        if ($found == 1) {
            my $foo;
            sysread READER, $foo, 1280;
            if ($foo eq $testbuf) {
                print "WARNING: payload mismatch\n";
            }
        } else {
            print "FAILURE: len: $len\n";
        }
        
        $trials++;
        print "TRIAL: $trials\n";
        sleep(.05);
    }
}
# need to kill off the nc6 process
print WRITER eof;

