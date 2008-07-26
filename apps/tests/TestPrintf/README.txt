README for TestPrintf
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:
This application is used to test the basic functionality of the printf service.
Calls to the standard c-style printf command are made to print various strings
of text over the serial line.  Only upon calling printfflush() does the
data actually get sent out over the serial line.

Tools:

net.tinyos.tools.PrintfClient is a Java application that displays the output on
the PC.

Usage:

java net.tinyos.tools.PrintfClient -comm serial@<serial port>:<mote>

Known bugs/limitations:

None.
 
$Id: README.txt,v 1.2 2008-07-26 02:32:43 klueska Exp $
