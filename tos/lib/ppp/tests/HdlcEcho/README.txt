The HdlcEcho application receives HDLC-encoded frames and echoes them back,
with the number of octets in the received frame inserted at the start
(resulting in a returned frame that is one octet longer than was sent).

This test requires the PPP4Py package.  See
$(OSIANROOT)/tinyos/tos/lib/ppp/README for further details.

Build and install for your platform.  If your device is not available on
/dev/ttyUSB0 at 115200 baud, you will have to edit the gendata.py script.
Then run the test.sh script.

Test this with these build combinations:

# Defaults
make osian surf
# Enable mote-side compression of the address/control fields
make accomp osian surf
# Enable both mote-side and pc-side compression of address/control fields
make accomp inhibit_accomp osian surf
