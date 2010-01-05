README for TestStartSync
Author/Contact: Jan Hauer <hauer@tkn.tu-berlin.de>

Description:

In this application one node takes the role of a PAN coordinator in a
beacon-enabled 802.15.4 PAN, it transmits periodic beacons with a frequency
defined in the app_profile.h file. A second node acts as a device, it first
scans all available channels for beacons from the coordinator and once it finds
a beacon it tries to synchronize to and track all future beacons. 

Criteria for a successful test:

After a few seconds all nodes should have the LED1 turned on and LED2
toggling in unison every second.


Tools: NONE

Usage: 

1. Install the coordinator:

    $ cd coordinator; make <platform> install

2. Install one (or more) devices:

    $ cd device; make <platform> install

You can change some of the configuration parameters in app_profile.h

Known bugs/limitations:

- Many TinyOS 2 platforms do not have a clock that satisfies the
  precision/accuracy requirements of the IEEE 802.15.4 standard (e.g. 
  62.500 Hz, +-40 ppm in the 2.4 GHz band); in this case the MAC timing 
  is not standard compliant

$Id: README.txt,v 1.3 2010-01-05 17:12:56 janhauer Exp $

