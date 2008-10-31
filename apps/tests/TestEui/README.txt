$Id: README.txt,v 1.1 2008-10-31 17:01:31 sallai Exp $

README for TestEui
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:

The TestEui application prints out the IEEE EUI64 of the device periodically
using printf. Currently supported platforms: iris.

Tools:

net.tinyos.tools.PrintfClient is a Java application that displays the output on
the PC.

Usage:

java net.tinyos.tools.PrintfClient -comm serial@<serial port>:<mote>

Known bugs/limitations:

None.
 