README for TestData
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:

In this application one node takes the role of a PAN coordinator in a
beacon-enabled 802.15.4 PAN; it transmits periodic beacons and waits for
incoming DATA frames. A second node acts as a device; it first scans the
pre-defined channel for beacons from the coordinator and once it finds a beacon
it tries to synchronize to and track all future beacons. It then starts to
transmit DATA frames to the coordinator as fast as possible (direct
transmission in the contention access period, CAP).

The third LED (Telos: blue) is toggled whenever the coordinator has transmitted
a beacon or whenever a device has received a beacon. On the coordinator the
second LED (Telos: green) is toggled for every 20 received DATA frames. On a
device the second LED is toggled for every 20 transmitted (and acknowledged)
DATA frames. The first LED (Telos: red) is used for debugging, it denotes an
error in the protocol stack and should never be on.

Tools: NONE

Usage: 

1. Install the coordinator:

    $ cd coordinator; make <platform> install

2. Install one or more devices

    $ cd device; make <platform> install,X

    where X is a pre-assigned short address and should be different 
    for every device.

You can change some of the configuration parameters in app_profile.h

Known bugs/limitations:

- Many TinyOS 2 platforms do not have a clock that satisfies the
  precision/accuracy requirements of the IEEE 802.15.4 standard (e.g. 
  62.500 Hz, +-40 ppm in the 2.4 GHz band); in this case the MAC timing 
  is not standard compliant

$Id: README.txt,v 1.1 2009-05-18 16:21:55 janhauer Exp $o

