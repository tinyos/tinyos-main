README for TestSerial
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:

TestSerial is a simple application that may be used to test that the
TinyOS java toolchain can communicate with a mote over the serial
port. The java application sends packets to the serial port at 1Hz:
the packet contains an incrementing counter. When the mote application
receives a counter packet, it displays the bottom three bits on its
LEDs. (This application is similar to RadioCountToLeds, except that it
operates over the serial port.) Likewise, the mote also sends packets
to the serial port at 1Hz. Upon reception of a packet, the java
application prints the counter's value to standard out.

Java Application Usage:
  java TestSerial [-comm <packetsource>]

  If not specified, the <packetsource> defaults to sf@localhost:9002 or
  to your MOTECOM environment variable (if defined).

Tools:

Known bugs/limitations:

None.

