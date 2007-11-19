README for AntiTheft
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:

AntiTheft is a demo "antitheft" application. The accompanying
tutorial-slides.ppt Powerpoint file is a tutorial for TinyOS that uses
AntiTheft to introduce various aspects of TinyOS and its services.
The slides are also available in PDF format in tutorial-slides.pdf
(but with animation missing).

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

This demo is written for mica2, micaz or iris motes using the mts300
sensor board.

The code in the Nodes directory should be installed on the motes
detecting theft. Each mote should have a separate id, and a mts31n0 or
mts300 sensor board.  The code in the Root directory should be installed
on a mote connected to the PC using a programming board. It talks to the
java GUI, forwarding settings from the PC to the sensor network, and
forwarding theft alerts from the sensor network to the PC. See below for
detailed usage instructions.

Tools:

The java directory contains a control GUI for the antitheft demo app.

Usage:

The following instructions will get you started with the AntiTheft demo
(the instructions are for mica2 motes, replace mica2 with micaz or iris
if using either of those motes)

1. Compile the root and node code for the antitheft application for your
   platform (mica2, micaz or iris):

    $ (cd Nodes; make mica2)
    $ (cd Root; make mica2)

2. Install the root code on a mote with a distinct identifier (e.g., 0):

    $ (cd Root; make mica2 reinstall.0 <your usual installation options>)
    # For instance: (cd Root; make mica2 reinstall.0 mib510,/dev/ttyUSB0)

3. Install the node code on some number of mica2 motes, giving each mote
   a distinct id.

    $ (cd Nodes; make mica2 reinstall.N <your usual installation options>)
    # For instance: (cd Nodes; make mica2 reinstall.22 mib510,/dev/ttyUSB0)

4. Put some mts310 sensor boards on the non-root mica2 motes. You can use
   mts300 boards instead, but then the acceleration detection will not work.

5. Connect the root mica2 mote to your PC and switch on all motes.

6. Compile and run the java application. The text below assumes your 
   serial port is /dev/ttyS0, replace with the actual port you are using
   (e.g., COM3 on Windows or /dev/ttyUSB0 on Linux)

   $ cd java
   $ make # Unecessary if antitheft.jar exists
   $ java net.tinyos.sf.SerialForwarder -comm serial@/dev/ttyS0:mica2
   $ ./run # start the graphical user interface

7. The buttons and text field on the right allow you to change the theft
   detection and reporting settings. The interval text box changes the
   interval at which motes check for theft (default is every
   second). Changes are only sent to the mote network when you press the
   Update button. Finally, if you've selected the Server theft report
   option, the message area will report received theft messages.

Known bugs/limitations:

- A newly turned on mote may not send theft reports (when the "Server"
  theft report option is chosen), as:
  o It takes a little while after motes turn on for them to join the multihop
    collection network. 
  o It can take a little while for motes to receive the current settings.

None.


$Id: README.txt,v 1.6 2007-11-19 17:21:20 sallai Exp $
