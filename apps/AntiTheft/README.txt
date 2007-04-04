README for AntiTheft
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:

AntiTheft is a demo "antitheft" application. The accompanying
tutorial-slides.ppt Powerpoint file is a tutorial for TinyOS that uses
AntiTheft to introduce various aspects of TinyOS and its services.

AntiTheft can detect theft by:
- light level (a dark mote is a mote that has been stolen and placed in
  a concealed dark place, e.g., a pocket!)
- acceleration (you have to move a mote to steal it...)

It can report theft by:
- turning on an alert light (a red LED)
- beeping a sounder
- reporting the theft to nodes within broadcast radio range (nodes
  receiving this message turn on their red LED)
- reporting the theft to a central node via multihop (collection) routing

The antitheft detection and reporting choices are remotely controllable
using the java GUI found in the java subdirectory.

Nodes blink their yellow LED when turned on or when an internal error
occurs, and blink their green LED when new settings are received.

This demo is written for mica2 or micaz motes using the mts300 sensor
board.

The code in the Nodes directory should be installed on the motes
detecting theft. Each mote should have a separate id, and a mts300
sensor board.  The code in the Root directory should be installed on a
mote connected to the PC using a programming board. It talks to the java
GUI, forwarding settings from the PC to the sensor network, and
forwarding theft alerts from the sensor network to the PC.

Tools:

The java directory contains a control GUI for the antitheft demo app.
To run it, change to the java subdirectory and type:
  make # Unecessary if antitheft.jar exists
  java net.tinyos.sf.SerialForwarder -comm serial@<serial port>:<mote>
  # e.g., java net.tinyps.sf.SerialForwarder -comm serial@/dev/ttyUSB0:mica2
  # or java net.tinyps.sf.SerialForwarder -comm serial@COM2:telosb
  ./run

The buttons and text field on the right allow you to change the theft detection
and reporting settings. The interval text box changes the interval at which
motes check for theft (default is every second). Changes are only sent to the
mote network when you press the Update button. Finally, if you've selected
the Server theft report option, the message area will report received theft
messages.

Known bugs/limitations:

- A newly turned on mote may not send theft reports (when the "Server"
  theft report option is chosen), as:
  o It takes a little while after motes turn on for them to join the multihop
    collection network. 
  o It can take a little while for motes to receive the current settings.

None.


$Id: README.txt,v 1.3 2007-04-04 22:29:29 idgay Exp $
