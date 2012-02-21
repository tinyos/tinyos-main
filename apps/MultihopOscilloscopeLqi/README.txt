README for MultihopOscilloscopeLqi
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:

MultihopOscilloscope is a simple data-collection demo. This variant,
MultihopOscilloscopeLqi, works only on platforms that have the CC2420.
Rather than use CTP, it uses MultihopLqi (lib/net/lqi), which is 
much lighter weight but not quite as efficient or reliable. 

The application periodically samples the default sensor and broadcasts a
message every few readings. These readings can be displayed by the Java
"Oscilloscope" application found in the ./java subdirectory. The sampling rate
starts at 1Hz, but can be changed from the Java application.

You can compile MultihopOscilloscope with a sensor board's default sensor by
compiling as follows:

  SENSORBOARD=<sensorboard name> make <mote>

You can change the sensor used by editing MultihopOscilloscopeAppC.nc.

Tools:

The Java application displays readings it receives from motes running the
MultihopOscilloscope demo via a serial forwarder. To run it, change to the
./java subdirectory and type:

  make
  java net.tinyos.sf.SerialForwarder -comm serial@<serial port>:<mote>
  # e.g., java net.tinyos.sf.SerialForwarder -comm serial@/dev/ttyUSB0:mica2
  # or java net.tinyos.sf.SerialForwarder -comm serial@COM2:telosb
  ./run

The controls at the bottom of the screen allow you to zoom in or out the X
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
