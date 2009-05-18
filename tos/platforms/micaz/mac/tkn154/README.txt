This directory contains the TKN15.4 "platform glue" code for the micaz
platform. Like the telos platform, micaz uses the CC2420 radio and in order not
to maintain identical configuration files, the micaz platform pulls in (uses) some
files from the platform/telosb/mac/tkn154 directory. This includes the central
MAC configurations "Ieee802154BeaconEnabledC" and "Ieee802154NonBeaconEnabledC",
to which the next higher layer will wire to.
The ./Makefile.include file defines in which order the directories are parsed and
should be included by any micaz application. 

More information on TKN15.4 can be found here:
tinyos-2.x/tos/lib/mac/tkn154/README.txt
 
