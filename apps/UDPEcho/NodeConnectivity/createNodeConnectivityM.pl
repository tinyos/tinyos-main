#!/usr/bin/perl

# FileName:    createMotelabTopology.pl 
# Date:        December 31, 2004
#
# Description: Converts a TOSSIM .nss (topology) file into Motelab format
# Usage:  ./createMotelabTopology.pl  .nssfile     

# Input:  A TOSSIM .nss topology file
# Output: A nesc file containing a 2D array that represents 
#         the latency for each node and a func that returns true or false
#         as to whether that node can communicate with other nodes


use strict;

######################
#                    #
#  Parse Parameters  #
#                    #
######################

if ( 2 > @ARGV ) {
    die "Usage: ./createMotelabTopology <mapfile(see exampleMap.txt as a sample)>  <.nss file> ";
}

#######################
#                     #
#  Open file handles  #
#                     #
#######################

open(INPUT_MAP,  "$ARGV[0]")
    or die "Unable to open input file $ARGV[0] ($!)";

open(INPUT_NSS,  "$ARGV[1]")
    or die "Unable to open input file $ARGV[1] ($!)";

#########################
#                       #
#  Parse and store file #
#  outputs              #
#                       #
#########################

my @mappingArray;
while (my @input = split(/\s+/, <INPUT_MAP>)) {
  $mappingArray[$input[0]] = $input[1];
}

my %probHash;
my $maxI = 0;
my $maxJ = 0;

while (my @input = split(/:/, <INPUT_NSS>)) {

  # 09 Jan 2005 : GWA : Yikes, not sure about ordering here.  Also what the
  #               .nss file includes is the bit error probability,
  #               essentially the inverse of what we want.

  $probHash{"$input[0]x$input[1]"} = (1 - $input[2]);
  
  if ($input[0] > $maxI) {
    $maxI = $input[0];
  }
  if ($input[1] > $maxJ) {
    $maxJ = $input[1];
  }
}

#############################
#                           #
#  Write out the nesC code  #
#                           #
#############################

my $dateString = `date`;
print <<TOP;
// Filename: NodeConnectivityM.nc
// Generated on $dateString
// Created by createMotelabTopology.pl

module NodeConnectivityM {
  provides {
    interface NodeConnectivity;
  }
} implementation {
TOP

my $arrayWidth = $maxI + 1;
my $arrayHeight = $maxJ + 1;
my $connectivityString = <<START;
  uint8_t connectivity[$arrayWidth][$arrayHeight] =
  {
START
$connectivityString .= "    ";
for (my $i = 0; $i <= $maxI; $i++) {
  $connectivityString .= "{ ";
  for (my $j = 0; $j <= $maxJ; $j++) {
    if ($i == $j) {
      $connectivityString .= "1";
    } elsif (!defined($probHash{"$i" . "x" . "$j"})) {
      $connectivityString .= "0";
    } else {
      $connectivityString .= $probHash{"$i" . "x" . "$j"};
    }
    if ($j != $maxJ) {
      $connectivityString .= ", ";
    }
  }
  $connectivityString .= " }";
  if ($i != $maxI) {
    $connectivityString .= ",";
  }
  $connectivityString .= "\n";
  if ($i != $maxI) {
    $connectivityString .= "    ";
  }
}
$connectivityString .= <<END;
  };
END
print "$connectivityString";

my $mappingString = "{ ";
my $mappingSize = @mappingArray;
for (my $i = 0; $i < @mappingArray; $i++) {
  $mappingString .= $mappingArray[$i];
  if ($i != (@mappingArray - 1)) {
    $mappingString .= ", ";
  }
}
$mappingString .= " };";

print <<MAPPING;
  uint16_t mapping[$mappingSize] = $mappingString
MAPPING

print <<REALEND;
  
  command int8_t NodeConnectivity.mapping(uint16_t moteid) {
    uint8_t i;
    for (i = 0; i < $mappingSize; i++) {
      if (mapping[i] == moteid) {
        return i;
      }
    }
    return -1;
  }

  command bool NodeConnectivity.connected(uint16_t srcnode, uint16_t dstnode) {
    int8_t src = call NodeConnectivity.mapping(srcnode);
    int8_t dst = call NodeConnectivity.mapping(dstnode);

    if ((src == -1) ||
        (dst == -1)) {
      return FALSE;
    }

    if (connectivity[src][dst] == 1) {
      return TRUE;
    } else {
      return FALSE;
    }
  }
}
REALEND
