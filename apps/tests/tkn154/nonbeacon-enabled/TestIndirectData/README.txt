README for TestIndirectData
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:

In this application one node takes the role of a PAN coordinator in a
nonbeacon-enabled 802.15.4 PAN; it switches its radio to receive mode and
creates a packet which is addressed to the predefined address of the device.
This packet is marked as indirect transmissions, therefore queued and sent only
after explicit poll of the device.  After a successful transmission another
packet is created after a definite time.

A second node acts as the device; it switches to the pre-defined channel and
polls the coordinator in predefined intervals for outstanding indirect
transmissions.

A few basic parameters of this example can be adjusted through the
'app_profile.h' file.

Leds: On the coordinator the second LED (Telos: green) flashes whenever a
packet for an indirect transmission is created and queued.  When this packet
has not been polled by the device within the transaction time, the packet is
discarded which is displayed by the first led (Telos: red). On the device the
third LED (Telos: blue) flashes when after a poll of the coordinator an
indirect transmission arrives.


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

$Id: README.txt,v 1.1 2009-06-10 09:23:45 janhauer Exp $o

