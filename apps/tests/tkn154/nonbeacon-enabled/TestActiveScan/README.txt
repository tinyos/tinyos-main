README for TestActiveScan
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:

In this application one node takes the role of a PAN coordinator in a
nonbeacon-enabled 802.15.4 PAN, it switches its radio to receive mode.  A
second node acts as a device, it switches to the pre-defined channel and
periodically performs active-scans (i.e. sends out beacon request frames) on
the predefined channel and expects beacon frames in return. 

Criteria for a successful test:

On the coordinator node (only) the second LED should toggle once every 2 
seconds. On the device the second and third LED should toggle once every 2 
seconds, but with a small offset of half a second. On the device the first
LED may toggle, but this should happen very rarely.


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

$Id: README.txt,v 1.2 2009-10-29 17:42:55 janhauer Exp $o

