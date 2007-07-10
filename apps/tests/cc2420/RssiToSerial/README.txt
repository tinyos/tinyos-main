
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


Java Application Usage:
  Linux: java SpecAnalyzer.class [-comm <packetsource>]
  Windows: java SpecAnalyzer [-comm <packetsource>]

  If not specified, the <packetsource> defaults to sf@localhost:9001 or
  to your MOTECOM environment variable (if defined).
