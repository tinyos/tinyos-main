README for RadioCountToLeds
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:

This is a low power listening version of RadioCountToLeds,
using the broadcast address to delivery packets.  That means even in
an ack'ing LPL scheme, the delivery will remain on for the full 
duration of the receiver's LPL check to ensure all listeners get the message.

Try it with ACK_LOW_POWER_LISTENING and NOACK_LOW_POWER_LISTENING by editing
the Makefile

RadioCountToLeds maintains a 4Hz counter, broadcasting its value in 
an AM packet every time it gets updated. A RadioCountToLeds node that 
hears a counter displays the bottom three bits on its LEDs. This 
application is a useful test to show that basic AM communication and 
timers work.

Tools:

RadioCountMsg.java is a Java class representing the message that
this application sends.  RadioCountMsg.py is a Python class representing
the message that this application sends.

Known bugs/limitations:

None.


$Id: README.txt,v 1.1 2007-04-12 17:14:08 rincon Exp $
