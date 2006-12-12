README for RadioCountToLeds
Author/Contact: tinyos-help@millennium.berkeley.edu

Description:

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


$Id: README.txt,v 1.4 2006-12-12 18:22:48 vlahan Exp $
