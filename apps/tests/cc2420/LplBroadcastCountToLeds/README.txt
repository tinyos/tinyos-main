README for RadioCountToLeds
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:

This is a low power listening version of RadioCountToLeds,
using the broadcast address to delivery packets.  That means the 
delivery will remain on for the full duration of the receiver's 
LPL check to ensure all listeners get the message.

Each node is performing 1 second receive checks, but there is a 
1.5 second delay between each transmission.

Verification:
 * Install the application on two motes
 * Both motes should count up their LED's just like RadioCountToLeds
   - This indicates they are communicating with each other.
 * LED's will not toggle in rhythm.
   - Being a broadcast LPL transmission, you'll sometimes see
     the LED's count up one at a time, or multiple counts
     at a time.  This is normal.

If you see LED's waggling on both motes, the test passed.

To compile for motes with CC2420 radios, you must do:
  env CFLAGS="-DLOW_POWER_LISTENING" make <platform>




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


$Id: README.txt,v 1.3 2008-06-23 23:43:53 idgay Exp $
