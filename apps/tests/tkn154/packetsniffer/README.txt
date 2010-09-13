README for Sniffer
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:

This application uses a single node to passively monitor all traffic on a given
wireless channel and forward the content of any received IEEE 802.15.4 frame
over the serial line. The information that is forwarded per received frame is
the following:

1. the length of the MAC header + MAC payload portion 
2. the entire MAC header
3. the entire MAC payload
4. some frame-specific metadata (RSSI, LQI, timestamp, etc.)

On the PC-side (a) with a few changes
"$TOSROOT/apps/BaseStation15.4/seriallisten15-4.c" can be adapted to display
textual information on the frame content (if this is sufficient for you, also
take a look at ../nonbeacon-enabled/TestPromiscuous app); (b) there exists a
tool that visualizes the frame fields in a JAVA GUI, it's available here:
http://www.z-monitor.org (c) another option might be to update wireshark to
display frames received by this application (but I have not started to look
into this).

The exact format of the data exchanged over the serial line is best explained
on an example: assuming a MAC DATA frame of MPDU size 15 byte (= PHY length
field) with a 9 byte MAC header (including destination PAN, destination address
and source address) and a 4 byte MAC payload the data sent by the mote to the
PC over serial would be as follows:

0x02 0x0d 0x41 0x88 0x44 0x22 0x00 0xff 0xff 0x01 0x00 0x3f 0x06 0x01 0x45 0x6a 0xee 0x01 0x09 0x1a 0x56 0x20 0xcc 0x00

The first byte is always "0x02". This is a dispatch ID which tells that the
serial packet is not an active message (AM), but an 802.15.4 frame. In
particular, this means that a SerialForwarder will not accept the packet
(because it would expect a "0x00" there, see Serial.h). The next byte ("0x0d" =
13) is the size of the MAC header + payload portion. Note that the MAC footer
(CRC) is *not* taken into consideration, i.e. the second byte is identical to
the PHY length field minus 2. What follows is the MAC header ("0x41 0x88 0x44
0x22 0x00 0xff 0xff 0x01 0x00") and MAC payload ("0x3f 0x06 0x01 0x45"). The
remaining 9 byte are the matadata contained in the nx_struct "sniffer_metadata"
defined in the "./app_profile.h" file. Note that, like the 802.15.4 formatting
convention, the metadata is little-endian encoded.

Criteria for a successful test:

LED2 should always be on; LED1 should toggle every time a packet is received
(and forwarded over serial line); LED0 denotes an error and should never be on.

Known bugs/limitations:

- The timestamps for ACKs are incorrect

$Id: README.txt,v 1.1 2009/10/29 17:42:56 janhauer Exp $

