README for TestAssociate
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:

In this application one node takes the role of a PAN coordinator in a
nonbeacon-enabled 802.15.4 PAN; it switches its radio to receive mode and waits
for devices to request association to its PAN. Whenever a device tries to
associate, the PAN coordinator allows association and assigns to the device a
unique short address (starting from zero, incremented for every device
requesting association). 

A second node acts as a device; it switches to the pre-defined channel and
tries to associate to the PAN. A short time after association the device then
disassociates from the PAN. 

On the coordinator the second LED (Telos: green) is switched on whenever an
association request was successful and it is switched off, whenever a
disassociation request was received. On a device the second LED is switched on
while the device is associated to the PAN, and it is switched off after
disassociation. The first LED (Telos: red) is used for debugging, it denotes an
error in the protocol stack and should never be on.

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

$Id: README.txt,v 1.1 2009-05-18 17:13:02 janhauer Exp $o

