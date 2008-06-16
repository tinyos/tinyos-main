README for TestPROMISCUOUS
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

    $ make telosb install

Start the printf client on 

    $ cd $TOSDIR/../apps/tests/TestPrintf
    $ make telosb
    $ java PrintfClient -comm serial@/dev/ttyUSBXXX:telosb

(http://docs.tinyos.net/ has a section on how to use the TinyOS printf library)

Known bugs/limitations:

- Currently this application only works on TelosB nodes
- The timestamps for ACKs are incorrect

$Id: README.txt,v 1.1 2008-06-16 18:22:46 janhauer Exp $

