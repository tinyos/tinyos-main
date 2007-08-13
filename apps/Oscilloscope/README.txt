README for Oscilloscope
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:

Oscilloscope is a simple data-collection demo. It periodically samples
the default sensor and broadcasts a message over the radio every 10
readings. These readings can be received by a BaseStation mote and
displayed by the Java "Oscilloscope" application found in the java
subdirectory. The sampling rate starts at 4Hz, but can be changed from
the Java application.

You can compile Oscilloscope with a sensor board's default sensor by compiling
as follows:
  SENSORBOARD=<sensorboard name> make <mote>

You can change the sensor used by editing OscilloscopeAppC.nc.

Tools:

To display the readings from Oscilloscope motes, install the BaseStation
application on a mote connected to your PC's serial port. Then run the 
Oscilloscope display application found in the java subdirectory, as
follows:
  cd java
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


$Id: README.txt,v 1.5 2007-08-13 15:51:20 idgay Exp $
