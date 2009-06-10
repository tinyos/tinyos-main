README for TestActiveScan
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:

In this application one node takes the role of a PAN coordinator in a
nonbeacon-enabled 802.15.4 PAN; it switches its radio to receive mode.

A second node acts as a device; it switches to the pre-defined channel and
performs active-scans on the predefined channel. 

A few basic parameters of this example can be adjusted through the
'app_profile.h' file.

Leds Coordinator: The first led (Telos: red) is used for debugging purposes
only and when switched on indicating an error in the protocol-stack.  The
second led (Telos: green) flashes when an active scan, more exactly a
beacon-request, is received by the coordinator.

Leds Device: The third led (Telos: blue) is activated for a second whenever an
active-scan is performed.  Shortly after that the second or the first led
flashes.  The second led (Telos: green), indicating that the coordinator
defined in the 'app_profile.h' where found in that scan.  The first led if
either no devices or only no matching devices where found within the scan.

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

$Id: README.txt,v 1.1 2009-06-10 09:38:41 janhauer Exp $o

