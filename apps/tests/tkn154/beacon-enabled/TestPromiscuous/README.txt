README for TestPromiscuous
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:

In this application the node enables promiscuous mode, i.e. its radio is
switched to receive mode and all incoming frames that pass the CRC check are
signalled to the upper layer. The application uses the TinyOS printf library
(tos/lib/printf) to output information on the MAC header fields and payload for
every received frame over the serial port. The second (TelosB: green) LED is
toggled whenever a frame is received.

Tools: The printf java client in $TOSDIR/../apps/tests/TestPrintf

Usage: 

Install the application on a node

    $ make <platform> install

Start the printf client, e.g. 

    $ java net.tinyos.tools.PrintfClient -comm serial@/dev/ttyUSBXXX:<platform>

(http://docs.tinyos.net/ has a section on how to use the TinyOS printf library)

Known bugs/limitations:

- The timestamps for ACKs are incorrect

$Id: README.txt,v 1.1 2009-05-18 16:21:55 janhauer Exp $

