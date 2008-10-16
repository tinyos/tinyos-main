README for apps/tests/deluge/Basestation
Author/Contact:

Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
Razvan Musaloiu-E. <razvanm@cs.jhu.edu>

Description:

This is a sample application for Deluge T2. The application is similar
with GoldenImage, but it includes the basestation behavior by using
the CFLAGS=-DDELUGE_BASESTATION flag.

For telosb the command to install the program is like this:
         make telosb install bsl,/dev/ttyUSB0

Prerequisites:

Python 2.4 with pySerial

References:

The Deluge T2 wiki page from http://docs.tinyos.net/
