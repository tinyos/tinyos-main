README for TestActiveScan
Author/Contact: Jan Hauer <hauer@tkn.tu-berlin.de>

Description:

In this application one node takes the role of a PAN coordinator in a
nonbeacon-enabled 802.15.4 PAN, it switches its radio to receive mode.  A
second node acts as a device, it switches to the pre-defined channel and
periodically performs active-scans (i.e. sends out beacon request frames) on
the predefined channel and expects beacon frames in return. 

Criteria for a successful test:

The coordinator should toggle LED1 once every 2 seconds. The device should
toggle LED1 and LED2 every 2 seconds (not necessarily simultaneously).


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

$Id: README.txt,v 1.3 2010-01-05 17:12:56 janhauer Exp $o

