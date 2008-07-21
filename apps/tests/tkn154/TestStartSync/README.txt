README for TestStartSync
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:

In this application one node takes the role of a PAN coordinator in a
beacon-enabled 802.15.4 PAN; it transmits periodic beacons with a frequency
defined in the app_profile.h file. A second node acts as a device; it first
scans all available channels for beacons from the coordinator and once it finds
a beacon it tries to synchronize to and track all future beacons. 

The third LED (Telos: blue) is toggled whenever the coordinator has transmitted
a beacon or whenever a device has received a beacon. On the coordinator the
second LED (Telos: green) is switched on after it has started transmitting
beacons. On a device the second LED is switched on whenever the device is
synchronized to the coordinator's beacons. The first LED (Telos: red) is used
for debugging, it denotes an error in the protocol stack and should never be
on.

Tools: NONE

Usage: 

1. Install the coordinator:

    $ cd coordinator; make telosb install

2. Install one (or more) devices:

    $ cd device; make telosb install

You can change some of the configuration parameters in app_profile.h

Known bugs/limitations:

- Currently this application only works on TelosB nodes
- The beacon period is not standard-compliant, because TelosB lacks a
  clock with sufficient precision/accuracy

$Id: README.txt,v 1.1 2008-07-21 15:18:16 janhauer Exp $

