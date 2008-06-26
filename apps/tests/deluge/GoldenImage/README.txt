README for apps/tests/deluge/GoldenImage
Author/Contact:

Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
Razvan Musaloiu-E. <razvanm@cs.jhu.edu>

Description:

This is a sample application for Deluge T2. The application is similar 
to Null, but it includes Deluge T2.

To program a basestation (a mote which can accept images over the
serial port) you have to add CFLAGS=-DDELUGE_BASESTATION to the make
command. For telosb this might look like this:
	 CFLAGS=-DDELUGE_BASESTATION make telosb install bsl,/dev/ttyUSB0

Prerequisites:

Python 2.4 with pySerial

References:

The Deluge T2 manual is available under $TOS_DIR/doc/html/.
