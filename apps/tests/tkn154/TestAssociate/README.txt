README for TestAssociate
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:

In this application one node takes the role of a PAN coordinator in a
beacon-enabled 802.15.4 PAN; it transmits periodic beacons and waits for
devices to request association to its PAN. Whenever a device tries to
associate, the PAN coordinator allows association and assigns to the device a
unique short address (starting from zero, incremented for every device
requesting association). 

A second node acts as a device; it first scans the pre-defined channel for
beacons from the coordinator and once it finds a beacon it tries to associate
to the PAN and synchronize to and track all future beacons. A short time after
association the device then disassociates from the PAN. 

The third LED (Telos: blue) is toggled whenever the coordinator has transmitted
a beacon or whenever a device has received a beacon. On the coordinator the
second LED (Telos: green) is switched on whenever an association request was
successful and it is switched off, whenever a disassociation request was
received. On a device the second LED is switched on while the device is
associated to the PAN, i.e. it is switched off after disassociation. The first
LED (Telos: red) is used for debugging, it denotes an error in the protocol
stack and should never be on.

Tools: NONE

Usage: 

1. Install the coordinator:

    $ cd coordinator; make telosb install

2. Install one (or more) devices:

    $ cd device; make telosb install

You can change some of the configuration parameters in app_profile.h

Known bugs/limitations:

- Currently this application only works on TelosB nodes
- The MAC timing is not standard compliant, because TelosB lacks a
  clock with sufficient precision/accuracy

$Id: README.txt,v 1.1 2008-07-21 14:56:58 janhauer Exp $o

