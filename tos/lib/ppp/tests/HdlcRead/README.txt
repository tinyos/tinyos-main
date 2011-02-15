The HdlcRead application receives HDLC-encoded frames over the serial port,
and prints a summary of what it got.

This test requires the PPP4Py package.  See
$(OSIANROOT)/tinyos/tos/lib/ppp/README for further details.

Build and install for your platform.  If your device is not available on
/dev/ttyUSB0 at 115200 baud, you will have to edit the gendata.py script.
Then run the test.sh script.
