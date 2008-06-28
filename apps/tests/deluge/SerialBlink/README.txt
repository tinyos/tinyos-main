README for apps/tests/deluge/SerialBlink
Author/Contact:

Chieh-Jan Mike Liang <cliang4@cs.jhu.edu>
Razvan Musaloiu-E. <razvanm@cs.jhu.edu>

Description:

This is a sample application for Deluge T2. The program blinks and
sends a serial message every second. On a testbed equipped with a
serial back-channel the following test can be run:
   1) Compile and burn the program on all the motes on the
      testbed. The serial messages send by the motes is one-byte value
      of 0.
   2) Compile and burn a base station. This can be done by adding
      CFLAGS=-DDELUGE_BASESTATION to the make command. For telosb this
      will look like this:
      	   CFLAGS=-DDELUGE_BASESTATION make telosb
   3) Compile a different version of SerialBlink by adding
      CFLAGS=-DBLINK_REVERSE to the make command. For telosb this
      will look like this:
      	   CFLAGS=-DBLINK_REVERSE make telosb
   4) Upload the new SerialBlink to the base station. For a telosb
      connected to /dev/ttyUSB0 this can be accomplish using this
      command:
       	   tos-deluge /dev/ttyUSB0 telosb -i 1 build/telosb/tos_image.xml
   5) Give the command to disseminate-and-reboot:
       	   tos-deluge /dev/ttyUSB0 telosb -dr 1

As the motes get and reprogram with the new image they will start
sending on the serial a one-byte value of 2.

For a more detailed discussion on Deluge T2, please refer to the Deluge 
T2 wiki page.

Prerequisites:

Python 2.4 with pySerial

References:

The Deluge T2 wiki page from http://docs.tinyos.net/
