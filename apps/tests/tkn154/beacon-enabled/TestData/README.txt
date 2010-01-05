README for TestData
Author/Contact: Jan Hauer <hauer@tkn.tu-berlin.de>

Description:

In this application one node takes the role of a PAN coordinator in a
beacon-enabled 802.15.4 PAN, it transmits periodic beacons and waits for
incoming DATA frames. A second node acts as a device, it first scans the
pre-defined channel for beacons from the coordinator and once it finds a beacon
it tries to synchronize to and track all future beacons. It then starts to
transmit DATA frames to the coordinator as fast as possible (direct
transmission in the contention access period, CAP).

Criteria for a successful test:

Coordinator and device should both toggle LED2 about twice per second in
unison. They should also each toggle LED1 about 5 times per second (but
not necessarily in unison). Note: the nodes should be close to each other, 
because the transmission power is reduced to -20 dBm.


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

$Id: README.txt,v 1.3 2010-01-05 17:12:56 janhauer Exp $o

