README for tkn154 test applications
Author/Contact: Jan Hauer <hauer@tkn.tu-berlin.de>

Description:

This folder contains test applications for "TKN15.4", a platform-independent
IEEE 802.15.4-2006 MAC implementation. Applications that use the beacon-enabled
mode are located in the "beacon-enabled" folder, applications that use the
nonbeacon-enabled mode are in the "nonbeacon-enabled" folder. Every test
application resides in a separate subdirectory which includes a README.txt
describing what it does and how it can be installed.  The TKN15.4
implementation can be found in tinyos-2.x/tos/lib/mac/tkn154 (start with the
README.txt in that directory).


If you want to use the TKN15.4 MAC instead of your platform's default MAC
protocol in your own application, all you need to do is add the line

    include $(TINYOS_OS_DIR)/lib/mac/tkn154/Makefile.include

in your application's Makefile after the "include $(TINYOS_ROOT_DIR)/Makefile.include"
line as shown
in the example applications. This is also true, if your application uses the
Active Message abstraction and you want to use the TKN15.4 MAC underneath AM.
The full-blown MAC consumes quite a lot of program memory, but you can remove
some functionality at compile time by setting IEEE154_X_DISABLED flags defined
in $(TINYOS_OS_DIR)/lib/mac/tkn154/TKN154.h (e.g. adding them to the CFLAGS in your
Makefile). The MAC interfaces are located in tos/lib/mac/tkn154/interfaces
and TKN154.h is typically the only MAC header file that your application needs
to include.


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


