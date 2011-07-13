README for TestGts
Author/Contact: Ricardo Severino <rars@isep.ipp.pt>
                Stefano Tennina <sota@isep.ipp.pt>

Description:

In this application one node takes the role of a PAN coordinator in a
beacon-enabled 802.15.4 PAN, it transmits periodic beacons and waits for an
incoming GTS request. A second node acts as a device, it first scans the
pre-defined channel for beacons from the coordinator and once it finds a beacon
it tries to synchronize to and track all future beacons. It then requests a
(transmit) GTS slot from the coordinator via the MLME-GTS.request() primitive.
As soon as the slot is granted and signalled in the beacon frame, the device
starts to send its data within that slot. A second GTS slot is then requested
for reception. If the request is successfull, the PAN Coordinator will begin to
transmit to the device in that slot.  In the meanwhile, the first GTS is
deallocated by the device which stops transmitting.  This causes a reallocation
of the GTS slots. Later, the PAN Coordinator stops transmitting, but the
second GTS remains in beacon, although unused. When it finally expires, the PAN
Coordinator removes it.

To use the GTS services in your own application make sure you define the
IEEE154_GTS_DEVICE_ENABLED (device) or IEEE154_GTS_COORD_ENABLE (PAN coordinator) 
preprocessor macro, for example, by adding the line 
"CFLAGS += -DIEEE154_GTS_DEVICE_ENABLED" in your application's Makefile.


Criteria for a successful test:

Coordinator and device should both toggle LED2 once per two per second in
unison. After a few seconds the device will turn LED1 for about a second (and
then turn it off). Afterwards the coordinator will turn its LED1 on (it will
remain on). This assumes a setup of: 1 device + 1 coordinator.

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

- The coordinator will transmit data only to a single device, even
  if more devices are in use

- Many TinyOS 2 platforms do not have a clock that satisfies the
  precision/accuracy requirements of the IEEE 802.15.4 standard (e.g. 
  62.500 Hz, +-40 ppm in the 2.4 GHz band); in this case the MAC timing 
  is not standard compliant



