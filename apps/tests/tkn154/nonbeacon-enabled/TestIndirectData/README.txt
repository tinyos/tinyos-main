README for TestIndirectData
Author/Contact: Jan Hauer <hauer@tkn.tu-berlin.de>

Description:

In this application one node takes the role of a PAN coordinator in a
nonbeacon-enabled 802.15.4 PAN, every 3 seconds it sends a packet to a device
using indirect transmission (i.e. the packet is buffered until it is polled by
the device). A second node acts as the device, it switches to the pre-defined
channel and polls the coordinator every 1 second for outstanding indirect
transmissions.

Criteria for a successful test:

Assuming one coordinator and one device has been installed, the coordinator
should briefly flash LED1 every 3 seconds. The device should briefly flash 
LED2 every 1 second. 


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

