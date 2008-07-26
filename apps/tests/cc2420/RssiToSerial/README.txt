README for RssiToSerial
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:

This is more of a general demonstration than a test.

Install this application to one node, connected to the computer.
The node will measure the environmental RSSI from the CC2420
and sending those readings over the serial port.

Use the Java application to display the relative RSSI readings.

No activity:
[+++++++++++++++                                   ]


Transmitter nearby:
[+++++++++++++++++++++++++++++++++++               ]


Since the Java side has to convert the readings into a CLI bar
graph, it's scaled by some (possibly non-linear) factor.  


Tools:
  java SpecAnalyzer [-comm <packetsource>]

  If not specified, the <packetsource> defaults to sf@localhost:9002 or
  to your MOTECOM environment variable (if defined).

Known bugs/limitations:

None.

$Id: README.txt,v 1.3 2008-07-26 02:32:44 klueska Exp $
