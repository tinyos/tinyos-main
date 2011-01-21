README for tkn154 test applications
Author/Contact: Jan Hauer <hauer@tkn.tu-berlin.de>

Description:

This folder contains test applications for "TKN15.4", a platform-independent
IEEE 802.15.4-2006 MAC implementation. Applications that use the beacon-enabled
mode are located in the "beacon-enabled" folder, applications that use the
nonbeacon-enabled mode are in the "nonbeacon-enabled" folder. Every test
application resides in a separate subdirectory which includes a README.txt
describing what it does and how it can be installed.

The TKN15.4 implementation can be found in tinyos-2.x/tos/lib/mac/tkn154
(start with the README.txt in that directory).

If you pass "tkn154debug" to the make system, then a debug mode is enabled,
where useful information is sent over the serial line and can be displayed
with the java PrintfClient (see TinyOS tutorial "The TinyOS printf Library").
Example: "make telosb install tkn154debug"
To display debug messages run (replace XXX):
  "java net.tinyos.tools.PrintfClient -comm serial@/dev/ttyUSBXXX:telosb"

Note: TEP3 recommends that interface names "should be mixed case, starting
upper case". To match the syntax used in the IEEE 802.15.4 standard the
interfaces provided by the MAC to the next higher layer deviate from this
convention (they are all caps, e.g. MLME_START).

$Id: README.txt,v 1.4 2010-01-05 17:12:57 janhauer Exp $

