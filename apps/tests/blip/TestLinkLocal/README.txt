README for TestLinkLocal
Author/Contact: Stephen Dawson-Haggerty <tinyos-help@millennium.berkeley.edu>

Description:

TestLinkLocal tests the basic Link-Local communication functionality of blip.
It verifies that the radio is working, and address resolution is correct, and
that 64-bit addressing mode works correctly.

Build with:
$ make epic blip

Install on at least two motes -- the node ID's don't matter since they will
use only 64-bit address mode.

1. Once per second, each mote transmits a packet (an echo request) to the
   link-local multicast all-nodes group (ff02::1).  Led0 is toggled each time
   this happens.  The source address is the node's link-local unicast address
   derived from an EUI-64.

2. All nodes receiving an echo request toggle Led1.  They also reply to the
   echo request with a unicast packet to the originator.

3. Nodes receiving a unicast reply to one of their echo requests toggle Led2.

Therefore, if everything is working, you should see Led0 and Led2 blinking
together, and Led1 blinking in sequence with the other mote's transmission.

This application can help troubleshoot problems with the header compression
layer; to disable header compression, edit the Makefile to uncommment
"-DLIB6LOWPAN_HC_VERSION=-1".

Additional debugging output is availiable via printf; on Linux, you can
examine it with
$ stty -F /dev/ttyUSB0 57600 && tail -f /dev/ttyUSB0

Tools:

Known bugs/limitations:


