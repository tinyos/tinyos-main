README for Oscilloscope
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:

Oscilloscope is a simple data-collection demo. It periodically samples the
default sensor and broadcasts a message every 10 readings. These readings
can be displayed by the Java "Oscilloscope" application found in the java
subdirectory. The sampling rate starts at 4Hz, but can be changed from the
Java application.

You can compile Oscilloscope with a sensor board's default sensor by compiling
as follows:
  SENSORBOARD=<sensorboard name> make <mote>

You can change the sensor used by editing OscilloscopeAppC.nc.

Tools:

The Java application displays readings it receives from motes running the
Oscilloscope demo via a serial forwarder. To run it, change to the java
subdirectory and type:
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


$Id: README.txt,v 1.3 2006-11-07 19:30:34 scipio Exp $
