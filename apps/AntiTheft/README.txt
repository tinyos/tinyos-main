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

Known bugs/limitations:

None.


$Id: README.txt,v 1.2 2007-04-02 20:39:04 idgay Exp $
