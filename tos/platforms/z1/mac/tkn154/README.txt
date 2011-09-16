This directory contains the TKN15.4 "platform glue" code for the z1
platform. Like the telos platform, z1 uses the CC2420 radio and in order not
to maintain identical configuration files, the z1 platform pulls in (uses) some
files from the platform/telosb/mac/tkn154 directory. 

The ./Makefile.include file defines in which order the directories are parsed and
should be included by any z1 application. 

More information on TKN15.4 can be found here:
tinyos-2.x/tos/lib/mac/tkn154/README.txt
 
