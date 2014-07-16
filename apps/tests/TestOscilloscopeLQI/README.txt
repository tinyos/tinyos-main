README for MultihopOscilloscope
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:

MultihopOscilloscope is a simple data-collection demo. It periodically samples
the default sensor and broadcasts a message every few readings. These readings
can be displayed by the Java "Oscilloscope" application found in the
TINYOS_ROOT_DIR/apps/Oscilloscope/java subdirectory. The sampling rate starts at 4Hz,
but can be changed from the Java application.

You can compile MultihopOscilloscope with a sensor board's default sensor by
compiling as follows:

  SENSORBOARD=<sensorboard name> make <mote>

You can change the sensor used by editing MultihopOscilloscopeAppC.nc.

This version of MultihopOscilloscope uses the MultihopLQI collection
layer in tos/lib/net/lqi.

Tools:

The Java application displays readings it receives from motes running the
MultihopOscilloscope demo via a serial forwarder. To run it, change to the
TINYOS_ROOT_DIR/apps/Oscilloscope/java subdirectory and type:

  make
  java net.tinyos.sf.SerialForwarder -comm serial@<serial port>:<mote>
  # e.g., java net.tinyps.sf.SerialForwarder -comm serial@/dev/ttyUSB0:mica2
  # or java net.tinyps.sf.SerialForwarder -comm serial@COM2:telosb
  ./run

The controls at the bootom of the screen allow yoy to zoom in or out the X
axis, change the range of the Y axis, and clear all received data. You can
change the color used to display a mote by clicking on its color in the
mote table.

Known bugs/limitations:

None.

See also:
TEP 113: Serial Communications, TEP 119: Collection.

Notes:

MultihopOscilloscope configures a mote whose TOS_NODE_ID modulo 500 is zero 
to be a collection root.
